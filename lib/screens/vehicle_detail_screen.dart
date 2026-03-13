import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'property_list_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> ownedInstances = [];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  bool get isOwned => ownedInstances.isNotEmpty;

  Future<void> _loadVehicleData() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> instances = await db.rawQuery('''
      SELECT 
        ov.id as ownedId, 
        ov.consecutive,
        ov.tag,
        p.name as garageName,
        ovp.slotNumb
      FROM owned_vehicles ov
      LEFT JOIN ownedVehicles_properties ovp ON ov.id = ovp.idOVeh
      LEFT JOIN owned_properties op ON ovp.idOProp = op.id
      LEFT JOIN properties p ON op.idProp = p.id
      WHERE ov.idVeh = ?
    ''', [widget.vehicle.id]);

    setState(() {
      ownedInstances = instances;
      widget.vehicle.isOwned = instances.isNotEmpty;
      isLoading = false;
    });
  }

  void _addNewInstance() async {
    await DatabaseHelper.instance.purchaseVehicle(widget.vehicle.id);
    _loadVehicleData();
  }

  Future<void> _removeInstance(int ownedId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('owned_vehicles', where: 'id = ?', whereArgs: [ownedId]);
    await _loadVehicleData();
  }

  final Map<String, String> shopNames = {
    'arena': 'Arena War',
    'bennys': "Benny's Original Motor Works",
    'bennysConversion': "Benny's (Conversión)",
    'docktease': 'DockTease',
    'elitas': 'Elitas Travel',
    'lm': 'Legendary Motorsport',
    'pedal': 'Pedal and Metal',
    'ssasa': 'Southern San Andreas Super Autos',
    'warstock': 'Warstock Cache & Carry',
    'notAvailable': 'No Disponible',
    'notAvailableLm': 'Eliminado - Legendary Motorsport',
    'notAvailableSsasa': 'Eliminado - SSASA',
    'notAvailableWarstock': 'Eliminado - Warstock',
    'specialAcidLab': 'Laboratorio de Ácido',
    'specialArenaRewards': 'Recompensa de Arena War',
    'specialBdb': 'Bottom Dollar Bounties',
    'specialBunker': 'Compra con el Búnker',
    'specialCareerProgress': 'Progreso de Carrera',
    'specialCasinoMissions': 'Misiones del Casino',
    'specialCasinoReward': 'Premio del Casino',
    'specialClub': 'Premio del Club de LS',
    'specialMoc': 'Centro de Operaciones Móvil',
    'specialOnlyStolen': 'Solo Robado (Calle)',
    'unknown': 'Desconocido',
  };

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topHeader(),
              const SizedBox(height: 24),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _image(),
                          const SizedBox(height: 16),
                          if (isOwned) _quantityBox(),
                          const SizedBox(height: 16),
                          _priceBar(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: _rightDataTable()),
                  ],
                )
              else
                Column(
                  children: [
                    _image(),
                    const SizedBox(height: 16),
                    if (isOwned) _quantityBox(),
                    const SizedBox(height: 16),
                    _priceBar(),
                    const SizedBox(height: 24),
                    _rightDataTable(),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
    final String brandKey = widget.vehicle.manufacturer
        .toLowerCase()
        .replaceAll(' ', '')
        .trim();
    return Row(
      children: [
        if (widget.vehicle.manufacturer.isNotEmpty)
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/manufacturers/$brandKey.png',
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) =>
                  const Icon(Icons.business, color: Colors.white24, size: 50),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.vehicle.manufacturer.isNotEmpty)
                Text(
                  widget.vehicle.manufacturer.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 20,
                    fontFamily: 'Pricedown',
                  ),
                ),
              Text(
                widget.vehicle.getLocalizedName(context),
                style: const TextStyle(
                  fontSize: 54,
                  color: Colors.white,
                  fontFamily: 'Pricedown',
                  height: 0.9,
                ),
              ),
            ],
          ),
        ),
        _actionButtons(),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        _buildIconStatus(
          label: "Obtenido",
          child: Switch(
            value: isOwned,
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            onChanged: (val) {
              if (val) {
                _addNewInstance();
              } else {
                for (var inst in ownedInstances) {
                  _removeInstance(inst['ownedId']);
                }
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        _buildIconStatus(
          label: "Favorito",
          child: IconButton(
            icon: Icon(
              widget.vehicle.isWishlisted
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: widget.vehicle.isWishlisted ? const Color.fromARGB(255, 255, 255, 255) : Colors.white,
            ),
            onPressed: () => setState(
              () => widget.vehicle.isWishlisted = !widget.vehicle.isWishlisted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconStatus({required String label, required Widget child}) {
    return Column(
      children: [
        child,
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Chalet'),
        ),
      ],
    );
  }

  Widget _image() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white12),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          widget.vehicle.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Center(
            child: Icon(Icons.directions_car, color: Colors.white10, size: 60),
          ),
        ),
      ),
    );
  }

  Widget _quantityBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.white12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                "Cantidad",
                style: TextStyle(color: Colors.white54, fontSize: 24, fontFamily: 'HouseScript'),
              ),
              const SizedBox(width: 16),
              _qtyButton('-', () {
                if (ownedInstances.isNotEmpty) {
                  _removeInstance(ownedInstances.last['ownedId']);
                }
              }),
              SizedBox(
                width: 40,
                child: Text(
                  ownedInstances.length.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Pricedown'),
                ),
              ),
              _qtyButton('+', _addNewInstance),
            ],
          ),
          if (ownedInstances.isNotEmpty)
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PropertyListScreen(),
                  ),
                );
              },
              child: const Text(
                'Gestionar Ubicaciones',
                style: TextStyle(color: Colors.white70, fontFamily: 'Chalet'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white12,
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _priceBar() {
    final formatCurrency = NumberFormat('#,##0', 'en_US');

    final precioFormateado = formatCurrency.format(widget.vehicle.price);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.white12)),

      child: Text(
        'Precio Regular: \$$precioFormateado',
        style: const TextStyle(color: Color.fromARGB(216, 255, 245, 245), fontSize: 22, fontFamily: 'Pricedown'),
      ),
    );
  }

  Widget _rightDataTable() {
    final extras = widget.vehicle.extras ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del Vehículo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'HouseScript'
            ),
          ),
          const Divider(color: Colors.white12, height: 24),
          _dataRow('Modo de obtención:', _getObtainingContent()),
          _dataRow(
            'Categoría:',
            categoryNames[widget.vehicle.category] ?? widget.vehicle.category,
          ),
          _dataRow(
            'Mejora HSW:',
            extras.contains('hsw') ? 'Disponible (Hao\'s Special Works)' : 'No',
          ),
          _dataRow(
            'Mejora de Drift:',
            extras.contains('drift') ? 'Disponible en LS Car Meet' : 'No',
          ),
          _dataRow('Tecnología de Imani:', _getImaniContent()),
          _dataRow('Armamento:', _getWeaponryContent()),
          _dataRow(
            'Servicio Especial:',
            extras.contains('pegasus')
                ? 'Pegasus Lifestyle Management'
                : 'Entrega Personal',
          ),
          const SizedBox(height: 20),
          const Text(
            'En Propiedad:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'HouseScript'
            ),
          ),
          const SizedBox(height: 8),
          _garagesContent(),
        ],
      ),
    );
  }

  String _getImaniContent() {
    if (widget.vehicle.imaniTech == null || widget.vehicle.imaniTech!.isEmpty) {
      return "No disponible";
    }
    final labels = {
      "jammer": "Inhibidor de Misiles",
      "remote": "Control Remoto",
      "armor": "Blindaje Reforzado",
      "mines": "Minas de Proximidad",
    };
    return widget.vehicle.imaniTech!
        .map((t) => "• ${labels[t] ?? t}")
        .join("\n");
  }

  String _getObtainingContent() {
    if (widget.vehicle.obtaining == null || widget.vehicle.obtaining!.isEmpty) {
      return "No disponible";
    }
    return widget.vehicle.obtaining!.map((t) => shopNames[t] ?? t).join(', ');
  }

  String _getWeaponryContent() {
    final w = widget.vehicle.weaponry;
    if (w == null) return "Sin armamento";
    List<String> list = [];
    if (w.primary != null) list.add("• Principal: ${w.primary}");
    if (w.missileType != null) list.add("• Misiles: ${w.missileType}");
    if (w.mines != null) list.add("• Minas: ${w.mines}");
    if (w.special != null) list.add("• Especial: ${w.special}");
    return list.join("\n");
  }

  Widget _garagesContent() {
    if (ownedInstances.isEmpty) {
      return const Text(
        'No obtenido.',
        style: TextStyle(color: Colors.white54, fontSize: 15),
      );
    }

    return Column(
      children: ownedInstances.map((inst) {
        final int ownedId = inst['ownedId'];
        final String location = inst['garageName'] ?? 'Sin asignar';
        final String slot = inst['slotNumb'] != null
            ? ' - Slot ${inst['slotNumb']}'
            : '';
        final String label = inst['tag'] != null && inst['tag'].isNotEmpty
            ? inst['tag']
            : (inst['consecutive'] > 1
                  ? 'Unidad #${inst['consecutive']}'
                  : 'Unidad principal');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: 'Pricedown'
                      ),
                    ),
                    Text(
                      '$location$slot',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Chalet'
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.label_outline,
                  color: Colors.white54,
                  size: 20,
                ),
                onPressed: () => _showTagDialog(ownedId, inst['tag'] ?? ""),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _confirmDeleteInstance(ownedId, label),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTagDialog(int ownedId, String currentTag) {
  TextEditingController tagController = TextEditingController(text: currentTag);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      title: const Text(
        "ETIQUETA PERSONALIZADA",
        style: TextStyle(
          color: Color(0xFF39FF14),
          fontFamily: 'Pricedown',
          fontSize: 24,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Define un nombre o uso para esta unidad:",
            style: TextStyle(color: Colors.white70, fontFamily: 'Chalet'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: tagController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'Chalet'),
            decoration: const InputDecoration(
              hintText: "Ej: Drifting, De Paseo, Rally...",
              hintStyle: TextStyle(color: Colors.white24, fontFamily: 'Chalet'),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF39FF14)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CANCELAR",
            style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39FF14),
            foregroundColor: Colors.black,
          ),
          onPressed: () async {
            await DatabaseHelper.instance.updateVehicleTag(
              ownedId,
              tagController.text,
            );
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
            _loadVehicleData();
          },
          child: const Text(
            "GUARDAR",
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Chalet'),
          ),
        ),
      ],
    ),
  );
}

  void _confirmDeleteInstance(int ownedId, String label) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      title: const Text(
        "¿ELIMINAR VEHÍCULO?",
        style: TextStyle(
          color: Colors.redAccent,
          fontFamily: 'Pricedown',
          fontSize: 24,
        ),
      ),
      content: Text(
        "Se eliminará la $label de tu inventario.\n\nEsta acción NO se puede deshacer.",
        style: const TextStyle(color: Colors.white70, fontFamily: 'Chalet'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CANCELAR",
            style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            await _removeInstance(ownedId);
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
          child: const Text(
            "ELIMINAR",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Chalet',
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 20, fontFamily: 'HouseScript'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Chalet'),
            ),
          ),
        ],
      ),
    );
  }
}
