import 'package:flutter/material.dart';

// -------------------------------------------------------------
// 1. DASHBOARD CONTENT WIDGET
// -------------------------------------------------------------

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- Sales & Orders Summary Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(child: SummaryCard(title: 'Total Sales', value: '\$1,250', icon: Icons.attach_money, color: Colors.green)),
              const SizedBox(width: 16.0),
              Expanded(child: SummaryCard(title: 'Total Orders', value: '82', icon: Icons.shopping_bag_outlined, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 24.0),
          
          // --- Product/Stock Summary Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(child: SmallSummaryCard(title: 'Products', value: '45', icon: Icons.category_outlined)),
              const SizedBox(width: 16.0),
              Expanded(child: SmallSummaryCard(title: 'Low Stock', value: '3', icon: Icons.warning_amber_outlined, isAlert: true)),
            ],
          ),
          const SizedBox(height: 32.0),
          
          // --- Recent Orders Section ---
          Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          
          RecentOrderTile(orderId: 'Order #1882', product: 'Handmade Soap', time: 'Simply - 3h ago', price: '\$25.00'),
          const Divider(),
          RecentOrderTile(orderId: 'Order #1881', product: 'Clay Vase', time: 'WooCommerce - 1h ago', price: '\$40.00'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. REUSABLE CUSTOM WIDGETS (Defined here so DashboardContent can use them)
// -------------------------------------------------------------

class SummaryCard extends StatelessWidget {
  final String title; final String value; final IconData icon; final Color color;
  const SummaryCard({super.key, required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4.0),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class SmallSummaryCard extends StatelessWidget {
  final String title; final String value; final IconData icon; final bool isAlert;
  const SmallSummaryCard({super.key, required this.title, required this.value, required this.icon, this.isAlert = false});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : Colors.black)),
                Icon(icon, color: isAlert ? Colors.red : Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class RecentOrderTile extends StatelessWidget {
  final String orderId; final String product; final String time; final String price;
  const RecentOrderTile({super.key, required this.orderId, required this.product, required this.time, required this.price});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(product, style: TextStyle(color: Colors.grey[800])),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
