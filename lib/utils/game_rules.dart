class GameRules {
  static const Map<String, int> propertyLimits = {
    'Agencies': 1,
    'Arena Workshop': 1,
    'Auto Shops': 1,
    'Bail Enforcement': 1,
    'Bunkers': 1,
    'Casino Penthouse': 1,
    'Executive Offices': 1,
    'Facilities': 1,
    'Nightclubs': 1,
    'Retro Arcades': 1,
    'Salvage Yards': 1,
    'Vehicle Warehouses': 1,
    'Yachts': 1,
    'MC Clubhouses': 1,
    'Garment Factory': 1,
    'Hangars': 1,
    'Story Mode Properties': 1,
    'GTA + Exclusive': 1,
    'Eclipse Blvd Garage': 1,
    'Mansions': 3, 
    'Apartments & Garages': 6, 
    'Special Cargo Warehouses': 5,
    'MC Businesses': 5,
    'Large Vehicle Properties': 5,
    'Money Fronts': 3, 
    
  };

  static int get maxTrackableProperties {
    return propertyLimits.values.reduce((sum, limit) => sum + limit);
  }

  static bool hasReachedLimit(String propertyType, int currentOwned) {
    final limit = propertyLimits[propertyType] ?? 0;
    return currentOwned >= limit;
  }

  static String getMCBusinessSubtype(String name) {
    final lowerName = name.toLowerCase();
    
    if (lowerName.contains("weed")) return "Weed";
    if (lowerName.contains("cocaine")) return "Cocaine";
    if (lowerName.contains("methamphetamine")) return "Meth";
    if (lowerName.contains("counterfeit") || lowerName.contains("cash")) return "Cash";
    if (lowerName.contains("document") || lowerName.contains("forgery")) return "Document";
    
    return "Unknown";
  }

  static const List<String> nonTradableTypes = [
    'Large Vehicle Properties', 
    'Yachts',                  
    'Story Mode Properties',   
    'Eclipse Blvd Garage',
  ];
}