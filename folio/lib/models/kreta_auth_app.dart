import 'package:folio/models/user.dart';
import 'package:folio_kreta_api/client/api.dart';

/// Which official e-KRÉTA app a login presents itself as. Students log in as
/// the student app, parents as the guardian ("Szülő") app; the KRÉTA login
/// page is the same, only the client id and redirect differ.
class KretaAuthApp {
  const KretaAuthApp._(this.clientId, this.redirectUri, this.state);

  static const student = KretaAuthApp._(
    'kreta-ellenorzo-student-mobile-ios',
    'https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect',
    'folio_student_mobile',
  );

  /// From the official guardian app (hu.ekreta.guardian 5.17.0).
  static const guardian = KretaAuthApp._(
    'kreta-ellenorzo-guardian-mobile-android',
    'https://mobil.e-kreta.hu/ellenorzo-guardian/prod/oauthredirect',
    'folio_guardian_mobile',
  );

  static KretaAuthApp forRole(Role role) =>
      role == Role.parent ? guardian : student;

  final String clientId;
  final String redirectUri;
  final String state;

  /// KRÉTA login page (code flow with the app's fixed PKCE pair).
  String get authorizeUrl =>
      '${BaseKreta.kretaIdp}/connect/authorize?prompt=login&nonce=wylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU&response_type=code&code_challenge_method=S256&scope=openid%20email%20offline_access%20kreta-ellenorzo-webapi.public%20kreta-eugyintezes-webapi.public%20kreta-fileservice-webapi.public%20kreta-mobile-global-webapi.public%20kreta-dkt-webapi.public%20kreta-ier-webapi.public&code_challenge=HByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ&redirect_uri=$redirectUri&client_id=$clientId&state=$state';

  /// The student user agent rewritten to the guardian app for parents.
  String userAgent(String studentUserAgent) => identical(this, guardian)
      ? studentUserAgent
          .replaceFirst('hu.ekreta.student/', 'hu.ekreta.guardian/')
          .replaceFirst('eKretaStudent/', 'eKretaGuardian/')
      : studentUserAgent;
}
