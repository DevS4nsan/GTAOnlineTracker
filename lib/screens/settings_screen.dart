import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
// import '../database/database_tester.dart'; <-- FOR UNIT TEST SECTION
import '../screens/ai_import_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'about_support_screen.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isGridViewDefault = true;
  //REAL UPDATES
  bool _updateAvailable = false;
  String _newVersion = "";
  String _updateNotes = "";
  String _updateUrl = "";

  //TESTING UPDATES
  /*
  bool _updateAvailable = true; // <--- FORZADO A TRUE PARA VER EL EFECTO
  String _newVersion = "1.1.0";
  String _updateNotes =
      "¡Prueba de actualización forzada!\n- Nuevos filtros\n- Búsqueda global";
  String _updateUrl = "https://github.com";
  */

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _silentCheckForUpdates();
  }

  Future<void> _silentCheckForUpdates() async {
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/version.json',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['latest_version'] != "1.0.0") {
          // Tu versión actual
          if (mounted) {
            setState(() {
              _updateAvailable = true;
              _newVersion = data['latest_version'];
              _updateNotes = data['release_notes'];
              _updateUrl = data['download_url'];
            });
          }
        }
      }
    } catch (e) {
      // IF FAILS, STILL UPDATED
    }
  }


  void _showUpdateDialog(String version, String notes, String url) {
    showDialog(
      context: context,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "CANCELAR",
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridViewDefault = prefs.getBool('property_view_is_grid') ?? true;
    });
  }

  Future<void> _toggleGridView(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('property_view_is_grid', value);
    setState(() {
      _isGridViewDefault = value;
    });
  }

  void _confirmWipeData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "¡ADVERTENCIA!",
          style: TextStyle(
            color: Colors.redAccent,
            fontFamily: 'Pricedown',
            fontSize: 28,
          ),
        ),
        content: const Text(
          "¿Estás seguro de que quieres borrar todo tu progreso?\n\nSe eliminarán todos tus vehículos, propiedades y asignaciones. Esta acción NO se puede deshacer.",
          style: TextStyle(color: Colors.white70, fontFamily: 'Chalet'),
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
              Navigator.pop(context);
              await DatabaseHelper.instance.clearDatabaseForTesting();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Datos borrados con éxito."),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text(
              "BORRAR TODO",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: const Row(
          children: [
            Icon(Icons.settings_outlined, color: Colors.white, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                "CONFIGURACIÓN Y RESPALDO",
                style: TextStyle(
                  fontFamily: 'Pricedown',
                  fontSize: 26,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionTitle("Preferencias de Interfaz"),
          _buildSettingsTile(
            icon: Icons.grid_view,
            title: "Vista de Garajes",
            subtitle: "Usar cuadrícula en lugar de lista por defecto",
            trailing: Switch(
              value: _isGridViewDefault,
              activeColor: const Color(0xFF39FF14),
              onChanged: _toggleGridView,
            ),
          ),
          const Divider(color: Colors.white10, height: 40),

          _buildSectionTitle("Gestión de Datos"),
          _buildSettingsTile(
            icon: Icons.upload_file,
            title: "Exportar Progreso (Backup)",
            subtitle: "Guarda un archivo con todos tus autos y propiedades",
            onTap: _exportBackup,
          ),
          _buildSettingsTile(
            icon: Icons.download_outlined,
            title: "Importar Progreso",
            subtitle: "Restaura tus datos",
            onTap: _importBackup, 
          ),
          _buildSettingsTile(
            icon: Icons.auto_awesome,
            title: "Importación por IA",
            subtitle: "Pega el análisis de una captura de pantalla",
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                border: Border.all(color: Colors.orangeAccent),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "BETA",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Chalet',
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiImportScreen()),
              );
            },
          ),

          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: "Borrar todos los datos",
            subtitle: "Elimina tu inventario local por completo",
            isDestructive: true,
            onTap: _confirmWipeData,
          ),
          const Divider(color: Colors.white10, height: 40),

          _buildSectionTitle("Información del Sistema"),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: "Versión de la Aplicación",
            subtitle: "v1.0.0 (Toca para opciones)",
            trailing: Text(
              _updateAvailable ? "ACTUALIZACIÓN DISPONIBLE" : "ACTUALIZADA",
              style: TextStyle(
                color: _updateAvailable
                    ? Colors.orangeAccent
                    : const Color.fromARGB(255, 0, 221, 37),
                fontSize: _updateAvailable
                    ? 11
                    : 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'HouseScript',
              ),
            ),
            onTap: () {
              if (_updateAvailable) {
                _showUpdateDialog(_newVersion, _updateNotes, _updateUrl);
              } else {
                
              }
            },
          ),
          const SizedBox(height: 24),

          _buildSettingsTile(
            icon: Icons.favorite_border,
            title: "Conoce el Proyecto",
            subtitle: "Créditos, soporte y contacto",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutSupportScreen(),
                ),
              );
            },
          ),

          // --- UNIT TEST BUTTON, COMMENT THIS ON PRODUCTION ---
          /*_buildSectionTitle("Herramientas de Desarrollador"),
          _buildSettingsTile(
            icon: Icons.bug_report,
            title: "Ejecutar Pruebas Unitarias",
            subtitle: "Simula escenarios extremos en la base de datos",
            trailing: const Text("DEV", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              // 1. Avisamos que va a empezar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ejecutando pruebas en consola..."))
              );
              
              // 2. Corremos el script
              await DatabaseTester.runAllTests(context);
              
              // 3. Recargamos los contadores si tienes
              if (mounted) {
                setState(() {});
              }
            },
          ),*/
          const Divider(color: Colors.white10, height: 40),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              "DESCARGO DE RESPONSABILIDAD:\n\nEsta es una aplicación no oficial creada por fans. No está afiliada, asociada, autorizada, respaldada ni conectada oficialmente de ninguna manera con Rockstar Games, Take-Two Interactive, o cualquiera de sus subsidiarias o afiliadas.\n\nGrand Theft Auto V y Grand Theft Auto Online son marcas registradas de Take-Two Interactive.",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.5,
                fontFamily: 'Chalet',
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'HouseScript',
      ),
    ),
  );

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'Chalet',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontFamily: 'Chalet',
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _exportBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF39FF14)),
        ),
      ),
    );

    try {
      String backupJson = await DatabaseHelper.instance.createFullBackupJson();
      final date = DateTime.now().toString().split(' ')[0];
      final fileName = "GTA_Tracker_Backup_$date.json";

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Selecciona dónde guardar tu respaldo',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(backupJson);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Respaldo guardado exitosamente"),
                backgroundColor: Color(0xFF39FF14),
              ),
            );
          }
        }
      } else {
        await Share.shareXFiles([
          XFile.fromData(
            utf8.encode(backupJson),
            mimeType: 'application/json',
            name: fileName,
          ),
        ], subject: 'Respaldo de mi progreso en GTA Online Tracker');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al exportar: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _importBackup() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "RESTAURAR RESPALDO",
          style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Pricedown'),
        ),
        content: const Text(
          style: TextStyle(fontFamily: 'Chalet'),
          "Si restauras un archivo, perderás todos los datos actuales de la aplicación. ¿Deseas continuar?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "IMPORTAR",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Chalet',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF39FF14)),
          ),
        ),
      );
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        await DatabaseHelper.instance.restoreFromFullBackup(content);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Progreso restaurado con éxito!"),
            backgroundColor: Color.fromARGB(255, 43, 194, 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al importar: El archivo no es válido."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
