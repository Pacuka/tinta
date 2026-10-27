import 'dart:convert';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/models/school.dart';
import 'package:folio_kreta_api/models/student.dart';
import 'package:uuid/uuid.dart';

const String demoUserId = 'demo-user-00000000-0000-0000-0000-000000000000';

enum Role { student, parent }

/// Parent accounts: KRÉTA puts the guardian's own name ("Pintér István",
/// family name first) in the token's `name` claim; we keep the first name.
String parentFirstNameFromFullName(Object? fullName) {
  final parts = (fullName ?? '')
      .toString()
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty && !p.endsWith('.'))
      .toList();
  if (parts.isEmpty) return '';
  return parts.length > 1 ? parts[1] : parts[0];
}

class User {
  late String id;
  String username;
  String password;
  String instituteCode;
  String name;
  Student student;
  Role role;
  String nickname;

  /// Parent accounts: the guardian's own first name (from the KRÉTA guardian
  /// profile), used only in the home greeting. Empty otherwise.
  String parentFirstName;
  String picture;
  int gradeStreak;
  // new login method
  String accessToken;
  DateTime accessTokenExpire;
  String refreshToken;
  String idpApplication;
  String idpRememberBrowser;
  // cloud sync
  // String qwidAccessToken;
  // DateTime? qwidAccessTokenExpire;
  // String qwidRefreshToken;

  String get displayName => nickname != '' ? nickname : name;

  /// Name for the home greeting: the parent on parent accounts (when known),
  /// otherwise the student's first name.
  String get greetingFirstName {
    if (role == Role.parent && parentFirstName.isNotEmpty) {
      return parentFirstName;
    }
    final parts = displayName.split(" ");
    return parts.length > 1 ? parts[1] : parts[0];
  }
  bool get hasStreak => gradeStreak > 0;

  User({
    String? id,
    required this.name,
    required this.username,
    required this.password,
    required this.instituteCode,
    required this.student,
    required this.role,
    this.nickname = "",
    this.parentFirstName = "",
    this.picture = "",
    this.gradeStreak = 0,
    required this.accessToken,
    required this.accessTokenExpire,
    required this.refreshToken,
    this.idpApplication = "",
    this.idpRememberBrowser = "",
    // this.qwidAccessToken = "",
    // this.qwidAccessTokenExpire,
    // this.qwidRefreshToken = "",
  }) {
    if (id != null) {
      this.id = id;
    } else {
      this.id = const Uuid().v4();
    }
  }

  factory User.fromMap(Map map) {
    return User(
      id: map["id"],
      instituteCode: map["institute_code"],
      username: map["username"],
      password: map["password"],
      name: map["name"].trim(),
      student: map["student"] != 'null'
          ? Student.fromJson(jsonDecode(map["student"]))
          : Student(
              id: const Uuid().v4(),
              name: 'Ismeretlen Diák',
              school: School(instituteCode: '', name: '', city: ''),
              birth: DateTime.now(),
              yearId: '1',
              parents: [],
              gradeDelay: 0,
            ),
      role: Role.values[map["role"] ?? 0],
      nickname: map["nickname"] ?? "",
      parentFirstName: map["parent_first_name"] ?? "",
      picture: map["picture"] ?? "",
      gradeStreak: map["grade_streak"] ?? 0,
      accessToken: map["access_token"] ?? "",
      accessTokenExpire: DateTime.parse(map["access_token_expire"] != ""
          ? map["access_token_expire"]
          : DateTime.now().toIso8601String()),
      refreshToken: map["refresh_token"] ?? "",
      idpApplication: map["idp_application"] ?? "",
      idpRememberBrowser: map["idp_remember_browser"] ?? "",
      // qwidAccessToken: map["qwid_access_token"] ?? "",
      // qwidAccessTokenExpire: map["qwid_access_token_expire"] != ""
      //     ? DateTime.parse(map["qwid_access_token_expire"])
      //     : null,
      // qwidRefreshToken: map["qwid_refresh_token"] ?? "",
    );
  }

  Map<String, Object?> toMap() {
    return {
      "id": id,
      "username": username,
      "password": password,
      "institute_code": instituteCode,
      "name": name,
      "student": jsonEncode(student.json),
      "role": role.index,
      "nickname": nickname,
      "parent_first_name": parentFirstName,
      "picture": picture,
      "grade_streak": gradeStreak,
      "access_token": accessToken,
      "access_token_expire": accessTokenExpire.toIso8601String(),
      "refresh_token": refreshToken,
      "idp_application": idpApplication,
      "idp_remember_browser": idpRememberBrowser,
      // "qwid_access_token": qwidAccessToken,
      // "qwid_access_token_expire": qwidAccessTokenExpire != null
      //     ? qwidAccessTokenExpire!.toIso8601String()
      //     : "",
      // "qwid_refresh_token": qwidRefreshToken,
    };
  }

  @override
  String toString() => jsonEncode(toMap());

  static User demo() {
    return User(
      id: demoUserId,
      name: 'Demo Diák',
      username: 'demo',
      password: '',
      instituteCode: 'demo',
      student: Student(
        id: demoUserId,
        name: 'Demo Diák',
        school: School(
          instituteCode: 'demo',
          name: 'Demo Iskola',
          city: 'Budapest',
        ),
        birth: DateTime(2005, 9, 1),
        yearId: '1',
        parents: [],
        gradeDelay: 0,
      ),
      role: Role.student,
      nickname: 'Demo',
      accessToken: 'demo',
      accessTokenExpire: DateTime.now().add(const Duration(days: 365)),
      refreshToken: 'demo',
    );
  }

  bool get isDemo => id == demoUserId;

  static Map<String, Object?> loginBody({
    required String username,
    required String password,
    required String instituteCode,
  }) {
    return {
      "userName": username,
      "password": password,
      "institute_code": instituteCode,
      "grant_type": "password",
      "client_id": KretaAPI.clientId,
    };
  }

  static Map<String, Object?> refreshBody({
    required String refreshToken,
    required String instituteCode,
  }) {
    return {
      "refresh_token": refreshToken,
      "institute_code": instituteCode,
      "client_id": KretaAPI.clientId,
      "grant_type": "refresh_token",
      "refresh_user_data": "false",
    };
  }

  static Map<String, Object?> logoutBody({
    required String refreshToken,
  }) {
    return {
      "refresh_token": refreshToken,
      "client_id": KretaAPI.clientId,
    };
  }
}
