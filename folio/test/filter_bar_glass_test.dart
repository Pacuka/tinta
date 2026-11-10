import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio_mobile_ui/common/filter_bar.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

SettingsProvider _settings(AccentColor c) =>
    SettingsProvider.defaultSettings()..update(accentColor: c, store: false);

class _Host extends StatefulWidget {
  const _Host({required this.items, this.censored = false, this.onTap});
  final List<Widget> items;
  final bool censored;
  final void Function(int)? onTap;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final controller =
      TabController(length: widget.items.length, vsync: this);
  @override
  Widget build(BuildContext context) => FilterBar(
        items: widget.items,
        controller: controller,
        pillStyle: true,
        disableFading: true,
        censored: widget.censored,
        onTap: widget.onTap,
      );
}

Widget _app(AccentColor c, Widget child) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: _settings(c),
      child: MaterialApp(home: Scaffold(body: child)),
    );

const _tabs = [
  Tab(text: 'Összes'),
  Tab(text: 'Jegyek'),
  Tab(text: 'Számonkérés'),
  Tab(text: 'Üzenetek'),
];

TabController _controllerOf(WidgetTester t) =>
    t.state<_HostState>(find.byType(_Host)).controller;

void main() {
  testWidgets('Üveg: glass segmented control instead of the pill TabBar',
      (tester) async {
    await tester.pumpWidget(_app(AccentColor.uveg, const _Host(items: _tabs)));
    expect(find.byType(GlassSegmentedControl), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('Üveg follows the TabController (page swipe)', (tester) async {
    await tester.pumpWidget(_app(AccentColor.uveg, const _Host(items: _tabs)));
    _controllerOf(tester).animateTo(2);
    await tester.pumpAndSettle();
    final seg = tester.widget<GlassSegmentedControl>(
        find.byType(GlassSegmentedControl));
    expect(seg.selectedIndex, 2);
  });

  testWidgets('Üveg: tapping a filter moves the controller and calls onTap',
      (tester) async {
    int? tapped;
    await tester.pumpWidget(_app(
        AccentColor.uveg, _Host(items: _tabs, onTap: (i) => tapped = i)));
    await tester.tap(find.text('Jegyek'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
    expect(_controllerOf(tester).index, 1);
  });

  testWidgets('a count badge tab still becomes a glass segment', (tester) async {
    final items = [
      const Tab(text: 'Összes'),
      Tab(
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Text('Számonkérés'),
        SizedBox(width: 6),
        Text('3'),
      ])),
    ];
    await tester.pumpWidget(_app(AccentColor.uveg, _Host(items: items)));
    expect(find.byType(GlassSegmentedControl), findsOneWidget);
    expect(find.text('Számonkérés'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('the count badge sits beside its label, not above it',
      (tester) async {
    final items = [
      const Tab(text: 'Összes'),
      Tab(
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Text('Számonkérés'),
        SizedBox(width: 6),
        Text('3'),
      ])),
    ];
    await tester.pumpWidget(_app(AccentColor.uveg, _Host(items: items)));
    final label = tester.getCenter(find.text('Számonkérés'));
    final badge = tester.getCenter(find.text('3'));
    expect((label.dy - badge.dy).abs(), lessThan(2.0));
    expect(badge.dx, greaterThan(label.dx));
    // Same baseline as a plain segment.
    expect((tester.getCenter(find.text('Összes')).dy - label.dy).abs(),
        lessThan(2.0));
  });

  testWidgets('censored keeps real labels hidden', (tester) async {
    await tester.pumpWidget(
        _app(AccentColor.uveg, const _Host(items: _tabs, censored: true)));
    expect(find.text('Jegyek'), findsNothing);
  });

  testWidgets('Kobalt keeps the old TabBar', (tester) async {
    await tester
        .pumpWidget(_app(AccentColor.kobalt, const _Host(items: _tabs)));
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(GlassSegmentedControl), findsNothing);
  });
}
