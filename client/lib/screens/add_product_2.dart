// add_product_step2_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_product_3.dart';

class AddProductStep2Screen extends StatefulWidget {
  const AddProductStep2Screen({super.key});

  @override
  State<AddProductStep2Screen> createState() => _AddProductStep2ScreenState();
}

class _AddProductStep2ScreenState extends State<AddProductStep2Screen> {
  final _formKey = GlobalKey<FormState>();

  final _skuCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();
  final _compareAtCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _lenCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heigCtrl = TextEditingController();
  final _widCtrl = TextEditingController();


  @override
  void dispose() {
    _skuCtrl.dispose();
    _mrpCtrl.dispose();
    _compareAtCtrl.dispose();
    _barcodeCtrl.dispose();
    _lenCtrl.dispose();
    _weightCtrl.dispose();
    _heigCtrl.dispose();
    _widCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_formKey.currentState!.validate()) {
      
      // TODO: Navigate to Step 3 screen here
       Navigator.push(context, MaterialPageRoute(builder: (_) => const ChannelsAndPublishingStep()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

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
                Text('Step 2 of 3', style: t.labelMedium),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 2 / 3,
                    minHeight: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    backgroundColor:
                        const Color.fromARGB(255, 98, 196, 241).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Step 2 of 3', style: t.labelMedium),
              ),
              const Spacer(),
              FilledButton(onPressed: _goNext, child: const Text('Next')),
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
              const _StepperRowStep2Active(),
              const SizedBox(height: 16),

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
                      _requiredLabel(context, 'SKU'),
                      TextFormField(
                        controller: _skuCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'e.g., TSH-ORG-001',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      _requiredLabel(context, 'Price (MRP)'),
                      TextFormField(
                        controller: _mrpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          hintText: '999.00',
                          prefixIcon:
                              Icon(Icons.currency_rupee, size: 18, color: cs.secondary),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final n = double.tryParse(v.replaceAll(',', ''));
                          if (n == null) return 'Enter a valid amount';
                          if (n <= 0) return 'Amount must be > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _label(context, 'Compare-at Price (Optional)'),
                      TextFormField(
                        controller: _compareAtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          hintText: '1299.00',
                          prefixIcon:
                              Icon(Icons.currency_rupee, size: 18, color: cs.secondary),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _label(context, 'Barcode'),
                      TextFormField(
                        controller: _barcodeCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // ✅ numbers only
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter barcode',
                          prefixIcon: Icon(Icons.qr_code_2, size: 20, color: cs.secondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                       _requiredLabel(context, 'Length(cm)'),
                      TextFormField(
                        controller: _lenCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) ,
                        ],
                        decoration: InputDecoration(
                          hintText: '30',
                          
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      
                       _requiredLabel(context, 'Height(cm)'),
                      TextFormField(
                        controller: _heigCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) ,
                        ],
                        decoration: InputDecoration(
                          hintText: '25',
                          
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      
                       _requiredLabel(context, 'Width(cm)'),
                      TextFormField(
                        controller: _widCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) ,
                        ],
                        decoration: InputDecoration(
                          hintText: '20',
                          
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      
                       _requiredLabel(context, 'Weight(kg)'),
                      TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) ,
                        ],
                        decoration: InputDecoration(
                          hintText: '5',
                          
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

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

  // --- Label helpers (with red asterisk for required) ---
  Widget _requiredLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(
            text: text,
            style: Theme.of(context).textTheme.labelLarge,
            children: [
              TextSpan(
                text: ' *',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

// ---- Top stepper row with step 2 active ----
class _StepperRowStep2Active extends StatelessWidget {
  const _StepperRowStep2Active();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = const [
      (true, Icons.check, 'Core\nDetails'),
      (true, Icons.attach_money, 'Pricing\n& Shipping'), // active/completed look
      (false, Icons.storefront, 'Channels\n& Publishing'),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _StepDot(
            active: items[i].$1,
            icon: items[i].$2,
            label: items[i].$3,
            isCore: i == 0,
          ),
          if (i != items.length - 1)
            Expanded(
              child: Divider(
                height: 32,
                thickness: 1,
                indent: 8,
                endIndent: 8,
                color: cs.onSurface.withOpacity(.25),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final bool isCore;
  const _StepDot({required this.active, required this.icon, required this.label,this.isCore = false,});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bgColor = isCore
        ? cs.secondary // ✅ Core Details gets secondary color
        : (active ? cs.primary : cs.surfaceVariant);

    final Color iconColor = isCore
        ? Colors.white
        : (active ? cs.onPrimary : cs.onSurfaceVariant);

    final Color textColor = isCore
        ? cs.secondary // ✅ Core Details label in secondary color
        : (active ? cs.primary : cs.onSurfaceVariant);   

    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: bgColor,
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: active ? FontWeight.w600 : null,
                ),
          ),
        ),
      ],
    );
  }
}
