import 'package:flutter/material.dart';
import 'add_product.dart';
import 'package:inventify/widget/filter.dart';

class Product {
  final String name;
  final int stock;
  final String sku;
  final double price;
  final String category;

  const Product({
    required this.name,
    required this.stock,
    required this.sku,
    required this.price,
    required this.category,
  });
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  ProductFilter _activeFilters = ProductFilter.initial();
  String _query = '';
  String _simpleFilter = 'All';

  final List<Product> _allProducts = const [
    Product(name: 'Freshwear Scarf', stock: 55, sku: 'SCARF-BLU41', price: 15.00, category: 'Apparel'),
    Product(name: 'Scented Candle', stock: 12, sku: 'CANDLE-LAV-05', price: 21.00, category: 'Home Goods'),
    Product(name: 'Clay Vase', stock: 0, sku: 'VASE-GRN-K1D', price: 40.00, category: 'Decor'),
    Product(name: 'Leather Belt', stock: 200, sku: 'BELT-BLK-LGE', price: 35.00, category: 'Accessories'),
    Product(name: 'Copper Mug', stock: 5, sku: 'MUG-COP-001', price: 18.00, category: 'Kitchen'),
    Product(name: 'Smart Watch', stock: 10, sku: 'WATCH-SMT-A90', price: 199.00, category: 'Electronics'),
  ];

  @override
  void initState() {
    super.initState();
    _activeFilters.priceRange = RangeValues(0, _allProducts.map((p) => p.price).reduce((a, b) => a > b ? a : b));
    _activeFilters.stockRange = RangeValues(0, _allProducts.map((p) => p.stock).reduce((a, b) => a > b ? a : b).toDouble());
  }

  void _openFilters() async {
    final result = await Navigator.push<ProductFilter>(
      context,
      MaterialPageRoute(
        builder: (_) => FilterScreen(
          initialFilters: _activeFilters,
          onApplyFilters: (newFilters) {
            setState(() {
              _activeFilters = newFilters;
            });
          },
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _activeFilters = result;
      });
    }
  }

  void _goToAddProduct() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddNewProductScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added')),
      );
      setState(() {});
    }
  }

  List<Product> get _filteredProducts {
    Iterable<Product> list = _allProducts;

    switch (_simpleFilter) {
      case 'In Stock':
        list = list.where((p) => p.stock > 0);
        break;
      case 'Out of Stock':
        list = list.where((p) => p.stock == 0);
        break;
      case 'All':
      default:
        break;
    }

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q));
    }

    list = list.where((p) {
      final meetsPrice = p.price >= _activeFilters.priceRange.start && p.price <= _activeFilters.priceRange.end;
      final meetsStockRange = p.stock >= _activeFilters.stockRange.start.round() && p.stock <= _activeFilters.stockRange.end.round();
      final isLowStock = p.stock > 0 && p.stock < 20;
      final isOutOfStock = p.stock == 0;

      final meetsCategory = _activeFilters.selectedCategories.isEmpty || _activeFilters.selectedCategories.contains(p.category);

      bool meetsStockStatus = true;
      if (_activeFilters.showLowStockOnly && !_activeFilters.showOutOfStockOnly) {
        meetsStockStatus = isLowStock;
      } else if (_activeFilters.showOutOfStockOnly && !_activeFilters.showLowStockOnly) {
        meetsStockStatus = isOutOfStock;
      } else if (_activeFilters.showLowStockOnly && _activeFilters.showOutOfStockOnly) {
        meetsStockStatus = isLowStock || isOutOfStock;
      }

      return meetsPrice && meetsStockRange && meetsCategory && meetsStockStatus;
    });
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddProduct,
         backgroundColor: cs.secondary, // ✅ FAB background is now secondary color
         foregroundColor: cs.onSecondary,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // Search + Filter icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: cs.onSurface),
                    cursorColor: cs.primary,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: cs.onSurface.withOpacity(.6)),
                      prefixIcon: Icon(Icons.search, color: cs.onSurface.withOpacity(.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      // Adaptive fill color for light/dark
                      fillColor: isDark ? cs.surfaceVariant.withOpacity(.06) : cs.surfaceVariant.withOpacity(.12),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Filter',
                  onPressed: _openFilters,
                  icon: Icon(Icons.filter_list, color: cs.onSurface.withOpacity(.8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterButton(
                  label: 'All',
                  isActive: _simpleFilter == 'All',
                  onPressed: () => setState(() => _simpleFilter = 'All'),
                ),
                const SizedBox(width: 8.0),
                FilterButton(
                  label: 'In Stock',
                  isActive: _simpleFilter == 'In Stock',
                  onPressed: () => setState(() => _simpleFilter = 'In Stock'),
                ),
                const SizedBox(width: 8.0),
                FilterButton(
                  label: 'Out of Stock',
                  isActive: _simpleFilter == 'Out of Stock',
                  onPressed: () => setState(() => _simpleFilter = 'Out of Stock'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Product list (filtered)
          Expanded(
            child: Builder(
              builder: (_) {
                final items = _filteredProducts;
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No products match this filter.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final p = items[i];
                    return ProductTile(
                      name: p.name,
                      stock: p.stock,
                      sku: p.sku,
                      price: p.price,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// --- UI helpers (ProductTile and FilterButton) ---
// ----------------------------------------------------------------

class ProductTile extends StatelessWidget {
  final String name;
  final int stock;
  final String sku;
  final double price;

  const ProductTile({
    super.key,
    required this.name,
    required this.stock,
    required this.sku,
    required this.price,
  });

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
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('SKU: $sku'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rupee symbol used here
          Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Stock: $stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stockColor)),
        ],
      ),
      onTap: () {},
    );
  }
}

/// FilterButton now uses the theme's secondary color for active state
class FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const FilterButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final activeBg = cs.secondary;
    final activeFg = cs.onSecondary;
    final inactiveFg = cs.onSurface.withOpacity(.85);
    final inactiveBorder = cs.outline;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? activeFg : inactiveFg,
        backgroundColor: isActive ? activeBg : Colors.transparent,
        side: BorderSide(
          color: isActive ? activeBg : inactiveBorder,
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
