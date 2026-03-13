import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/vehicle.dart';
import '../widgets/stat_card.dart';
import '../database/database_helper.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Map<int, Map<String, dynamic>> slotOccupants = {};
  List<String> ownedUpgrades = [];
  List<dynamic> availableUpgrades = [];
  bool isLoading = true;
  bool _isGridView = true;
  Map<String, Vehicle> vehicleCatalog = {};

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _loadAllData();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('property_view_is_grid') ?? true;
    });
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool('property_view_is_grid', _isGridView);
  }

  Future<void> _loadAllData() async {
    final String response = await rootBundle.loadString(
      'assets/data/vehicles.json',
    );
    final List<dynamic> data = json.decode(response);
    final Map<String, Vehicle> catalog = {};
    for (var item in data) {
      final v = Vehicle.fromJson(item);
      catalog[v.id] = v;
    }
    vehicleCatalog = catalog;

    setState(() => isLoading = true);

    if (widget.property.isOwned) {
      final db = await DatabaseHelper.instance.database;
      final ownedData = await db.query(
        'owned_properties',
        where: 'idProp = ?',
        whereArgs: [widget.property.id],
        limit: 1,
      );

      if (ownedData.isNotEmpty) {
        widget.property.capacity = ownedData.first['slots'] as int;
      }
    }

    await _loadOccupants();

    if (widget.property.isOwned) {
      await _loadUpgrades();
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadUpgrades() async {
    ownedUpgrades = await DatabaseHelper.instance.getOwnedUpgradesForProperty(
      widget.property.id,
    );

    final String response = await rootBundle.loadString(
      'assets/data/upgrades.json',
    );
    final List<dynamic> catalogData = json.decode(response);

    setState(() {
      availableUpgrades = catalogData.where((u) {
        bool isForThisPropertyType = u['propertyType'] == widget.property.type;
        bool isNotOwned = !ownedUpgrades.contains(u['id']);

        if (!isForThisPropertyType || !isNotOwned) return false;

        if (widget.property.type == 'Large Vehicle Properties') {
          if (widget.property.id == 'lvp_4301') {
            return u['targetVehicle'] == 'trailerlarge';
          }
          if (widget.property.id == 'lvp_4101') {
            return u['targetVehicle'] == 'mammoth_avenger';
          }
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _purchaseUpgrade(dynamic upgrade) async {
    try {
      await DatabaseHelper.instance.purchasePropertyUpgrade(
        widget.property.id,
        upgrade['id'],
        upgrade['id'],
        upgrade['addedCapacity'],
      );

      setState(() {
        widget.property.capacity += (upgrade['addedCapacity'] as int);
      });

      await _loadUpgrades();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _loadOccupants() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT ovp.slotNumb, v.id as catalogId, v.name, v.manufacturer, v.image, ov.tag 
      FROM ownedVehicles_properties ovp
      JOIN owned_vehicles ov ON ovp.idOVeh = ov.id
      JOIN vehicles v ON ov.idVeh = v.id
      JOIN owned_properties op ON ovp.idOProp = op.id
      WHERE op.idProp = ?
    ''',
      [widget.property.id],
    );

    setState(() {
      slotOccupants = {
        for (var row in results)
          row['slotNumb']: {
            'catalogId': row['catalogId'],
            'name': row['name'],
            'manufacturer': row['manufacturer'],
            'image': row['image'] ?? 'assets/vehicles/placeholder.jpg',
            'tag': row['tag'],
          },
      };
      isLoading = false;
    });
  }

  String _getReservedLabel(String propertyType, int slotNumb) {
    if (propertyType == 'Facilities') {
      if (slotNumb == 8) return "RESERVADO: AVENGER";
      if (slotNumb == 9) return "RESERVADO: KHANJALI";
      if (slotNumb == 10) return "RESERVADO: CHERNOBOG";
      if (slotNumb == 11) return "RESERVADO: RCV";
      if (slotNumb == 12) return "RESERVADO: THRUSTER";
    }
    if (propertyType == 'Bunkers') {
      if (slotNumb == 1) return "RESERVADO: REMOLQUE AA";
      if (slotNumb == 2) return "RESERVADO: MOC";
      if (slotNumb == 3) return "RESERVADO: CADDY";
    }
    if (propertyType == 'Arena Workshop') {
      if (slotNumb == 10 || slotNumb == 21 || slotNumb == 31) {
        return "RESERVADO: CERBERUS";
      }
      if (slotNumb == 11) return "MESA: RC BANDITO";
    }
    if (propertyType == 'Nightclubs') {
      if (slotNumb == 1) return "RESERVADO: SPEEDO CUSTOM";
      if (slotNumb == 2) return "RESERVADO: MULE CUSTOM";
      if (slotNumb == 3) return "RESERVADO: POUNDER CUSTOM";
      if (slotNumb == 4) return "RESERVADO: TERRORBYTE";
    }
    if (propertyType == 'Large Vehicle Properties' &&
        widget.property.id == 'lvp_4001') {
      if (slotNumb == 1) return "RESERVADO: SPARROW";
      if (slotNumb == 2) return "RESERVADO: KRAKEN AVISA";
      if (slotNumb == 3) return "RESERVADO: TOREADOR";
    }
    if (propertyType == 'Large Vehicle Properties' &&
        widget.property.id == 'lvp_4201') {
      if (slotNumb == 1) return "RESERVADO: OPPRESSOR MK2";
    }
    return "(VACÍO)";
  }

  String _getVehicleDisplayName(Map<String, dynamic> vehicle) {
    final catalogId =
        vehicle['catalogId'] ??
        vehicle['id'];
    final vehicleObj = vehicleCatalog[catalogId];

    String baseName = vehicleObj != null
        ? vehicleObj.getLocalizedName(context).toUpperCase()
        : vehicle['name'].toString().toUpperCase();

    String tag = vehicle['tag']?.toString() ?? '';

    if (tag.isNotEmpty) {
      return "$baseName - [${tag.toUpperCase()}]";
    }
    return baseName;
  }

  void _showVehicleSelector(int slotNumb) async {
    final db = await DatabaseHelper.instance.database;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    String storageCondition = "v.storageType = 'garage'";

    if (widget.property.type == 'Vehicle Warehouses') {
      storageCondition = "v.storageType = 'special_warehouse'";
    }
    if (widget.property.id == 'lvp_4001') {
      storageCondition = "v.storageType = 'kosatka_internal'";
    }
    if (widget.property.id == 'lvp_4201') {
      storageCondition = "v.storageType = 'terrorbyte_internal'";
    }
    if (widget.property.id == 'lvp_3001') {
      storageCondition = "v.storageType = 'acidlab_internal'";
    }

    if (widget.property.type == 'Hangars') {
      storageCondition =
          "(v.storageType = 'hangar' OR v.id = 'mammoth_avenger')";
    }

    if (widget.property.type == 'Facilities') {
      if (slotNumb <= 7) {
        storageCondition = "v.storageType = 'garage'";
      } else if (slotNumb == 8) {
        storageCondition = "v.id = 'mammoth_avenger'";
      } else if (slotNumb == 9) {
        storageCondition = "v.storageType = 'facility_khanjali'";
      } else if (slotNumb == 10) {
        storageCondition = "v.storageType = 'facility_chernobog'";
      } else if (slotNumb == 11) {
        storageCondition = "v.storageType = 'facility_rcv'";
      } else if (slotNumb == 12) {
        storageCondition = "v.storageType = 'facility_thruster'";
      }
    }

    if (widget.property.type == 'Bunkers') {
      if (slotNumb == 1) {
        storageCondition = "v.id = 'vomfeuer_trailersmall2'";
      } else if (slotNumb == 2) {
        storageCondition = "v.id = 'trailerlarge'";
      } else if (slotNumb == 3) {
        storageCondition = "v.id = 'caddy'";
      }
    }

    if (widget.property.type == 'Nightclubs') {
      if (slotNumb == 1) {
        storageCondition = "v.id = 'vapid_speedo3'";
      } else if (slotNumb == 2) {
        storageCondition = "v.id = 'maibatsu_mule3'";
      } else if (slotNumb == 3) {
        storageCondition = "v.id = 'mtl_pounder2'";
      } else if (slotNumb == 4) {
        storageCondition = "v.id = 'benefactor_terbyte'";
      } else {
        storageCondition = "v.storageType = 'garage'";
      }
    }

    if (widget.property.type == 'Arena Workshop') {
      if (slotNumb == 10 || slotNumb == 21 || slotNumb == 31) {
        storageCondition = "v.storageType = 'arena_cerberus'";
      } else if (slotNumb == 11) {
        storageCondition = "v.id = 'rcbandito'";
      } else {
        storageCondition = "v.storageType = 'garage'";
      }
    }

    final List<Map<String, dynamic>> availableVehs = await db.rawQuery('''
      SELECT 
        v.id,
        ov.id as ownedId,
        v.name, 
        v.manufacturer, 
        v.image,
        ov.tag,
        ov.consecutive
      FROM vehicles v
      JOIN owned_vehicles ov ON v.id = ov.idVeh
      WHERE $storageCondition 
      AND ov.id NOT IN (SELECT idOVeh FROM ownedVehicles_properties)
    ''');

    if (!mounted) return;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: _buildVehicleSelectorContent(availableVehs, slotNumb),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildVehicleSelectorContent(availableVehs, slotNumb),
        ),
      );
    }
  }

  Widget _buildVehicleSelectorContent(
    List<Map<String, dynamic>> vehicles,
    int slotNumb,
  ) {
    final bool isOccupied = slotOccupants.containsKey(slotNumb);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SELECCIONAR VEHÍCULO",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pricedown',
                  fontSize: 24,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        if (isOccupied)
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text(
              "VACIAR ESPACIO",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            onTap: () async {
              await DatabaseHelper.instance.removeVehicleFromSlot(
                widget.property.id,
                slotNumb,
              );
              if (!mounted) return;
              Navigator.pop(context);
              _loadOccupants();
            },
          ),
        Expanded(
          child: vehicles.isEmpty
              ? const Center(
                  child: Text(
                    "No tienes vehículos comprados aún",
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: vehicles.length,
                  itemBuilder: (context, i) {
                    final veh = vehicles[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.asset(veh['image'], fit: BoxFit.cover),
                      ),
                      title: Text(
                        veh['consecutive'] > 1 &&
                                (veh['tag'] == null ||
                                    veh['tag'].toString().isEmpty)
                            ? "${_getVehicleDisplayName(veh)} #${veh['consecutive']}"
                            : _getVehicleDisplayName(veh),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pricedown',
                          fontSize: 22
                        ),
                      ),
                      subtitle: Text(
                        veh['manufacturer'],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontFamily: 'Chalet'
                        ),
                      ),
                      onTap: () async {
                        await DatabaseHelper.instance.assignVehicleToSlot(
                          widget.property.id,
                          veh['ownedId'] as int,
                          slotNumb,
                        );

                        if (!mounted) return;
                        Navigator.pop(context);
                        _loadOccupants();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInfoCards(),
              const SizedBox(height: 40),
              const Divider(color: Color(0xFF333333), thickness: 2),
              const SizedBox(height: 24),

              if (widget.property.isOwned) ...[
                _buildUpgradesSection(),
                if (availableUpgrades.isNotEmpty) const SizedBox(height: 32),

                const Divider(color: Color(0xFF333333), thickness: 2),
                const SizedBox(height: 24),

                _buildGarageHeader(),
                const SizedBox(height: 16),
                _isGridView ? _buildGarageGrid() : _buildGarageList(),
              ] else
                _buildLockedMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGarageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'GARAJE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Pricedown',
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: Colors.white54,
              ),
              onPressed: _toggleViewMode,
            ),
            const SizedBox(width: 10),
            Text(
              '${slotOccupants.length} / ${widget.property.capacity} SLOTS',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGarageGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    int columns = 2;
    double ratio = 0.85;

    if (screenWidth > 1200) {
      columns = 5;
    } else if (screenWidth > 900) {
      columns = 4;
    } else if (screenWidth > 600) {
      columns = 3;
    } else if (screenWidth <= 400) {
      columns = 1;
      ratio = 1.6;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: ratio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.property.capacity,
      itemBuilder: (context, index) =>
          _buildSlotCard(index + 1, isCompact: false),
    );
  }

  Widget _buildGarageList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.property.capacity,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSlotCard(index + 1, isCompact: true),
      ),
    );
  }

  Widget _buildSlotCard(int slotNumb, {required bool isCompact}) {
    final vehicle = slotOccupants[slotNumb];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: vehicle != null
              ? const Color(0xFF39FF14).withOpacity(0.5)
              : const Color(0xFF333333),
        ),
      ),
      child: InkWell(
        onTap: () => _showVehicleSelector(slotNumb),
        child: isCompact
            ? _buildCompactContent(slotNumb, vehicle)
            : _buildFullContent(slotNumb, vehicle),
      ),
    );
  }

  Widget _buildFullContent(int slotNumb, dynamic vehicle) {
    return Column(
      children: [
        Expanded(
          child: vehicle != null
              ? Image.asset(
                  vehicle['image'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : const Center(
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white10,
                    size: 40,
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          width: double.infinity,
          color: Colors.black26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                "SLOT $slotNumb",
                style: const TextStyle(
                  color: Color(0xFF39FF14),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                vehicle != null
                    ? _getVehicleDisplayName(vehicle)
                    : _getReservedLabel(widget.property.type, slotNumb),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (vehicle != null)
                Text(
                  vehicle['manufacturer'],
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContent(int slotNumb, dynamic vehicle) {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Container(
            width: 100,
            color: Colors.black38,
            child: vehicle != null
                ? Image.asset(vehicle['image'], fit: BoxFit.cover)
                : const Icon(Icons.add, color: Colors.white10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SLOT $slotNumb",
                  style: const TextStyle(
                    color: Color(0xFF39FF14),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  vehicle != null
                      ? _getVehicleDisplayName(vehicle)
                      : _getReservedLabel(
                          widget.property.type,
                          slotNumb,
                        ).replaceAll("(VACÍO)", "DISPONIBLE"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (vehicle != null)
                  Text(
                    vehicle['manufacturer'],
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.lock_outline, color: Colors.white24, size: 48),
          SizedBox(height: 16),
          Text(
            "PROPIEDAD NO ADQUIRIDA",
            style: TextStyle(
              color: Colors.white54,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Compra esta propiedad para gestionar su garaje",
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String imagePath = 'assets/images/properties/${widget.property.id}.jpg';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF333333), width: 2),
          ),
          child: ClipRRect(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.domain, size: 80, color: Color(0xFF333333)),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.property.type.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF39FF14),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          widget.property.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontFamily: 'Pricedown',
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'PRECIO',
              value: '\$${widget.property.price}',
              icon: Icons.attach_money,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              title: 'UBICACIÓN',
              value: widget.property.location.split(',').last.trim(),
              icon: Icons.location_on,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          StatCard(
            title: 'PRECIO',
            value: '\$${widget.property.price}',
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 12),
          StatCard(
            title: 'UBICACIÓN',
            value: widget.property.location.split(',').last.trim(),
            icon: Icons.location_on,
          ),
        ],
      );
    }
  }

  Widget _buildUpgradesSection() {
    if (availableUpgrades.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "EXPANSIONES DE GARAJE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Pricedown',
          ),
        ),
        const SizedBox(height: 16),
        ...availableUpgrades.map((upgrade) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: const Color(0xFF39FF14).withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.build_circle,
                color: Color(0xFF39FF14),
                size: 36,
              ),
              title: Text(
                upgrade['name'].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "+${upgrade['addedCapacity']} Espacios de almacenamiento",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14).withOpacity(0.2),
                  foregroundColor: const Color(0xFF39FF14),
                  side: const BorderSide(color: Color(0xFF39FF14)),
                  elevation: 0,
                ),
                onPressed: () => _purchaseUpgrade(upgrade),
                child: Text(
                  "\$${upgrade['price']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
