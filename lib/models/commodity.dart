import 'package:flutter/material.dart';

/// A tradeable commodity.
class Commodity {
  final String id;
  final String name;
  final String icon; // icon identifier for custom painter
  final int basePrice;
  final String category; // essential, industrial, tech, luxury, illegal
  final String description;
  final double volatility;
  final bool illegal;

  const Commodity({
    required this.id,
    required this.name,
    required this.icon,
    required this.basePrice,
    required this.category,
    required this.description,
    required this.volatility,
    this.illegal = false,
  });

  factory Commodity.fromJson(Map<String, dynamic> json) {
    return Commodity(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      basePrice: json['basePrice'] as int,
      category: json['category'] as String,
      description: json['description'] as String,
      volatility: (json['volatility'] as num).toDouble(),
      illegal: json['illegal'] as bool? ?? false,
    );
  }
}
