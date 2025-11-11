import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart'; // Required for Uint8List
import 'add_product_2.dart'; 


class AddNewProductScreen extends StatefulWidget {
  const AddNewProductScreen({super.key});

  @override
  State<AddNewProductScreen> createState() => _AddNewProductScreenState();
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  String? _category;

  // Use (path, bytes) tuple instead of File for web compatibility
  final _images = <(String, Uint8List)>[]; 
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    
    // Read bytes for each picked file (required for display on web)
    final byteFutures = picked.map((xFile) => xFile.readAsBytes());
    final bytesList = await Future.wait(byteFutures);

    setState(() {
      _images.addAll(
        Iterable.generate(picked.length, (i) => (picked[i].path, bytesList[i])),
      );
    });
  }

  // Function to handle setting an image as primary (moves to index 0)
  void _onSetPrimary(int index) {
    if (index == 0) return;
    setState(() {
      final image = _images.removeAt(index);
      _images.insert(0, image);
    });
  }

  void _onRemove(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }


  void goToNextStep(Widget nextScreen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  void _next() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    goToNextStep(const AddProductStep2Screen());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _brandCtrl.dispose();
    _hsnCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        bottom: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 1 of 3', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:  LinearProgressIndicator(
                  value: 1 / 3, // update as you move through steps
                  minHeight: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  
                  backgroundColor: const Color.fromARGB(255, 98, 196, 241).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        ),
      ),

      // Bottom bar: Back • Step 1 of 3 • Next
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Back')),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Step 1 of 3', style: textTheme.labelMedium),
              ),
              const Spacer(),
              FilledButton(onPressed: _next, child: const Text('Next')),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top stepper row (icons + labels)
              _StepperRow(),
              const SizedBox(height: 16),

              // Card with fields
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
                ),
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // PRODUCT NAME
                      _label('Product Name', textTheme, required: true),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Organic Cotton T-Shirt',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // DESCRIPTION
                      _label('Description', textTheme, ),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Write a detailed product description…',
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Product Images', textTheme),
                      const SizedBox(height: 6),
                      // 🛑 UploadBox now handles the layout to match Figma
                      _UploadBox(
                        images: _images,
                        onAdd: _pickImages,
                        onRemove: _onRemove,
                        onSetPrimary: _onSetPrimary, 
                      ),
                      const SizedBox(height: 16),

                      _label('Category ', textTheme, required: true),
                      DropdownButtonFormField<String>(
                        value: _category,
                        hint: const Text('Select category'),
                        items: const [
                          DropdownMenuItem(value: 'Apparel', child: Text('Apparel')),
                          DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                          DropdownMenuItem(value: 'Home Goods', child: Text('Home Goods')),
                          DropdownMenuItem(value: 'Handicrafts', child: Text('Handicrafts')),
                          DropdownMenuItem(value: 'Accessories', child: Text('Accessories')),
                        ],
                        onChanged: (v) => setState(() => _category = v),
                        validator: (v) => v == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 12),

                      // BRAND
                      _field('Brand', _brandCtrl, cs, hint: 'Brand name', prefixIcon: Icons.local_offer),
                      const SizedBox(height: 12),

                      // HSN CODE
                      _field('HSN Code', _hsnCtrl, cs,
                          hint: 'e.g., 6109', keyboardType: TextInputType.number,
                          inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) 
  ],
                          ),

                          
                      const SizedBox(height: 12),

                       _label('Stock', textTheme, required: true),
                      TextFormField(
                        controller: _stockCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                         FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) 
  ],
                        decoration: const InputDecoration(
                        
                          hintText: 'e.g., 10',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // COUNTRY OF ORIGIN
                      _field('Country of Origin', _countryCtrl, cs, hint: 'e.g., India', prefixIcon: Icons.public),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Uses RichText to show a red asterisk if required is true.
  Widget _label(String text, TextTheme t, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: required
            ? RichText(
                text: TextSpan(
                  text: text,
                  style: t.labelLarge,
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              )
            : Text(text, style: t.labelLarge),
      );

  // Helper for text fields with optional icon
  Widget _field(String label, TextEditingController c, ColorScheme cs,
      {String? hint, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, IconData? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, Theme.of(context).textTheme),
        TextFormField(
          controller: c,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: cs.secondary) : null,
          ),
        ),
      ],
    );
  }
}

// ---- Stepper row ----
class _StepperRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = const [
      (true, Icons.inventory_2, 'Core\nDetails'),
      (false, Icons.attach_money, 'Pricing\n& Shipping'),
      (false, Icons.storefront, 'Channels\n& Publishing'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          // Step Circle + Label
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: items[i].$1 ? cs.primary : cs.surfaceVariant,
                  child: Icon(
                    items[i].$2,
                    size: 20,
                    color: items[i].$1 ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items[i].$3,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              items[i].$1 ? cs.primary : cs.onSurfaceVariant.withOpacity(0.8),
                          fontWeight:
                              items[i].$1 ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),

          // Divider line BETWEEN circles (except after last one)
          if (i != items.length - 1)
            Container(
              width: 28,
              height: 1.5,
              margin: const EdgeInsets.only(bottom: 24), // aligns the line between icons
              color: cs.outline.withOpacity(0.5),
            ),
        ],
      ],
    );
  }
}

// ---- Upload box (dashed) ----
class _UploadBox extends StatelessWidget {
  final List<(String, Uint8List)> images;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index) onSetPrimary;

  const _UploadBox({
    required this.images,
    required this.onAdd,
    required this.onRemove,
    required this.onSetPrimary, 
  });

  // Helper method to create the main, large Dotted Upload Box
  Widget _buildLargeDottedUploadBox(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return DottedBorder(
      color: cs.outlineVariant,
      dashPattern: const [6, 6],
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 150, // Fixed height to match initial design screenshot
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload, size: 36, color: cs.secondary),
              const SizedBox(height: 8),
              const Text('Click or drag images to upload'),
              const SizedBox(height: 4),
              const Text('PNG, JPG up to 10MB each. Drag to reorder.',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // 🛑 KEY CHANGE: Use a Column to stack the large upload box and the grid.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. The Large Dotted Upload Box (always visible at the top)
        _buildLargeDottedUploadBox(context),

        // 2. The Image Thumbnails Grid (only visible if images are present)
        if (images.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0, 
            ),
            itemBuilder: (context, i) {
              final cs = Theme.of(context).colorScheme;
              final isPrimary = i == 0;
              final imageBytes = images[i].$2;
              
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(imageBytes, fit: BoxFit.cover), 
                  ),
                  
                  // Primary Tag
                  if (isPrimary)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.secondary, 
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text('Primary',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                )),
                      ),
                    ),

                  // Remove Button (Top Right)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      onTap: () => onRemove(i),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),

                  // "Set as Primary" button (Bottom Right - only for non-primary images)
                  if (!isPrimary)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: InkWell(
                        onTap: () => onSetPrimary(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Set Primary',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  )),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String title;
  
  const _StepChip({required this.active, required this.icon, required this.title, });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: active ? cs.primary : cs.surfaceVariant,
          child: Icon(icon, size: 18, color: active ? cs.onPrimary : cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        // Title
        Text(title,
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              color: active ? cs.primary : cs.onSurface,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}