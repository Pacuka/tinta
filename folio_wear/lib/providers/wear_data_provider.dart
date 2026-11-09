import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/wear_extras.dart';
import '../models/wear_lesson.dart';
import '../models/wear_notification.dart';

class WearDataProvider with ChangeNotifier, WidgetsBindingObserver {
  static const _channel = MethodChannel('app.zan1456.folio.wear/data');

  static void Function(double delta)? onRotaryInput;

  List<WearLesson> _lessons = [];
  List<WearNotification> _notifications = [];
  WearExtras? _extras;
  DateTime? _lastSync;
  bool _connected = false;
  bool _isPaired = false;
  String _pairingCode = '';
  bool _loaded = false;
  bool _foreground = true;
  Timer? _pairingRetry;

  /// The phone only hears a pairing request while Tinta is open on it, so an
  /// unpaired watch keeps asking until the code is confirmed.
  static const pairingRetryInterval = Duration(seconds: 5);

  List<WearLesson> get lessons => _lessons;
  List<WearNotification> get notifications => _notifications;
  WearExtras? get extras => _extras;
  DateTime? get lastSync => _lastSync;
  bool get connected => _connected;
  bool get isPaired => _isPaired;
  String get pairingCode => _pairingCode;

  /// False until the saved state is read, so a paired watch doesn't flash
  /// the pairing screen on start.
  bool get loaded => _loaded;

  WearDataProvider() {
    _channel.setMethodCallHandler(_handleNativeCall);
    WidgetsBinding.instance.addObserver(this);
    _loadCached();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _updatePairingRetry();
    if (foreground) requestSync();
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onTimetableReceived':
        _parseTimetable(call.arguments as String);
        break;
      case 'onNotificationsReceived':
        _parseNotifications(call.arguments as String);
        break;
      case 'onExtrasReceived':
        _parseExtras(call.arguments as String);
        break;
      case 'onConnectionChanged':
        _connected = call.arguments as bool;
        _updatePairingRetry();
        notifyListeners();
        break;
      case 'onRotaryInput':
        onRotaryInput?.call((call.arguments as num).toDouble());
        break;
      case 'onLoggedOut':
        _forget();
        _updatePairingRetry();
        notifyListeners();
        break;
      case 'onPairConfirmed':
        final code = call.arguments as String;
        if (code == _pairingCode) {
          _isPaired = true;
          _updatePairingRetry();
          try { await _channel.invokeMethod('setIsPaired', true); } catch (_) {}
          notifyListeners();
          // Data sent before the pairing was ignored: ask for it now.
          await requestSync();
        }
        break;
    }
  }

  void _parseTimetable(String json) {
    try {
      final raw = jsonDecode(json) as List<dynamic>;
      _lessons = raw
          .map((e) => WearLesson.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      _lastSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('WearDataProvider: timetable parse error: $e');
    }
  }

  void _parseNotifications(String json) {
    try {
      final raw = jsonDecode(json) as List<dynamic>;
      _notifications = raw
          .map((e) =>
              WearNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      debugPrint('WearDataProvider: notifications parse error: $e');
    }
  }

  void _parseExtras(String json) {
    final extras = WearExtras.tryParse(json);
    if (extras == null) {
      debugPrint('WearDataProvider: extras parse error');
      return;
    }
    _extras = extras;
    notifyListeners();
  }

  Future<void> _loadCached() async {
    try {
      final result = await _channel.invokeMethod<Map>('getCachedData');
      if (result != null) {
        if (result['timetable'] != null) {
          _parseTimetable(result['timetable'] as String);
        }
        if (result['notifications'] != null) {
          _parseNotifications(result['notifications'] as String);
        }
        if (result['extras'] != null) {
          _parseExtras(result['extras'] as String);
        }
        if (result['connected'] != null) {
          _connected = result['connected'] as bool;
        }
        if (result['isPaired'] != null) {
          _isPaired = result['isPaired'] as bool;
        }
        if (result['pairingCode'] != null) {
          _pairingCode = result['pairingCode'] as String;
        }
      }
    } catch (_) {}

    // Generate pairing code if missing
    if (_pairingCode.isEmpty) {
      _pairingCode = _generateCode();
      try { await _channel.invokeMethod('setPairingCode', _pairingCode); } catch (_) {}
    }

    _loaded = true;
    _updatePairingRetry();
    notifyListeners();

    requestSync();

    // Pull retry: if lessons are still empty after 4s, pull from native cache
    Future.delayed(const Duration(seconds: 4), () async {
      if (_lessons.isEmpty) {
        try {
          await _channel.invokeMethod('pullDataNow');
        } catch (_) {}
      }
    });
  }

  String _generateCode() =>
      List.generate(6, (_) => Random().nextInt(10)).join();

  Future<void> _sendPairingRequest() async {
    try { await _channel.invokeMethod('sendPairingRequest', _pairingCode); } catch (_) {}
  }

  void _updatePairingRetry() {
    final shouldAsk = _loaded &&
        _foreground &&
        _connected &&
        !_isPaired &&
        _pairingCode.isNotEmpty;
    if (!shouldAsk) {
      _pairingRetry?.cancel();
      _pairingRetry = null;
      return;
    }
    if (_pairingRetry != null) return;
    _sendPairingRequest();
    _pairingRetry =
        Timer.periodic(pairingRetryInterval, (_) => _sendPairingRequest());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pairingRetry?.cancel();
    super.dispose();
  }

  Future<void> requestSync() async {
    try { await _channel.invokeMethod('requestSync'); } catch (_) {}
  }

  /// Drops the phone's data from memory (native storage is cleared too).
  void _forget() {
    _isPaired = false;
    _lessons = [];
    _notifications = [];
    _extras = null;
    _lastSync = null;
  }

  Future<void> unpair() async {
    _forget();
    _pairingCode = _generateCode();
    try {
      await _channel.invokeMethod('clearData');
      await _channel.invokeMethod('setPairingCode', _pairingCode);
    } catch (_) {}
    _updatePairingRetry();
    notifyListeners();
  }

  WearLesson? get currentLesson {
    final now = DateTime.now();
    try {
      return _lessons.firstWhere((l) => l.isActiveAt(now) && !l.isCancelled);
    } catch (_) { return null; }
  }

  WearLesson? get nextLesson {
    final now = DateTime.now();
    try {
      return _lessons.firstWhere((l) => l.start.isAfter(now) && !l.isCancelled);
    } catch (_) { return null; }
  }

  List<WearLesson> get todayLessons {
    final today = DateTime.now();
    return _lessons.where((l) =>
        l.start.year == today.year &&
        l.start.month == today.month &&
        l.start.day == today.day).toList();
  }

  /// All lessons in the synced week, grouped by day — used when today is empty.
  Map<DateTime, List<WearLesson>> get weekLessonsByDay {
    final map = <DateTime, List<WearLesson>>{};
    for (final l in _lessons) {
      final day = DateTime(l.start.year, l.start.month, l.start.day);
      map.putIfAbsent(day, () => []).add(l);
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}
