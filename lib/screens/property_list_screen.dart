import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/property.dart';
import '../models/property_filter.dart';
import '../widgets/property_card.dart';
import '../widgets/dynamic_progress_bar.dart';
import '../widgets/boxy_search_field.dart';
import '../widgets/property_filters_modal.dart';
import '../utils/game_rules.dart';
import '../widgets/property_limits_modal.dart';
import '../database/database_helper.dart';
import '../screens/property_detail_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  List<Property> allProperties = [];
  List<Property> filteredProperties = [];
  bool isLoading = true;
  String searchQuery = "";
  bool _isSearchingMobile = false;
  String? errorMessage;
  Map<String, bool> ownedProperties = {};
  PropertyFilter currentFilter = PropertyFilter();
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
    'Eclipse Blvd Garage': 'Garaje de Eclipse Blvd',
  };

  @override
  void initState() {
    super.initState();
    _refreshPropertiesFromDB();
  }

  Future<void> _refreshPropertiesFromDB() async {
    final serviceVehicles = await DatabaseHelper.instance
        .getOwnedServiceVehicles();

    setState(() => isLoading = true);
    final db = await DatabaseHelper.instance.database;

    final String response = await rootBundle.loadString(
      'assets/data/properties.json',
    );
    final List<dynamic> data = json.decode(response);
    List<Property> catalog = data
        .map((json) => Property.fromJson(json))
        .toList();

    final List<Map<String, dynamic>> owned = await db.query('owned_properties');
    final ownedIds = owned.map((row) => row['idProp'] as String).toSet();

    setState(() {
      allProperties = catalog;
      for (var sv in serviceVehicles) {
        allProperties.add(
          Property(
            id: sv['idProp'],
            name: sv['specStorage'] ?? 'Vehículo de Servicio',
            type: 'Service Vehicle',
            capacity: sv['slots'],
            building: 'Mobile Operations',
            price: 0,
            location: 'Global',
            isOwned: true,
            lat: 0.0,
            lng: 0.0,
          ),
        );
      }
      ownedProperties = {for (var id in ownedIds) id: true};

      for (var prop in allProperties) {
        prop.isOwned = ownedIds.contains(prop.id);
      }
      _applyFilters();
      isLoading = false;
    });
  }

  void _abrirFiltros(BuildContext context) async {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    PropertyFilter? result;

    if (isDesktop) {
      result = await showDialog<PropertyFilter>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            vertical: 24.0,
            horizontal: 24.0,
          ), // Margen estilo autos
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ), // <--- ¡LIBERADO A 1200!
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PropertyFilterModal(initialFilter: currentFilter),
            ),
          ),
        ),
      );
    } else {
      result = await showModalBottomSheet<PropertyFilter>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: PropertyFilterModal(initialFilter: currentFilter),
        ),
      );
    }

    if (result != null) {
      setState(() {
        currentFilter = result!;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    Map<String, int> ownedCounts = {};
    Set<String> ownedMCSubtypes = {};
    for (var p in allProperties) {
      if (p.isOwned) {
        String mappedCategory = (p.type == 'Apartments' || p.type == 'Garages')
            ? 'Apartments & Garages'
            : p.type;

        ownedCounts[mappedCategory] = (ownedCounts[mappedCategory] ?? 0) + 1;

        if (p.type == 'MC Businesses') {
          ownedMCSubtypes.add(GameRules.getMCBusinessSubtype(p.name));
        }
      }
    }

    setState(() {
      filteredProperties = allProperties.where((p) {
        final bool matchesSearch =
            p.building.toLowerCase().contains(searchQuery.toLowerCase()) ||
            p.name.toLowerCase().contains(searchQuery.toLowerCase());
        final bool matchesCategory =
            currentFilter.selectedCategory == "All" ||
            p.type == currentFilter.selectedCategory;
        final double price = (p.price).toDouble();
        final bool matchesPrice =
            price >= currentFilter.priceRange.start &&
            price <= currentFilter.priceRange.end;
        bool matchesObtained = true;
        if (currentFilter.obtainedFilter == "Obtained" && !p.isOwned) {
          matchesObtained = false;
        }
        if (currentFilter.obtainedFilter == "Unobtained" && p.isOwned) {
          matchesObtained = false;
        }
        bool canBeShown = true;
        if (!p.isOwned) {
          String mappedCategory =
              (p.type == 'Apartments' || p.type == 'Garages')
              ? 'Apartments & Garages'
              : p.type;

          int currentOwnedOfThisType = ownedCounts[mappedCategory] ?? 0;

          if (GameRules.hasReachedLimit(
            mappedCategory,
            currentOwnedOfThisType,
          )) {
            canBeShown = false;
          } else if (p.type == 'MC Businesses') {
            String subtype = GameRules.getMCBusinessSubtype(p.name);
            if (ownedMCSubtypes.contains(subtype)) {
              canBeShown = false;
            }
          }
        }

        return matchesSearch &&
            matchesCategory &&
            matchesPrice &&
            matchesObtained &&
            canBeShown;
      }).toList();

      filteredProperties.sort((a, b) {
        int comparison = 0;

        if (currentFilter.selectedSort == "Name") {
          comparison = (a.name).compareTo(b.name);
        } else if (currentFilter.selectedSort == "Price") {
          comparison = (a.price).compareTo(b.price);
        } else if (currentFilter.selectedSort == "Category") {
          comparison = (a.type).compareTo(b.type);
        }

        return currentFilter.sortOrder == "Descending"
            ? -comparison
            : comparison;
      });
    });
  }

  void _toggleOwnership(String propertyId) async {
    final prop = allProperties.firstWhere((p) => p.id == propertyId);
    bool isTradable = ![
      'Large Vehicle Properties',
      'Yachts',
      'Story Mode Properties',
    ].contains(prop.type);

    if (!isTradable) {
      if (prop.isOwned) {
        _showStandardPropertyOptions(prop);
      } else {
        await DatabaseHelper.instance.addOwnedProperty(propertyId);
        await _refreshPropertiesFromDB();
      }
      return;
    }
    if (prop.isOwned) {
      _showStandardPropertyOptions(prop);
      return;
    }
    if (prop.type == 'MC Businesses') {
      String subtype = GameRules.getMCBusinessSubtype(prop.name);
      final sameSubtypeOwned = allProperties.firstWhere(
        (p) =>
            p.isOwned &&
            p.type == 'MC Businesses' &&
            GameRules.getMCBusinessSubtype(p.name) == subtype,
        orElse: () => Property(
          id: 'none',
          name: '',
          type: '',
          building: '',
          capacity: 0,
          price: 0,
          location: '',
          lat: 0,
          lng: 0,
        ),
      );

      if (sameSubtypeOwned.id != 'none') {
        _confirmTradeIn(sameSubtypeOwned, prop);
        return;
      }
    }
    String mappedCategory =
        (prop.type == 'Apartments' || prop.type == 'Garages')
        ? 'Apartments & Garages'
        : prop.type;

    int currentOwnedCount = allProperties.where((p) {
      String pCat = (p.type == 'Apartments' || p.type == 'Garages')
          ? 'Apartments & Garages'
          : p.type;
      return p.isOwned && pCat == mappedCategory;
    }).length;

    if (GameRules.hasReachedLimit(mappedCategory, currentOwnedCount)) {
      _showTradeInModal(prop);
      return;
    }
    if (GameRules.propertyLimits[mappedCategory] == 1) {
      final existing = allProperties.firstWhere(
        (p) => p.isOwned && p.type == prop.type,
        orElse: () => Property(
          id: 'none',
          name: '',
          type: '',
          building: '',
          capacity: 0,
          price: 0,
          location: '',
          lat: 0,
          lng: 0,
        ),
      );
      if (existing.id != 'none') {
        _confirmTradeIn(existing, prop);
        return;
      }
    }

    await DatabaseHelper.instance.addOwnedProperty(propertyId);
    await _refreshPropertiesFromDB();
  }

  void _showStandardPropertyOptions(Property prop) {
    bool isTradable = ![
      'Large Vehicle Properties',
      'Yachts',
      'Story Mode Properties',
    ].contains(prop.type);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          prop.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pricedown',
            fontSize: 20,
          ),
        ),
        content: Text(
          isTradable
              ? "En GTA Online no se pueden vender propiedades, solo mudarse a otras (Trade-in).\n\nSi quieres 'venderla' en el juego, usa MUDAR y elige un garaje barato. Solo usa ELIMINAR si agregaste esta propiedad a la app por error."
              : "Esta propiedad especial es única y no permite mudanzas. Solo puedes eliminarla del registro si la agregaste por error.",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.removeOwnedProperty(prop.id);
              await _refreshPropertiesFromDB();
            },
            child: const Text(
              "ELIMINAR POR ERROR",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (isTradable)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showTradeInModal(prop);
              },
              child: const Text(
                "MUDAR",
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

  void _showTradeInModal(Property currentProp) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final alternatives = allProperties.where((p) {
      if (p.type != currentProp.type) return false;
      if (p.id == currentProp.id) return false;
      if (p.isOwned) return false;
      if (p.type == 'MC Businesses') {
        String currentSubtype = GameRules.getMCBusinessSubtype(
          currentProp.name,
        );
        String altSubtype = GameRules.getMCBusinessSubtype(p.name);
        if (currentSubtype != altSubtype) return false;
      }
      return true;
    }).toList();

    Widget buildHeader() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.swap_horiz, color: Colors.orangeAccent, size: 40),
            const SizedBox(height: 10),
            const Text(
              "MUDANZA DE PROPIEDAD",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pricedown',
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No puedes eliminar tu ${currentProp.type} directamente. Selecciona a qué ubicación te quieres mudar:",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    Widget buildList(ScrollController? controller) {
      return ListView.builder(
        controller:
            controller,
        itemCount: alternatives.length,
        itemBuilder: (context, index) {
          final alt = alternatives[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment, color: Colors.white54),
            ),
            title: Text(
              alt.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              alt.capacity > 0
                  ? "\$${alt.price} • ${alt.location}\n🚘 ${alt.capacity} Plazas"
                  : "\$${alt.price} • ${alt.location}",
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
            onTap: () async {
              Navigator.pop(context);
              _confirmTradeIn(
                currentProp,
                alt,
              );
            },
          );
        },
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor:
              Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(16),
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  buildHeader(),
                  const Divider(color: Colors.white10),
                  Flexible(child: buildList(null)),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              buildHeader(),
              const Divider(color: Colors.white10),
              Expanded(
                child: buildList(
                  scrollController,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _confirmTradeIn(Property oldProp, Property newProp) async {
    final impact = await DatabaseHelper.instance.getPropertyImpact(oldProp.id);
    int currentCars = impact['cars'] as int;
    int newCapacity = newProp.capacity;
    bool isDowngrade = currentCars > newCapacity;

    bool confirm =
        await showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Row(
              children: [
                Icon(Icons.sync_alt, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "CONFIRMAR MUDANZA",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontFamily: 'Pricedown',
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: "¿Estás seguro de que quieres mudarte a ",
                  ),
                  TextSpan(
                    text: "${newProp.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: "?\n\nEsto reemplazará tu "),
                  TextSpan(
                    text: "${oldProp.name}.\n\n",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: "Se transferirán automáticamente:\n"),
                  TextSpan(
                    text: "🚗 ${impact['cars']} Vehículos\n",
                    style: const TextStyle(
                      color: Color(0xFF39FF14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: "🛠️ ${impact['upgrades']} Expansiones\n\n",
                    style: const TextStyle(
                      color: Color(0xFF39FF14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isDowngrade)
                    TextSpan(
                      text:
                          "⚠️ ADVERTENCIA: El nuevo garaje solo tiene $newCapacity plazas. Los ${currentCars - newCapacity} vehículos restantes no se borrarán, pero irán al almacén y no serán visibles hasta que los muevas a otra propiedad.",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "CANCELAR",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "CONFIRMAR",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await DatabaseHelper.instance.addOwnedProperty(
        newProp.id,
        oldCatalogId: oldProp.id,
      );
      await _refreshPropertiesFromDB();
    }
  }

  void _abrirModalLimites(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width > 900;
    Map<String, int> ownedCounts = {};
    Set<String> ownedMCSubtypes = {};

    for (var p in allProperties) {
      if (ownedProperties.containsKey(p.id)) {
        String mappedCategory = (p.type == 'Apartments' || p.type == 'Garages')
            ? 'Apartments & Garages'
            : p.type;
        ownedCounts[mappedCategory] = (ownedCounts[mappedCategory] ?? 0) + 1;
        if (p.type == 'MC Businesses') {
          ownedMCSubtypes.add(GameRules.getMCBusinessSubtype(p.name));
        }
      }
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PropertyLimitsModal(
                ownedCounts: ownedCounts,
                ownedMCSubtypes: ownedMCSubtypes,
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.75,
          child: PropertyLimitsModal(
            ownedCounts: ownedCounts,
            ownedMCSubtypes: ownedMCSubtypes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final totalProps = GameRules.maxTrackableProperties;
    final obtainedProps = allProperties.where((p) => p.isOwned).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFunctionalBar(isDesktop, obtainedProps, totalProps),
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
          const Icon(Icons.apartment, color: Colors.white, size: 32),
          const SizedBox(width: 15),
          const Text(
            "LISTA DE PROPIEDADES",
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
              _applyFilters();
            },
            hintText: "Buscar propiedades...",
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 3,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _abrirModalLimites(
                context,
              ),
              child: DynamicProgressBar(
                obtained: obtained,
                total: total,
                label: "Propiedades Adquiridas",
              ),
            ),
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
            onPressed: () {
              setState(() {
                _isSearchingMobile = false;
                searchQuery = "";
              });
              _applyFilters();
            },
          ),
          Expanded(
            child: BoxySearchField(
              onChanged: (val) {
                searchQuery = val;
                _applyFilters();
              },
              autoFocus: true,
              hintText: "Buscar propiedades...",
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
            child: GestureDetector(
              onTap: () => _abrirModalLimites(context),
              child: DynamicProgressBar(
                obtained: obtained,
                total: total,
                label: "Propiedades Adquiridas",
              ),
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
    bool isActive =
        currentFilter.selectedCategory != "All" ||
        currentFilter.obtainedFilter != "All" ||
        currentFilter.priceRange.start > 0 ||
        currentFilter.priceRange.end < 15000000;
    String buttonText = "Filtros";
    if (isActive) {
      if (currentFilter.selectedCategory != "All") {
        buttonText =
            propertyTranslations[currentFilter.selectedCategory] ??
            currentFilter.selectedCategory.toUpperCase();
      } else {
        buttonText = "FILTRANDO...";
      }
    }

    return InkWell(
      onTap: () => _abrirFiltros(context),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.limeAccent.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isActive ? Colors.limeAccent : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                buttonText,
                style: TextStyle(
                  color: isActive ? Colors.limeAccent : Colors.white54,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.filter_list,
              color: isActive ? Colors.limeAccent : Colors.white,
            ),
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
    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (filteredProperties.isEmpty) {
      return const Center(
        child: Text(
          "No se encontraron propiedades",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return isDesktop
        ? GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 12,
              mainAxisExtent:
                  180,
            ),
            itemCount: filteredProperties.length,
            itemBuilder: (ctx, i) => PropertyCard(
              property: filteredProperties[i],
              isOwned:
                  filteredProperties[i].isOwned,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PropertyDetailScreen(property: filteredProperties[i]),
                  ),
                );
              },
              onToggleObtained: () =>
                  _toggleOwnership(filteredProperties[i].id),
              onLocateMap: () {},
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProperties.length,
            itemBuilder: (ctx, i) => PropertyCard(
              property: filteredProperties[i],
              isOwned:
                  filteredProperties[i].isOwned,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PropertyDetailScreen(property: filteredProperties[i]),
                  ),
                );
              },
              onToggleObtained: () =>
                  _toggleOwnership(filteredProperties[i].id),
              onLocateMap: () {},
            ),
          );
  }
}
