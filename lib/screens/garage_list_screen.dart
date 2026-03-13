import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../widgets/dynamic_progress_bar.dart';
import '../widgets/boxy_search_field.dart';
import '../models/vehicle.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class GarageListScreen extends StatefulWidget {
  const GarageListScreen({super.key});

  @override
  State<GarageListScreen> createState() => _GarageListScreenState();
}

class _GarageListScreenState extends State<GarageListScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> propertiesSummary = [];
  List<Map<String, dynamic>> allVehicles = [];
  Map<String, Vehicle> vehicleCatalog = {};
  
  int totalSlots = 0;
  int occupiedSlots = 0;
  
  String searchQuery = "";
  bool _isSearchingMobile = false;

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    setState(() => isLoading = true);
    
    final String response = await rootBundle.loadString('assets/data/vehicles.json');
    final List<dynamic> data = json.decode(response);
    final Map<String, Vehicle> catalog = {};
    for (var item in data) {
      final v = Vehicle.fromJson(item);
      catalog[v.id] = v;
    }

    final db = DatabaseHelper.instance;
    final props = await db.getUserPropertiesSummary();
    final vehs = await db.getUserVehiclesInventory();

    int tSlots = 0;
    int oSlots = 0;

    for (var p in props) {
      tSlots += (p['totalCapacity'] as int? ?? 0);
      oSlots += (p['occupiedSlots'] as int? ?? 0);
    }

    setState(() {
      vehicleCatalog = catalog;
      propertiesSummary = props;
      allVehicles = vehs;
      totalSlots = tSlots;
      occupiedSlots = oSlots;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.warehouse_outlined, color: Colors.white, size: 28), 
            SizedBox(width: 16),
            Text(
              "MI INVENTARIO", 
              style: TextStyle(
                color: Colors.white, 
                fontFamily: 'Pricedown', 
                fontSize: 32,
              )
            ),
          ],
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
        : Column(
            children: [
              _buildFunctionalBar(isDesktop, occupiedSlots, totalSlots),
              
              const SizedBox(height: 8),
              const Divider(color: Colors.white10, height: 1),

              Expanded(
                child: _buildPropertiesList(),
              ),
            ],
          ),
    );
  }

  Widget _buildFunctionalBar(bool isDesktop, int obtained, int total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: isDesktop ? null : BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(8)),
      child: isDesktop 
        ? _buildDesktopFunctionalRow(obtained, total) 
        : _buildMobileFunctionalRow(obtained, total),
    );
  }

  Widget _buildDesktopFunctionalRow(int obtained, int total) {
    return Row(
      children: [
        Expanded(
          flex: 1, 
          child: BoxySearchField(
            hintText: "Buscar vehículo, etiqueta o garaje...",
            onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 1, 
          child: DynamicProgressBar(
            obtained: obtained, 
            total: total, 
            label: "Plazas Ocupadas"
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFunctionalRow(int obtained, int total) {
    if (_isSearchingMobile) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), 
            onPressed: () {
              setState(() {
                _isSearchingMobile = false;
                searchQuery = "";
              });
            }
          ),
          Expanded(
            child: BoxySearchField(
              autoFocus: true, 
              hintText: "Buscar vehículo o etiqueta...",
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white), 
            onPressed: () => setState(() => _isSearchingMobile = true)
          ),
          Expanded(
            child: DynamicProgressBar(
              obtained: obtained, 
              total: total, 
              label: "Plazas Ocupadas"
            ),
          ),
          const SizedBox(width: 48), 
        ],
      );
    }
  }

  Widget _buildPropertiesList() {
    if (propertiesSummary.isEmpty) {
      return const Center(
        child: Text(
          "No has comprado ninguna propiedad aún.",
          style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
        ),
      );
    }

    List<Map<String, dynamic>> filteredProps = [];
    Map<String, List<Map<String, dynamic>>> filteredVehsByProp = {};

    for (var prop in propertiesSummary) {
      final String propName = prop['name'];
      
      final propVehicles = allVehicles.where((v) => v['garageName'] == propName).toList();
      
      if (searchQuery.isEmpty) {
        filteredProps.add(prop);
        filteredVehsByProp[propName] = propVehicles;
        continue;
      }

      final matchingVehicles = propVehicles.where((v) {
        final catalogId = v['catalogId'];
        final vehicleObj = vehicleCatalog[catalogId];
        
        final name = vehicleObj != null 
            ? vehicleObj.getLocalizedName(context).toLowerCase() 
            : (v['name'] ?? '').toString().toLowerCase();
            
        final tag = (v['tag'] ?? '').toString().toLowerCase();
        final brand = (v['manufacturer'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) || tag.contains(searchQuery) || brand.contains(searchQuery);
      }).toList();

      final bool propNameMatches = propName.toLowerCase().contains(searchQuery) || 
                                   (prop['type'] as String).toLowerCase().contains(searchQuery);

      if (matchingVehicles.isNotEmpty || propNameMatches) {
        filteredProps.add(prop);
        filteredVehsByProp[propName] = matchingVehicles.isNotEmpty ? matchingVehicles : propVehicles;
      }
    }

    if (filteredProps.isEmpty) {
      return const Center(
        child: Text(
          "No se encontraron resultados.",
          style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProps.length,
      itemBuilder: (context, index) {
        final prop = filteredProps[index];
        final String propName = prop['name'];
        final int capacity = prop['totalCapacity'];
        final int occupied = prop['occupiedSlots'];

        final propertyVehicles = filteredVehsByProp[propName] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: searchQuery.isNotEmpty,
              collapsedIconColor: Colors.white54,
              iconColor: Colors.white,
              title: Text(
                propName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Chalet'
                ),
              ),
              subtitle: Text(
                prop['type'].toUpperCase(),
                style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'Chalet'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$occupied / $capacity",
                    style: TextStyle(
                      color: occupied == capacity ? const Color(0xFF39FF14) : Colors.white54, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(searchQuery.isNotEmpty ? Icons.search : Icons.keyboard_arrow_down), 
                ],
              ),
              children: [
                const Divider(color: Colors.white10, height: 1),
                if (propertyVehicles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text("Sin coincidencias en este garaje", style: TextStyle(color: Colors.white38, fontFamily: 'Chalet')),
                  )
                else
                  ...propertyVehicles.map((veh) => _buildVehicleRow(veh)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleRow(Map<String, dynamic> veh) {
    final String tag = veh['tag'] ?? '';
    final catalogId = veh['catalogId'];
    final vehicleObj = vehicleCatalog[catalogId];
    final String name = vehicleObj != null 
        ? vehicleObj.getLocalizedName(context).toUpperCase() 
        : veh['name'].toString().toUpperCase();
        
    final String slot = veh['slotNumb'] != null ? "Slot ${veh['slotNumb']}" : "Sin slot";

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Image.asset(veh['image'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.directions_car, color: Colors.white24)),
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Pricedown'),
            children: [
              TextSpan(text: name),
              if (tag.isNotEmpty) ...[
                const TextSpan(text: "  "),
                TextSpan(
                  text: "[$tag]",
                  style: const TextStyle(color: Color.fromARGB(255, 161, 255, 145), fontSize: 16, fontFamily: 'Pricedown'),
                ),
              ]
            ],
          ),
        ),
        subtitle: Text(
          slot,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        onTap: () {
          // FUTURE: SEE DETAILS
        },
      ),
    );
  }
}