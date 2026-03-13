// lib/widgets/property_card.dart
import 'package:flutter/material.dart';
import '../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final bool isOwned;
  final VoidCallback onTap;
  final VoidCallback onToggleObtained;
  final VoidCallback onLocateMap;
  final Map<String, String> propertyTranslations = {
    'All': 'Todas',
    'Agencies': 'Agencias',
    'Apartments': 'Apartamentos y Garajes',
    'Arena Workshop': 'Taller de la Arena',
    'Auto Shops': 'Talleres',
    'Bail Enforcement': 'Oficina de Fianzas',
    'Bunkers': 'Búnkeres',
    'Casino Penthouse': 'Penthouse del Casino',
    'Executive Offices': 'Oficinas',
    'Facilities': 'Instalaciones',
    'GTA + Exclusive': 'Exclusivo de GTA +',
    'Garages': 'Garajes',
    'Garment Factory': 'Fábrica Textil',
    'Hangars': 'Hangares',
    'Large Vehicle Properties': 'Vehículos de gran Tamaño',
    'MC Clubhouses': 'Sedes del Club de Moteros',
    'MC Businesses': 'Negocios del Club de Moteros',
    'Mansions': 'Mansiones',
    'Money Fronts': 'Empresas Tapaderas',
    'Nightclubs': 'Clubes nocturnos',
    'Retro Arcades': 'Negocios de Maquinitas',
    'Salvage Yards': 'Deshuesaderos',
    'Special Cargo Warehouses': 'Almacenes de Mercancía Especial',
    'Vehicle Warehouses': 'Almacenes de Vehículos',
    'Yachts': 'Yates',
    'Eclipse Blvd Garage': 'Garaje de Eclipse Blvd ',
  };
  

  PropertyCard({
    super.key,
    required this.property,
    required this.isOwned,
    required this.onTap,
    required this.onToggleObtained,
    required this.onLocateMap,
  });

  

  @override
  Widget build(BuildContext context) {
    final borderColor = isOwned ? Colors.white30 : Colors.white10; 
    final bgColor = isOwned ? const Color(0xFF151515) : const Color(0xFF0A0A0A); 
    final gtaGreen = const Color(0xFF39FF14); 

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          height: 165,
          margin: const EdgeInsets.only(bottom: 12),
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.zero, 
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.black,
                  child: Image.asset(
                    'assets/images/properties/${property.id}.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.business,
                          size: 40,
                          color: Colors.white12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (propertyTranslations[property.type] ?? property.type).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Chalet'
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Pricedown',
                          height: 1.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.garage_outlined, color: Colors.white38, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            property.capacity > 0 ? '${property.capacity} PLAZAS' : 'SIN GARAJE',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Chalet'
                            ),
                          ),
                          const Spacer(),
                          // Precio
                          Text(
                            '\$${property.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Chalet'
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onToggleObtained,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOwned ? gtaGreen.withOpacity(0.1) : Colors.transparent,
                                foregroundColor: isOwned ? gtaGreen : Colors.white,
                                side: BorderSide(
                                  color: isOwned ? gtaGreen.withOpacity(0.5) : Colors.white24, 
                                  width: 1
                                ),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                elevation: 0,
                                fixedSize: const Size.fromHeight(36),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isOwned ? Icons.check : Icons.add_shopping_cart, 
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOwned ? 'ADQUIRIDO' : 'COMPRAR',
                                    style: const TextStyle(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.bold, 
                                      fontFamily: 'Chalet'
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // MAP BUTTON (NOT YET)
                          /*Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24, width: 1),
                              color: Colors.transparent,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.map_outlined, color: Colors.white54, size: 18),
                              onPressed: onLocateMap,
                              tooltip: 'Ver en Mapa',
                            ),
                          ),*/
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}