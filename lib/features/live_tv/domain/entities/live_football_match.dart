import 'live_tv_channel.dart';

/// Represents an in-progress (live) football match verified against
/// the real-time EPG schedule of its broadcasting [LiveTvChannel]s in Cineva.
class LiveFootballMatch {
  final String id;
  final String competitionName;
  final String homeTeamName;
  final String? homeTeamLogo;
  final String homeScore;
  final String awayTeamName;
  final String? awayTeamLogo;
  final String awayScore;
  final String statusDetail;
  final bool isLive;
  final LiveTvChannel primaryChannel;
  final List<LiveTvChannel> alternateChannels;

  /// Maps a [LiveTvChannel.id] to its real-time EPG programme label and
  /// broadcast time slot (e.g. `'UEL 2026/27: OLY Vs MIL (L) • 00:40–02:55 WIB'`).
  final Map<String, String> channelProgramInfo;

  const LiveFootballMatch({
    required this.id,
    required this.competitionName,
    required this.homeTeamName,
    this.homeTeamLogo,
    required this.homeScore,
    required this.awayTeamName,
    this.awayTeamLogo,
    required this.awayScore,
    required this.statusDetail,
    required this.isLive,
    required this.primaryChannel,
    this.alternateChannels = const [],
    this.channelProgramInfo = const {},
  });

  /// All available channels (primary + unique alternates) currently broadcasting this match.
  List<LiveTvChannel> get allChannels {
    final result = <LiveTvChannel>[primaryChannel];
    for (final ch in alternateChannels) {
      if (result.every((existing) => existing.id != ch.id)) {
        result.add(ch);
      }
    }
    return result;
  }

  /// Returns the real-time EPG programme title & time window for [channelId], if available.
  String? programInfoForChannel(String channelId) {
    final info = channelProgramInfo[channelId];
    if (info == null || info.trim().isEmpty) return null;
    return info.trim();
  }

  /// Concise comma/bullet-separated summary of all channels airing this match.
  String get broadcastingChannelNames =>
      allChannels.map((c) => c.name).join(' • ');
}
