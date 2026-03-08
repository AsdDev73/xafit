class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final List<String> tags;
  final bool isCustom;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.tags,
    this.isCustom = false,
  });
}
