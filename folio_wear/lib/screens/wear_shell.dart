import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wear_data_provider.dart';
import '../theme/wear_theme.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'todos_screen.dart';
import 'wear_settings_screen.dart';

/// Pages change only with a horizontal swipe. Vertical scrolling and the crown
/// stay on the current page, so a long list can't slip into the next one.
class WearShell extends StatefulWidget {
  const WearShell({super.key});

  static const pageDotsKey = ValueKey('page-dots');

  @override
  State<WearShell> createState() => _WearShellState();
}

class _WearShellState extends State<WearShell> {
  final _scrollCtrls = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];
  int _currentPage = 0;

  static const _pages = 4;
  static const _crownStep = 120.0;
  static const _exitDistance = 60.0;
  static const _exitSteepness = 1.5;

  double _pulledRight = 0.0;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    WearDataProvider.onRotaryInput = _handleRotary;
  }

  @override
  void dispose() {
    WearDataProvider.onRotaryInput = null;
    for (final c in _scrollCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleRotary(double delta) {
    final ctrl = _scrollCtrls[_currentPage];
    if (!ctrl.hasClients) return;
    final pos = ctrl.position;
    ctrl.jumpTo(
        (pos.pixels + delta * _crownStep).clamp(0.0, pos.maxScrollExtent));
  }

  /// windowSwipeToDismiss is off, so the app handles the swipe-right exit.
  bool _onPageScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification) {
      _pulledRight = 0.0;
      _dragStart = n.dragDetails?.globalPosition;
    }
    if (n is OverscrollNotification && n.overscroll < 0) {
      final drag = n.dragDetails;
      final start = _dragStart;
      if (drag == null || start == null) return false;
      _pulledRight -= n.overscroll;
      final moved = drag.globalPosition - start;
      if (_pulledRight >= _exitDistance &&
          moved.dx > moved.dy.abs() * _exitSteepness) {
        _pulledRight = double.negativeInfinity;
        SystemNavigator.pop();
      }
    }
    return false;
  }

  void _onPageChanged(int page) {
    HapticFeedback.mediumImpact();
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WearDataProvider>(builder: (context, data, _) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onPageScroll,
            child: PageView(
              physics: const ClampingScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: [
                HomeScreen(scrollController: _scrollCtrls[0]),
                TodosScreen(scrollController: _scrollCtrls[1]),
                NotificationsScreen(scrollController: _scrollCtrls[2]),
                WearSettingsScreen(scrollController: _scrollCtrls[3]),
              ],
            ),
          ),

          // Kapcsolat jelző — jobb felső sarok
          Positioned(
            top: 8.0,
            right: 26.0,
            child: _ConnectionDot(connected: data.connected),
          ),

          // Lapozó pontok — alul középen
          Positioned(
            bottom: 20.0,
            left: 0,
            right: 0,
            child: Row(
              key: WearShell.pageDotsKey,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _pages; i++) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: i == _currentPage ? 16.0 : 5.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? WearColors.ink
                          : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                  ),
                  if (i < _pages - 1) const SizedBox(width: 4.0),
                ],
              ],
            ),
          ),
        ]),
      );
    });
  }
}

class _ConnectionDot extends StatelessWidget {
  final bool connected;
  const _ConnectionDot({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color =
        connected ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);
    return Container(
      width: 7.0,
      height: 7.0,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 5.0,
              spreadRadius: 1.0),
        ],
      ),
    );
  }
}
