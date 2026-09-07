class AppNotification {
  final String key;
  final String title;
  final String text;
  final String? subText;
  final String package;
  final String appName;
  final DateTime postTime;
  final String? iconBase64;

  AppNotification({
    required this.key,
    required this.title,
    required this.text,
    this.subText,
    required this.package,
    required this.appName,
    required this.postTime,
    this.iconBase64,
  });

  factory AppNotification.fromMap(Map<dynamic, dynamic> map) {
    return AppNotification(
      key: map['key'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      subText: map['subText'] as String?,
      package: map['package'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      postTime: DateTime.fromMillisecondsSinceEpoch(
        (map['postTime'] as int? ?? 0),
      ),
      iconBase64: map['iconBase64'] as String?,
    );
  }
}

