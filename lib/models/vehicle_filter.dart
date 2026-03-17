import 'package:flutter/material.dart';

class VehicleFilter {
  String selectedSort;
  String sortOrder;
  String obtainedFilter;
  RangeValues priceRange;
  String selectedCategory;
  bool imaniTech;
  bool hasWeapons;
  bool isRemoved;
  bool hasHSW;
  bool hasDrift;
  bool isWishlisted;

  VehicleFilter({
    this.selectedSort = "Name",
    this.sortOrder = "Ascending",
    this.obtainedFilter = "All",
    this.priceRange = const RangeValues(0, 10000000),
    this.selectedCategory = "All",
    this.imaniTech = false,
    this.hasWeapons = false,
    this.isRemoved = false,
    this.hasHSW = false,
    this.hasDrift = false,
    this.isWishlisted = false,
  });
}