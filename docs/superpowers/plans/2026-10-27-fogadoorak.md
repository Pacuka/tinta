# Fogadóórák Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teacher consultation hours in Tinta with full official-app parity (list, book a slot, cancel) plus home feed item, notifications and "add to calendar".

**Architecture:** New model + `ConsultingProvider` in `folio_kreta_api` (same shape as `CaseProvider`: talks to `KretaClient`, keeps a per-user list, exposes book/cancel returning a user message or null). UI page + bottom sheet in `folio_mobile_ui/lib/pages/consulting/`, entered from the Több menu. Home feed gets a `FilterType.consulting`. Background notifier gets a "consulting" state key. kamu-kreta gets stateful routes for testing writes.

**Tech Stack:** Flutter/Dart (provider, http, share_plus), Python stdlib (kamu-kreta).

**Spec:** `docs/superpowers/specs/2026-10-27-fogadoorak-design.md`

## Global Constraints

- Endpoints: `GET sajat/Fogadoorak?datumTol=&datumIg=`, `GET sajat/Fogadoorak/{uid}`, `POST|DELETE sajat/Fogadoorak/Idopontok/Jelentkezesek/{slotUid}` on `BaseKreta.kreta(iss)` + `/ellenorzo/v3/` (same base as `KretaApiEndpoints.exams`).
- Date range: `datumTol` = today − 1 day, `datumIg` = today + 90 days, format like `KretaAPI.timetable` (UTC ISO).
- All times `DateTime.parse(..).toLocal()`.
- No new pub dependencies. Calendar = `.ics` file via share_plus.
- User-facing text Hungarian; state labels exactly: "Jelentkezés leadva · HH:mm", "Nem kell jelentkezni", "Lezárult", "Nincs szabad hely", "Szabad jelentkezés".
- Error texts exactly: taken by others → "Ezt az időpontot közben elvitték, válassz másikat!"; already booked by me → "Már van foglalásod ennél a tanárnál."; no response → existing `uncertainSubmitMessage`; other → "Nem sikerült. Próbáld újra később!".
- NEVER POST/DELETE against the live KRÉTA while testing. Phone tests only with the KAMU_KRETA build (release build, `--dart-define=KAMU_KRETA=true`, versionCode ≥ 2005).
- Never print/log access tokens.

## Review Focus

1. Account switch while the page is open → list must belong to the active user only (clear on user id change, like `TimetableProvider._activeUserId`).
2. Double tap on "Foglalás" → exactly one POST (button disabled while in flight).
3. Deadline is null / unparsable → treat as "no deadline", never crash.
4. Teacher with zero `Fogadoorak` or empty `Idopontok` → no row / "Nincs szabad hely", not an exception.
5. Network failure on book → shows uncertain message and reloads the list instead of offering a resend.

Each is pinned by a test in the owning task (marked "RF").

---

### Task 1: kamu-kreta consultation-hour routes

**Files:**
- Modify: `../kreta-dev/kamu-kreta/server.py` (fixtures + GET/POST/DELETE routing)
- Test: `../kreta-dev/kamu-kreta/tests/test_server.py`
- Modify: `../kreta-dev/kamu-kreta/README.md` (one line listing the new routes)

**Interfaces:**
- Produces: `server.consulting_hours()` → list in `ConsultingHourListDto` shape; in-memory `server.CONSULTING_BOOKED: set[str]` of slot uids; routes:
  - `GET /ellenorzo/V3/Sajat/Fogadoorak` (ignore query, path match case-insensitive like the other routes)
  - `GET /ellenorzo/V3/Sajat/Fogadoorak/{uid}` → one hour or 404
  - `POST …/Fogadoorak/Idopontok/Jelentkezesek/{slotUid}` → 200; 400 `{"uzenet":"A választott időpont már foglalt.","hibakod":"FogadooraIdopontFoglalt"}` if the slot is taken by someone else (slot uid ending `-x`), 400 `{"uzenet":"Ön már foglalt egy időpontot!","hibakod":"FogadooraMarJelentkezett"}` if another slot of the same hour is already booked
  - `DELETE` same path → 200 and removes from the set; logged via `log()`.
- Fixtures (relative to today, 16:00 local written as UTC "Z" like the rest): hour `FO1` teacher "Kamu Tanár Anna" in 3 days, signup enabled, deadline in 2 days, room "12", slots every 10 min 16:00–16:50 (`FO1-0`..`FO1-4`, plus `FO1-5-x` already taken by others → listed so the race can be tested); hour `FO2` "Kamu Tanár Béla" in 5 days, `IsJelentkezesFeatureEnabled: false`, no slots; hour `FO3` "Kamu Tanár Cecília" 2 days ago, deadline passed. `IsJelentkeztem` = uid in `CONSULTING_BOOKED`.

- [ ] **Step 1: Write failing tests** `test_consulting_list_shapes` (3 teachers, `FO2` has `IsJelentkezesFeatureEnabled` False, `FO1` has 6 `Idopontok`), `test_consulting_book_and_cancel` (POST `FO1-1` → 200, list shows `IsJelentkeztem` True for `FO1-1`; second POST `FO1-2` → 400 with hibakod `FogadooraMarJelentkezett`; DELETE `FO1-1` → 200 and flag False; naplo has the POST), `test_consulting_taken_slot` (POST `FO1-5-x` → 400 `FogadooraIdopontFoglalt`). Reset `CONSULTING_BOOKED` in `setUp`.
- [ ] **Step 2:** `python3 -m unittest tests.test_server` → new tests FAIL.
- [ ] **Step 3:** Implement routes + fixtures.
- [ ] **Step 4:** Same command → all OK.
- [ ] **Step 5:** Commit in `kreta-dev`: `feat(kamu): consultation hours with booking`.

### Task 2: Model + derived state

**Files:**
- Create: `folio_kreta_api/lib/models/consulting_hour.dart`
- Test: `folio/test/consulting_hour_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum ConsultingState { booked, noSignup, closed, full, open }
  class ConsultingSlot { String id; DateTime start, end; bool mine; }
  class ConsultingHour {
    String id; String teacherId, teacherName; DateTime start, end;
    DateTime? deadline; bool signupEnabled; String room; List<ConsultingSlot> slots;
    ConsultingSlot? get myBooking;
    List<ConsultingSlot> get freeSlots;          // !mine, start after now
    ConsultingState state(DateTime now);
    static List<ConsultingHour> listFromJson(List json); // flattens ConsultingHourListDto
    factory ConsultingHour.fromJson(Map json, {required String teacherId, required String teacherName});
    Map<String, dynamic> toCacheJson(); factory ConsultingHour.fromCacheJson(Map json);
  }
  ```
- KRÉTA has no "taken by others" flag, so `freeSlots` = all non-mine slots starting after now; a race is reported by the POST error.
- State rules (first match): `myBooking != null` → booked; `!signupEnabled` → noSignup; `(deadline ?? end).isBefore(now)` → closed; `freeSlots.isEmpty` → full; else open.

- [ ] **Step 1: Write failing tests** using a JSON sample copied from kamu `consulting_hours()` output: parses 3 hours, teacher names, room "12", 6 slots; times are local; state: FO1 open, FO2 noSignup, FO3 closed; after setting slot `mine` → booked; FO1 with `now` after deadline → closed; FO1 with all slots in the past → full. **RF3:** `JelentkezesHatarido: null` and `"garbage"` → `deadline == null`, no throw. **RF4:** teacher with `Fogadoorak: []` → no hours; hour with `Idopontok: null` → `slots` empty, state full. Cache round-trip equals.
- [ ] **Step 2:** `cd folio && flutter test test/consulting_hour_test.dart` → FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Same → PASS.
- [ ] **Step 5:** Commit `feat(fogadoora): model and state`.

### Task 3: API + ConsultingProvider (load, book, cancel)

**Files:**
- Modify: `folio_kreta_api/lib/client/api.dart` (add 3 URL builders + endpoint consts)
- Create: `folio_kreta_api/lib/providers/consulting_provider.dart`
- Modify: `folio/lib/app.dart` (register `ChangeNotifierProvider<ConsultingProvider>` next to `CaseProvider`)
- Modify: `folio/lib/api/providers/sync.dart` (add `ConsultingProvider.fetch()` to both task lists)
- Test: `folio/test/consulting_provider_test.dart`

**Interfaces:**
- Consumes: Task 2 model; `KretaClient.getAPI`, `postAPI(rawResponse: true)`, `deleteAPI` (returns status code or null); `uncertainSubmitMessage` from `case_provider.dart`.
- Produces:
  ```dart
  KretaAPI.consultingHours(String iss, DateTime from, DateTime to)
  KretaAPI.consultingHour(String iss, String uid)
  KretaAPI.consultingReservation(String iss, String slotUid)
  String? parseConsultingError(int? status, String? body); // pure, maps to the Global Constraints texts
  class ConsultingProvider extends ChangeNotifier {
    ConsultingProvider({required BuildContext context});
    List<ConsultingHour> get hours;   // sorted by start
    bool get loading; String? get error;
    Future<void> fetch();             // swallow errors into `error`, keep old list
    Future<void> restore();           // from JSON file consulting_<userId>.json in app support dir
    Future<String?> book(ConsultingSlot slot, ConsultingHour hour);   // null = OK
    Future<String?> cancel(ConsultingSlot slot, ConsultingHour hour);
  }
  ```
- Error mapping: hibakod or uzenet containing `Foglalt`/`már foglalt` (taken by others) → taken text; `MarJelentkezett`/`Ön már foglalt` → already-booked text; status null → `uncertainSubmitMessage`; other ≥300 → generic text; 2xx → null.
- After book/cancel (success or uncertain): re-fetch the list (not just one hour — simpler, same correctness). **RF1:** `fetch`/`restore` clear `hours` when `_user.id` differs from the last loaded id before loading.

- [ ] **Step 1: Write failing tests** for `parseConsultingError`: (400, kamu taken body) → taken text; (400, already body) → already text; (null, null) → `uncertainSubmitMessage`; (500, "") → generic; (200, "") → null. **RF5** covered by the null case.
- [ ] **Step 2:** `flutter test test/consulting_provider_test.dart` → FAIL.
- [ ] **Step 3:** Implement URLs, `parseConsultingError`, provider, registration, sync hook.
- [ ] **Step 4:** Tests PASS; `flutter analyze folio_kreta_api folio` no new errors.
- [ ] **Step 5:** Commit `feat(fogadoora): API and provider`.

### Task 4: Fogadóórák page, sheet, Több menu entry

**Files:**
- Create: `folio_mobile_ui/lib/pages/consulting/consulting_page.dart`
- Create: `folio_mobile_ui/lib/pages/consulting/consulting_sheet.dart`
- Create: `folio_mobile_ui/lib/pages/consulting/consulting.i18n.dart` (hu/en/de like `absences_page.i18n.dart`)
- Modify: `folio_mobile_ui/lib/screens/navigation/more_menu.dart` (always-shown card "Fogadóórák", icon `Icons.event_available_rounded`, opens the page with `CupertinoPageRoute` on the root navigator like messages/notes)
- Test: `folio/test/consulting_page_test.dart` (widget tests)

**Interfaces:**
- Consumes: `ConsultingProvider` (Task 3), `ConsultingState`, `InkStroke` header pattern from `pages/notes/notes_page.dart`.
- Produces: `ConsultingPage` widget; `showConsultingSheet(BuildContext, ConsultingHour)`; `String consultingStateLabel(ConsultingHour, DateTime now)` (exact labels from Global Constraints, booked = "Jelentkezés leadva · 16:10"); `String? deadlineHint(ConsultingHour, DateTime now)` → "Még 2 napig jelentkezhetsz" / "Ma még jelentkezhetsz" / null.
- Page: pull-to-refresh → `fetch()`; "A te foglalásaid" card when any `myBooking`; list grouped by day (reuse `DateWidget`/date header style used on other pages); search field when > 5 distinct teachers; empty state "Most nincs meghirdetett fogadóóra."; error state with "Újra" button.
- Sheet: details (teacher, date, time, room, deadline); open → slot chips (`HH:mm`), select then "Foglalás" button with confirm dialog "Biztosan jelentkezel erre az időpontra?"; booked → "Lemondás" with confirm; if deadline passed, confirm text adds "Utána már nem tudsz újra jelentkezni."; result message via `CustomSnackBar` (success: "Sikeres jelentkezés!" / "Lemondva."). **RF2:** while a request is in flight the buttons are disabled (`_busy` flag).

- [ ] **Step 1: Write failing tests:** `consultingStateLabel` for each state; `deadlineHint` for 2 days / today / passed; widget test: sheet with an open hour, tap slot then "Foglalás" twice quickly (confirm dialog auto-accepted via a test hook or by tapping "Igen") → fake provider's `book` called exactly once (RF2).
- [ ] **Step 2:** `flutter test test/consulting_page_test.dart` → FAIL.
- [ ] **Step 3:** Implement page, sheet, i18n, menu card.
- [ ] **Step 4:** Tests PASS; analyze clean.
- [ ] **Step 5:** Commit `feat(fogadoora): page, booking sheet, menu entry`.

### Task 5: Home feed item + "Naptárba" (.ics)

**Files:**
- Create: `folio/lib/ui/filter/widgets/consulting.dart` (`List<DateWidget> getWidgets(List<ConsultingHour>)` — only hours with `myBooking` and end in the future; date = booking start; widget = a tile "Fogadóóra · <tanár>", "HH:mm–HH:mm · <terem>", tap opens the sheet)
- Modify: `folio/lib/ui/filter/widgets.dart` (`FilterType.consulting`, include in `FilterType.all`)
- Create: `folio_mobile_ui/lib/pages/consulting/ics.dart` (`String buildIcs(ConsultingHour hour, ConsultingSlot slot)`; `Future<void> shareIcs(...)` writes `fogadoora.ics` to temp dir and calls `SharePlus.instance.share` with the file, mime `text/calendar`)
- Modify: `consulting_sheet.dart` ("Naptárba" button on own booking)
- Test: `folio/test/consulting_ics_test.dart`

**Interfaces:**
- Consumes: Task 2/3/4.
- `buildIcs`: `BEGIN:VCALENDAR`, `VERSION:2.0`, `PRODID:-//Tinta//Fogadoora//HU`, one `VEVENT` with `UID:<slot.id>@tinta`, `DTSTART`/`DTEND` in UTC `yyyyMMddTHHmmssZ`, `SUMMARY:Fogadóóra – <teacher>`, `LOCATION:<room>`, CRLF line endings.

- [ ] **Step 1: Write failing tests:** ics contains the exact lines above for a fixed slot (16:10–16:20 local → correct UTC), uses `\r\n`; feed `getWidgets` returns 1 item for a booked future hour and 0 for unbooked or past.
- [ ] **Step 2:** `flutter test test/consulting_ics_test.dart` → FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(fogadoora): home feed item and calendar export`.

### Task 6: Notifications

**Files:**
- Modify: `folio/lib/helpers/update_notifier.dart` (in `_check`, after exams)
- Test: `folio/test/update_notifier_test.dart` (extend)

**Interfaces:**
- Consumes: `KretaAPI.consultingHours`, `ConsultingHour.listFromJson`, `NotifyState.add(kind, id)`.
- New hour: `state.add("consulting", hour.id)` new and `hour.end` in future and `settings.notificationsLessonsEnabled` → note "Új fogadóóra: <tanár>", "<nap> · HH:mm–HH:mm".
- Reminder: hour with `myBooking` whose start is today, now ≥ 07:00 and before the slot start, `state.add("consultingReminder", slot.id)` new → note "Ma fogadóóra: <tanár>", "HH:mm · <terem>". (Background fetch runs every ~15 min, so this lands in the morning; no exact alarm needed.)
- Extract the decision into a pure function `List<(String,String)> consultingNotes(List<ConsultingHour> hours, NotifyState state, DateTime now, {required bool enabled})` so it is testable without plugins.

- [ ] **Step 1: Write failing tests:** first run with FO1 → one "Új fogadóóra" note, second run → none; booked slot today at 16:10, now 07:30 → one "Ma fogadóóra" note, again → none; now 06:00 → none; disabled → none.
- [ ] **Step 2:** `flutter test test/update_notifier_test.dart` → FAIL.
- [ ] **Step 3:** Implement + call from `_check`.
- [ ] **Step 4:** PASS (whole `flutter test` suite green).
- [ ] **Step 5:** Commit `feat(fogadoora): notifications`.

### Task 7: On-device verification + real read-only range check

**Files:** none (ledger only: `.superpowers/sdd/2026-10-27-fogadoorak/progress.md`)

- [ ] **Step 1:** Start kamu (`python3 server.py`), `adb reverse tcp:8765 tcp:8765`, build release with `--dart-define=KAMU_KRETA=true --build-number=2005`, install.
- [ ] **Step 2:** On the phone (kamu account): Több → Fogadóórák shows 3 hours with labels Szabad jelentkezés / Nem kell jelentkezni / Lezárult; book FO1 16:10 → "Sikeres jelentkezés!", label "Jelentkezés leadva · 16:10", top card visible, home feed item visible; book another slot → "Már van foglalásod…"; cancel → "Lemondva."; "Naptárba" opens the share sheet with the .ics. Small screenshots for the user.
- [ ] **Step 3:** Real account (user's own, read-only): log the HTTP status and count of hours for one GET of `sajat/Fogadoorak` with the planned range; no POST/DELETE. Note the result in the ledger; if KRÉTA rejects the 90-day range, shrink it and re-test.
- [ ] **Step 4:** Commit ledger; update project memory.
