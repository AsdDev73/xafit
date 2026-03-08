class BodyProfile {
  final String alias;
  final double? heightCm;
  final String goal;
  final double? targetWeight;
  final int? age;

  const BodyProfile({
    required this.alias,
    this.heightCm,
    required this.goal,
    this.targetWeight,
    this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'alias': alias,
      'heightCm': heightCm,
      'goal': goal,
      'targetWeight': targetWeight,
      'age': age,
    };
  }

  factory BodyProfile.fromMap(Map<String, dynamic> map) {
    return BodyProfile(
      alias: map['alias'] ?? 'Usuario',
      heightCm: map['heightCm'] != null
          ? (map['heightCm'] as num).toDouble()
          : null,
      goal: map['goal'] ?? 'Mantenimiento',
      targetWeight: map['targetWeight'] != null
          ? (map['targetWeight'] as num).toDouble()
          : null,
      age: map['age'],
    );
  }

  BodyProfile copyWith({
    String? alias,
    double? heightCm,
    String? goal,
    double? targetWeight,
    int? age,
  }) {
    return BodyProfile(
      alias: alias ?? this.alias,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      age: age ?? this.age,
    );
  }

  static const BodyProfile empty = BodyProfile(
    alias: 'Usuario',
    goal: 'Mantenimiento',
  );
}
