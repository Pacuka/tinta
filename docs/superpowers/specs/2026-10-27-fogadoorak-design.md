# Fogadóórák (teacher consultation hours) — design

Date: 2026-10-27 · Status: approved in chat, awaiting spec review

## Goal

Everything the official e-KRÉTA app (student + guardian 5.17.0) can do with
consultation hours, but nicer: list, book a time slot, cancel, plus home feed,
notifications and "add to calendar". Works for student and parent accounts.

User rule: full parity incl. write actions; real bookings on the live KRÉTA
only with the user's explicit OK. All write testing on kamu-kreta.

## API (from decompiled hu.ekreta.student 5.17.0, MobileApiV3)

Base: `https://<inst>.e-kreta.hu/ellenorzo/v3/` (same as other `sajat/*`).

| Call | Purpose |
|---|---|
| `GET sajat/Fogadoorak?datumTol=&datumIg=` | `List<ConsultingHourListDto>` |
| `GET sajat/Fogadoorak/{uid}` | one `ConsultingHourDto` (refresh after booking) |
| `POST sajat/Fogadoorak/Idopontok/Jelentkezesek/{slotUid}` | book a slot (no body) |
| `DELETE sajat/Fogadoorak/Idopontok/Jelentkezesek/{slotUid}` | cancel booking |

DTOs:

- `ConsultingHourListDto { Tanar: {Uid, Nev}, Fogadoorak: [ConsultingHourDto] }`
- `ConsultingHourDto { Uid, KezdoIdopont, VegIdopont, JelentkezesHatarido,
  IsJelentkezesFeatureEnabled, Terem: {Uid, Nev}, Idopontok: [Slot] }`
- `ConsultingHourTimeSlotDto { Uid, KezdoIdopont, VegIdopont, IsJelentkeztem }`

Times are ISO strings in UTC ("…Z") → `.toLocal()` like other models.
`Idopontok` only lists bookable slots + the user's own (the official app's
"already taken by others" error shows taken slots can still race). Date range:
`datumTol` = today − 1 day, `datumIg` = today + 90 days; during implementation,
check with one real read-only GET what range the school actually returns.

Official error texts (for mapping): already booked one by me / slot taken by
others / generic failure. KRÉTA error body shape is the same as the e-ügyintézés
one → reuse `parseSubmitError` style mapping, with friendly Hungarian messages.

## Derived state per consultation hour

| State | Rule | Label |
|---|---|---|
| booked | any slot `IsJelentkeztem` | "Jelentkezés leadva · 17:20" |
| noSignup | `!IsJelentkezesFeatureEnabled` | "Nem kell jelentkezni" |
| closed | deadline passed (or end passed) and not booked | "Lezárult" |
| full | signup enabled, deadline open, no free slot | "Nincs szabad hely" |
| open | otherwise | "Szabad jelentkezés" (+ "még 2 napig") |

Pure function, unit tested.

## Components

**folio_kreta_api**
- `models/consulting_hour.dart`: `ConsultingHour`, `ConsultingSlot`,
  `ConsultingTeacher`; `fromJson`, derived `state`, `myBooking`, `freeSlots`.
- `client/api.dart`: `consultingHours(iss, from, to)`, `consultingHour(iss, uid)`,
  `consultingReservation(iss, slotUid)`.
- `client/client.dart`: POST/DELETE helpers returning status + body (same
  pattern as the igazolás submit).
- `providers/consulting_provider.dart`: load list (cached in memory + JSON file
  per user like other non-DB features), `book(slot)`, `cancel(slot)`; after a
  write re-fetches that one hour (`GET Fogadoorak/{uid}`); per-user, cleared on
  account switch. Parent accounts use the guardian UA automatically (existing
  `KretaAuthApp`).

**folio_mobile_ui**
- Több menu: new card "Fogadóórák" (always shown, not a navbar page).
- `pages/consulting/consulting_page.dart`: InkStroke header like other pages;
  "A te foglalásaid" highlight card on top (only if any); list grouped by day;
  each row: teacher, time range, room, state chip, deadline hint; search field
  for teacher name (shown when > 5 teachers); pull to refresh; empty state
  "Most nincs meghirdetett fogadóóra."; error state with retry.
- `consulting_sheet.dart`: bottom sheet on tap — details, slot buttons (time
  chips), confirm step, cancel button for own booking; late-cancel warning when
  the deadline is passed ("utána nem tudsz újra jelentkezni"); double-tap guard;
  friendly messages: "Ezt az időpontot közben elvitték, válassz másikat",
  "Már van foglalásod ennél a tanárnál". Uncertain network result → "Nem biztos,
  hogy megérkezett, frissítsd a listát" (never blind resend).
- "Naptárba" button on a booking: builds an `.ics` file and opens it via
  share_plus (no new dependency).
- Home feed: own upcoming bookings as items ("Fogadóóra · <tanár>", time, room).

**Notifications** (`folio/lib/helpers/update_notifier.dart`)
- New consultation hour appeared (state key "consulting", like exams).
- Morning reminder on the day of a booking (scheduled like the lesson reminder).

**kamu-kreta** (`kreta-dev/kamu-kreta/server.py`)
- Fixtures: 3 teachers: one open with free slots, one noSignup, one closed;
  slots in 10 min steps; state kept in memory so book/cancel change the list;
  POST on an already-booked slot → 400 with official-style error; all writes
  logged to naplo. Tests in `tests/test_server.py`.

## Testing

- Dart unit tests: JSON parsing (sample from kamu), state rules, error mapping,
  `.ics` text.
- kamu tests for the new routes.
- On phone with kamu: list, book, cancel, error case, home item, notification.
- Real account: read-only list GET only. A real booking only if the user asks.

## Out of scope

Teacher side, web KRÉTA features, booking for multiple children at once (each
child = own account, as today).
