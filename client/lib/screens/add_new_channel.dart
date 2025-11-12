import 'package:flutter/material.dart';

enum ChannelType { woocommerce, ondc }

class AddChannelPage extends StatefulWidget {
  const AddChannelPage({super.key});

  @override
  State<AddChannelPage> createState() => _AddChannelPageState();
}

class _AddChannelPageState extends State<AddChannelPage> {
  ChannelType? _selected;
  bool _useDropdown = false; // toggle between cards and dropdown

  // WooCommerce fields
  final _wooUrlCtl = TextEditingController();
  final _wooKeyCtl = TextEditingController();
  final _wooSecretCtl = TextEditingController();

  // ONDC fields (example placeholders — change as needed)
  final _ondcRegistryCtl = TextEditingController();
  final _ondcBuyerCtl = TextEditingController();
  final _ondcSellerCtl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _wooUrlCtl.dispose();
    _wooKeyCtl.dispose();
    _wooSecretCtl.dispose();
    _ondcRegistryCtl.dispose();
    _ondcBuyerCtl.dispose();
    _ondcSellerCtl.dispose();
    super.dispose();
  }

  void _showHelp(String title, String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))
        ],
      ),
    );
  }

  Widget _channelCard(ChannelType type, String label, String subtitle, String monogram) {
    final selected = _selected == type;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _selected = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(.12) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? cs.primary : cs.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: selected ? cs.primary.withOpacity(.18) : cs.surfaceVariant.withOpacity(.18),
              ),
              child: Text(
                monogram,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _selectorArea() {
    if (_useDropdown) {
      return DropdownButtonFormField<ChannelType>(
        value: _selected,
        hint: const Text('Select channel'),
        items: const [
          DropdownMenuItem(value: ChannelType.woocommerce, child: Text('WooCommerce')),
          DropdownMenuItem(value: ChannelType.ondc, child: Text('ONDC')),
        ],
        onChanged: (v) => setState(() => _selected = v),
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      );
    } else {
      return Column(
        children: [
          _channelCard(ChannelType.woocommerce, 'WooCommerce', 'Use your Woo store (REST API)', 'W'),
          const SizedBox(height: 10),
          _channelCard(ChannelType.ondc, 'ONDC', 'Buy/Sell on ONDC network', 'O'),
        ],
      );
    }
  }

  Widget _wooForm() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldWithHelp(
          label: 'Shop URL',
          child: TextFormField(
            controller: _wooUrlCtl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://example.com'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter shop URL';
              return null;
            },
          ),
          helpTitle: 'Shop URL',
          helpText: 'Enter your store base URL (example: https://your-shop.com). Do NOT include trailing paths; the plugin will call the REST API endpoints automatically.',
        ),
        const SizedBox(height: 10),
        _fieldWithHelp(
          label: 'Consumer Key',
          child: TextFormField(
            controller: _wooKeyCtl,
            decoration: const InputDecoration(hintText: 'ck_xxx...'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter consumer key' : null,
          ),
          helpTitle: 'Consumer Key',
          helpText: 'Generated from WooCommerce → Settings → Advanced → REST API. This is your API consumer key.',
        ),
        const SizedBox(height: 10),
        _fieldWithHelp(
          label: 'Consumer Secret',
          child: TextFormField(
            controller: _wooSecretCtl,
            decoration: const InputDecoration(hintText: 'cs_xxx...'),
            obscureText: true,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter consumer secret' : null,
          ),
          helpTitle: 'Consumer Secret',
          helpText: 'Generated alongside the consumer key. Keep it private.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            child: const Text('Connect WooCommerce'),
          ),
        ),
      ],
    );
  }

  Widget _ondcForm() {
    // Placeholder labels — change to actual ONDC parameters if you want
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldWithHelp(
          label: 'Registry / Gateway URL',
          child: TextFormField(
            controller: _ondcRegistryCtl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://ondc-gateway.example'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter gateway URL' : null,
          ),
          helpTitle: 'Registry / Gateway URL',
          helpText: 'The ONDC gateway or registry URL your integration needs to communicate with.',
        ),
        const SizedBox(height: 10),
        _fieldWithHelp(
          label: 'Buyer ID / Client ID',
          child: TextFormField(
            controller: _ondcBuyerCtl,
            decoration: const InputDecoration(hintText: 'client or buyer id'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Buyer/Client ID' : null,
          ),
          helpTitle: 'Buyer ID / Client ID',
          helpText: 'Your ONDC-issued buyer/client identifier. Used to identify your application on the network.',
        ),
        const SizedBox(height: 10),
        _fieldWithHelp(
          label: 'Seller ID / Token',
          child: TextFormField(
            controller: _ondcSellerCtl,
            decoration: const InputDecoration(hintText: 'seller id or token'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter seller id or token' : null,
          ),
          helpTitle: 'Seller ID / Token',
          helpText: 'Authentication token or seller identifier as required by your ONDC provider.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            child: const Text('Connect ONDC'),
          ),
        ),
      ],
    );
  }

  Widget _fieldWithHelp({
    required String label,
    required Widget child,
    required String helpTitle,
    required String helpText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            child,
          ]),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _showHelp(helpTitle, helpText),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Center(child: Text('?')),
          ),
        )
      ],
    );
  }

  void _submit() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a channel first.')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Collect values and call your backend / connect flow
    if (_selected == ChannelType.woocommerce) {
      final url = _wooUrlCtl.text.trim();
      final key = _wooKeyCtl.text.trim();
      final secret = _wooSecretCtl.text.trim();

      // TODO: Replace with your connect logic
      debugPrint('Connect WooCommerce: $url | $key | $secret');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WooCommerce connected (demo).')));
    } else {
      final registry = _ondcRegistryCtl.text.trim();
      final buyer = _ondcBuyerCtl.text.trim();
      final seller = _ondcSellerCtl.text.trim();

      // TODO: Replace with your connect logic
      debugPrint('Connect ONDC: $registry | $buyer | $seller');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ONDC connected (demo).')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Channel')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text('Select channel', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                const Text('Cards'),
                Switch(
                  value: _useDropdown,
                  onChanged: (v) => setState(() => _useDropdown = v),
                ),
                const Text('Dropdown'),
              ],
            ),
            const SizedBox(height: 12),
            _selectorArea(),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _selected == ChannelType.woocommerce
                    ? _wooForm()
                    : _selected == ChannelType.ondc
                        ? _ondcForm()
                        : Container(
                            key: const ValueKey('placeholder'),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Choose a channel above to view connection fields.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
