import 'dart:async';
import 'package:flutter/widgets.dart';

/// Rebuilds once a minute and when the app comes back to the foreground.
class MinuteTicker extends StatefulWidget {
  final WidgetBuilder builder;
  const MinuteTicker({super.key, required this.builder});

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker>
    with WidgetsBindingObserver {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer =
        Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
