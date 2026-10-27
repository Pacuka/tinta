import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/kreta_auth_app.dart';
import 'package:folio/models/user.dart';

void main() {
  test('student and parent use their own official client ids', () {
    expect(KretaAuthApp.forRole(Role.student).clientId,
        'kreta-ellenorzo-student-mobile-ios');
    expect(KretaAuthApp.forRole(Role.parent).clientId,
        'kreta-ellenorzo-guardian-mobile-android');
  });

  test('redirect uri matches the app', () {
    expect(KretaAuthApp.student.redirectUri,
        'https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect');
    expect(KretaAuthApp.guardian.redirectUri,
        'https://mobil.e-kreta.hu/ellenorzo-guardian/prod/oauthredirect');
  });

  test('authorize url carries the matching client and redirect', () {
    final u = Uri.parse(KretaAuthApp.guardian.authorizeUrl);
    expect(u.host, 'idp.e-kreta.hu');
    expect(u.queryParameters['client_id'],
        'kreta-ellenorzo-guardian-mobile-android');
    expect(u.queryParameters['redirect_uri'],
        'https://mobil.e-kreta.hu/ellenorzo-guardian/prod/oauthredirect');
    expect(u.queryParameters['scope'], contains('kreta-ellenorzo-webapi.public'));
    final s = Uri.parse(KretaAuthApp.student.authorizeUrl);
    expect(s.queryParameters['client_id'], 'kreta-ellenorzo-student-mobile-ios');
  });

  test('parent requests introduce themselves as the guardian app', () {
    expect(
        KretaAuthApp.guardian
            .userAgent('hu.ekreta.student/5.17.0/23013RK75C/16/36'),
        'hu.ekreta.guardian/5.17.0/23013RK75C/16/36');
    expect(KretaAuthApp.student.userAgent('hu.ekreta.student/5.17.0/X/16/36'),
        'hu.ekreta.student/5.17.0/X/16/36');
  });

  test('refresh and logout keep the client the token was issued to', () {
    // Everyone logs in on the same KRÉTA page with the student client; the
    // account type (student/parent) is read from the token afterwards.
    expect(
        User.refreshBody(refreshToken: 'r', instituteCode: 'i')['client_id'],
        'kreta-ellenorzo-student-mobile-ios');
    expect(User.logoutBody(refreshToken: 'r')['client_id'],
        'kreta-ellenorzo-student-mobile-ios');
  });
}
