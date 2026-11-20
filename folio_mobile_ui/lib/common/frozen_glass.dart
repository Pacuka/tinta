import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// The "frozen" glass of every Üveg sheet and dialog.
///
/// Live glass re-blurs what is behind it on every frame; on a phone-sized
/// sheet that cost 15.9 ms per frame on the Redmi (120 Hz budget: 8.3 ms)
/// and the opening stuttered. But what is behind a sheet or dialog does not
/// change while it is open, so the page is photographed ONCE when the
/// popup opens, blurred once, and the sheet then only shows that picture:
/// a plain image draw per frame (user, 2026-11-20).
///
/// Only for popup routes (sheets, dialogs): there the page behind is
/// covered by the modal barrier and cannot scroll. Anywhere else the
/// caller keeps live glass.
class FrozenBackdrop {
  FrozenBackdrop._();

  /// Wraps the whole app; the photo is taken of this boundary.
  static final GlobalKey rootKey = GlobalKey(debugLabel: 'FrozenBackdrop');

  static Widget wrapApp(Widget app) =>
      RepaintBoundary(key: rootKey, child: app);

  /// Resolution of the photo relative to logical pixels. It gets blurred
  /// anyway, so a low resolution looks the same and is much cheaper.
  static const double photoScale = 0.5;

  /// Whether [context] sits in a popup (sheet, dialog), where a frozen
  /// background is correct.
  static bool canFreeze(BuildContext context) =>
      ModalRoute.of(context) is PopupRoute;
}

class FrozenGlass extends StatefulWidget {
  const FrozenGlass({
    super.key,
    required this.borderRadius,
    required this.tint,
    required this.blurSigma,
    required this.rim,
    required this.child,
    this.saturation = 1.25,
    this.highlight = 0.10,
  });

  final BorderRadius borderRadius;

  /// Laid over the blurred picture (the glass colour).
  final Color tint;

  /// Blur strength in logical pixels.
  final double blurSigma;

  /// The lit 0.8 px edge.
  final Color rim;

  /// Colour boost of the blurred picture, like real glass (1 = none).
  final double saturation;

  /// Strength of the light catching the top edge (0 = none).
  final double highlight;

  final Widget child;

  @override
  State<FrozenGlass> createState() => _FrozenGlassState();
}

class _FrozenGlassState extends State<FrozenGlass> {
  ui.Image? _photo;
  Offset _photoOrigin = Offset.zero;

  @override
  void initState() {
    super.initState();
    // After the popup's first frame: the sheet is still below the screen
    // and the dialog fully transparent, the barrier not drawn yet, so the
    // photo shows just the page behind.
    SchedulerBinding.instance.addPostFrameCallback((_) => _capture());
  }

  void _capture() {
    if (!mounted) return;
    final ro = FrozenBackdrop.rootKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary || !ro.attached) return;
    ui.Image? raw;
    try {
      raw = ro.toImageSync(pixelRatio: FrozenBackdrop.photoScale);
      final w = raw.width, h = raw.height;
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      final sigma = widget.blurSigma * FrozenBackdrop.photoScale;
      canvas.drawImage(
        raw,
        Offset.zero,
        Paint()
          ..imageFilter = ui.ImageFilter.compose(
            outer: ColorFilter.matrix(_saturationMatrix(widget.saturation)),
            inner: ui.ImageFilter.blur(
                sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
          ),
      );
      // what the glass really sees: the page under the modal barrier
      final barrier = ModalRoute.of(context)?.barrierColor;
      if (barrier != null && barrier.a > 0) {
        canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
            Paint()..color = barrier);
      }
      final picture = rec.endRecording();
      final blurred = picture.toImageSync(w, h);
      picture.dispose();
      _photoOrigin = ro.localToGlobal(Offset.zero);
      setState(() {
        _photo?.dispose();
        _photo = blurred;
      });
    } catch (_) {
      // No photo: the tinted panel alone still reads as a sheet.
    } finally {
      raw?.dispose();
    }
  }

  @override
  void dispose() {
    _photo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: _FrozenPhoto(
        photo: _photo,
        photoOrigin: _photoOrigin,
        borderRadius: widget.borderRadius,
        // no photo yet (first frame, or a test): a denser glass colour
        tint: _photo == null
            ? widget.tint
                .withValues(alpha: (widget.tint.a + 0.25).clamp(0.0, 1.0))
            : widget.tint,
        highlight: widget.highlight,
        rim: widget.rim,
        // the content's own Material, so list rows' ripples show
        child: Material(type: MaterialType.transparency, child: widget.child),
      ),
    );
  }

  static List<double> _saturationMatrix(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}

/// Paints the blurred photo behind its child, lined up with the screen
/// wherever the sheet currently is (it slides while opening).
class _FrozenPhoto extends SingleChildRenderObjectWidget {
  const _FrozenPhoto({
    required this.photo,
    required this.photoOrigin,
    required this.borderRadius,
    required this.tint,
    required this.highlight,
    required this.rim,
    super.child,
  });

  final ui.Image? photo;
  final Offset photoOrigin;
  final BorderRadius borderRadius;
  final Color tint;
  final double highlight;
  final Color rim;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFrozenPhoto()
    ..photo = photo
    ..photoOrigin = photoOrigin
    ..borderRadius = borderRadius
    ..tint = tint
    ..highlight = highlight
    ..rim = rim;

  @override
  void updateRenderObject(BuildContext context, _RenderFrozenPhoto ro) {
    ro
      ..photo = photo
      ..photoOrigin = photoOrigin
      ..borderRadius = borderRadius
      ..tint = tint
      ..highlight = highlight
      ..rim = rim;
  }
}

/// Paints, back to front: the blurred photo (lined up with the screen
/// wherever the sheet currently is, it slides while opening), the glass
/// colour, the light on the top edge, the content, then the lit rim.
class _RenderFrozenPhoto extends RenderProxyBox {
  ui.Image? _photo;
  set photo(ui.Image? v) {
    if (v == _photo) return;
    _photo = v;
    markNeedsPaint();
  }

  Offset _photoOrigin = Offset.zero;
  set photoOrigin(Offset v) {
    if (v == _photoOrigin) return;
    _photoOrigin = v;
    markNeedsPaint();
  }

  BorderRadius _borderRadius = BorderRadius.zero;
  set borderRadius(BorderRadius v) {
    if (v == _borderRadius) return;
    _borderRadius = v;
    markNeedsPaint();
  }

  Color _tint = const Color(0x00000000);
  set tint(Color v) {
    if (v == _tint) return;
    _tint = v;
    markNeedsPaint();
  }

  double _highlight = 0;
  set highlight(double v) {
    if (v == _highlight) return;
    _highlight = v;
    markNeedsPaint();
  }

  Color _rim = const Color(0x00000000);
  set rim(Color v) {
    if (v == _rim) return;
    _rim = v;
    markNeedsPaint();
  }

  final Paint _photoPaint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final rect = offset & size;
    final photo = _photo;
    if (photo != null) {
      // where the screen's top-left is, in this box's coordinates
      final screenTopLeft = globalToLocal(_photoOrigin);
      final dst = Rect.fromLTWH(
        offset.dx + screenTopLeft.dx,
        offset.dy + screenTopLeft.dy,
        photo.width / FrozenBackdrop.photoScale,
        photo.height / FrozenBackdrop.photoScale,
      );
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawImageRect(
        photo,
        Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
        dst,
        _photoPaint,
      );
      canvas.restore();
    }
    canvas.drawRect(rect, Paint()..color = _tint);
    if (_highlight > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: _highlight),
              const Color(0x00FFFFFF),
            ],
            stops: const [0.0, 0.12],
          ).createShader(rect),
      );
    }
    super.paint(context, offset);
    if (_rim.a > 0) {
      // the child may have pushed layers: ask for the canvas again
      context.canvas.drawRRect(
        _borderRadius.toRRect(rect).deflate(0.4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _rim,
      );
    }
  }
}
