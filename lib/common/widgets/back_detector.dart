import 'package:flutter/gestures.dart'
    show
        kBackMouseButton,
        PointerCancelEvent,
        PointerDeviceKind,
        PointerDownEvent,
        PointerUpEvent;
import 'package:material_ui/material_ui.dart';

const double kIosBackEdgeWidth = 32;
const double kIosBackSwipeDistance = 96;

@visibleForTesting
bool isEdgeBackSwipe(Offset start, Offset end) {
  final delta = end - start;
  return start.dx <= kIosBackEdgeWidth &&
      delta.dx >= kIosBackSwipeDistance &&
      delta.dx >= delta.dy.abs() * 1.5;
}

class BackDetector extends StatefulWidget {
  const BackDetector({
    super.key,
    required this.onBack,
    required this.child,
    this.enableEdgeSwipe = false,
    this.nativePopGestureInProgress,
  });

  final Widget child;
  final VoidCallback onBack;
  final bool enableEdgeSwipe;
  final bool Function()? nativePopGestureInProgress;

  @override
  State<BackDetector> createState() => _BackDetectorState();
}

class _BackDetectorState extends State<BackDetector> {
  int? _pointer;
  Offset? _start;

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == kBackMouseButton) {
      widget.onBack();
      return;
    }

    if (!widget.enableEdgeSwipe || event.kind != PointerDeviceKind.touch) {
      return;
    }
    if (_pointer != null) {
      _reset();
      return;
    }
    if (event.position.dx > kIosBackEdgeWidth) return;

    _pointer = event.pointer;
    _start = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final start = _start;
    _reset();
    if (start != null &&
        isEdgeBackSwipe(start, event.position) &&
        widget.nativePopGestureInProgress?.call() != true) {
      widget.onBack();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _reset();
  }

  void _reset() {
    _pointer = null;
    _start = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: .translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
