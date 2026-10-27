import 'package:intl/intl.dart';

class KretaAPI {
  // IDP API
  static String get login => BaseKreta.kretaIdp + KretaApiEndpoints.token;
  static String get logout => BaseKreta.kretaIdp + KretaApiEndpoints.revoke;
  static String get nonce => BaseKreta.kretaIdp + KretaApiEndpoints.nonce;
  static const clientId = "kreta-ellenorzo-student-mobile-ios";

  // ELLENORZO API
  static String notes(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.notes;
  static String events(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.events;
  static String student(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.student;
  static String grades(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.grades;
  static String absences(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.absences;
  static String groups(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.groups;
  static String groupAverages(String iss, String uid) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.groupAverages}?oktatasiNevelesiFeladatUid=$uid";
  static String averages(String iss, String uid) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.averages}?oktatasiNevelesiFeladatUid=$uid";
  static String timetable(String iss, {DateTime? start, DateTime? end}) =>
      BaseKreta.kreta(iss) +
      KretaApiEndpoints.timetable +
      (start != null && end != null
          ? "?datumTol=${start.toUtc().toIso8601String()}&datumIg=${end.toUtc().toIso8601String()}"
          : "");
  static String exams(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.exams;
  static String consultingHours(String iss, DateTime from, DateTime to) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.consultingHours}"
      "?datumTol=${from.toUtc().toIso8601String()}"
      "&datumIg=${to.toUtc().toIso8601String()}";
  static String consultingHour(String iss, String uid) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.consultingHours}/$uid";
  static String consultingReservation(String iss, String slotUid) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.consultingReservation}/$slotUid";
  static String homework(String iss, {DateTime? start, String? id}) =>
      BaseKreta.kreta(iss) +
      KretaApiEndpoints.homework +
      (id != null ? "/$id" : "") +
      (id == null && start != null
          ? "?datumTol=${DateFormat('yyyy-MM-dd').format(start)}"
          : "");
  static String capabilities(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.capabilities;
  static String downloadHomeworkAttachments(
          String iss, String uid, String type) =>
      BaseKreta.kreta(iss) +
      KretaApiEndpoints.downloadHomeworkAttachments(uid, type);
  static String subjects(String iss, String uid) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.subjects}?oktatasiNevelesiFeladatUid=$uid";
  static String contact(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.contact;
  static String bankAccount(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.bankAccount;
  static String digitalCertifications(String iss) =>
      BaseKreta.kreta(iss) + KretaApiEndpoints.digitalCertifications;
  static String digitalCertificationFile(String iss, int id) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.digitalCertificationFile(id)}";
  // Structure:
  // {
  //   "Uid": 000,
  //   "Tantargy": {
  //       "Uid": 000,
  //       "Nev": "Irodalom",
  //       "Kategoria": {
  //          "Uid": "000,magyar_nyelv_es_irodalom",
  //          "Nev": "magyar_nyelv_es_irodalom",
  //          "Leiras": "Magyar nyelv és irodalom"
  //       },
  //       "SortIndex": 0,
  //    },
  //    "Atlag": null, // float
  //    "AtlagAlakulasaIdoFuggvenyeben": Array[], // no idea what this is
  //    "SulyozottOsztalyzatOsszege": null, // int | float
  //    "SulyozottOsztalyzatSzama": null, // int | float
  //    "SortIndex": 0
  // }
  // refer to https://discord.com/channels/1111649116020285532/1111798771513303102/1148368925969612920

  // ADMIN API
  static String get sendMessage =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.sendMessage;
  static String messages(String endpoint) =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.messages(endpoint);
  static String message(String id) =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.message(id);
  static String get recipientCategories =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.recipientCategories;
  static String get availableCategories =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.availableCategories;
  static String get recipientTeachers =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.recipientTeachers;
  static String get recipientDirectorate =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.recipientDirectorate;
  static String get tmgiTypes =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.tmgiTypes;
  static String get caseTypes =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.caseTypes;
  static String get childData =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.childData;
  static String get cases => BaseKreta.kretaAdmin + KretaAdminEndpoints.cases;
  static String casesWithClosed(bool closed) =>
      closed ? "$cases?isLezartakIs=true" : cases;
  static String caseDetail(String id) => "$cases/$id";
  static String signer(String caseId, String kretaId) =>
      "${BaseKreta.kretaAdmin}/api/v1/ugy/alkalmazott/$caseId/$kretaId";
  static String printableCase(String id) =>
      "${BaseKreta.kretaAdmin}/api/v1/dokumentumok/kerelmek/$id";
  static String printableDecision(String id) =>
      "${BaseKreta.kretaAdmin}/api/v1/dokumentumok/hatarozatok/$id";
  static String get uploadTemp =>
      "${BaseKreta.kretaAdmin}/api/v1/ideiglenesfajlok";
  static String get uploadAttachment =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.uploadAttachment;
  static String downloadAttachment(String id) =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.downloadAttachment(id);
  static String get trashMessage =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.trashMessage;
  static String get deleteMessage =>
      BaseKreta.kretaAdmin + KretaAdminEndpoints.deleteMessage;

  // NOTIFICATION API
  static String get notificationRegistration =>
      BaseKreta.kretaNotification + '/Registration';
}

class BaseKreta {
  /// Debug builds only: when set (e.g. "http://127.0.0.1:8765"), every KRÉTA
  /// host points at the local fake KRÉTA server so nothing reaches the school.
  static String? fakeHost;

  static String kreta(String iss) => fakeHost ?? "https://$iss.e-kreta.hu";
  static String get kretaIdp => fakeHost ?? "https://idp.e-kreta.hu";
  static String get kretaAdmin => fakeHost ?? "https://eugyintezes.e-kreta.hu";
  static String get kretaFiles => fakeHost ?? "https://files.e-kreta.hu";
  static String get kretaNotification =>
      fakeHost ?? "https://kretaglobalmobileapi2.ekreta.hu/api/v3";

  /// Token/login requests (they must not carry the bearer token).
  static bool isIdpUrl(String url) =>
      url.contains("idp.e-kreta.hu") ||
      (fakeHost != null && url.startsWith("$fakeHost/connect/"));
}

class KretaApiEndpoints {
  static const token = "/connect/token";
  static const revoke = "/connect/revocation";
  static const nonce = "/nonce";
  static const notes = "/ellenorzo/V3/Sajat/Feljegyzesek";
  static const events = "/ellenorzo/V3/Sajat/FaliujsagElemek";
  static const student = "/ellenorzo/V3/Sajat/TanuloAdatlap";
  static const grades = "/ellenorzo/V3/Sajat/Ertekelesek";
  static const absences = "/ellenorzo/V3/Sajat/Mulasztasok";
  static const consultingHours = "/ellenorzo/V3/Sajat/Fogadoorak";
  static const consultingReservation =
      "/ellenorzo/V3/Sajat/Fogadoorak/Idopontok/Jelentkezesek";
  static const groups = "/ellenorzo/V3/Sajat/OsztalyCsoportok";
  static const groupAverages =
      "/ellenorzo/V3/Sajat/Ertekelesek/Atlagok/OsztalyAtlagok";
  static const averages =
      "/ellenorzo/V3/Sajat/Ertekelesek/Atlagok/TantargyiAtlagok";
  static const timetable = "/ellenorzo/V3/Sajat/OrarendElemek";
  static const exams = "/ellenorzo/V3/Sajat/BejelentettSzamonkeresek";
  static const homework = "/ellenorzo/V3/Sajat/HaziFeladatok";
  // static const homeworkDone = "/ellenorzo/V3/Sajat/HaziFeladatok/Megoldva"; // Removed from the API
  static const capabilities = "/ellenorzo/V3/Sajat/Intezmenyek";
  static String downloadHomeworkAttachments(String uid, String type) =>
      "/ellenorzo/V3/Sajat/Csatolmany/$uid";
  static const subjects =
      "/ellenorzo/V3/Sajat/Ertekelesek/Atlagok/TantargyiAtlagok";
  static const contact = "/ellenorzo/V3/Sajat/Elerhetoseg";
  static const bankAccount = "/ellenorzo/V3/Sajat/Bankszamla";
  static const digitalCertifications =
      "/ellenorzo/V3/documents/digitalisbizonyitvanyok";
  static String digitalCertificationFile(int id) =>
      "/ellenorzo/V3/documents/digitalisbizonyitvanyok/$id/file";
}

class KretaAdminEndpoints {
  //static const messages = "/api/v1/kommunikacio/postaladaelemek/sajat";
  static const sendMessage = "/api/v1/kommunikacio/uzenetek";
  static String messages(String endpoint) =>
      "/api/v1/kommunikacio/postaladaelemek/$endpoint";
  static String message(String id) =>
      "/api/v1/kommunikacio/postaladaelemek/$id";
  static const recipientCategories = "/api/v1/adatszotarak/cimzetttipusok";
  static const availableCategories = "/api/v1/kommunikacio/cimezhetotipusok";
  static const recipientTeachers = "/api/v1/kreta/alkalmazottak/tanar";
  static const recipientDirectorate = "/api/v1/kreta/alkalmazottak/igazgatosag";
  static const uploadAttachment = "/ideiglenesfajlok";
  // absence justification (TMGI case), parent accounts
  static const tmgiTypes = "/api/v1/adatszotarak/tmgiigazolastipusok";
  static const caseTypes = "/api/v1/adatszotarak/kerelemtipusok";
  static const childData = "/api/v1/kreta/gyerekemadatok";
  static const cases = "/api/v1/ugy/kerelmek";
  static String downloadAttachment(String id) =>
      "/api/v1/dokumentumok/uzenetek/$id";
  static const trashMessage = "/api/v1/kommunikacio/postaladaelemek/kuka";
  static const deleteMessage = "/api/v1/kommunikacio/postaladaelemek/torles";
  // profile management
  static const editProfile = "/api/profilapi/saveprofildata";
}
