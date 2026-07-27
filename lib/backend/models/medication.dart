class Medication {
  final String id;
  final String name;
  final String category;
  final double standardDosePerKg;
  final double minDosePerKg;
  final double maxDosePerKg;
  final String unit;
  final List<String> interactions; 
  final String warning;

  Medication({
    required this.id,
    required this.name,
    required this.category,
    required this.standardDosePerKg,
    required this.minDosePerKg,
    required this.maxDosePerKg,
    required this.unit,
    this.interactions = const [],
    this.warning = "Monitor vitals during administration.",
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      standardDosePerKg: json['standardDosePerKg'].toDouble(),
      minDosePerKg: json['minDosePerKg'].toDouble(),
      maxDosePerKg: json['maxDosePerKg'].toDouble(),
      unit: json['unit'],
      interactions: List<String>.from(json['interactions'] ?? []),
      warning: json['warning'] ?? "Monitor vitals during administration.",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'standardDosePerKg': standardDosePerKg,
      'minDosePerKg': minDosePerKg,
      'maxDosePerKg': maxDosePerKg,
      'unit': unit,
      'interactions': interactions,
      'warning': warning,
    };
  }
}
