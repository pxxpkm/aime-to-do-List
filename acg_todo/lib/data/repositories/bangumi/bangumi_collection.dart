class BangumiCollection {
  final int subjectId;
  final String name;
  final String? nameCn;
  final String? posterUrl;
  final int? eps;
  final int type;
  final int status;
  final int? score;
  final int? lastTouch;

  BangumiCollection({
    required this.subjectId,
    required this.name,
    this.nameCn,
    this.posterUrl,
    this.eps,
    required this.type,
    required this.status,
    this.score,
    this.lastTouch,
  });

  factory BangumiCollection.fromSubjectJson(Map<String, dynamic> json, int status) {
    final images = json['images'] as Map<String, dynamic>?;
    return BangumiCollection(
      subjectId: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      nameCn: json['name_cn'] as String?,
      posterUrl: images?['large'] as String? ?? images?['common'] as String?,
      eps: json['eps'] as int? ?? json['eps_count'] as int?,
      type: json['type'] as int? ?? 2,
      status: status,
      score: _parseScore(json['rating'] as Map<String, dynamic>?),
      lastTouch: json['lasttouch'] as int?,
    );
  }

  String get displayName => (nameCn != null && nameCn!.isNotEmpty) ? nameCn! : name;

  static int? _parseScore(Map<String, dynamic>? rating) {
    if (rating == null) return null;
    final score = rating['score'];
    if (score is int) return score;
    if (score is double) return score.toInt();
    return null;
  }
}
