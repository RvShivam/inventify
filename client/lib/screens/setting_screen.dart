import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventify/screens/login_screen.dart';
import 'package:inventify/services/auth_service.dart';
import 'package:inventify/services/organization_service.dart';
import 'package:inventify/services/token_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _orgService = OrganizationService();
  final _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _orgData;
  Map<String, dynamic>? _userData;
  bool _isAdmin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final org = await _orgService.getOrganization();
      final user = await _authService.getProfile();
      final roleId = await TokenStore.getRoleId();
      
      if (mounted) {
        setState(() {
          _orgData = org;
          _userData = user;
          _isAdmin = roleId == 1; // Assuming 1 is Admin
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _regenerateCode() async {
    if (!_isAdmin) return;

    try {
      final newCode = await _orgService.regenerateReferralCode();
      setState(() {
        _orgData?['referralCode'] = newCode;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral code updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update code: $e')),
        );
      }
    }
  }

  void _copyCode() {
    final code = _orgData?['referralCode'];
    if (code != null) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copied to clipboard')),
      );
    }
  }

  void _open(BuildContext context, String name) {
    // Navigation or dialog logic can go here
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16),
          child: Text(
            title,
            style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    Widget panel({required Widget child}) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withOpacity(.14)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: child,
        );

    Widget settingTile({
      required BuildContext ctx,
      required String title,
      String? subtitle,
      required IconData leading,
      Color? leadingBg,
      Color? leadingFg,
      VoidCallback? onTap,
      bool destructive = false,
    }) {
      final fg = destructive ? Colors.redAccent : null;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _open(ctx, title),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: leadingBg ?? cs.surfaceVariant.withOpacity(.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(leading, color: leadingFg ?? (fg ?? cs.primary), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: t.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: t.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(.68),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(.6)),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      top: false, // since your AppBar is outside this screen
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Profile Card
          panel(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.primary.withOpacity(.22)),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Text(
                        (_userData?['name'] as String?)?.isNotEmpty == true
                            ? (_userData!['name'] as String).substring(0, 1).toUpperCase()
                            : 'U',
                        style: t.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userData?['name'] ?? 'User',
                            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(_userData?['email'] ?? '',
                            style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _open(context, 'Edit Profile'),
                    icon: const Icon(Icons.edit_rounded),
                    color: cs.onSurface.withOpacity(.7),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Staff Invitation Section
          sectionHeader('Staff Invitation'),
          panel(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person_add_alt_1_rounded, color: cs.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invitation Code',
                            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_orgData?['memberCount'] ?? 0} staff members connected',
                            style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Code', style: t.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                      color: cs.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group_outlined, size: 20, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _orgData?['referralCode'] ?? 'N/A',
                            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAdmin ? _regenerateCode : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text('Generate New Code'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy_rounded),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Only admins can generate new codes',
                        style: t.bodySmall?.copyWith(color: cs.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Account Section
          sectionHeader('Account'),
          panel(
            child: Column(
              children: [
                settingTile(
                  ctx: context,
                  leading: Icons.person_2_rounded,
                  title: 'Profile',
                  subtitle: 'Manage your account information',
                  onTap: () => _open(context, 'Profile'),
                ),
                const Divider(height: 0),
                settingTile(
                  ctx: context,
                  leading: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Configure notification preferences',
                  onTap: () => _open(context, 'Notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Security
          sectionHeader('Security'),
          panel(
            child: settingTile(
              ctx: context,
              leading: Icons.lock_rounded,
              title: 'Privacy & Security',
              subtitle: 'Password, two-factor authentication',
              onTap: () => _open(context, 'Privacy & Security'),
            ),
          ),
          const SizedBox(height: 12),

          // Support
          sectionHeader('Support'),
          panel(
            child: settingTile(
              ctx: context,
              leading: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'FAQs, contact support, tutorials',
              onTap: () => _open(context, 'Help & Support'),
            ),
          ),
          const SizedBox(height: 12),

          // Account Actions
          sectionHeader('Account Actions'),
          panel(
            child: settingTile(
              ctx: context,
              leading: Icons.logout_rounded,
              leadingBg: Colors.redAccent.withOpacity(.12),
              leadingFg: Colors.redAccent,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Sign out'),
                    content: const Text('Are you sure you want to sign out of your account?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(c).pop();
                          _logout();
                        },
                        child: const Text(
                          'Sign out',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
              destructive: true,
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'App Version 1.0.0',
              style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.6)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
