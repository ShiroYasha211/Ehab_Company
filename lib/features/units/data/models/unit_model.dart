class UnitModel {
  final int? id;
  final String name;
  final int? childUnitId; // الوحدة الأصغر مباشرة
  final double conversionFactor; // كم وحدة صغرى داخل هذه الوحدة

  UnitModel({
    this.id,
    required this.name,
    this.childUnitId,
    this.conversionFactor = 1.0,
  });

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: map['id'],
      name: map['name'],
      childUnitId: map['childUnitId'],
      conversionFactor: (map['conversionFactor'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'childUnitId': childUnitId,
      'conversionFactor': conversionFactor,
    };
  }
}
