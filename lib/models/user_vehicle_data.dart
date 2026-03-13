class UserVehicleData {
  final String vehicleId;
  bool isOwned;
  int quantity;
  List<String> assignedGarages;
  bool isWishlisted;

  UserVehicleData({
    required this.vehicleId,
    this.isOwned = false,
    this.quantity = 0,
    this.assignedGarages = const [],
    this.isWishlisted = false,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'isOwned': isOwned,
    'quantity': quantity,
    'assignedGarages': assignedGarages,
    'isWishlisted': isWishlisted
  };
}