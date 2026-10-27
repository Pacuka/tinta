import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/message.dart';

// Response shape of GET kommunikacio/postaladaelemek/{id} for a sent message
const _sent = r'''{"azonosito": 100, "isElolvasva": true, "isToroltElem": false, "tipus": {"kod": "ELKULDOTT"}, "uzenet": {"azonosito": 100, "kuldesDatum": "2026-10-27T12:24:43.910322Z", "feladoNev": "Én (Tinta)", "feladoTitulus": "tanár", "szoveg": "hxbdbd", "targy": "dnsndbd", "cimzettLista": [{"azonosito": 1, "kretaAzonosito": 1000, "nev": "Kamu Diák", "tipus": {"azonosito": 1, "kod": "TANULO", "rovidNev": "Tanuló", "nev": "Tanuló", "leiras": "Tanuló"}}], "csatolmanyok": []}}''';

void main() {
  test('a sent message parses and keeps the sent type', () {
    final m = Message.fromJson(jsonDecode(_sent), forceType: MessageType.sent);
    expect(m.type, MessageType.sent);
    expect(m.subject, isNotEmpty);
  });
}
