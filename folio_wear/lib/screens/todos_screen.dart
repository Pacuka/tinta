import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/day_state.dart';
import '../models/wear_extras.dart';
import '../providers/wear_data_provider.dart';
import '../theme/wear_theme.dart';
import '../widgets/edge_fade.dart';
import '../widgets/page_title.dart';
import '../widgets/minute_ticker.dart';
import '../widgets/wear_curved_scrollbar.dart';

// Round screen: keep content away from the curved edge.
const _kHPad = 22.0;

/// Homework and exams of the next days. Only what and when: the text is on
/// the phone.
class TodosScreen extends StatelessWidget {
  final ScrollController scrollController;
  const TodosScreen({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Consumer<WearDataProvider>(builder: (context, data, _) {
        return MinuteTicker(builder: (_) {
          final extras = data.extras;
          if (extras == null) {
            return const _Message('Frissítsd a Tintát a telefonon');
          }
          final now = DateTime.now();
          final todos = extras.upcoming(now);
          if (todos.isEmpty) {
            return const _Message('Nincs teendő a következő 7 napban');
          }
          return WearCurvedScrollbar(
            controller: scrollController,
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.only(top: 30.0, bottom: 8.0),
                  sliver: SliverToBoxAdapter(child: PageTitle('Teendők')),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                          _kHPad, 0.0, _kHPad, 4.0),
                      child: EdgeFade(child: _Tile(todos[i], now)),
                    ),
                    childCount: todos.length,
                    addRepaintBoundaries: false,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 52.0)),
              ],
            ),
          );
        });
      }),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WearColors.muted, fontSize: 13.0),
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  final WearTodo todo;
  final DateTime now;
  const _Tile(this.todo, this.now);

  String get _dayLabel {
    final due = DateTime(todo.due.year, todo.due.month, todo.due.day);
    if (due == DateTime(now.year, now.month, now.day)) return 'Ma';
    return nextDayLabel(due, now);
  }

  @override
  Widget build(BuildContext context) {
    final color =
        todo.isExam ? const Color(0xFFF48FB1) : const Color(0xFFFFE082);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: WearColors.surface,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(children: [
        Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            todo.isExam ? Icons.quiz_rounded : Icons.assignment_rounded,
            size: 15.0,
            color: color,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todo.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _dayLabel,
                style:
                    const TextStyle(color: WearColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
