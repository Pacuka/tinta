import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/user.dart';

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
}
