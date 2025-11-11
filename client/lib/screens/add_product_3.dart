import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChannelsAndPublishingStep extends StatefulWidget {
  const ChannelsAndPublishingStep({super.key});

  @override
  State<ChannelsAndPublishingStep> createState() => _ChannelsAndPublishingStepState();
}

class _ChannelsAndPublishingStepState extends State<ChannelsAndPublishingStep> {
  // Toggles
  bool wooEnabled = false;
  bool ondcEnabled = false;

  // --- WooCommerce Settings ---
  final TextEditingController wooCustomPriceCtrl = TextEditingController();
  String? wooTaxStatus; // taxable, shipping, none
  final TextEditingController wooShippingClassCtrl = TextEditingController();

  // --- ONDC Settings ---
  String? ondcCategory; // e.g., Grocery, Fashion, Electronics
  String? ondcFulfillment; // Hyperlocal / Intercity
  final TextEditingController ondcReturnWindowDaysCtrl = TextEditingController();
  final TextEditingController ondcMaxDispatchHrsCtrl = TextEditingController();

  @override
  void dispose() {
    wooCustomPriceCtrl.dispose();
    wooShippingClassCtrl.dispose();
    ondcReturnWindowDaysCtrl.dispose();
    ondcMaxDispatchHrsCtrl.dispose();
    super.dispose();
  }

  int get selectedCount => [wooEnabled, ondcEnabled].where((e) => e).length;

  void _saveAndPublish() {
    // Validate nothing heavy here; you can add per-channel validations if required.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Publishing to $selectedCount channel(s)…')),
    );
  }

  // ---------- Bottom Sheets ----------
  Future<void> _showWooOptions() async {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('WooCommerce Settings', style: t.titleMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Customize pricing and metadata for this channel', style: t.bodySmall),
              const SizedBox(height: 16),

              // Custom Price
              Text('Custom Price (Override)', style: t.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: wooCustomPriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                decoration: InputDecoration(
                  hintText: 'Leave empty to use default price',
                  prefixIcon: Icon(Icons.attach_money, color: cs.secondary, size: 18),
                  suffixIcon: IconButton(
                    onPressed: () => wooCustomPriceCtrl.clear(),
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tax Status
              Text('Tax Status', style: t.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: wooTaxStatus,
                items: const [
                  DropdownMenuItem(value: 'taxable', child: Text('Taxable')),
                  DropdownMenuItem(value: 'shipping', child: Text('Shipping')),
                  DropdownMenuItem(value: 'none', child: Text('None')),
                ],
                onChanged: (v) => setState(() => wooTaxStatus = v),
                decoration: const InputDecoration(hintText: 'Select tax status'),
              ),
              const SizedBox(height: 16),

              // Shipping Class
              Text('Shipping Class', style: t.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: wooShippingClassCtrl,
                decoration: const InputDecoration(hintText: 'e.g., standard'),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showOndcOptions() async {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('ONDC Settings', style: t.titleMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Set ONDC-specific catalog and SLA values', style: t.bodySmall),
              const SizedBox(height: 16),

              // Category
              Text('Category', style: t.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: ondcCategory,
                items: const [
                  DropdownMenuItem(value: 'grocery', child: Text('Grocery')),
                  DropdownMenuItem(value: 'fashion', child: Text('Fashion')),
                  DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                ],
                onChanged: (v) => setState(() => ondcCategory = v),
                decoration: const InputDecoration(hintText: 'Select a category'),
              ),
              const SizedBox(height: 16),

              // Fulfillment Type
              Text('Fulfillment', style: t.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: ondcFulfillment,
                items: const [
                  DropdownMenuItem(value: 'hyperlocal', child: Text('Hyperlocal')),
                  DropdownMenuItem(value: 'intercity', child: Text('Intercity')),
                ],
                onChanged: (v) => setState(() => ondcFulfillment = v),
                decoration: const InputDecoration(hintText: 'Choose fulfillment type'),
              ),
              const SizedBox(height: 16),

              // Return Window (days)
              Text('Return Window (days)', style: t.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: ondcReturnWindowDaysCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'e.g., 7'),
              ),
              const SizedBox(height: 16),

              // Max Dispatch Time (hours)
              Text('Max Dispatch Time (hours)', style: t.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: ondcMaxDispatchHrsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'e.g., 24'),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 3 of 3', style: t.labelMedium),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 3 / 3,
                    minHeight: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    backgroundColor: cs.primary.withOpacity(0.2),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
              Text('Step 3 of 3', style: t.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              FilledButton(
                onPressed: selectedCount == 0 ? null : _saveAndPublish,
                child: const Text('Save and Publish'),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _StepperRowStep4Active(),
              const SizedBox(height: 16),

              // Card: Select Sales Channels (Shopify removed)
              _boxed(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Sales Channels', style: t.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Choose where you want to list this product',
                      style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7)),
                    ),
                    const SizedBox(height: 12),

                    // WooCommerce
                    _channelTile(
                      context,
                      title: 'WooCommerce',
                      enabled: wooEnabled,
                      onChanged: (v) => setState(() => wooEnabled = v),
                      trailing: wooEnabled
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.tune, size: 18),
                              label: const Text('Options'),
                              onPressed: _showWooOptions,
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // ONDC
                    _channelTile(
                      context,
                      title: 'ONDC',
                      enabled: ondcEnabled,
                      onChanged: (v) => setState(() => ondcEnabled = v),
                      trailing: ondcEnabled
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.tune, size: 18),
                              label: const Text('Options'),
                              onPressed: _showOndcOptions,
                            )
                          : null,
                    ),

                    const SizedBox(height: 12),

                    // Ready banner
                    if (selectedCount > 0)
                      Container(
                        decoration: BoxDecoration(
                          color: cs.secondary.withOpacity(.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.secondary.withOpacity(.4)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: cs.secondary, // filled circle
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready to publish on $selectedCount channel(s)',
                                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your product will be synced automatically to selected channels',
                                    style: t.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Small helpers ---
  Widget _boxed({required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

 Widget _channelTile(
  BuildContext context, {
  required String title,
  required bool enabled,
  required ValueChanged<bool> onChanged,
  Widget? trailing,
}) {
  final cs = Theme.of(context).colorScheme;

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.outlineVariant.withOpacity(.3)), // lightened
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Switch(
        value: enabled,
        onChanged: onChanged,

        // ✅ Secondary color when ON
        activeTrackColor: cs.secondary,
        inactiveTrackColor: cs.surfaceVariant,

        // ✅ White thumb on secondary
        activeColor: Colors.white,
        inactiveThumbColor: cs.outlineVariant,

        // Removes black outline in Material 3
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing: trailing,
    ),
  );
}

}

// ---- Stepper (Step 4 active) ----
class _StepperRowStep4Active extends StatelessWidget {
  const _StepperRowStep4Active();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // (completed, icon, label, isActive)
    final items = const [
      (true, Icons.check, 'Core\nDetails', false),
      (true, Icons.check, 'Pricing\n& Shipping', false),
      (false, Icons.storefront, 'Channels\n& Publishing', true),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _StepDot(
            completed: items[i].$1,
            icon: items[i].$2,
            label: items[i].$3,
            active: items[i].$4,
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
  final bool completed;
  final bool active;
  final IconData icon;
  final String label;

  const _StepDot({
    required this.completed,
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Completed steps: simple filled circle with secondary + white check.
    // Active step: filled with primary (or primaryContainer) and white icon.
    final Color bg = completed
        ? cs.secondary
        : (active ? cs.primary : cs.surfaceVariant);
    final Color fg = completed
        ? Colors.white
        : (active ? cs.onPrimary : cs.onSurfaceVariant);

    final Color textColor = completed
        ? cs.secondary
        //: (active ? cs.primary : null);
        : (active ? cs.primary : Theme.of(context).textTheme.bodySmall?.color ?? cs.onSurface);

    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: bg,
          child: Icon(icon, size: 18, color: fg),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: active || completed ? FontWeight.w600 : null,
                ),
          ),
        ),
      ],
    );
  }
}
