import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final String id;
  final String laundryId;
  final String name;
  final String description;
  final String priceType; // 'per_kg' or 'per_piece'
  final double pricePerKg;
  final double pricePerPiece;
  final int estimatedHours; // duration in hours
  final String? icon; // optional icon path

  const ServiceModel({
    required this.id,
    required this.laundryId,
    required this.name,
    required this.description,
    required this.priceType,
    this.pricePerKg = 0.0,
    this.pricePerPiece = 0.0,
    required this.estimatedHours,
    this.icon,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      laundryId: map['laundryId'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      priceType: map['priceType'] as String? ?? 'per_kg',
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      pricePerPiece: (map['pricePerPiece'] as num?)?.toDouble() ?? 0.0,
      estimatedHours: map['estimatedHours'] as int? ?? 0,
      icon: map['icon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'laundryId': laundryId,
      'name': name,
      'description': description,
      'priceType': priceType,
      'pricePerKg': pricePerKg,
      'pricePerPiece': pricePerPiece,
      'estimatedHours': estimatedHours,
      'icon': icon,
    };
  }

  @override
  List<Object?> get props => [
        id,
        laundryId,
        name,
        description,
        priceType,
        pricePerKg,
        pricePerPiece,
        estimatedHours,
        icon,
      ];
}

