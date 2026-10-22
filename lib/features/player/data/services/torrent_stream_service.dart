import 'dart:async';

/// Status of the video stream session.
class TorrentStreamState {
  final String status; // 'initializing', 'buffering', 'ready', 'streaming', 'error', 'stopped'
  final double progress; // 0.0 to 100.0
  final int downloadSpeedBytes; // bytes/sec
  final int peers;
  final int seeds;
  final String? streamUrl;
  final String? errorMessage;

  const TorrentStreamState({
    required this.status,
    this.progress = 0.0,
    this.downloadSpeedBytes = 0,
    this.peers = 0,
    this.seeds = 0,
    this.streamUrl,
    this.errorMessage,
  });

  String get speedFormatted {
    if (downloadSpeedBytes > 1048576) {
      return '${(downloadSpeedBytes / 1048576).toStringAsFixed(2)} MB/s';
    } else if (downloadSpeedBytes > 1024) {
      return '${(downloadSpeedBytes / 1024).toStringAsFixed(0)} KB/s';
    }
    return '$downloadSpeedBytes B/s';
  }
}

/// Service managing video stream state safely without native Go crashes.
class TorrentStreamService {
  final _stateController = StreamController<TorrentStreamState>.broadcast();
  Stream<TorrentStreamState> get stateStream => _stateController.stream;

  TorrentStreamState _currentState = const TorrentStreamState(status: 'idle');
  TorrentStreamState get currentState => _currentState;

  /// Starts streaming session safely.
  Future<String?> startStream(String magnetOrStreamUrl) async {
    _updateState(TorrentStreamState(
      status: 'ready',
      streamUrl: magnetOrStreamUrl,
    ));
    return magnetOrStreamUrl;
  }

  void _updateState(TorrentStreamState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Stops current streaming session.
  Future<void> stopCurrentStream() async {
    _updateState(const TorrentStreamState(status: 'stopped'));
  }

  void dispose() {
    _stateController.close();
  }
}
