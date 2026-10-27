/// Remembers which page motions already ran in this app launch, so each
/// page animates its header once instead of on every tab switch.
class MotionOnce {
  static final Set<String> _played = {};

  /// True the first time [key] is asked for, false afterwards.
  static bool shouldPlay(String key) => _played.add(key);

  static void reset() => _played.clear();
}
