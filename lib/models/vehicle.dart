import 'package:flutter/material.dart';

class Weaponry {
  final String? primary;
  final String? missileType;
  final String? mines;
  final String? special;

  Weaponry({this.primary, this.missileType, this.mines, this.special});

  factory Weaponry.fromJson(Map<String, dynamic> json) {
    return Weaponry(
      primary: json['primary'],
      missileType: json['missileType'],
      mines: json['mines'],
      special: json['special'],
    );
  }
}

class Vehicle {
  final String id;
  final String name;
  final Map<String, dynamic>? displayName;
  final String manufacturer;
  final String category;
  final String dlc;
  final int price;
  final String image;
  final bool isRemoved;
  final List<String>? obtaining;
  final List<String>? imaniTech;
  final List<String>? extras;
  final Weaponry? weaponry;
  int ownedCount;

  final bool isLargeVeh;
  final String? storageType;

  bool isOwned;
  bool isWishlisted;

  Vehicle({
    required this.id,
    required this.name,
    this.displayName,
    required this.manufacturer,
    required this.category,
    required this.dlc,
    required this.price,
    required this.image,
    required this.isRemoved,
    required this.obtaining,
    this.imaniTech,
    this.extras,
    this.weaponry,
    required this.isLargeVeh,
    this.storageType,        
    this.isOwned = false,
    this.isWishlisted = false,
    this.ownedCount = 0,
  });

  String get imagePath => image;

  String getLocalizedName(BuildContext context) {
    if (displayName == null || displayName!.isEmpty) return name;

    try {
      String locale = Localizations.localeOf(context).languageCode;
      return displayName![locale] ?? displayName!['en'] ?? name;
    } catch (e) {
      return name;
    }
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    bool largeDetection = false;

    if (json['isLargeVeh'] is int) {
      largeDetection = json['isLargeVeh'] == 1;
    } 
    else if (json['extras'] is List) {
      largeDetection = json['extras'].contains('isLargeVeh');
    }

    return Vehicle(
      id: json['id'],
      name: json['name'],
      displayName: json['displayName'],
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'] ?? '',
      dlc: json['dlc'] ?? '',
      price: json['price'] ?? 0,
      image: json['image'] ?? '',
      isRemoved: json['isRemoved'] ?? false,
      obtaining: json['obtaining'] != null
          ? List<String>.from(json['obtaining'])
          : [],
      imaniTech: json['imaniTech'] != null
          ? List<String>.from(json['imaniTech'])
          : null,
      extras: json['extras'] != null ? List<String>.from(json['extras']) : null,
      weaponry: json['weaponry'] != null
          ? Weaponry.fromJson(json['weaponry'])
          : null,
      isLargeVeh: largeDetection,
      storageType: json['storageType'],
      isOwned: json['isOwned'] == 1 || json['isOwned'] == true,
      isWishlisted: json['isWishlisted'] == 1 || json['isWishlisted'] == true,
      ownedCount: json['ownedCount'] ?? 0,
    );

    
  }

  
}