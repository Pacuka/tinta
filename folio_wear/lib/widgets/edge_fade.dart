import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// How far from the middle (as a share of half the screen) an item stays
/// untouched, and what it shrinks to at the very edge.
const _flatZone = 0.5;
const _edgeScale = 0.75;
const _edgeOpacity = 0.35;

({double scale, double opacity}) edgeEffect(double center, double height) {
  final half = height / 2;
  final distance = (center - half).abs() / half;
  final t = ((distance - _flatZone) / (1 - _flatZone)).clamp(0.0, 1.0);
  final eased = pow(t, 2).toDouble();
  return (
    scale: 1 - (1 - _edgeScale) * eased,
    opacity: 1 - (1 - _edgeOpacity) * eased,
  );
}

/// Shrinks and fades its child towards the top and bottom of the round
/// screen. Works in paint, so scrolling costs no rebuilds. Needs to be
/// repainted while scrolling: no RepaintBoundary between it and the list.
class EdgeFade extends SingleChildRenderObjectWidget {
  const EdgeFade({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderEdgeFade(
        MediaQuery.sizeOf(context).height,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderEdgeFade renderObject) {
    renderObject.screenHeight = MediaQuery.sizeOf(context).height;
  }
}

class _RenderEdgeFade extends RenderProxyBox {
  _RenderEdgeFade(this._screenHeight);

  double _screenHeight;
  set screenHeight(double value) {
    if (value == _screenHeight) return;
    _screenHeight = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final middle = size.center(Offset.zero);
    final effect = edgeEffect(localToGlobal(middle).dy, _screenHeight);
    if (effect.scale == 1.0) {
      super.paint(context, offset);
      return;
    }
    final transform = Matrix4.translationValues(middle.dx, middle.dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(effect.scale, effect.scale, 1.0))
      ..multiply(Matrix4.translationValues(-middle.dx, -middle.dy, 0.0));
    context.pushTransform(needsCompositing, offset, transform,
        (context, offset) {
      context.pushOpacity(
          offset, (effect.opacity * 255).round(), super.paint);
    });
  }
}
