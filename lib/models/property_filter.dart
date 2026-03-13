import 'package:flutter/material.dart';

class PropertyFilter {
  final String selectedSort;
  final String sortOrder;  
  final String obtainedFilter;
  final RangeValues priceRange;
  final String selectedCategory;

  PropertyFilter({
    this.selectedSort = "Category",
    this.sortOrder = "Ascending",
    this.obtainedFilter = "All",
    this.priceRange = const RangeValues(0, 15000000),
    this.selectedCategory = "All",
  });
}