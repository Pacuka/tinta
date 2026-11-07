import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/day_state.dart';
import '../providers/wear_data_provider.dart';
import '../widgets/day_switcher.dart';
import '../widgets/home_ring.dart';
import '../widgets/ink_timeline.dart';
import '../widgets/minute_ticker.dart';
import '../widgets/wear_curved_scrollbar.dart';

/// The ring fills the first screen, the timetable follows it below.
class HomeScreen extends StatefulWidget {
  final ScrollController scrollController;
  const HomeScreen({super.key, required this.scrollController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Round screen: keep content away from the curved edge.
  static const _hPad = 12.0;

  /// Kept as a date, so the choice lapses when that day is no longer next.
  DateTime? _chosenDay;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return ColoredBox(
      color: Colors.black,
      child: Consumer<WearDataProvider>(builder: (context, data, _) {
        return WearCurvedScrollbar(
          controller: widget.scrollController,
          child: CustomScrollView(
            controller: widget.scrollController,
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
                    child: MinuteTicker(builder: (_) {
                      final now = DateTime.now();
                      final next = nextSchoolDay(data.lessons, now);
                      if (next != _chosenDay) _chosenDay = null;
                      final showNext = _chosenDay != null;
                      return Column(children: [
                        if (next != null) ...[
                          DaySwitcher(
                            nextLabel: nextDayLabel(next, now),
                            showNext: showNext,
                            onChanged: (v) =>
                                setState(() => _chosenDay = v ? next : null),
                          ),
                          const SizedBox(height: 10.0),
                        ],
                        InkTimeline(
                          lessons: data.lessons,
                          now: now,
                          day: showNext ? next : null,
                        ),
                      ]);
                    }),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
