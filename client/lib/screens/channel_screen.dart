import 'package:flutter/material.dart';
import 'add_new_channel.dart';

class ChannelsBody extends StatelessWidget {
  const ChannelsBody({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Only Allow user whose role permits channel addition ( user is admin), role = 1
    // This can be done by checking the role from TokenStore

    return SafeArea(
      top: false, // AppBar is in MainScreen, so no extra top padding
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionHeader(
            title: 'Sales Channels',
            subtitle: 'Manage your store integrations',
          ),
          const SizedBox(height: 12),

          ChannelCard(
            leadingMonogram: 'S',
            storeName: 'Main Store',
            platformName: 'Shopify',
            ordersText: '45 orders',
            status: ChannelStatus.connected,
            revenue: '\$1,125',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          ChannelCard(
            leadingMonogram: 'W',
            storeName: 'Marketplace',
            platformName: 'WooCommerce',
            ordersText: '37 orders',
            status: ChannelStatus.connected,
            revenue: '\$925',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          ChannelCard(
            leadingMonogram: 'IG',
            storeName: 'Social Store',
            platformName: 'Instagram Shop',
            ordersText: '12 orders',
            status: ChannelStatus.syncing,
            revenue: '\$280',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          ChannelCard(
            leadingMonogram: 'B2B',
            storeName: 'B2B Portal',
            platformName: 'Custom',
            ordersText: '0 orders',
            status: ChannelStatus.disconnected,
            revenue: '\$0',
            onTap: () {},
          ),

          const SizedBox(height: 16),

          _AddNewChannelCard(
            onConnect: () {
              // TODO: open your connect-channel flow
              Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddChannelPage()),
    );
            },
          ),

          const SizedBox(height: 12),
         
        ],
      ),
    );
  }
}

/* ==== Section Header ==== */
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/* ==== Models / Enums ==== */
enum ChannelStatus { connected, syncing, disconnected }

/* ==== Channel Card ==== */
class ChannelCard extends StatelessWidget {
  final String leadingMonogram;
  final String storeName;
  final String platformName;
  final String ordersText;
  final ChannelStatus status;
  final String revenue;
  final VoidCallback? onTap;

  const ChannelCard({
    super.key,
    required this.leadingMonogram,
    required this.storeName,
    required this.platformName,
    required this.ordersText,
    required this.status,
    required this.revenue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(.18)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _MonogramBadge(text: leadingMonogram),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          storeName,
                          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PlatformBadge(text: platformName),
                      const SizedBox(width: 8),
                      Text(
                        ordersText,
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(revenue, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/* ==== Monogram Badge ==== */
class _MonogramBadge extends StatelessWidget {
  final String text;
  const _MonogramBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(.35)),
        color: cs.primary.withOpacity(.10),
      ),
      child: Text(
        text,
        style: t.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

/* ==== Platform Badge ==== */
class PlatformBadge extends StatelessWidget {
  final String text;
  const PlatformBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.28)),
        color: cs.surfaceVariant.withOpacity(.25),
      ),
      child: Text(
        text,
        style: t.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withOpacity(.8),
        ),
      ),
    );
  }
}

/* ==== Status Chip ==== */
class StatusChip extends StatelessWidget {
  final ChannelStatus status;
  const StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    late final String label;
    late final Color bg;
    late final Color fg;
    late final IconData icon;

    switch (status) {
      case ChannelStatus.connected:
        label = 'Connected';
        bg = cs.secondary.withOpacity(.18);
        fg = cs.secondary;
        icon = Icons.check_circle_rounded;
        break;
      case ChannelStatus.syncing:
        label = 'Syncing';
        bg = cs.primary.withOpacity(.18);
        fg = cs.primary;
        icon = Icons.sync_rounded;
        break;
      case ChannelStatus.disconnected:
        label = 'Disconnected';
        bg = Colors.redAccent.withOpacity(.18);
        fg = Colors.redAccent;
        icon = Icons.error_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: fg.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/* ==== Add New Channel Card ==== */
class _AddNewChannelCard extends StatelessWidget {
  final VoidCallback onConnect;
  const _AddNewChannelCard({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.25)),
        color: cs.surface,
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.surfaceVariant.withOpacity(.35),
              border: Border.all(color: cs.outlineVariant.withOpacity(.25)),
            ),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          Text('Add New Channel',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Connect another sales platform',
            style: t.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onConnect,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.primary.withOpacity(.45)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Connect Channel'),
            ),
          ),
        ],
      ),
    );
  }
}
