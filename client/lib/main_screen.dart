import 'package:flutter/material.dart';
import 'package:inventify/widget/bottom_nav_bar.dart';
import 'package:inventify/features/dashboard/dashboard_screen.dart';
import 'package:inventify/screens/setting_screen.dart';
import 'package:inventify/screens/channel_screen.dart';
import 'package:inventify/screens/products_screen.dart';
import 'package:inventify/screens/order_screen.dart';

// Placeholder for screens you haven't built yet
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title Screen'));
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of all the main screens
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductsScreen(),
    const OrdersScreen(),
    const ChannelsBody(),
    const SettingsScreen(),
  ];
  
  // List of titles for the AppBar
  final List<String> _titles = [
    'Dashboard',
    'Products',
    'Orders',
    'Channels',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}