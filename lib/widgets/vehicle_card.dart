import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../screens/vehicle_detail_screen.dart';

final Map<String, String> categoryNames = {
  'Boat': 'Botes',
  'Commercial': 'Comerciales',
  'Compact': 'Compactos',
  'Coupe': 'Coupes',
  'Cycle': 'Bicicletas',
  'Emergency': 'Emergencias',
  'Helicopter': 'Helicópteros',
  'Industrial': 'Industriales',
  'Military': 'Militares',
  'Motorcycle': 'Motocicletas',
  'Muscle': 'Muscle',
  'Off_road': 'Todoterreno',
  'Open_wheel': 'Ruedas Descubiertas',
  'Plane': 'Aviones',
  'Sedan': 'Sedanes',
  'Service': 'Servicio',
  'Sport': 'Deportivos',
  'Sport_classic': 'Deportivos Clásicos',
  'Super': 'Súper',
  'Suv': 'SUV',
  'Utility': 'Utilitarios',
  'Van': 'Furgonetas',
  'unknown': 'Desconocido',
};

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onToggleOwned;
  final VoidCallback onToggleWishlist;
  final VoidCallback onRefresh;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onToggleOwned,
    required this.onToggleWishlist,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
      child: Material(
        color: const Color(0xFF0A0A0A),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailScreen(vehicle: vehicle),
              ),
            );
            onRefresh();
          },
          splashColor: Colors.white10,
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: 140,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      Image.asset(
                        vehicle.imagePath,
                        width: 180,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 180,
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.directions_car,
                                color: Colors.white24,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                      if (vehicle.ownedCount > 1)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 43, 155, 23),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              "X${vehicle.ownedCount}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontFamily: 'Chalet',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.manufacturer.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Pricedown",
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          vehicle.getLocalizedName(context),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: "Pricedown",
                            height: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        (categoryNames[vehicle.category] ?? vehicle.category)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          fontFamily: 'HouseScript',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          vehicle.isOwned
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: vehicle.isOwned
                              ? Colors.white
                              : Colors.white24,
                          size: 32,
                        ),
                        onPressed: onToggleOwned,
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          vehicle.isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: vehicle.isWishlisted
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : Colors.white24,
                          size: 30,
                        ),
                        onPressed:
                            onToggleWishlist,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
