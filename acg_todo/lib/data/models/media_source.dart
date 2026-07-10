enum MediaSource { anilist, bangumi }

extension MediaSourceLabel on MediaSource {
  String get label => switch (this) {
    MediaSource.anilist => 'AniList',
    MediaSource.bangumi => 'Bangumi',
  };
}
