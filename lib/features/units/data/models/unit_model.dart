class UnitModel {
  final int? id;
  final String name;

  UnitModel({this.id, required this.name});

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(id: map['id'], name: map['name']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
