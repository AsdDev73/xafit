class BodyProgressEntry {
  final String id;
  final DateTime date;
  final double weight;
  final double? waist;
  final double? chest;
  final double? arm;
  final double? thigh;
  final double? bodyFat;

  const BodyProgressEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.waist,
    this.chest,
    this.arm,
    this.thigh,
    this.bodyFat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'waist': waist,
      'chest': chest,
      'arm': arm,
      'thigh': thigh,
      'bodyFat': bodyFat,
    };
  }

  factory BodyProgressEntry.fromMap(Map<String, dynamic> map) {
    return BodyProgressEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      weight: (map['weight'] as num).toDouble(),
      waist: map['waist'] != null ? (map['waist'] as num).toDouble() : null,
      chest: map['chest'] != null ? (map['chest'] as num).toDouble() : null,
      arm: map['arm'] != null ? (map['arm'] as num).toDouble() : null,
      thigh: map['thigh'] != null ? (map['thigh'] as num).toDouble() : null,
      bodyFat: map['bodyFat'] != null
          ? (map['bodyFat'] as num).toDouble()
          : null,
    );
  }
}
