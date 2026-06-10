class ReelsFreeTimeRecord {
  final String id;
  final int durationMinutes;
  final DateTime timestamp;

  ReelsFreeTimeRecord({
    required this.id,
    required this.durationMinutes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'durationMinutes': durationMinutes,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ReelsFreeTimeRecord.fromJson(Map<String, dynamic> json) => ReelsFreeTimeRecord(
        id: json['id'],
        durationMinutes: json['durationMinutes'] ?? 0,
        timestamp: DateTime.parse(json['timestamp']),
      );
}