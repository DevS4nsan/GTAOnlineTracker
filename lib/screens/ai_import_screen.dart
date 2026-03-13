import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../database/database_helper.dart';

class AiImportScreen extends StatefulWidget {
  const AiImportScreen({super.key});

  @override
  State<AiImportScreen> createState() => _AiImportScreenState();
}

class _AiImportScreenState extends State<AiImportScreen> {
  final TextEditingController _jsonController = TextEditingController();
  List<Map<String, dynamic>> _catalogProperties = [];
  String? selectedGarageId;
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

  final String aiPrompt =
      """Rol: Eres un asistente experto en Grand Theft Auto Online. Tu tarea es analizar capturas de pantalla de los garajes del jugador y extraer la información.

Instrucciones:
1. Identifica el nombre del garaje/propiedad. Si no lo ves, usa "Desconocido".
2. Lista todos los vehículos en orden de aparición (este será su Slot).
3. Ignora los espacios que digan "Vacío" o "Disponible", pero respeta su número de posición (Slot).
4. Devuelve ÚNICAMENTE un bloque de código JSON válido, usando exactamente esta estructura de ejemplo:

{
  "garages": [
    {
      "garage_name": "Eclipse Towers",
      "slots": [
        {"slot": 1, "car_name": "Adder"},
        {"slot": 2, "car_name": "Zentorno"}
      ]
    }
  ]
}""";

  @override
  void initState() {
    super.initState();
    _loadPropertiesCatalog();
  }

  Future<void> _loadPropertiesCatalog() async {
    final String response = await rootBundle.loadString(
      'assets/data/properties.json',
    );
    final List<dynamic> data = json.decode(response);
    final List<String> upgradableTypes = ['Executive Offices', 'Retro Arcades', 'Casino Penthouse'];

    setState(() {
      _catalogProperties = data
          .where((e) => (e['capacity'] ?? 0) > 0 || upgradableTypes.contains(e['type']))
          .map((e) => {
                "id": e['id'],
                "name": e['name'],
                "type": e['type'],
                "capacity": e['capacity'] ?? 0,
              })
          .toList();

      _catalogProperties.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );
    });
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _processImport() async {
    if (_jsonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pega el código JSON primero."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.importFromAIGeneratedJSON(
        _jsonController.text,
        forcedPropertyId: selectedGarageId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Garaje importado mágicamente con éxito!"),
          backgroundColor: Color(0xFF39FF14),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error en el formato JSON. Asegúrate de copiarlo bien.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showExampleModal() {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isDesktop ? 800 : double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "EJEMPLO DE CAPTURAS VÁLIDAS",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/tutorial_ai.jpg',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 200,
                      color: const Color(0xFF1A1A1A),
                      child: const Center(
                        child: Text(
                          "Imagen no encontrada",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white70,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Cerrar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          children: [
            AiSparkles(size: 32),
            SizedBox(width: 12),
            Text(
              "IMPORTACION POR IA",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pricedown',
                fontSize: 32,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.orangeAccent, width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Función experimental. Puede fallar con vehículos especiales o modificados. Revisa tus garajes tras importar. Optimizada para idioma Español",
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 11,
                        fontFamily: 'Chalet',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: isDesktop ? 300 : double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFE0E0E0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  onPressed: _processImport,
                  child: const Text(
                    "Procesar Importacion",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Chalet',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildStepCard(
                step: "PASO 1",
                text: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                      fontFamily: 'Chalet',
                    ),
                    children: [
                      const TextSpan(
                        text:
                            "Toma captura de pantalla de la lista de vehículos de uno de tus garajes desde el menú del juego (puedes ver un ejemplo dando click al botón ",
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ),
                      const TextSpan(
                        text:
                            "), puedes tomarlas desde el Menú Interacción o llamando al Mecánico.",
                      ),
                    ],
                  ),
                ),
                leftIcon: Icons.photo_camera_outlined,
                actionIcon: Icons.image_outlined,
                onAction: _showExampleModal,
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                step: "PASO 2",
                text: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                      fontFamily: 'Chalet',
                    ),
                    children: [
                      const TextSpan(
                        text:
                            "Copia las siguientes instrucciones dando click al botón ",
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.content_copy,
                          color: Colors.white54,
                          size: 14,
                        ),
                      ),
                      const TextSpan(
                        text:
                            " y envíalas a Gemini, Chat GPT o tu IA preferida, junto con tus fotos de UN SOLO GARAJE a la vez.",
                      ),
                    ],
                  ),
                ),

                leftIcon: Icons.psychology_outlined,
                actionIcon: Icons.content_copy,
                onAction: () {
                  Clipboard.setData(ClipboardData(text: aiPrompt));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Instrucciones copiadas!")),
                  );
                },
                child: _buildPromptPreview(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildStepCard(
                step: "PASO 3",
                text:
                    "En caso que la IA no logre identificar el nombre del garaje brindado, selecciona el garaje donde se encuentran tus vehiculos, sabras que no se logró identificar si el campo 'garage_name' indica la palabra 'Desconocido'",
                leftIcon: Icons.location_city_outlined,
                child: _buildDropdown(),
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                step: "PASO 4",
                text: "Pega el código (JSON) proporcionado por la IA aquí:",
                leftIcon: Icons.integration_instructions_outlined,
                actionIcon: Icons.paste,
                onAction: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null && data.text != null) {
                    setState(() => _jsonController.text = data.text!);
                  }
                },
                child: _buildTextField(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildStepCard(
          step: "PASO 1",
          text: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
                fontFamily: 'sans-serif',
              ),
              children: [
                const TextSpan(
                  text:
                      "Toma captura de pantalla de la lista de vehículos de uno de tus garajes desde el menú del juego (puedes ver un ejemplo dando click al botón ",
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
                const TextSpan(
                  text:
                      "), puedes tomarlas desde el Menú Interacción o llamando al Mecánico.",
                ),
              ],
            ),
          ),
          leftIcon: Icons.photo_camera_outlined,
          actionIcon: Icons.image_outlined,
          onAction: _showExampleModal,
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          step: "PASO 2",
          text: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
                fontFamily: 'sans-serif',
              ),
              children: [
                const TextSpan(
                  text:
                      "Copia las siguientes instrucciones dando click al botón ",
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.content_copy,
                    color: Colors.white54,
                    size: 14,
                  ),
                ),
                const TextSpan(
                  text:
                      " y envíalas a Gemini, Chat GPT o tu IA preferida, junto con tus fotos de UN SOLO GARAJE a la vez...",
                ),
              ],
            ),
          ),

          leftIcon: Icons.psychology_outlined,
          actionIcon: Icons.content_copy,
          onAction: () {
            Clipboard.setData(ClipboardData(text: aiPrompt));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Instrucciones copiadas!")),
            );
          },
          child: _buildPromptPreview(),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          step: "PASO 3",
          text:
              "En caso que la IA no logre identificar el nombre del garaje brindado, selecciona el garaje donde se encuentran tus vehiculos, sabras que no se logró identificar si el campo 'garage_name' indica la palabra 'Desconocido'",
          leftIcon: Icons.location_city_outlined,
          child: _buildDropdown(),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          step: "PASO 4",
          text: "Pega el código (JSON) proporcionado por la IA aquí:",
          leftIcon:
              Icons.integration_instructions_outlined,
          actionIcon: Icons.paste,
          onAction: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data != null && data.text != null) {
              setState(() => _jsonController.text = data.text!);
            }
          },
          child: _buildTextField(),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required dynamic text,
    required IconData leftIcon,
    IconData? actionIcon,
    VoidCallback? onAction,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(leftIcon, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'HouseScript',
                      ),
                    ),
                    const SizedBox(height: 4),
                    text is String
                        ? Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                              fontFamily: 'Chalet',
                            ),
                          )
                        : text,
                  ],
                ),
              ),
              if (actionIcon != null)
                IconButton(
                  onPressed: onAction,
                  icon: Icon(actionIcon, color: Colors.white54, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 16), child],
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedGarageId,
          dropdownColor: const Color(0xFF1A1A1A),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          itemHeight: 60,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Row(
                children: [
                  AiSparkles(size: 18),
                  SizedBox(width: 10),
                  Text(
                    "Detección Automática (Recomendado)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            ..._catalogProperties.map(
              (p) {
                String typeKey = p['type'] as String;
                String translatedType = propertyTranslations[typeKey] ?? typeKey;
                int capacity = p['capacity'] as int;
                String capacityText = capacity > 0 ? "$capacity PLAZAS" : "REQUIERE EXPANSIÓN";

                return DropdownMenuItem(
                  value: p['id'] as String,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p['name'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${translatedType.toUpperCase()} • $capacityText",
                        style: const TextStyle(
                          color: Colors.white54, 
                          fontSize: 11, 
                          fontFamily: 'Chalet'
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],
          onChanged: (val) => setState(() => selectedGarageId = val),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _jsonController,
      maxLines: 8,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontFamily: 'Chalet',
      ),
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.black,
        hintText:
            '{\n  "garages": [\n    {\n      "garage_name": "Maze Bank West",\n      "slots": [\n        {"slot": 1, "car_name": "Zentorno"},\n        {"slot": 2, "car_name": "Adder"}\n      ]\n    }\n  ]\n}',
        hintStyle: TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildPromptPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        aiPrompt,
        maxLines: 40,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color:
              Colors.white38,
          fontSize: 12,
          fontFamily: 'Chalet',
        ),
      ),
    );
  }
}

class AiSparkles extends StatelessWidget {
  final double size;
  const AiSparkles({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.25,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: CustomPaint(
              size: Size(size * 0.85, size * 0.85),
              painter: _SparklePainter(color: Colors.white),
            ),
          ),
          Positioned(
            right: 0,
            bottom: size * 0.1,
            child: CustomPaint(
              size: Size(size * 0.45, size * 0.45),
              painter: _SparklePainter(color: Colors.white.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();

    final double w = size.width;
    final double h = size.height;

    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(w / 2, h / 2, w, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, h);
    path.quadraticBezierTo(w / 2, h / 2, 0, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
