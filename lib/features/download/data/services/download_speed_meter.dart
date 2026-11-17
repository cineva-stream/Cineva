/// Measures real network throughput of a download using a sliding time window.
///
/// Bytes must be reported as they arrive on the wire (e.g. from Dio's
/// `onReceiveProgress`), NOT when a whole segment finishes or when a previously
/// downloaded file is re-used from disk. Reporting at segment completion made the
/// indicator spike far above the real link speed because 12 parallel workers tend to
/// finish in bursts, and re-used segments were counted as if they had just been
/// downloaded in a single instant.
class DownloadSpeedMeter {
  /// Length of the sliding window used to average the speed.
  final Duration window;

  final int Function() _nowMs;

  final List<_Sample> _samples = <_Sample>[];
  int _total = 0;
  bool _started = false;

  DownloadSpeedMeter({
    this.window = const Duration(seconds: 4),
    int Function()? nowMs,
  }) : _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Total bytes reported so far.
  int get totalBytes => _total;

  /// Registers [bytes] newly received from the network.
  void add(int bytes) {
    if (bytes <= 0) return;
    final now = _nowMs();
    if (!_started) {
      _started = true;
      _samples.add(_Sample(now, 0));
    }
    _total += bytes;
    _samples.add(_Sample(now, _total));
    _trim(now);
  }

  void _trim(int now) {
    final cutoff = now - window.inMilliseconds;
    // Keep one sample at or before the cutoff as the window baseline.
    while (_samples.length > 1 && _samples[1].timeMs <= cutoff) {
      _samples.removeAt(0);
    }
  }

  /// Average bytes per second over the sliding window (0 when idle).
  double get bytesPerSecond {
    if (!_started || _samples.isEmpty) return 0;
    final now = _nowMs();
    _trim(now);
    final first = _samples.first;
    var elapsedMs = now - first.timeMs;
    // Avoid exaggerating the very first burst: assume at least half a second.
    if (elapsedMs < 500) elapsedMs = 500;
    final windowMs = window.inMilliseconds;
    if (elapsedMs > windowMs) elapsedMs = windowMs;
    final bytes = _total - first.total;
    if (bytes <= 0) return 0;
    return bytes * 1000.0 / elapsedMs;
  }

  /// Human readable speed such as `2.4 MB/s (19.2 Mbps)` or `850 KB/s (6.8 Mbps)`.
  String get formatted => format(bytesPerSecond);

  /// Formats [bytesPerSecond] as `<MB/s | KB/s> (<Mbps>)`.
  static String format(double bytesPerSecond) {
    final bps = bytesPerSecond.isFinite && bytesPerSecond > 0
        ? bytesPerSecond
        : 0.0;
    final mbps = (bps * 8) / 1000000.0;
    if (bps >= 1048576) {
      return '${(bps / 1048576).toStringAsFixed(1)} MB/s (${mbps.toStringAsFixed(1)} Mbps)';
    }
    return '${(bps / 1024).toStringAsFixed(0)} KB/s (${mbps.toStringAsFixed(1)} Mbps)';
  }
}

class _Sample {
  final int timeMs;
  final int total;
  const _Sample(this.timeMs, this.total);
}
