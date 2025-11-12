import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, String name) {
    // Navigation or dialog logic can go here
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
                        'JD',
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
                        Text('John Doe',
                            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('john.doe@example.com',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out (demo)')),
                          );
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
