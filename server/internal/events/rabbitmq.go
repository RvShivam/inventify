package events

import (
	"encoding/json"
	"errors"
	"log"
	"sync"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

var (
	mu         sync.RWMutex
	conn       *amqp.Connection
	ch         *amqp.Channel
	amqpURL    string
	readyCond  = sync.NewCond(&mu) // signalled when ch is ready
	consumers  = make([]*consumerReg, 0)
	closing    = false
	reconnWait = 3 * time.Second
)

// consumerReg holds information about a registered consumer so we can re-create it on reconnect.
type consumerReg struct {
	QueueName  string
	BindingKey string
	Handler    func(body []byte) error
	Options    consumerOptions
}

type consumerOptions struct {
	Durable    bool
	AutoDelete bool
	Exclusive  bool
	NoWait     bool
	Args       amqp.Table
	// Note: you may want to add PrefetchCount, ConsumerName etc.
}

// InitRabbitMQ initializes connection and channel; returns error if initial connection fails.
// It spawns a reconnect goroutine that will try to re-establish the connection if it drops.
func InitRabbitMQ(url string) error {
	mu.Lock()
	if conn != nil {
		// already initialized
		mu.Unlock()
		return nil
	}
	amqpURL = url
	mu.Unlock()

	if err := dialAndSetup(); err != nil {
		return err
	}

	// start a monitor for connection close to reconnect automatically
	go monitorConnection()

	return nil
}

// dialAndSetup performs actual dialing and basic setup (exchange)
func dialAndSetup() error {
	mu.Lock()
	defer mu.Unlock()

	if closing {
		return errors.New("events package is shutting down")
	}

	var err error
	conn, err = amqp.Dial(amqpURL)
	if err != nil {
		return err
	}
	ch, err = conn.Channel()
	if err != nil {
		_ = conn.Close()
		conn = nil
		return err
	}

	// declare durable exchange
	if err := ch.ExchangeDeclare(
		ExchangeName,
		ExchangeType,
		true,  // durable
		false, // autoDelete
		false, // internal
		false, // noWait
		nil,   // args
	); err != nil {
		_ = ch.Close()
		_ = conn.Close()
		ch = nil
		conn = nil
		return err
	}

	// notify anyone waiting that channel is ready
	readyCond.Broadcast()

	// re-create registered consumers
	for _, reg := range consumers {
		go startConsumerForReg(reg)
	}

	log.Println("[events] connected to rabbitmq and exchange declared")
	return nil
}

// monitorConnection watches for connection close and tries to reconnect.
func monitorConnection() {
	for {
		mu.RLock()
		c := conn
		mu.RUnlock()

		if c == nil {
			// try to dial after a wait
			time.Sleep(reconnWait)
			if err := dialAndSetup(); err != nil {
				log.Println("[events] reconnect failed:", err)
			}
			continue
		}

		// wait for close notification
		closeErrChan := make(chan *amqp.Error, 1)
		c.NotifyClose(closeErrChan)
		err := <-closeErrChan
		if err == nil {
			// graceful close triggered by Close(); exit monitor
			log.Println("[events] rabbitmq connection closed gracefully")
			return
		}
		log.Println("[events] rabbitmq connection closed, will attempt reconnect:", err)

		// cleanup existing channel/connection pointers
		mu.Lock()
		if ch != nil {
			_ = ch.Close()
			ch = nil
		}
		if conn != nil {
			_ = conn.Close()
			conn = nil
		}
		mu.Unlock()

		// attempt reconnect in a loop
		for {
			if closing {
				return
			}
			if err := dialAndSetup(); err != nil {
				log.Println("[events] reconnect attempt failed:", err)
				time.Sleep(reconnWait)
				continue
			}
			// reconnected
			break
		}
	}
}

// Publish publishes a message to the exchange with given routing key. msg will be JSON-marshaled.
func Publish(routingKey string, msg interface{}) error {
	mu.RLock()
	localCh := ch
	mu.RUnlock()
	if localCh == nil {
		return errors.New("rabbitmq channel not ready")
	}
	body, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	pub := amqp.Publishing{
		ContentType:  "application/json",
		Body:         body,
		DeliveryMode: amqp.Persistent,
		Timestamp:    time.Now(),
	}
	if err := localCh.Publish(ExchangeName, routingKey, false, false, pub); err != nil {
		return err
	}
	return nil
}

// Consume registers a consumer (queue + binding) and starts delivering messages to handler.
// The handler must return nil on success (message will be Acked) or an error (message will be Nack'ed and requeued).
// Durable queue is created by default.
func Consume(queueName, bindingKey string, handler func(body []byte) error) error {
	reg := &consumerReg{
		QueueName:  queueName,
		BindingKey: bindingKey,
		Handler:    handler,
		Options: consumerOptions{
			Durable: true,
			Args:    nil,
		},
	}

	mu.Lock()
	consumers = append(consumers, reg)
	localCh := ch
	mu.Unlock()

	// if channel is already ready, start consumer immediately
	if localCh != nil {
		go startConsumerForReg(reg)
	}
	return nil
}

// startConsumerForReg sets up queue, binding and a goroutine that processes deliveries for a reg.
func startConsumerForReg(reg *consumerReg) {
	for {
		// wait until a channel is ready
		mu.Lock()
		for ch == nil && !closing {
			readyCond.Wait()
		}
		localCh := ch
		mu.Unlock()

		if closing {
			return
		}
		if localCh == nil {
			time.Sleep(500 * time.Millisecond)
			continue
		}

		// declare queue
		queue, err := localCh.QueueDeclare(
			reg.QueueName,
			reg.Options.Durable,
			reg.Options.AutoDelete,
			reg.Options.Exclusive,
			reg.Options.NoWait,
			reg.Options.Args,
		)
		if err != nil {
			log.Printf("[events] queue declare error for %s: %v — will retry", reg.QueueName, err)
			time.Sleep(reconnWait)
			continue
		}

		// bind queue to exchange with bindingKey
		if err := localCh.QueueBind(queue.Name, reg.BindingKey, ExchangeName, false, nil); err != nil {
			log.Printf("[events] queue bind error for %s -> %s: %v — will retry", queue.Name, reg.BindingKey, err)
			time.Sleep(reconnWait)
			continue
		}

		// start consuming
		msgs, err := localCh.Consume(queue.Name, "", false, false, false, false, nil)
		if err != nil {
			log.Printf("[events] consume error for %s: %v — will retry", queue.Name, err)
			time.Sleep(reconnWait)
			continue
		}

		// process deliveries until the channel is closed
		processing := true
		for processing {
			select {
			case d, ok := <-msgs:
				if !ok {
					// channel closed — break to outer loop so we wait for reconnect
					processing = false
					break
				}
				// call handler synchronously; handler decides ack/nack via returned error
				if err := reg.Handler(d.Body); err != nil {
					// Nack and requeue
					_ = d.Nack(false, true)
					log.Printf("[events] handler error for queue %s: %v — message nacked and requeued", queue.Name, err)
					continue
				} else {
					_ = d.Ack(false)
				}
			}
		}

		// if we reach here, something closed the msgs channel; try to restart consumer on next loop iteration
		log.Printf("[events] consumer for queue=%s binding=%s stopped; will re-register when connection returns", reg.QueueName, reg.BindingKey)
		time.Sleep(500 * time.Millisecond)
	}
}

// Close gracefully closes the channel and connection and prevents further reconnect attempts.
func Close() error {
	mu.Lock()
	closing = true
	if ch != nil {
		if err := ch.Close(); err != nil {
			log.Println("[events] channel close error:", err)
		}
		ch = nil
	}
	if conn != nil {
		if err := conn.Close(); err != nil {
			log.Println("[events] connection close error:", err)
		}
		conn = nil
	}
	readyCond.Broadcast()
	mu.Unlock()
	return nil
}
