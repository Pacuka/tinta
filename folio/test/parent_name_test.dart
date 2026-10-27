import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:folio/models/user.dart';

String _jwt(Map claims) =>
    'x.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.y';

User _user(Role role, {String parentFirstName = ''}) => User.demo()
  ..name = 'Pintér Botond'
  ..nickname = ''
  ..role = role
  ..parentFirstName = parentFirstName;

void main() {
  test('first name taken from the token name (family name first)', () {
    expect(parentFirstNameFromFullName('Pintér István'), 'István');
    expect(parentFirstNameFromFullName('Dr. Kiss Anna Mária'), 'Anna');
    expect(parentFirstNameFromFullName('Kata'), 'Kata');
    expect(parentFirstNameFromFullName(null), '');
  });

  test('parent first name survives saving and loading', () {
    final u = User.fromMap(
        _user(Role.parent, parentFirstName: 'Kata').toMap());
    expect(u.parentFirstName, 'Kata');
  });

  test('greeting uses the parent name on parent accounts', () {
    expect(_user(Role.parent, parentFirstName: 'Kata').greetingFirstName,
        'Kata');
    expect(_user(Role.parent).greetingFirstName, 'Botond');
    expect(_user(Role.student).greetingFirstName, 'Botond');
  });

  test('messages from a parent account are signed with the parent name', () {
    final parent = _user(Role.parent)
      ..accessToken = _jwt({'name': 'Pintér István', 'role': 'Gondviselo'});
    expect(parent.senderName, 'Pintér István');
    expect(_user(Role.student).senderName, 'Pintér Botond');
    expect((_user(Role.parent)..accessToken = '').senderName, 'Pintér Botond');
  });
}
