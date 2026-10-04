import 'package:flutter/material.dart';

/// Government type affects laws, taxes, encounters.
enum GovernmentType {
  federalDemocracy,
  corporateCouncil,
  miningConsortium,
  agrarianRepublic,
  plutocraticCouncil,
  miningCorporation,
  researchDirectorate,
  frontierAnarchy,
  industrialCartel,
}

/// Law level affects police encounters and contraband penalties.
enum LawLevel {
  strict,    // Terra, Neptune
  moderate,  // Mars, Venus, Titan
  lenient,   // Saturn, Mercury
  lawless,   // Io
}

/// A planet in the game.
class Planet {
  final String id;
  final String name;
  final String description;
  final Color color;
  final Color accentColor;
  final Color? ringColor;
  final double size;
  final GovernmentType governmentType;
  final LawLevel lawLevel;
  final double taxRate;
  final List<String> specialties;
  final Map<String, int> basePrices;
  final int travelCost;
  final String bankName;
  final String governorName;
  final int shipyardTier;

  const Planet({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.accentColor,
    this.ringColor,
    required this.size,
    required this.governmentType,
    required this.lawLevel,
    required this.taxRate,
    required this.specialties,
    required this.basePrices,
    required this.travelCost,
    required this.bankName,
    required this.governorName,
    required this.shipyardTier,
  });

  factory Planet.fromJson(Map<String, dynamic> json) {
    return Planet(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      color: Color.fromARGB(
        255,
        json['color']['r'] as int,
        json['color']['g'] as int,
        json['color']['b'] as int,
      ),
      accentColor: Color.fromARGB(
        255,
        json['accentColor']['r'] as int,
        json['accentColor']['g'] as int,
        json['accentColor']['b'] as int,
      ),
      ringColor: json['ringColor'] != null
          ? Color.fromARGB(
              255,
              json['ringColor']['r'] as int,
              json['ringColor']['g'] as int,
              json['ringColor']['b'] as int,
            )
          : null,
      size: (json['size'] as num).toDouble(),
      governmentType: _govTypeFromString(json['governmentType'] as String),
      lawLevel: _lawLevelFromString(json['lawLevel'] as String),
      taxRate: (json['taxRate'] as num).toDouble(),
      specialties: List<String>.from(json['specialties'] as List),
      basePrices: Map<String, int>.from(
        (json['basePrices'] as Map).map(
          (k, v) => MapEntry(k as String, v as int),
        ),
      ),
      travelCost: json['travelCost'] as int,
      bankName: json['bankName'] as String,
      governorName: json['governorName'] as String,
      shipyardTier: json['shipyardTier'] as int,
    );
  }

  static GovernmentType _govTypeFromString(String s) {
    switch (s) {
      case 'federal_democracy': return GovernmentType.federalDemocracy;
      case 'corporate_council': return GovernmentType.corporateCouncil;
      case 'mining_consortium': return GovernmentType.miningConsortium;
      case 'agrarian_republic': return GovernmentType.agrarianRepublic;
      case 'plutocratic_council': return GovernmentType.plutocraticCouncil;
      case 'mining_corporation': return GovernmentType.miningCorporation;
      case 'research_directorate': return GovernmentType.researchDirectorate;
      case 'frontier_anarchy': return GovernmentType.frontierAnarchy;
      case 'industrial_cartel': return GovernmentType.industrialCartel;
      default: return GovernmentType.corporateCouncil;
    }
  }

  static LawLevel _lawLevelFromString(String s) {
    switch (s) {
      case 'strict': return LawLevel.strict;
      case 'moderate': return LawLevel.moderate;
      case 'lenient': return LawLevel.lenient;
      case 'lawless': return LawLevel.lawless;
      default: return LawLevel.moderate;
    }
  }

  /// Is this planet a good producer of a given commodity?
  bool produces(String commodityId) => specialties.contains(commodityId);
}
