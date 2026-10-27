import 'package:flutter/material.dart';

const _blobAsset = 'assets/icons/ic_splash.png';

/// Cold-start intro: the ink blot splats (elastic scale), then the overlay
/// fades out and reveals the app. Plays once per app process.
class InkSplashIntro extends StatefulWidget {
  const InkSplashIntro({super.key, required this.child});

  final Widget child;

  static bool _played = false;

  @override
  State<InkSplashIntro> createState() => _InkSplashIntroState();
}

class _InkSplashIntroState extends State<InkSplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _visible = !InkSplashIntro._played;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_visible || _c.isAnimating || _c.isCompleted) return;
    InkSplashIntro._played = true;
    if (MediaQuery.of(context).disableAnimations) {
      _visible = false;
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always the same Stack, so the app below is never remounted when the
    // intro ends (a remount drops focus: the keyboard would close).
    if (!_visible) {
      return Stack(children: [widget.child, const SizedBox.shrink()]);
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final splat = CurvedAnimation(
        parent: _c, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    final fade = CurvedAnimation(
        parent: _c, curve: const Interval(0.62, 1.0, curve: Curves.easeIn));
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Opacity(
              opacity: 1 - fade.value,
              child: ColoredBox(
                // Same background as the native splash screen.
                color: dark ? const Color(0xFF101218) : const Color(0xFFF6F7F9),
                child: Center(
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * splat.value + 0.15 * fade.value,
                    child: Image.asset(_blobAsset,
                        width: 150,
                        height: 150,
                        // Dark splash uses the light ink, like the native one.
                        color: dark ? const Color(0xFF9DB0FF) : null,
                        colorBlendMode: BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small ink blot that "breathes" while data is refreshing.
class InkPulse extends StatefulWidget {
  const InkPulse({super.key, this.size = 34});

  final double size;

  @override
  State<InkPulse> createState() => _InkPulseState();
}

class _InkPulseState extends State<InkPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) => Opacity(
        opacity: 0.55 + 0.45 * t.value,
        child: Transform.scale(
          scale: 0.85 + 0.2 * t.value,
          child: Image.asset(_blobAsset,
              width: widget.size,
              height: widget.size,
              color: Theme.of(context).colorScheme.secondary,
              colorBlendMode: BlendMode.srcIn),
        ),
      ),
    );
  }
}
