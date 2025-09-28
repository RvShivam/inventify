import 'package:flutter/material.dart';
import 'package:inventify/widget/metric_card.dart';
import 'package:inventify/widget/order_list_item.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> metricData = [
      {'title': 'Total Sales', 'value': '\$1,250', 'icon': Icons.attach_money, 'color': colorScheme.secondary},
      {'title': 'Total Orders', 'value': '82', 'icon': Icons.shopping_cart, 'color': colorScheme.secondary},
      {'title': 'Products', 'value': '45', 'icon': Icons.inventory_2, 'color': colorScheme.secondary},
      {'title': 'Low Stock', 'value': '3', 'icon': Icons.warning_amber, 'color': colorScheme.error},
    ];
    
    final List<Map<String, dynamic>> recentOrdersData = [
      {'title': 'Order #1082 - Handmade Scarf', 'subtitle': 'Shopify, 2m ago', 'amount': '\$25.00', 'color': colorScheme.secondary},
      {'title': 'Order #1081 - Clay Vase', 'subtitle': 'WooCommerce, 1h ago', 'amount': '\$40.00', 'color': colorScheme.secondary},
      {'title': 'Order #1080 - Scented Candle', 'subtitle': 'Amazon, 3h ago', 'amount': '\$15.50', 'color': colorScheme.secondary},
    ];

    // The root widget is now the SingleChildScrollView, NOT a Scaffold
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final crossAxisCount = isWide ? 4 : 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: metricData.map((item) {
                  return MetricCard(
                    title: item['title'],
                    value: item['value'],
                    icon: item['icon'],
                    iconColor: item['color'],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Recent Orders',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                itemCount: recentOrdersData.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = recentOrdersData[index];
                  return OrderListItem(
                    title: item['title'],
                    subtitle: item['subtitle'],
                    amount: item['amount'],
                    color: item['color'],
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
            ],
          );
        },
      ),
    );
  }
}
