class Property {
  final String id;
  final String type;
  final String building;
  final String name;
  int capacity;
  final int price;
  final String location;
  final double lat;
  final double lng;
  bool isOwned;

  Property({
    required this.id,
    required this.type,
    required this.building,
    required this.name,
    required this.capacity,
    required this.price,
    required this.location,
    required this.lat,
    required this.lng,
    this.isOwned = false,
  });

  static const Map<String, String> sharedBuildImages = {
    'apt_17001': 'eclipse_towers',
    'apt_17002': 'eclipse_towers',
    'apt_17003': 'eclipse_towers',
    'apt_17004': 'eclipse_towers',
    'apt_17005': 'eclipse_towers',
    'apt_17006': 'eclipse_towers',
    'apt_17007': 'eclipse_towers',
    'apt_17008': 'eclipse_towers',
    'apt_22301': 'alta_street',
    'apt_22302': 'alta_street',
    'apt_17201': 'integrity_way',
    'apt_17202': 'integrity_way',
    'apt_17203': 'integrity_way',
    'apt_22501': 'weazel_plaza',
    'apt_22502': 'weazel_plaza',
    'apt_22503': 'weazel_plaza',
    'apt_17401': 'tinsel_towers',
    'apt_17402': 'tinsel_towers',
    'apt_17403': 'tinsel_towers',
    'apt_17101': 'delperro_heights',
    'apt_17102': 'delperro_heights',
    'apt_17103': 'delperro_heights',
    'apt_17301': 'richards_majestic',
    'apt_17302': 'richards_majestic',
    'apt_17303': 'richards_majestic',
  };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      building: json['building'] ?? 'Desconocido',
      name: json['name'] ?? 'Desconocido',
      capacity: json['capacity'] ?? 0,
      price: json['price'] ?? 0,
      location: json['location'] ?? 'Desconocida',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      isOwned: json['isOwned'] == 1 || json['isOwned'] == true,
    );
  }

  String get imagePath {
    String folder = '';

    switch (type) {
      case 'Agencies':
        folder = 'agencies';
        break;
      case 'Apartments':
        folder = 'apartments';
        break;
      case 'Arena Workshop':
        folder = 'arena';
        break;
      case 'Auto Shops':
        folder = 'taller';
        break;
      case 'Bail Enforcement':
        folder = 'bottomdollar';
        break;
      case 'Bunkers':
        folder = 'bunkers';
        break;
      case 'Casino Penthouse':
        folder = 'penthouse';
        break;
      case 'Executive Offices':
        folder = 'offices';
        break;
      case 'Facilities':
        folder = 'facilities';
        break;
      case 'GTA + Exclusive':
        folder = 'gta+';
        break;
      case 'Garages':
        folder = 'garages';
        break;
      case 'Garment Factory':
        folder = 'garment';
        break;
      case 'Hangars':
        folder = 'hangars';
        break;
      case 'MC Clubhouses':
        folder = 'mc/headquarters';
        break;
      case 'MC Businesses':
        if (name.contains('Cocaine')) {
          folder = 'mc/business/coca';
        } else if (name.contains('Meth')) {
          folder = 'mc/business/meta';
        } else if (name.contains('Weed')) {
          folder = 'mc/business/mari';
        } else if (name.contains('Document')) {
          folder = 'mc/business/docs';
        } else if (name.contains('Counterfeit')) {
          folder = 'mc/business/money';
        } else {
          folder = 'mc/business';
        }
        break;
      case 'Mansions':
        folder = 'mansions';
        break;
      case 'Money Fronts':
        folder = 'moneyfronts';
      case 'Salvage Yards':
        folder = 'salvageyards';
        break;
      case 'Nightclubs':
        folder = 'nightclubs';
        break;
      case 'Retro Arcades':
        folder = 'arcades';
        break;
      case 'Special Cargo Warehouses':
        folder = 'warehouses/cargo';
        break;
      case 'Story Mode Properties':
        folder = 'storymode';
        break;
      case 'Vehicle Warehouses':
        folder = 'warehouses/vehicle';
        break;
      case 'Yachts':
        folder = 'yachts';
        break;
      case 'Eclipse Blvd Garage':
        folder = 'eclipseblvd';
        break;
      case 'Large Vehicle Properties':
        String vehicleFileName = '';

        if (id == 'lvp_4001') {
          vehicleFileName = 'kosatka';
        } else if (id == 'lvp_4101') {
          vehicleFileName = 'avenger';
        } else if (id == 'lvp_4201') {
          vehicleFileName = 'terbyte';
        } else if (id == 'lvp_4301') {
          vehicleFileName = 'trailerlarge';
        } else if (id == 'lvp_3001') {
          vehicleFileName = 'brickade2';
        }
        return 'assets/vehicles/warstock/$vehicleFileName.jpg';
      default:
        folder = 'props';
    }

    String fileName = sharedBuildImages[id.trim()] ?? id;

    return 'assets/props/$folder/$fileName.jpg';
  }
}
