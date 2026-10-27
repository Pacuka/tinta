import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';

// Shape copied from kamu-kreta consulting_hours() (same as the official DTOs).
Map _slot(String uid, String start, String end, {bool mine = false}) => {
      "Uid": uid,
      "KezdoIdopont": start,
      "VegIdopont": end,
      "IsJelentkeztem": mine,
    };

List _sample({bool fo1SlotMine = false}) => [
      {
        "Tanar": {"Uid": "TA", "Nev": "Kamu Tanár Anna"},
        "Fogadoorak": [
          {
            "Uid": "FO1",
            "KezdoIdopont": "2026-11-05T15:00:00Z",
            "VegIdopont": "2026-11-05T16:00:00Z",
            "JelentkezesHatarido": "2026-11-04T22:59:00Z",
            "IsJelentkezesFeatureEnabled": true,
            "Terem": {"Uid": "T12", "Nev": "12"},
            "Idopontok": [
              _slot("FO1-0", "2026-11-05T15:00:00Z", "2026-11-05T15:10:00Z"),
              _slot("FO1-1", "2026-11-05T15:10:00Z", "2026-11-05T15:20:00Z",
                  mine: fo1SlotMine),
              _slot("FO1-2", "2026-11-05T15:20:00Z", "2026-11-05T15:30:00Z"),
              _slot("FO1-3", "2026-11-05T15:30:00Z", "2026-11-05T15:40:00Z"),
              _slot("FO1-4", "2026-11-05T15:40:00Z", "2026-11-05T15:50:00Z"),
              _slot("FO1-5-x", "2026-11-05T15:50:00Z", "2026-11-05T16:00:00Z"),
            ],
          }
        ],
      },
      {
        "Tanar": {"Uid": "TB", "Nev": "Kamu Tanár Béla"},
        "Fogadoorak": [
          {
            "Uid": "FO2",
            "KezdoIdopont": "2026-11-07T15:00:00Z",
            "VegIdopont": "2026-11-07T16:00:00Z",
            "JelentkezesHatarido": null,
            "IsJelentkezesFeatureEnabled": false,
            "Terem": {"Uid": "TT", "Nev": "Tanári"},
            "Idopontok": [],
          }
        ],
      },
      {
        "Tanar": {"Uid": "TC", "Nev": "Kamu Tanár Cecília"},
        "Fogadoorak": [
          {
            "Uid": "FO3",
            "KezdoIdopont": "2026-10-30T15:00:00Z",
            "VegIdopont": "2026-10-30T16:00:00Z",
            "JelentkezesHatarido": "2026-10-28T22:59:00Z",
            "IsJelentkezesFeatureEnabled": true,
            "Terem": {"Uid": "T7", "Nev": "7"},
            "Idopontok": [
              _slot("FO3-0", "2026-10-30T15:00:00Z", "2026-10-30T15:10:00Z"),
            ],
          }
        ],
      },
    ];

final _now = DateTime.utc(2026, 11, 1, 10).toLocal();

ConsultingHour _byId(List<ConsultingHour> hours, String id) =>
    hours.firstWhere((h) => h.id == id);

void main() {
  final hours = ConsultingHour.listFromJson(_sample());

  test('flattens teachers into hours', () {
    expect(hours.map((h) => h.id), containsAll(["FO1", "FO2", "FO3"]));
    expect(hours.length, 3);
    final fo1 = _byId(hours, "FO1");
    expect(fo1.teacherName, "Kamu Tanár Anna");
    expect(fo1.teacherId, "TA");
    expect(fo1.room, "12");
    expect(fo1.slots.length, 6);
    expect(fo1.signupEnabled, isTrue);
  });

  test('times are local', () {
    final fo1 = _byId(hours, "FO1");
    expect(fo1.start, DateTime.utc(2026, 11, 5, 15).toLocal());
    expect(fo1.start.isUtc, isFalse);
    expect(fo1.slots[1].start, DateTime.utc(2026, 11, 5, 15, 10).toLocal());
    expect(fo1.deadline, DateTime.utc(2026, 11, 4, 22, 59).toLocal());
  });

  test('states', () {
    expect(_byId(hours, "FO1").state(_now), ConsultingState.open);
    expect(_byId(hours, "FO2").state(_now), ConsultingState.noSignup);
    expect(_byId(hours, "FO3").state(_now), ConsultingState.closed);
  });

  test('own booking wins', () {
    final booked =
        _byId(ConsultingHour.listFromJson(_sample(fo1SlotMine: true)), "FO1");
    expect(booked.myBooking?.id, "FO1-1");
    expect(booked.state(_now), ConsultingState.booked);
    expect(booked.freeSlots.map((s) => s.id), isNot(contains("FO1-1")));
  });

  test('closed after the deadline', () {
    final after = DateTime.utc(2026, 11, 4, 23).toLocal();
    expect(_byId(hours, "FO1").state(after), ConsultingState.closed);
  });

  test('full when every slot is in the past', () {
    final fo1 = _byId(hours, "FO1");
    fo1.deadline = null;
    final during = DateTime.utc(2026, 11, 5, 15, 55).toLocal();
    expect(fo1.freeSlotsAt(during), isEmpty);
    expect(fo1.state(during), ConsultingState.full);
  });

  test('RF3: null or garbage deadline is no deadline', () {
    final List json = jsonDecode(jsonEncode(_sample()));
    json[0]["Fogadoorak"][0]["JelentkezesHatarido"] = "garbage";
    final fo1 = _byId(ConsultingHour.listFromJson(json), "FO1");
    expect(fo1.deadline, isNull);
    expect(_byId(hours, "FO2").deadline, isNull);
    expect(fo1.state(_now), ConsultingState.open);
  });

  test('RF4: empty teacher and missing slots', () {
    final List json = jsonDecode(jsonEncode([
      {"Tanar": {"Uid": "TX", "Nev": "X"}, "Fogadoorak": []},
      {"Tanar": {"Uid": "TY", "Nev": "Y"}, "Fogadoorak": null},
      ..._sample(),
    ]));
    (json[2] as Map)["Fogadoorak"][0]["Idopontok"] = null;
    final parsed = ConsultingHour.listFromJson(json);
    expect(parsed.length, 3);
    final fo1 = _byId(parsed, "FO1");
    expect(fo1.slots, isEmpty);
    expect(fo1.state(_now), ConsultingState.full);
  });

  test('cache round trip', () {
    final booked =
        ConsultingHour.listFromJson(_sample(fo1SlotMine: true));
    final back = booked
        .map((h) => ConsultingHour.fromCacheJson(h.toCacheJson()))
        .toList();
    final fo1 = _byId(back, "FO1");
    expect(fo1.teacherName, "Kamu Tanár Anna");
    expect(fo1.start, _byId(booked, "FO1").start);
    expect(fo1.deadline, _byId(booked, "FO1").deadline);
    expect(fo1.myBooking?.id, "FO1-1");
    expect(fo1.slots.length, 6);
    expect(_byId(back, "FO2").deadline, isNull);
  });
}
