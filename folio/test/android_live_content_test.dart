import 'package:flutter_test/flutter_test.dart';
import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio/helpers/android_live_activity_helper.dart';
import 'package:folio_kreta_api/models/lesson.dart';

Lesson _lesson(int index, DateTime start, String subject, String room) =>
    Lesson.fromJson({
      "Uid": "L$index",
      "Datum": DateTime(start.year, start.month, start.day).toIso8601String(),
      "KezdetIdopont": start.toIso8601String(),
      "VegIdopont": start.add(const Duration(minutes: 45)).toIso8601String(),
      "Oraszam": index,
      "TeremNeve": room,
      "Tantargy": {"Uid": "S-$subject", "Nev": subject},
    });

void main() {
  test('óra közben: tantárgy, terem, mi jön utána, idősáv', () {
    final c = AndroidLiveActivityHelper.liveContent(LiveCardState.duringLesson, {
      'index': '3. ',
      'title': 'Matematika',
      'subtitle': 'Terem: 204',
      'startDate': '1000',
      'endDate': '2000',
      'nextSubject': 'Fizika',
      'nextRoom': '105',
    })!;
    expect(c['title'], '3. Matematika');
    expect(c['body'], 'Terem: 204');
    expect(c['compact'], '3. Matematika · 204');
    expect(c['next'], 'Utána: Fizika · 105');
    expect(c['startMs'], 1000);
    expect(c['endMs'], 2000);
    expect(c['timerFormat'], 'még %s');
  });

  test('utolsó óra, üres terem: nincs "Terem:" felirat', () {
    final c = AndroidLiveActivityHelper.liveContent(LiveCardState.duringLesson, {
      'index': '7. ',
      'title': 'Ének',
      'subtitle': 'Terem: ',
      'startDate': '1',
      'endDate': '2',
    })!;
    expect(c['body'], '');
    expect(c['next'], 'Ez a mai utolsó órád.');
  });

  test('szünet: a következő óra és terem', () {
    final c = AndroidLiveActivityHelper.liveContent(LiveCardState.duringBreak, {
      'description': 'Menj fel a(z) 2. emeletre.',
      'startDate': '1',
      'endDate': '2',
      'nextSubject': 'Fizika',
      'nextRoom': '105',
    })!;
    expect(c['title'], 'Szünet');
    expect(c['body'], 'Következő: Fizika · 105');
    expect(c['compact'], 'Szünet → Fizika · 105');
    expect(c['next'], 'Menj fel a(z) 2. emeletre.');
  });

  test('reggel: "múlva" visszaszámlálás; nincs óra vagy vége -> semmi', () {
    final c = AndroidLiveActivityHelper.liveContent(LiveCardState.morning, {
      'startDate': '',
      'endDate': '5000',
      'nextSubject': 'Történelem',
      'nextRoom': '',
    })!;
    expect(c['title'], 'Következő óra: Történelem');
    expect(c['startMs'], 0);
    expect(c['timerFormat'], '%s múlva');
    expect(
        AndroidLiveActivityHelper.liveContent(
            LiveCardState.morning, {'endDate': '5000'}),
        isNull);
    expect(
        AndroidLiveActivityHelper.liveContent(
            LiveCardState.duringLesson, {'endDate': '0'}),
        isNull);
  });

  test('értesítés típusa -> natív mód', () {
    expect(AndroidLiveActivityHelper.liveMode('native'), 'auto');
    expect(AndroidLiveActivityHelper.liveMode('wavy'), 'wavy');
    expect(AndroidLiveActivityHelper.liveMode('android16'), 'promoted');
  });

  test('napi menetrend: óra előtt, órák, szünet, utolsó óra', () {
    final a = _lesson(1, DateTime(2026, 11, 11, 8), 'Matek', '204');
    final b = _lesson(2, DateTime(2026, 11, 11, 8, 55), 'Fizika', 'Labor_1');
    final plan = AndroidLiveActivityHelper.dayPlan([b, a], name: (l) => l.subject.name);
    expect(plan.map((p) => p['title']),
        ['Következő óra: Matek', '1. Matek', 'Szünet', '2. Fizika']);
    final ms = a.start.millisecondsSinceEpoch;
    expect(plan[0]['from'], ms - 3600000);
    expect(plan[0]['to'], ms);
    expect(plan[1]['next'], 'Utána: Fizika · Labor 1');
    expect(plan[2]['from'], a.end.millisecondsSinceEpoch);
    expect(plan[2]['to'], b.start.millisecondsSinceEpoch);
    expect(plan[2]['compact'], 'Szünet → Fizika · Labor 1');
    expect(plan[3]['next'], 'Ez a mai utolsó órád.');
    // Csengő-eltolás: minden idő eltolódik.
    final shifted = AndroidLiveActivityHelper.dayPlan([a],
        delay: const Duration(minutes: 2), name: (l) => l.subject.name);
    expect(shifted[1]['from'], ms - 120000);
    expect(AndroidLiveActivityHelper.dayPlan([]), isEmpty);
  });
}
