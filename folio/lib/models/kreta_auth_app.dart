import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:folio/models/user.dart';
import 'package:folio_kreta_api/client/api.dart';

/// Which official e-KRÉTA app a login presents itself as. Students log in as
/// the student app, parents as the guardian ("Szülő") app; the KRÉTA login
/// page is the same, only the client id and redirect differ.
class KretaAuthApp {
  const KretaAuthApp._(this.clientId, this.redirectUri);

  static const student = KretaAuthApp._(
    'kreta-ellenorzo-student-mobile-ios',
    'https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect',
  );

  /// From the official guardian app (hu.ekreta.guardian 5.17.0).
  static const guardian = KretaAuthApp._(
    'kreta-ellenorzo-guardian-mobile-android',
    'https://mobil.e-kreta.hu/ellenorzo-guardian/prod/oauthredirect',
  );

  static KretaAuthApp forRole(Role role) =>
      role == Role.parent ? guardian : student;

  final String clientId;
  final String redirectUri;

  /// The student user agent rewritten to the guardian app for parents.
  String userAgent(String studentUserAgent) => identical(this, guardian)
      ? studentUserAgent
          .replaceFirst('hu.ekreta.student/', 'hu.ekreta.guardian/')
          .replaceFirst('eKretaStudent/', 'eKretaGuardian/')
      : studentUserAgent;
}

/// One trip to the KRÉTA login page. Every attempt gets a fresh PKCE pair
/// (RFC 7636), state and nonce, so an intercepted login code is useless
/// without this attempt's verifier. (Folio used one fixed pair for everyone.)
class KretaLoginAttempt {
  KretaLoginAttempt(this.app)
      : codeVerifier = _randomString(32),
        state = _randomString(16),
        nonce = _randomString(16);

  final KretaAuthApp app;
  final String codeVerifier;
  final String state;
  final String nonce;

  static final _random = Random.secure();

  static String _randomString(int bytes) => _base64UrlNoPad(
      List<int>.generate(bytes, (_) => _random.nextInt(256)));

  static String _base64UrlNoPad(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  String get codeChallenge =>
      _base64UrlNoPad(sha256.convert(ascii.encode(codeVerifier)).bytes);

  /// KRÉTA login page; same parameters and order as before, only the
  /// PKCE challenge, state and nonce are this attempt's own.
  String get authorizeUrl =>
      '${BaseKreta.kretaIdp}/connect/authorize?prompt=login&nonce=$nonce&response_type=code&code_challenge_method=S256&scope=openid%20email%20offline_access%20kreta-ellenorzo-webapi.public%20kreta-eugyintezes-webapi.public%20kreta-fileservice-webapi.public%20kreta-mobile-global-webapi.public%20kreta-dkt-webapi.public%20kreta-ier-webapi.public&code_challenge=$codeChallenge&redirect_uri=${app.redirectUri}&client_id=${app.clientId}&state=$state';

  /// The redirect belongs to this attempt (not a stale or injected one).
  bool isOwnRedirect(Uri redirect) =>
      redirect.queryParameters['state'] == state;
}
