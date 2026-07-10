class BangumiUserInfo {
  final int id;
  final String username;
  final String nickname;
  final String? avatarUrl;

  BangumiUserInfo({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatarUrl,
  });

  factory BangumiUserInfo.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'] as Map<String, dynamic>?;
    return BangumiUserInfo(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: avatar?['large'] as String? ?? avatar?['medium'] as String?,
    );
  }
}
