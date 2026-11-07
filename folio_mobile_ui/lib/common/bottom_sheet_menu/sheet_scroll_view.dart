import 'package:flutter/material.dart';

/// Scrolling body of a bottom sheet. The scroll view takes the drag from the
/// sheet, so pulling further down at the very top closes the sheet here.
class SheetScrollView extends StatefulWidget {
  const SheetScrollView({super.key, required this.child});

  final Widget child;

  /// How far (px) to pull past the top before the sheet closes.
  static const closeDistance = 60.0;

  @override
  State<SheetScrollView> createState() => _SheetScrollViewState();
}

class _SheetScrollViewState extends State<SheetScrollView> {
  bool _closing = false;

  bool _onScroll(ScrollUpdateNotification n) {
    // No drag details: the bounce of a fling, not the finger.
    if (!_closing &&
        n.dragDetails != null &&
        n.metrics.pixels < -SheetScrollView.closeDistance) {
      _closing = true;
      Navigator.of(context).maybePop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: _onScroll,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: widget.child,
      ),
    );
  }
}
