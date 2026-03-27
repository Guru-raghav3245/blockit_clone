class FreedomSession {
  final String id;
  final int durationMinutes;
  final DateTime startTime;
  final bool usedParachute;

  FreedomSession({
    required this.id,
    required this.durationMinutes,
    required this.startTime,
    this.usedParachute = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'durationMinutes': durationMinutes,
        'startTime': startTime.toIso8601String(),
        'usedParachute': usedParachute,
      };

  factory FreedomSession.fromJson(Map<String, dynamic> json) => FreedomSession(
        id: json['id'],
        durationMinutes: json['durationMinutes'],
        startTime: DateTime.parse(json['startTime']),
        usedParachute: json['usedParachute'] ?? false,
      );
}