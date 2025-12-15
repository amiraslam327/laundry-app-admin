import 'package:equatable/equatable.dart';

class LaundryModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String phone;
  final String workingHours;
  final double lat;
  final double lng;
  final String address;

  const LaundryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.phone,
    required this.workingHours,
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory LaundryModel.fromMap(Map<String, dynamic> map) {
    return LaundryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      workingHours: map['workingHours'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'phone': phone,
      'workingHours': workingHours,
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        phone,
        workingHours,
        lat,
        lng,
        address,
      ];
}

