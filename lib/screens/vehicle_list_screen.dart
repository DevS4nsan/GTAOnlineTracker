import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/vehicle_filter.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/dynamic_progress_bar.dart';
import '../widgets/boxy_search_field.dart';
import 'filter_screen_modal.dart';
import '../database/database_helper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<Vehicle> allVehicles = [];
  List<Vehicle> filteredVehicles = [];
  bool isLoading = true;
  String searchQuery = "";
  bool _isSearchingMobile = false;
  String? errorMessage;
  VehicleFilter _currentFilter = VehicleFilter();

  @override
  void initState() {
    super.initState();
    _refreshVehiclesFromDB();
  }

  Future<void> _refreshVehiclesFromDB({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => isLoading = true);
    }
    try {
      final String response = await rootBundle.loadString(
        'assets/data/vehicles.json',
      );
      final List<dynamic> catalogData = json.decode(response);
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> counts = await db.rawQuery(
        'SELECT idVeh, COUNT(*) as qty FROM owned_vehicles GROUP BY idVeh',
      );
      final Map<String, int> qtyMap = {
        for (var row in counts) row['idVeh'] as String: row['qty'] as int,
      };
      final List<Map<String, dynamic>> wishlistRows = await db.query(
        'wishlisted_vehicles',
      );
      final Set<String> wishlistedIds = wishlistRows
          .map((row) => row['idVeh'] as String)
          .toSet();

      setState(() {
        allVehicles = catalogData.map((jsonItem) {
          final vehicle = Vehicle.fromJson(jsonItem);
          final int count = qtyMap[vehicle.id] ?? 0;
          vehicle.ownedCount = count;
          vehicle.isOwned = count > 0;
          vehicle.isWishlisted = wishlistedIds.contains(vehicle.id);

          return vehicle;
        }).toList();

        _applyAllFilters();
        isLoading = false;
      });
    } catch (e) {
      print("Error cargando datos: $e");
      setState(() => isLoading = false);
    }
  }
  void _abrirFiltros(BuildContext context) async {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    VehicleFilter? result;

    if (isDesktop) {
      result = await showDialog<VehicleFilter>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            vertical: 24.0,
            horizontal: 24.0,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FilterScreenModal(initialFilter: _currentFilter),
            ),
          ),
        ),
      );
    } else {
      result = await showModalBottomSheet<VehicleFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FilterScreenModal(initialFilter: _currentFilter),
      );
    }

    if (result != null) {
      setState(() {
        _currentFilter = result!;
      });
      _applyAllFilters();
    }
  }

  void _applyAllFilters() {
    setState(() {
      filteredVehicles = allVehicles.where((v) {
        final bool matchesSearch =
            v
                .getLocalizedName(context)
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            v.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            v.manufacturer.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchesOwned = true;
        if (_currentFilter.obtainedFilter == "Obtained") {
          matchesOwned = v.isOwned;
        }
        if (_currentFilter.obtainedFilter == "Unobtained") {
          matchesOwned = !v.isOwned;
        }
        final bool matchesPrice =
            v.price >= _currentFilter.priceRange.start &&
            v.price <= _currentFilter.priceRange.end;
        final bool matchesCategory =
            _currentFilter.selectedCategory == "All" ||
            v.category == _currentFilter.selectedCategory;
        final bool matchesWishlist =
            !_currentFilter.isWishlisted || v.isWishlisted;
        final bool matchesHSW =
            !_currentFilter.hasHSW || (v.extras?.contains('hsw') ?? false);
        final bool matchesDrift =
            !_currentFilter.hasDrift || (v.extras?.contains('drift') ?? false);
        final bool matchesImani =
            !_currentFilter.imaniTech || (v.imaniTech != null);
        final bool matchesWeapons =
            !_currentFilter.hasWeapons || (v.weaponry != null);
        final bool matchesRemoved = !_currentFilter.isRemoved || v.isRemoved;

        return matchesSearch &&
            matchesOwned &&
            matchesPrice &&
            matchesCategory &&
            matchesHSW &&
            matchesDrift &&
            matchesImani &&
            matchesWeapons &&
            matchesRemoved &&
            matchesWishlist;
      }).toList();
      filteredVehicles.sort((a, b) {
        int comparison = 0;
        switch (_currentFilter.selectedSort) {
          case "Name":
            comparison = a
                .getLocalizedName(context)
                .compareTo(b.getLocalizedName(context));
            break;
          case "Price":
            comparison = a.price.compareTo(b.price);
            break;
          case "Category":
            comparison = a.category.compareTo(b.category);
            break;
          case "DLC":
            comparison = a.dlc.compareTo(b.dlc);
            break;
        }
        return _currentFilter.sortOrder == "Ascending"
            ? comparison
            : -comparison;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final totalCars = allVehicles.length;
    final obtainedCars = allVehicles.where((v) => v.isOwned).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFunctionalBar(isDesktop, obtainedCars, totalCars),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            Expanded(child: _buildListContent(isDesktop)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(
            Icons.directions_car_filled,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 15),
          const Text(
            "LISTA DE VEHÍCULOS",
            style: TextStyle(
              fontFamily: "Pricedown",
              fontSize: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionalBar(bool isDesktop, int obtained, int total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: isDesktop
          ? null
          : BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(8),
            ),
      child: isDesktop
          ? _buildDesktopFunctionalRow(obtained, total)
          : _buildMobileFunctionalRow(obtained, total),
    );
  }

  Widget _buildDesktopFunctionalRow(int obtained, int total) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: BoxySearchField(
            onChanged: (val) {
              searchQuery = val;
              _applyAllFilters();
            },
            hintText: "Buscar vehículos...",
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 3,
          child: DynamicProgressBar(
            obtained: obtained,
            total: total,
            label: "Vehículos Obtenidos",
          ),
        ),
        const SizedBox(width: 15),
        Expanded(flex: 2, child: _buildFilterButton()),
      ],
    );
  }

  Widget _buildMobileFunctionalRow(int obtained, int total) {
    if (_isSearchingMobile) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _isSearchingMobile = false),
          ),
          Expanded(
            child: BoxySearchField(
              onChanged: (val) {
                searchQuery = val;
                _applyAllFilters();
              },
              autoFocus: true,
              hintText: "Buscar vehículos...",
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() => _isSearchingMobile = true),
          ),
          Expanded(
            child: DynamicProgressBar(
              obtained: obtained,
              total: total,
              label: "Vehículos Obtenidos",
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _abrirFiltros(context),
          ),
        ],
      );
    }
  }

  Widget _buildFilterButton() {
    return InkWell(
      onTap: () => _abrirFiltros(context),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Filtros",
              style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
            ),
            Icon(Icons.filter_list, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(bool isDesktop) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (filteredVehicles.isEmpty) {
      return const Center(
        child: Text(
          "No se encontró ningun vehículo",
          style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
        ),
      );
    }

    Future<void> handleToggleOwned(Vehicle vehicle) async {
      try {
        if (vehicle.isOwned) {
          await DatabaseHelper.instance.removeOwnedVehicle(vehicle.id);
        } else {
          await DatabaseHelper.instance.purchaseVehicle(vehicle.id);
        }
        await _refreshVehiclesFromDB(showLoader: false);
      } catch (e) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: const Color.fromARGB(255, 126, 19, 19),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        await _refreshVehiclesFromDB();
      }
    }

    return isDesktop
        ? GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
            ),
            itemCount: filteredVehicles.length,
            itemBuilder: (ctx, i) {
              final vehicle = filteredVehicles[i];
              return VehicleCard(
                vehicle: vehicle,
                onToggleOwned: () => handleToggleOwned(
                  vehicle,
                ),
                onRefresh: _refreshVehiclesFromDB,
                onToggleWishlist: () async {
                  await DatabaseHelper.instance.toggleWishlist(
                    vehicle.id,
                    vehicle.isWishlisted,
                  );
                  await _refreshVehiclesFromDB(
                    showLoader: false,
                  );
                },
              );
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredVehicles.length,
            itemBuilder: (ctx, i) {
              final vehicle = filteredVehicles[i];
              return VehicleCard(
                vehicle: vehicle,
                onToggleOwned: () => handleToggleOwned(
                  vehicle,
                ),
                onRefresh: _refreshVehiclesFromDB,
                onToggleWishlist: () async {
                  await DatabaseHelper.instance.toggleWishlist(
                    vehicle.id,
                    vehicle.isWishlisted,
                  );
                  await _refreshVehiclesFromDB(
                    showLoader: false,
                  );
                },
              );
            },
          );
  }
}
