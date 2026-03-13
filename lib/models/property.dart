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
}