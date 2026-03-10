class Exercise {
  final String id;
  final String name;
  final String? force;
  final String level;
  final String? mechanic;
  final String? equipment;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String category;
  final List<String>? images;

  Exercise({
    required this.id,
    required this.name,
    this.force,
    required this.level,
    this.mechanic,
    this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.category,
    this.images,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? json['name'] ?? '',
      name: json['name'] ?? '',
      force: json['force'],
      level: json['level'] ?? 'beginner',
      mechanic: json['mechanic'],
      equipment: json['equipment'],
      primaryMuscles: json['primaryMuscles'] != null 
          ? List<String>.from(json['primaryMuscles']) 
          : [],
      secondaryMuscles: json['secondaryMuscles'] != null 
          ? List<String>.from(json['secondaryMuscles']) 
          : [],
      instructions: json['instructions'] != null 
          ? List<String>.from(json['instructions']) 
          : [],
      category: json['category'] ?? '',
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'force': force,
      'level': level,
      'mechanic': mechanic,
      'equipment': equipment,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
      'category': category,
      'images': images,
    };
  }

  ///  points per workout — all exercises earn the same
  int getBasePoints() {
    return 20;
  }

  /// Get a display-friendly primary muscles string
  String getPrimaryMusclesDisplay() {
    if (primaryMuscles.isEmpty) return 'Full Body';
    return primaryMuscles.map((m) => _capitalize(m)).join(', ');
  }

  /// Get a display-friendly equipment string
  String getEquipmentDisplay() {
    if (equipment == null || equipment!.isEmpty) return 'Body Weight';
    return _capitalize(equipment!);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
