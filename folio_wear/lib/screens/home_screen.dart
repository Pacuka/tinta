import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wear_data_provider.dart';
import '../widgets/home_ring.dart';
import '../widgets/ink_timeline.dart';
import '../widgets/minute_ticker.dart';
import '../widgets/wear_curved_scrollbar.dart';

/// The ring fills the first screen, the timetable follows it below.
class HomeScreen extends StatelessWidget {
  final ScrollController scrollController;
  const HomeScreen({super.key, required this.scrollController});

  // Round screen: keep content away from the curved edge.
  static const _hPad = 28.0;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return ColoredBox(
      color: Colors.black,
      child: Consumer<WearDataProvider>(builder: (context, data, _) {
        return WearCurvedScrollbar(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: height,
                  child: HomeRing(
                    lessons: data.lessons,
                    onRefresh: data.requestSync,
                  ),
                ),
              ),
              if (data.lessons.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      _hPad, 12.0, _hPad, height * 0.22),
                  sliver: SliverToBoxAdapter(
                    child: MinuteTicker(
                      builder: (_) => InkTimeline(
                          lessons: data.lessons, now: DateTime.now()),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
