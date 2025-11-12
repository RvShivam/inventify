import 'package:flutter/material.dart';

class Product {
  final String name;
  final String sku;
  final double price;
  final int stock;
  final String category;

  Product({
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.category,
  });
}

class ProductFilter {
  RangeValues priceRange;
  RangeValues stockRange;
  bool showLowStockOnly;
  bool showOutOfStockOnly;
  Set<String> selectedCategories;

  ProductFilter({
    required this.priceRange,
    required this.stockRange,
    this.showLowStockOnly = false,
    this.showOutOfStockOnly = false,
    required this.selectedCategories,
  });

  factory ProductFilter.initial() => ProductFilter(
        priceRange: const RangeValues(0, 500),
        stockRange: const RangeValues(0, 200),
        selectedCategories: <String>{},
      );
}

class FilterScreen extends StatefulWidget {
  final ValueChanged<ProductFilter>? onApplyFilters;
  final ProductFilter? initialFilters;

  const FilterScreen({super.key, this.onApplyFilters, this.initialFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final double maxPrice = 500.0;
  final int maxStock = 200;
  final List<String> allCategories = const [
    'Apparel',
    'Home Goods',
    'Accessories',
    'Kitchen',
    'Decor',
    'Electronics'
  ];

  late ProductFilter currentFilters;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      currentFilters = ProductFilter(
        priceRange: widget.initialFilters!.priceRange,
        stockRange: widget.initialFilters!.stockRange,
        showLowStockOnly: widget.initialFilters!.showLowStockOnly,
        showOutOfStockOnly: widget.initialFilters!.showOutOfStockOnly,
        selectedCategories: Set.from(widget.initialFilters!.selectedCategories),
      );
    } else {
      currentFilters = ProductFilter.initial();
      currentFilters.priceRange = RangeValues(0, maxPrice);
      currentFilters.stockRange = RangeValues(0, maxStock.toDouble());
    }
  }

  void _resetFilters() {
    setState(() {
      currentFilters = ProductFilter.initial();
      currentFilters.priceRange = RangeValues(0, maxPrice);
      currentFilters.stockRange = RangeValues(0, maxStock.toDouble());
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop(currentFilters);
  }

  Widget _buildRangeSlider({
    required String title,
    required RangeValues values,
    required double max,
    required Function(RangeValues) onChanged,
    bool isInt = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isInt
                  ? values.start.round().toString()
                  : '₹${values.start.toStringAsFixed(2)}',
              style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold),
            ),
            Text(
              isInt
                  ? values.end.round().toString()
                  : '₹${values.end.toStringAsFixed(2)}',
              style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: 0,
          max: max,
          activeColor: cs.secondary,
          inactiveColor: cs.secondary.withOpacity(.25),
          divisions: isInt ? max.round() : null,
          labels: RangeLabels(
            isInt ? values.start.round().toString() : values.start.toStringAsFixed(0),
            isInt ? values.end.round().toString() : values.end.toStringAsFixed(0),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggleSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: cs.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: allCategories.map((category) {
        final isSelected = currentFilters.selectedCategories.contains(category);
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                currentFilters.selectedCategories.add(category);
              } else {
                currentFilters.selectedCategories.remove(category);
              }
            });
          },
          selectedColor: cs.secondary,
          labelStyle: TextStyle(
            color: isSelected ? cs.onSecondary : cs.onSurface.withOpacity(.8),
          ),
          backgroundColor: cs.surfaceVariant.withOpacity(.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? cs.secondary : cs.outline.withOpacity(.4),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Filters', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRangeSlider(
                    title: 'Price Range',
                    max: maxPrice,
                    values: currentFilters.priceRange,
                    onChanged: (RangeValues newValues) {
                      setState(() => currentFilters.priceRange = newValues);
                    },
                  ),
                  const Divider(height: 32, thickness: 1),
                  _buildRangeSlider(
                    title: 'Stock Range',
                    max: maxStock.toDouble(),
                    values: currentFilters.stockRange,
                    isInt: true,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        currentFilters.stockRange = RangeValues(
                          newValues.start.roundToDouble(),
                          newValues.end.roundToDouble(),
                        );
                      });
                    },
                  ),
                  const Divider(height: 32, thickness: 1),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Stock Status', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  _buildToggleSwitch(
                    title: 'Show Low Stock Only',
                    value: currentFilters.showLowStockOnly,
                    onChanged: (bool value) {
                      setState(() => currentFilters.showLowStockOnly = value);
                    },
                  ),
                  _buildToggleSwitch(
                    title: 'Show Out of Stock Only',
                    value: currentFilters.showOutOfStockOnly,
                    onChanged: (bool value) {
                      setState(() => currentFilters.showOutOfStockOnly = value);
                    },
                  ),
                  const Divider(height: 32, thickness: 1),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  _buildCategoryChips(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary, // ✅ Secondary color
                  foregroundColor: cs.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
