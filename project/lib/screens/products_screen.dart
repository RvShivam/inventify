import 'package:flutter/material.dart';

// -------------------------------------------------------------
// PRODUCTS SCREEN (MAIN VIEW)
// -------------------------------------------------------------
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // State to manage the active filter button
  String _activeFilter = 'In Stock'; 

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const FilterModal();
      },
    );
  }

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AddProductModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Note: This Scaffold includes the AppBar for the Products view.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // In a bottom navigation tab, this usually does nothing or navigates to a root screen
          },
        ),
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddProductModal,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
          const SizedBox(width: 8.0),
        ],
        elevation: 0.0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Search Field and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // Filter Buttons Row
                Row(
                  children: [
                    FilterButton(
                      label: 'In Stock',
                      isActive: _activeFilter == 'In Stock',
                      onPressed: () => setState(() => _activeFilter = 'In Stock'),
                    ),
                    const SizedBox(width: 8.0),
                    FilterButton(
                      label: 'Out of Stock',
                      isActive: _activeFilter == 'Out of Stock',
                      onPressed: () => setState(() => _activeFilter = 'Out of Stock'),
                    ),
                    const SizedBox(width: 8.0),
                    FilterButton(
                      label: 'Low Stock',
                      isActive: _activeFilter == 'Low Stock',
                      onPressed: () => setState(() => _activeFilter = 'Low Stock'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product List Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: const <Widget>[
                ProductTile(name: 'Freshwear Scarf', stock: 55, sku: 'SCARF-BLU41', price: 15.00),
                Divider(),
                ProductTile(name: 'Scented Candle', stock: 12, sku: 'CANDLE-LAV-05', price: 21.00),
                Divider(),
                ProductTile(name: 'Clay Vase', stock: 0, sku: 'VASE-GRN-K1D', price: 40.00),
                Divider(),
                ProductTile(name: 'Leather Belt', stock: 200, sku: 'BELT-BLK-LGE', price: 35.00),
                Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// HELPER WIDGETS
// -------------------------------------------------------------

class ProductTile extends StatelessWidget {
  final String name;
  final int stock;
  final String sku;
  final double price;

  const ProductTile({super.key, required this.name, required this.stock, required this.sku, required this.price});

  Color getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 20) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final stockColor = getStockColor(stock);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.0)),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('SKU: $sku'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Stock: $stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stockColor)),
        ],
      ),
      onTap: () {},
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const FilterButton({super.key, required this.label, required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? Colors.white : Colors.grey[700],
        backgroundColor: isActive ? Colors.blue : Colors.transparent,
        side: BorderSide(color: isActive ? Colors.blue : Colors.grey.shade300, width: 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class FilterModal extends StatelessWidget {
  const FilterModal({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Filter Modal UI code from previous response)
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.90, 
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Advanced Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Reset', style: TextStyle(color: Colors.blue))),
              ],
            ),
            const Divider(),
            // ... Filter Content (omitted for brevity)
            const Expanded(child: Center(child: Text("Filter Sliders and Sort Options"))),
            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductModal extends StatelessWidget {
  const AddProductModal({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Add Product Modal UI code from previous response)
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add New Product', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            // ... Form Content (omitted for brevity)
            const Expanded(child: Center(child: Text("Product Upload Form Fields"))),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save New Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// -------------------------------------------------------------
// END product_page.dart
// -------------------------------------------------------------