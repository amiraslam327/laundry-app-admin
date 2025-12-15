import 'package:equatable/equatable.dart';

class ServiceItem extends Equatable {
  final String id;
  final String name;
  final double price; // SAR per piece
  final int min;
  final int max;
  final String? categoryId; // Optional category ID

  const ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.min,
    required this.max,
    this.categoryId,
  });

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      min: map['min'] as int,
      max: map['max'] as int,
      categoryId: map['categoryId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'min': min,
      'max': max,
      if (categoryId != null) 'categoryId': categoryId,
    };
  }

  @override
  List<Object?> get props => [id, name, price, min, max, categoryId];
}

