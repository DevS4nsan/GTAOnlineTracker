import 'package:flutter/material.dart';
import 'package:gtaonlinetracker/screens/garage_list_screen.dart';
import 'package:gtaonlinetracker/screens/settings_screen.dart';
import '../widgets/header_section.dart';
import '../widgets/stat_card.dart';
import '../widgets/image_card.dart';
import 'vehicle_list_screen.dart';
import 'property_list_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../database/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const String CURRENT_APP_VERSION = "1.0.0";

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _activeStatIndex = 0;

  final List<Map<String, dynamic>> _stats = [
    {
      'icon': Icons.directions_car,
      'title': "VEHÍCULOS OBTENIDOS",
      'value': "...",
    },
    {'icon': Icons.attach_money, 'title': "PATRIMONIO TOTAL", 'value': "..."},
    {'icon': Icons.garage, 'title': "PLAZAS OCUPADAS", 'value': "..."},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates(context);
    });
  }

  Future<void> _loadDashboardData() async {
    final db = await DatabaseHelper.instance.database;

    try {
      final String vehsJson = await rootBundle.loadString(
        'assets/data/vehicles.json',
      );
      final List<dynamic> vehsData = json.decode(vehsJson);
      int totalVehicles = vehsData.length;

      final uniqueVehiclesQuery = await db.rawQuery(
        'SELECT COUNT(DISTINCT idVeh) as count FROM owned_vehicles',
      );
      int obtainedVehicles = (uniqueVehiclesQuery.first['count'] as int?) ?? 0;

      final slotsQuery = await db.rawQuery(
        'SELECT SUM(slots) as total FROM owned_properties',
      );
      int totalSlots = (slotsQuery.first['total'] as int?) ?? 0;

      final occupiedQuery = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ownedVehicles_properties',
      );
      int occupiedSlots = (occupiedQuery.first['count'] as int?) ?? 0;

      double totalSpent = 0.0;

      Map<String, double> vehiclePrices = {
        for (var v in vehsData) v['id']: (v['price'] ?? 0).toDouble(),
      };
      final ownedVehs = await db.query('owned_vehicles');
      for (var ov in ownedVehs) {
        totalSpent += vehiclePrices[ov['idVeh']] ?? 0.0;
      }

      final String propsJson = await rootBundle.loadString(
        'assets/data/properties.json',
      );
      final List<dynamic> propsData = json.decode(propsJson);
      Map<String, double> propertyPrices = {
        for (var p in propsData) p['id']: (p['price'] ?? 0).toDouble(),
      };
      final ownedProps = await db.query('owned_properties');
      for (var op in ownedProps) {
        totalSpent += propertyPrices[op['idProp']] ?? 0.0;
      }

      final String upgJson = await rootBundle.loadString(
        'assets/data/upgrades.json',
      );
      final List<dynamic> upgData = json.decode(upgJson);
      Map<String, double> upgradePrices = {
        for (var u in upgData) u['id']: (u['price'] ?? 0).toDouble(),
      };
      final ownedUpgs = await db.query('properties_upgrades');
      for (var ou in ownedUpgs) {
        totalSpent += upgradePrices[ou['upgradeType']] ?? 0.0;
      }

      String formattedValue;
      if (totalSpent >= 1000000) {
        final NumberFormat formatter = NumberFormat('#,##0.##', 'en_US');
        formattedValue = "\$${formatter.format(totalSpent / 1000000)}M";
      } else {
        final NumberFormat formatter = NumberFormat('#,##0', 'en_US');
        formattedValue = "\$${formatter.format(totalSpent)}";
      }

      if (mounted) {
        setState(() {
          _stats[0]['value'] = "$obtainedVehicles/$totalVehicles";
          _stats[1]['value'] = formattedValue;
          _stats[2]['value'] = "$occupiedSlots/$totalSlots";
        });
      }
    } catch (e) {
      print("Error cargando estadísticas: $e");
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      //CODE TO CHECK UPDATES MANUALLY
      /*_showUpdateDialog(
        context,
        "1.0.1",
        "¡Gran actualización de prueba!\n- Se añadió buscador global.\n- Mejoras de rendimiento.",
        "https://github.com",
      );
      return;*/

      final url = Uri.parse(
        'https://raw.githubusercontent.com/DevS4nsan/GTAOnlineTracker/refs/heads/main/version.json',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersion = data['latest_version'];
        final String downloadUrl = data['download_url'];
        final String releaseNotes = data['release_notes'];

        // Comparamos versiones (lógica simple)
        if (latestVersion != CURRENT_APP_VERSION) {
          if (!context.mounted) return;
          _showUpdateDialog(context, latestVersion, releaseNotes, downloadUrl);
        }
      }
    } catch (e) {
      print("Fallo al buscar actualizaciones: $e");
    }
  }

  void _showUpdateDialog(
    BuildContext context,
    String version,
    String notes,
    String url,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Color(0xFF39FF14)),
            SizedBox(width: 10),
            Text(
              "¡NUEVA ACTUALIZACIÓN!",
              style: TextStyle(color: Colors.white, fontFamily: 'Pricedown'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Versión $version ya disponible.",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              notes,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 15),
            const Text(
              "Puedes actualizar más tarde desde Configuración.",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontFamily: 'Chalet',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "MÁS TARDE",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
            ),
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              "DESCARGAR",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderSection(),
              const SizedBox(height: 30),
              isDesktop ? _buildDesktopStats() : _buildMobileStatSelector(),
              const SizedBox(height: 40),
              _buildMainGrid(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStatSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_stats.length, (index) {
            bool isActive = _activeStatIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _activeStatIndex = index),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF111111),
                    child: Icon(
                      _stats[index]['icon'],
                      color: isActive ? Colors.white : Colors.white24,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: isActive ? 1.0 : 0.0,
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: Color.fromARGB(255, 255, 255, 255),
                      size: 30,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        StatCard(
          icon: _stats[_activeStatIndex]['icon'],
          title: _stats[_activeStatIndex]['title'],
          value: _stats[_activeStatIndex]['value'],
        ),
      ],
    );
  }

  Widget _buildDesktopStats() {
    return Row(
      children: _stats
          .map(
            (stat) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: StatCard(
                  icon: stat['icon'],
                  title: stat['title'],
                  value: stat['value'],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMainGrid(bool isDesktop) {
    if (isDesktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ImageCard(
                  title: "LISTA DE VEHÍCULOS",
                  subtitle:
                      "Accede a la totalidad de vehículos obtenibles en Los Santos",
                  imagePath: "assets/garage.jpg",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleListScreen(),
                      ),
                    ).then((_) => _loadDashboardData());
                    ;
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ImageCard(
                  title: "LISTA DE PROPIEDADES",
                  subtitle:
                      "Forma tu imperio criminal con las mejores propiedades del estado de San Andreas",
                  imagePath: "assets/properties.jpg",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PropertyListScreen(),
                      ),
                    ).then((_) => _loadDashboardData());
                    ;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ImageCard(
                  title: "MI GARAGE",
                  subtitle: "Encuentra tus valiosos vehículos de tu imperio",
                  imagePath: "assets/wishlist.jpg",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GarageListScreen(),
                      ),
                    ).then((_) => _loadDashboardData());
                    ;
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ImageCard(
                  title: "CONFIGURACIÓN Y RESPALDO",
                  subtitle: "Personaliza tu experiencia",
                  imagePath: "assets/settings.jpg",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ).then((_) => _loadDashboardData());
                    ;
                  },
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          ImageCard(
            title: "LISTA DE VEHÍCULOS",
            subtitle: "Accede a la totalidad de vehículos obtenibles en Los Santos",
            imagePath: "assets/garage.jpg",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleListScreen(),
                ),
              ).then((_) => _loadDashboardData());
              ;
            },
          ),
          const SizedBox(height: 20),
          ImageCard(
            title: "LISTA DE PROPIEDADES",
            subtitle: "Forma tu imperio criminal con las mejores propiedades del estado de San Andreas",
            imagePath: "assets/properties.jpg",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertyListScreen(),
                ),
              ).then((_) => _loadDashboardData());
              ;
            },
          ),
          const SizedBox(height: 20),
          ImageCard(
            title: "MI GARAGE",
            subtitle: "Encuentra tus valiosos vehículos de tu imperio",
            imagePath: "assets/wishlist.jpg",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GarageListScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
          const SizedBox(height: 20),
          ImageCard(
            title: "CONFIGURACIÓN Y RESPALDO",
            subtitle: "Personaliza tu experiencia",
            imagePath: "assets/settings.jpg",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadDashboardData());
            },
          ),
        ],
      );
    }
  }
}
