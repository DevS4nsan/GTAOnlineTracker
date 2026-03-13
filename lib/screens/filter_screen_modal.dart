import 'package:flutter/material.dart';
import '../models/vehicle_filter.dart';
import 'package:intl/intl.dart';

class FilterScreenModal extends StatefulWidget {
  final VehicleFilter initialFilter;

  const FilterScreenModal({super.key, required this.initialFilter});

  @override
  State<FilterScreenModal> createState() => _FilterScreenModalState();
}

class _FilterScreenModalState extends State<FilterScreenModal> {
  late String _selectedSort;
  late String _sortOrder;
  late String _obtainedFilter;
  late RangeValues _priceRange;
  late String _selectedCategory;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  bool _showAllCategories = false;

  late bool _imaniTech;
  late bool _hasWeapons;
  late bool _removedFromWeb;
  late bool _hasHSW;
  late bool _hasDrift;
  late bool _isWishlisted;

  final Map<String, String> categoryNames = {
    'All': 'Todas',
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
  };

  final List<String> _categoryKeys = [
    'All',
    'Super',
    'Sport',
    'Sport_classic',
    'Muscle',
    'Off_road',
    'Sedan',
    'Coupe',
    'Suv',
    'Compact',
    'Motorcycle',
    'Cycle',
    'Open_wheel',
    'Van',
    'Commercial',
    'Industrial',
    'Utility',
    'Service',
    'Emergency',
    'Military',
    'Plane',
    'Helicopter',
    'Boat',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialFilter.selectedSort;
    _sortOrder = widget.initialFilter.sortOrder;
    _obtainedFilter = widget.initialFilter.obtainedFilter;
    _priceRange = widget.initialFilter.priceRange;
    _selectedCategory = widget.initialFilter.selectedCategory;
    _imaniTech = widget.initialFilter.imaniTech;
    _hasWeapons = widget.initialFilter.hasWeapons;
    _removedFromWeb = widget.initialFilter.isRemoved;
    _hasHSW = widget.initialFilter.hasHSW;
    _hasDrift = widget.initialFilter.hasDrift;
    _isWishlisted = widget.initialFilter.isWishlisted;
    _minPriceController = TextEditingController(
      text: _formatter.format(_priceRange.start.toInt()),
    );
    _maxPriceController = TextEditingController(
      text: _formatter.format(_priceRange.end.toInt()),
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),

          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Opciones de Ordenamiento"),
                      const SizedBox(height: 15),
                      _buildSortGrid(),
                      const SizedBox(height: 10),
                      _buildOrderButtons(),

                      const Divider(color: Colors.white12, height: 40),

                      _sectionTitle("Filtros"),
                      const SizedBox(height: 15),

                      _subHeaderWithLine("Propiedad"),
                      const SizedBox(height: 10),
                      _buildOwnershipGrid(),

                      const SizedBox(height: 20),
                      _subHeaderWithLine("Categoría"),
                      const SizedBox(height: 15),

                      _buildCategoryGrid(width),

                      const SizedBox(height: 20),
                      _subHeaderWithLine("Rango de Precio"),
                      _buildPriceSlider(context),

                      const SizedBox(height: 20),
                      _subHeaderWithLine("Filtros Especiales"),
                      const SizedBox(height: 15),
                      _buildSpecialSwitches(),

                      const SizedBox(height: 40),
                      _buildApplyButton(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int columns = (width / 140).floor();
        if (columns < 2)
          columns = 2;
        final double spacing = 10.0;
        final double itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "filtros",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pricedown',
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  "Reestablecer Filtros",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  Widget _buildSortGrid() {
    return _buildDynamicGrid([
      _selectableBox(
        "Nombre",
        _selectedSort == "Name",
        () => setState(() => _selectedSort = "Name"),
      ),
      _selectableBox(
        "Precio",
        _selectedSort == "Price",
        () => setState(() => _selectedSort = "Price"),
      ),
      _selectableBox(
        "Categoría",
        _selectedSort == "Category",
        () => setState(() => _selectedSort = "Category"),
      ),
      // FOR FUTURE _selectableBox("DLC", _selectedSort == "DLC", () => setState(() => _selectedSort = "DLC")),
    ]);
  }

  Widget _buildOrderButtons() {
    return _buildDynamicGrid([
      _selectableBox(
        "Ascendente",
        _sortOrder == "Ascending",
        () => setState(() => _sortOrder = "Ascending"),
      ),
      _selectableBox(
        "Descendente",
        _sortOrder == "Descending",
        () => setState(() => _sortOrder = "Descending"),
      ),
    ]);
  }

  Widget _buildOwnershipGrid() {
    return _buildDynamicGrid([
      _selectableBox(
        "Todos",
        _obtainedFilter == "All",
        () => setState(() => _obtainedFilter = "All"),
      ),
      _selectableBox(
        "Obtenidos",
        _obtainedFilter == "Obtained",
        () => setState(() => _obtainedFilter = "Obtained"),
      ),
      _selectableBox(
        "No Obtenidos",
        _obtainedFilter == "Unobtained",
        () => setState(() => _obtainedFilter = "Unobtained"),
      ),
    ]);
  }

  Widget _buildCategoryGrid(double width) {
    int columns = (width / 140).floor();
    if (columns < 2) columns = 2;
    int maxItemsToShow = _showAllCategories
        ? _categoryKeys.length
        : columns - 1;
    List<Widget> gridItems = [];
    for (int i = 0; i < maxItemsToShow && i < _categoryKeys.length; i++) {
      String catKey = _categoryKeys[i];
      gridItems.add(
        _selectableBox(
          categoryNames[catKey] ?? catKey,
          _selectedCategory == catKey,
          () => setState(() => _selectedCategory = catKey),
        ),
      );
    }

    if (!_showAllCategories) {
      gridItems.add(
        _selectableBox(
          "...",
          false,
          () => setState(() => _showAllCategories = true),
          isSpecialAction: true,
        ),
      );
    } else {
      gridItems.add(
        _selectableBox(
          "^",
          false,
          () => setState(() => _showAllCategories = false),
          isSpecialAction: true,
        ),
      );
    }

    return _buildDynamicGrid(gridItems);
  }

  Widget _buildSpecialSwitches() {
    return _buildDynamicGrid([
      _selectableBox(
        "Favoritos",
        _isWishlisted,
        () => setState(() => _isWishlisted = !_isWishlisted),
      ),
      _selectableBox(
        "Tecnología de Imani",
        _imaniTech,
        () => setState(() => _imaniTech = !_imaniTech),
      ),
      _selectableBox(
        "Tiene armas",
        _hasWeapons,
        () => setState(() => _hasWeapons = !_hasWeapons),
      ),
      _selectableBox(
        "Mejora de Hao",
        _hasHSW,
        () => setState(() => _hasHSW = !_hasHSW),
      ),
      _selectableBox(
        "Mejora de Drift",
        _hasDrift,
        () => setState(() => _hasDrift = !_hasDrift),
      ),
      _selectableBox(
        "Eliminado de Tiendas",
        _removedFromWeb,
        () => setState(() => _removedFromWeb = !_removedFromWeb),
      ),
    ]);
  }

  Widget _buildPriceSlider(BuildContext context) {
    return Column(
      children: [
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 10000000,
          activeColor: Colors.white,
          inactiveColor: Colors.white12,
          onChanged: (val) {
            setState(() {
              _priceRange = val;
              _minPriceController.text = _formatter.format(val.start.toInt());
              _maxPriceController.text = _formatter.format(val.end.toInt());
            });
          },
        ),
        Row(
          children: [
            Expanded(child: _buildEditablePriceBox(_minPriceController, true)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text("-", style: TextStyle(color: Colors.white)),
            ),
            Expanded(child: _buildEditablePriceBox(_maxPriceController, false)),
          ],
        ),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () {
          final result = VehicleFilter(
            selectedSort: _selectedSort,
            sortOrder: _sortOrder,
            obtainedFilter: _obtainedFilter,
            priceRange: _priceRange,
            selectedCategory: _selectedCategory,
            imaniTech: _imaniTech,
            hasWeapons: _hasWeapons,
            isRemoved: _removedFromWeb,
            hasHSW: _hasHSW,
            hasDrift: _hasDrift,
            isWishlisted: _isWishlisted,
          );
          Navigator.pop(context, result);
        },
        child: const Text(
          "APPLY FILTERS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildEditablePriceBox(TextEditingController controller, bool isMin) {
    return SizedBox(
      height: 45,
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            _validateAndApplyPrice(controller.text, isMin, controller);
          }
        },
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: const TextStyle(color: Colors.white54, fontSize: 13),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          onSubmitted: (value) {
            _validateAndApplyPrice(value, isMin, controller);
          },
        ),
      ),
    );
  }

  void _validateAndApplyPrice(
    String input,
    bool isMin,
    TextEditingController controller,
  ) {
    String cleanInput = input.replaceAll(',', '').replaceAll('\$', '').trim();
    double? parsedValue = double.tryParse(cleanInput);
    if (parsedValue == null) {
      parsedValue = isMin ? 0 : 10000000;
    }

    setState(() {
      if (isMin) {
        double validMin = parsedValue!.clamp(0.0, _priceRange.end);
        _priceRange = RangeValues(validMin, _priceRange.end);
        controller.text = validMin.toInt().toString();
      } else {
        double validMax = parsedValue!.clamp(_priceRange.start, 10000000.0);
        _priceRange = RangeValues(_priceRange.start, validMax);
        controller.text = validMax.toInt().toString();
      }
    });
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 22,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _subHeaderWithLine(String title) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: Colors.white12)),
    ],
  );

  Widget _selectableBox(
    String text,
    bool isSelected,
    VoidCallback onTap, {
    bool isSpecialAction = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : (isSpecialAction ? Colors.white10 : Colors.white24),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : (isSpecialAction ? Colors.white54 : Colors.white70),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedSort = "Name";
      _sortOrder = "Ascending";
      _obtainedFilter = "All";
      _priceRange = const RangeValues(0, 10000000);
      _selectedCategory = "All";
      _imaniTech = false;
      _hasWeapons = false;
      _removedFromWeb = false;
      _hasHSW = false;
      _hasDrift = false;
      _isWishlisted = false;
      _minPriceController.text = "0";
      _maxPriceController.text = "10000000";
    });
  }
}
