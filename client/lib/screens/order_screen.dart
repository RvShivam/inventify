import 'package:flutter/material.dart';

/// Lightweight model for an order item
class OrderItem {
  final String id;
  final String name;
  final String items;
  final String timeAgo;
  final String price;
  final String status;

  const OrderItem({
    required this.id,
    required this.name,
    required this.items,
    required this.timeAgo,
    required this.price,
    required this.status,
  });
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // sample orders
  final List<OrderItem> _orders = const [
    OrderItem(
      id: '#1082',
      name: 'Sarah Johnson',
      items: '2 items',
      timeAgo: '2m ago',
      price: '\$65.00',
      status: 'Processing',
    ),
    OrderItem(
      id: '#1081',
      name: 'Mike Chen',
      items: '1 item',
      timeAgo: '1h ago',
      price: '\$40.00',
      status: 'Shipped',
    ),
    OrderItem(
      id: '#1080',
      name: 'Emma Davis',
      items: '3 items',
      timeAgo: '3h ago',
      price: '\$95.00',
      status: 'Delivered',
    ),
    OrderItem(
      id: '#1079',
      name: 'Alex Rodriguez',
      items: '1 item',
      timeAgo: '5h ago',
      price: '\$25.00',
      status: 'Pending',
    ),
  ];

  // UI state
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderItem> get _filteredOrders {
    if (_query.trim().isEmpty) return _orders;
    final q = _query.toLowerCase();
    return _orders.where((o) {
      return o.id.toLowerCase().contains(q) ||
          o.name.toLowerCase().contains(q) ||
          o.status.toLowerCase().contains(q);
    }).toList();
  }

  Color _statusColor(String status, ColorScheme cs) {
    final s = status.toLowerCase();
    if (s == 'processing') return cs.primaryContainer;
    if (s == 'shipped') return cs.secondaryContainer;
    if (s == 'delivered') return Colors.green.shade300;
    if (s == 'pending') return Colors.amber.shade300;
    return cs.surfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final muted = tt.bodySmall?.color ?? cs.onSurface.withOpacity(0.6);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search, color: muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search orders, names, statuses...',
                        hintStyle: tt.bodySmall?.copyWith(color: muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Summary row
            Row(
              children: [
                Text(
                  'Orders',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_filteredOrders.length})',
                  style: tt.bodySmall?.copyWith(color: muted),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _query = 'pending';
                      _searchCtrl.text = _query;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_outlined, size: 16),
                  label: const Text('Pending'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Orders list
            Expanded(
              child: _filteredOrders.isEmpty
                  ? Center(
                      child: Text('No orders found', style: tt.bodyMedium?.copyWith(color: muted)),
                    )
                  : ListView.separated(
                      itemCount: _filteredOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final o = _filteredOrders[idx];
                        final statusColor = _statusColor(o.status, cs);

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Order details navigation
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.surfaceVariant.withOpacity(0.12)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // left column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            o.id,
                                            style: tt.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              o.status,
                                              style: tt.bodySmall?.copyWith(
                                                color: cs.onPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        o.name,
                                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${o.items} · ${o.timeAgo}',
                                        style: tt.bodySmall?.copyWith(color: muted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),

                                // right column (price)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      o.price,
                                      style: tt.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
