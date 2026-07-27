class Patient {
  final String id;
  final String name;
  final int age;
  final String bedNumber;
  final String status; // Stable, Critical, Recovering
  final double weight;
  double? systolicBP;
  double? diastolicBP;
  int? heartRate;
  
  // Clinical Labs/Values for Scoring
  double? bilirubin; // mg/dL
  double? platelets; // x10^3/uL
  double? creatinine; // mg/dL
  double? gcs; // Glasgow Coma Scale
  double? fiO2; // Fraction of Inspired Oxygen
  double? paO2; // Partial Pressure of Oxygen

  List<String> history;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.bedNumber,
    required this.status,
    required this.weight,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.bilirubin,
    this.platelets,
    this.creatinine,
    this.gcs = 15,
    this.fiO2 = 0.21,
    this.paO2,
    List<String>? history,
  }) : history = history ?? [];

  double? get map => (systolicBP != null && diastolicBP != null) 
    ? (systolicBP! + 2 * diastolicBP!) / 3 
    : null;

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      bedNumber: json['bedNumber']?.toString() ?? 'N/A',
      status: json['status']?.toString() ?? 'Stable',
      weight: double.tryParse(json['weight']?.toString() ?? '0.0') ?? 0.0,
      systolicBP: double.tryParse(json['systolicBP']?.toString() ?? ''),
      diastolicBP: double.tryParse(json['diastolicBP']?.toString() ?? ''),
      heartRate: int.tryParse(json['heartRate']?.toString() ?? ''),
      bilirubin: double.tryParse(json['bilirubin']?.toString() ?? ''),
      platelets: double.tryParse(json['platelets']?.toString() ?? ''),
      creatinine: double.tryParse(json['creatinine']?.toString() ?? ''),
      gcs: double.tryParse(json['gcs']?.toString() ?? '15') ?? 15,
      fiO2: double.tryParse(json['fiO2']?.toString() ?? '0.21') ?? 0.21,
      paO2: double.tryParse(json['paO2']?.toString() ?? ''),
      history: json['history'] is List 
          ? List<String>.from(json['history']) 
          : (json['history'] is String ? [json['history']] : []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bedNumber': bedNumber,
      'status': status,
      'weight': weight,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'bilirubin': bilirubin,
      'platelets': platelets,
      'creatinine': creatinine,
      'gcs': gcs,
      'fiO2': fiO2,
      'paO2': paO2,
      'history': history,
    };
  }
}
