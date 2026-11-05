import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Smoothly interpolates discrete physical mouse wheel scroll notches on desktop
/// platforms (Windows, macOS, Linux) into fluid, continuous frame deltas.
class SmoothMouseScrollHandler {
  SmoothMouseScrollHandler({
    required this.dispatchEvent,
    Ticker Function(TickerCallback onTick)? createTicker,
    this.decayRate = 14.0,
    this.minDeltaThreshold = 0.2,
  }) : _createTicker = createTicker ?? ((onTick) => Ticker(onTick, debugLabel: 'SmoothMouseScroll'));

  final void Function(PointerScrollEvent event) dispatchEvent;
  final Ticker Function(TickerCallback onTick) _createTicker;
  final double decayRate;
  final double minDeltaThreshold;

  Offset _targetOffset = Offset.zero;
  Offset _currentOffset = Offset.zero;
  Offset _lastPosition = Offset.zero;
  int _lastViewId = 0;
  int _lastDevice = 0;
  bool _isSynthesizing = false;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  bool get isSynthesizing => _isSynthesizing;
  bool get isAnimating =>
      (_targetOffset - _currentOffset).distance >= minDeltaThreshold;

  void handlePointerEvent(PointerEvent event) {
    if (event is PointerHoverEvent || event is PointerMoveEvent) {
      final movedDistance = (event.position - _lastPosition).distance;
      // If mouse moved far away (> 60px), snap ongoing animation to avoid scrolling
      // a different target unintentionally.
      if (movedDistance > 60.0 && isAnimating) {
        _currentOffset = _targetOffset;
        _stopTicker();
      }
      _lastPosition = event.position;
      _lastViewId = event.viewId;
      _lastDevice = event.device;
      return;
    }

    if (event is PointerScrollEvent &&
        event.kind == PointerDeviceKind.mouse &&
        !_isSynthesizing) {
      _lastPosition = event.position;
      _lastViewId = event.viewId;
      _lastDevice = event.device;

      final inDy = event.scrollDelta.dy;
      final diffDy = _targetOffset.dy - _currentOffset.dy;
      final inDx = event.scrollDelta.dx;
      final diffDx = _targetOffset.dx - _currentOffset.dx;

      // Handle vertical reversal & accumulation
      final double nextTargetY;
      if ((inDy > 0 && diffDy < -1.0) || (inDy < 0 && diffDy > 1.0)) {
        _currentOffset = Offset(_currentOffset.dx, 0.0);
        nextTargetY = inDy;
      } else {
        const maxBacklog = 360.0;
        final targetY = _targetOffset.dy + inDy;
        nextTargetY = targetY.clamp(
          _currentOffset.dy - maxBacklog,
          _currentOffset.dy + maxBacklog,
        );
      }

      // Handle horizontal reversal & accumulation
      final double nextTargetX;
      if ((inDx > 0 && diffDx < -1.0) || (inDx < 0 && diffDx > 1.0)) {
        _currentOffset = Offset(0.0, _currentOffset.dy);
        nextTargetX = inDx;
      } else {
        const maxBacklog = 360.0;
        final targetX = _targetOffset.dx + inDx;
        nextTargetX = targetX.clamp(
          _currentOffset.dx - maxBacklog,
          _currentOffset.dx + maxBacklog,
        );
      }

      _targetOffset = Offset(nextTargetX, nextTargetY);
      _startTicker();
      return;
    }
  }

  void _startTicker() {
    _ticker ??= _createTicker(_onTick);
    if (!_ticker!.isTicking) {
      _lastElapsed = Duration.zero;
      _ticker!.start();
    }
  }

  void _stopTicker() {
    if (_ticker != null && _ticker!.isActive) {
      _ticker!.stop(canceled: true);
    }
    _lastElapsed = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    final double dt;
    if (_lastElapsed == Duration.zero) {
      dt = 0.016; // First frame default ~16ms
    } else {
      final diff = elapsed - _lastElapsed;
      dt = (diff.inMicroseconds / 1000000.0).clamp(0.001, 0.050);
    }
    _lastElapsed = elapsed;

    final stillAnimating = step(dt);
    if (!stillAnimating) {
      _stopTicker();
    }
  }

  bool step(double dt) {
    final diff = _targetOffset - _currentOffset;
    if (diff.distance < minDeltaThreshold) {
      if (diff.distance > 0) {
        _dispatchDelta(diff);
        _currentOffset = _targetOffset;
      }
      return false;
    }

    // Exponential smoothing with decay:
    // factor = 1 - e^(-decayRate * dt)
    final factor = (1.0 - math.exp(-decayRate * dt)).clamp(0.04, 1.0);
    final step = diff * factor;

    _currentOffset += step;
    _dispatchDelta(step);
    return true;
  }

  void _dispatchDelta(Offset delta) {
    _isSynthesizing = true;
    try {
      dispatchEvent(
        PointerScrollEvent(
          viewId: _lastViewId,
          timeStamp: Duration.zero,
          kind: PointerDeviceKind.mouse,
          device: _lastDevice,
          position: _lastPosition,
          scrollDelta: delta,
        ),
      );
    } finally {
      _isSynthesizing = false;
    }
  }

  void dispose() {
    _stopTicker();
    _ticker?.dispose();
    _ticker = null;
  }
}

/// Mixin on [GestureBinding] and [SchedulerBinding] that intercepts discrete
/// mouse wheel [PointerScrollEvent]s on desktop platforms and smoothly dispatches
/// them across frames using [SmoothMouseScrollHandler].
mixin SmoothMouseScrollBindingMixin on GestureBinding, SchedulerBinding {
  SmoothMouseScrollHandler? _smoothScrollHandler;

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  void initInstances() {
    super.initInstances();
    if (_isDesktopPlatform) {
      _smoothScrollHandler = SmoothMouseScrollHandler(
        dispatchEvent: handlePointerEvent,
      );
    }
  }

  @override
  void handlePointerEvent(PointerEvent event) {
    if (_isDesktopPlatform && _smoothScrollHandler != null) {
      if (_smoothScrollHandler!.isSynthesizing) {
        super.handlePointerEvent(event);
        return;
      }

      if (event is PointerScrollEvent && event.kind == PointerDeviceKind.mouse) {
        _smoothScrollHandler!.handlePointerEvent(event);
        return;
      }

      if (event is PointerHoverEvent || event is PointerMoveEvent) {
        _smoothScrollHandler!.handlePointerEvent(event);
      }
    }

    super.handlePointerEvent(event);
  }
}

/// Custom [WidgetsFlutterBinding] that enables smooth mouse wheel scrolling on desktop.
class CinevaWidgetsBinding extends WidgetsFlutterBinding
    with SmoothMouseScrollBindingMixin {
  CinevaWidgetsBinding._();

  static CinevaWidgetsBinding? _instance;

  /// Ensures [CinevaWidgetsBinding] is initialized.
  static WidgetsBinding ensureInitialized() {
    _instance ??= CinevaWidgetsBinding._();
    return _instance!;
  }
}
