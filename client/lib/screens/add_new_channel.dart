import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:inventify/services/woo_service.dart'; 
import 'package:inventify/services/token_store.dart'; 

enum ChannelType { woocommerce, ondc }

class AddChannelPage extends StatefulWidget {
  const AddChannelPage({super.key});

  @override
  State<AddChannelPage> createState() => _AddChannelPageState();
}

class _AddChannelPageState extends State<AddChannelPage> {
  ChannelType? _selected;

  // WooCommerce fields
  final _wooUrlCtl = TextEditingController();
  final _wooKeyCtl = TextEditingController();
  final _wooSecretCtl = TextEditingController();

  // ONDC fields
  final _ondcRegistryCtl = TextEditingController();
  final _ondcBuyerCtl = TextEditingController();
  final _ondcSellerCtl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Service + state
  final WooService _wooService = WooService(
    baseUrl: 'http://10.0.2.2:8080', // change to localhost for iOS / web
  );
  bool _loading = false;

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
          color: selected ? cs.primary.withOpacity(.12) : cs.surface,
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

  // ---------------------- SELECTOR AREA (CARDS ONLY) ----------------------
  Widget _selectorArea() {
    return Column(
      children: [
        _channelCard(ChannelType.woocommerce, 'WooCommerce', 'Use your Woo store (REST API)', 'W'),
        const SizedBox(height: 10),
        _channelCard(ChannelType.ondc, 'ONDC', 'Buy/Sell on ONDC network', 'O'),
      ],
    );
  }

  // ---------------------- FORMS ----------------------
  Widget _wooForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldWithHelp(
          label: 'Shop URL',
          child: TextFormField(
            controller: _wooUrlCtl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://yourstore.com',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter shop URL';
              if (!v.startsWith('https://')) return 'Store URL must use HTTPS';
              return null;
            },
          ),
          helpTitle: 'Shop URL',
          helpText: 'Enter your WooCommerce store URL (must be HTTPS).',
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
          helpText: 'Generated in WooCommerce → Settings → Advanced → REST API.',
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
          helpText: 'Generated along with the key. Must have Read/Write permission.',
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Connect WooCommerce'),
          ),
        ),
      ],
    );
  }

  Widget _ondcForm() {
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
          helpText: 'Used to connect to ONDC gateway or registry.',
        ),
        const SizedBox(height: 10),
        _fieldWithHelp(
          label: 'Buyer ID / Client ID',
          child: TextFormField(
            controller: _ondcBuyerCtl,
            decoration: const InputDecoration(hintText: 'buyer/client id'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Buyer/Client ID' : null,
          ),
          helpTitle: 'Buyer ID',
          helpText: 'ONDC-issued buyer/client identifier.',
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
          helpText: 'Authentication token or seller identifier.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Connect ONDC'),
          ),
        ),
      ],
    );
  }

  // ---------------------- HELP FIELD UI ----------------------
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              child,
            ],
          ),
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

  // ---------------------- SUBMIT ----------------------
  void _submit() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a channel first.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final token = await TokenStore.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in before connecting a channel.')),
        );
        setState(() => _loading = false);
        return;
      }

      if (_selected == ChannelType.woocommerce) {
        final site = _wooUrlCtl.text.trim();
        final key = _wooKeyCtl.text.trim();
        final secret = _wooSecretCtl.text.trim();

        // call the backend
        final store = await _wooService.createWooStore(
          token: token,
          siteUrl: site,
          consumerKey: key,
          consumerSecret: secret,
          verifySSL: true,
        );

        final id = store['id'] ?? store['result'] ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WooCommerce store connected (id: $id)')),
        );

        // close and signal success
        if (mounted) Navigator.of(context).pop(true);

      } else {
        // For ONDC: integrate your ONDC service call here. For now demo:
        final registry = _ondcRegistryCtl.text.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ONDC connected (registry: $registry)')),
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      final msg = (e is Exception) ? e.toString() : 'Failed to connect';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------- UI ----------------------
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
            Text('Select channel', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Choose a channel above to view connection fields.',
                              style: t.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
