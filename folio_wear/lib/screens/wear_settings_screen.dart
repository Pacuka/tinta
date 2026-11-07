import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/wear_data_provider.dart';
import '../theme/wear_theme.dart';
import '../widgets/edge_fade.dart';
import '../widgets/page_title.dart';
import '../widgets/wear_curved_scrollbar.dart';

const _kCardBg = WearColors.surface;
// Round screen: keep content away from the curved edge.
const _kHPad = 22.0;
const _kRadius = 20.0;
const _kItemH = 52.0;

class WearSettingsScreen extends StatelessWidget {
  final ScrollController scrollController;
  const WearSettingsScreen({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Consumer<WearDataProvider>(builder: (context, data, _) {
        return WearCurvedScrollbar(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Header
              SliverPadding(
                padding: const EdgeInsets.only(
                    top: 30.0, left: 28.0, right: 28.0, bottom: 8.0),
                sliver: const SliverToBoxAdapter(child: PageTitle('Beállítások')),
              ),

              // Sync section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _kHPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TapItem(
                        icon: Icons.sync_rounded,
                        iconColor: const Color(0xFF80CBC4),
                        label: 'Szinkronizálás most',
                        subtitle: data.lastSync != null
                            ? _relTime(data.lastSync!)
                            : 'Még nem szinkronizált',
                        enabled: data.connected,
                        onTap: data.requestSync,
                      ),
                      const SizedBox(height: 4.0),
                      _InfoItem(
                        icon: data.isPaired
                            ? Icons.smartphone_rounded
                            : Icons.link_off_rounded,
                        iconColor: data.isPaired
                            ? const Color(0xFF80CBC4)
                            : const Color(0xFFEF9A9A),
                        label: data.isPaired ? 'Párosítva' : 'Nincs párosítva',
                        subtitle: data.isPaired
                            ? (data.connected
                                ? 'Telefon csatlakoztatva'
                                : 'A telefon nem elérhető')
                            : 'Kód: ${data.pairingCode}',
                      ),
                      if (data.isPaired) ...[
                        const SizedBox(height: 4.0),
                        _TapItem(
                          icon: Icons.link_off_rounded,
                          iconColor: const Color(0xFFEF9A9A),
                          label: 'Leválasztás',
                          subtitle: 'Párosítás törlése',
                          destructive: true,
                          onTap: () => _confirmUnpair(context, data),
                        ),
                      ],
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 52.0)),
            ],
          ),
        );
      }),
    );
  }

  static String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Most';
    if (d.inHours < 1) return '${d.inMinutes} perce';
    if (d.inDays < 1) return '${d.inHours} órája';
    return DateFormat('MM.dd HH:mm').format(t);
  }

  void _confirmUnpair(BuildContext context, WearDataProvider data) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: _kCardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Leválaszt?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15.0,
                fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Az eszköz leválasztásra kerül. Új párosítás szükséges.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11.0),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Mégse',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                data.unpair();
              },
              child: Text('Leválaszt',
                  style: TextStyle(
                      color: cs.error, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ItemBase extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  const _ItemBase({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = destructive
        ? const Color(0xFFEF9A9A)
        : Colors.white.withValues(alpha: enabled ? 1.0 : 0.38);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: EdgeFade(child: Container(
        height: _kItemH,
        margin: const EdgeInsets.only(bottom: 4.0),
        decoration: BoxDecoration(
          color: destructive
              ? const Color(0xFF3D1212)
              : _kCardBg,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: iconColor.withValues(
                    alpha: enabled ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon,
                  size: 16.0,
                  color: iconColor.withValues(
                      alpha: enabled ? 0.9 : 0.4)),
            ),
            const SizedBox(width: 10.0),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2.5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: WearColors.muted
                            .withValues(alpha: enabled ? 1.0 : 0.5),
                        height: 1.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            if (trailing != null) trailing!,
          ],
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TapItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  const _TapItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _ItemBase(
      icon: icon,
      iconColor: iconColor,
      label: label,
      subtitle: subtitle,
      destructive: destructive,
      enabled: enabled,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18.0,
        color: Colors.white.withValues(alpha: enabled ? 0.25 : 0.12),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _ItemBase(
      icon: icon,
      iconColor: iconColor,
      label: label,
      subtitle: subtitle,
    );
  }
}
