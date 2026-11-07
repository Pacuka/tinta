import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/update_notifier.dart';
import 'package:folio_kreta_api/models/homework.dart';

Map _hw({
  String text = "Olvasd el.",
  String due = "2026-11-09T00:00:00Z",
  List<String> files = const [],
}) =>
    {
      "Uid": "H1",
      "Szoveg": text,
      "HataridoDatuma": due,
      "Csatolmanyok": [
        for (final f in files) {"Uid": f, "Nev": "$f.pdf"}
      ],
      "Tantargy": {"Uid": "S1", "Nev": "Magyar"},
    };

void main() {
  group('signature', () {
    test('same homework, same signature', () {
      expect(Homework.signature(_hw()), Homework.signature(_hw()));
      expect(Homework.signature(_hw(text: " Olvasd el. ")),
          Homework.signature(_hw()));
      expect(Homework.signature(_hw(files: ["a", "b"])),
          Homework.signature(_hw(files: ["b", "a"])));
    });

    test('text, deadline and attachments all count', () {
      final base = Homework.signature(_hw());
      expect(Homework.signature(_hw(text: "Más.")), isNot(base));
      expect(Homework.signature(_hw(due: "2026-11-10T00:00:00Z")), isNot(base));
      expect(Homework.signature(_hw(files: ["a"])), isNot(base));
    });
  });

  group('carryModified', () {
    test('a first sighting is not a modification', () {
      final fresh = _hw();
      Homework.carryModified(null, fresh);
      expect(Homework.fromJson(fresh).modified, isFalse);
    });

    test('unchanged stays unmodified', () {
      final fresh = _hw();
      Homework.carryModified(_hw(), fresh);
      expect(Homework.fromJson(fresh).modified, isFalse);
    });

    test('a change saves the old version and the time, later syncs keep them',
        () {
      final at = DateTime(2026, 11, 4, 22, 0);
      final second = _hw(text: "Más.", due: "2026-11-10T00:00:00Z");
      Homework.carryModified(_hw(files: ["a"]), second, now: at);
      final hw = Homework.fromJson(second);
      expect(hw.modifiedAt, at);
      expect(hw.previous.single.content, "Olvasd el.");
      expect(hw.previous.single.replacedAt, at);
      expect(hw.previous.single.deadline,
          DateTime.parse("2026-11-09T00:00:00Z").toLocal());
      expect(hw.previous.single.attachments, ["a.pdf"]);

      final third = _hw(text: "Más.", due: "2026-11-10T00:00:00Z");
      Homework.carryModified(second, third, now: DateTime(2026, 11, 5));
      final same = Homework.fromJson(third);
      expect(same.modifiedAt, at);
      expect(same.previous, hasLength(1));
    });

    test('versions pile up, only the last ones are kept', () {
      Map last = _hw(text: "0");
      for (var i = 1; i <= Homework.maxPrevious + 3; i++) {
        final next = _hw(text: "$i");
        Homework.carryModified(last, next, now: DateTime(2026, 11, 1, i));
        last = next;
      }
      final hw = Homework.fromJson(last);
      expect(hw.previous, hasLength(Homework.maxPrevious));
      expect(hw.previous.first.content, "3");
      expect(hw.previous.last.content, "${Homework.maxPrevious + 2}");
    });

    test('survives the database round trip', () {
      final fresh = _hw(text: "Más.");
      Homework.carryModified(_hw(), fresh, now: DateTime(2026, 11, 4, 22));
      final hw = Homework.fromJson(jsonDecode(jsonEncode(fresh)));
      expect(hw.modifiedAt, DateTime(2026, 11, 4, 22));
      expect(hw.previous.single.content, "Olvasd el.");
    });
  });

  group('NotifyState.homeworkChanged', () {
    final file = File('${Directory.systemTemp.path}/tinta_hw_notify_test.json');
    tearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    test('first sighting is silent, then only real changes count', () {
      final s = NotifyState.empty(file);
      expect(s.homeworkChanged("H1", "a"), isFalse);
      expect(s.homeworkChanged("H1", "a"), isFalse);
      expect(s.homeworkChanged("H1", "b"), isTrue);
      expect(s.homeworkChanged("H1", "b"), isFalse);
    });

    test('signatures survive saving', () async {
      final s = NotifyState.empty(file)..homeworkChanged("H1", "a");
      await s.save();
      expect(file.readAsStringSync(), contains('"homework":{"H1":"a"}'));
    });
  });
}
