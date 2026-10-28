/// Entity representing a live TV broadcast channel.
class LiveTvChannel {
  final String id;
  final String name;
  final String category;
  final String streamUrl;
  final String? logoUrl;
  final String quality;
  final String country;
  final String? description;

  const LiveTvChannel({
    required this.id,
    required this.name,
    required this.category,
    required this.streamUrl,
    this.logoUrl,
    this.quality = 'HD',
    this.country = 'Global',
    this.description,
  });

  LiveTvChannel copyWith({
    String? id,
    String? name,
    String? category,
    String? streamUrl,
    String? logoUrl,
    String? quality,
    String? country,
    String? description,
  }) {
    return LiveTvChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      quality: quality ?? this.quality,
      country: country ?? this.country,
      description: description ?? this.description,
    );
  }
}
