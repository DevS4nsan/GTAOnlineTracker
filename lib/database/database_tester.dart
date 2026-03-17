import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseTester {
  static Future<void> runAllTests(BuildContext context) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    print("🚀 INICIANDO BATERÍA DE PRUEBAS UNITARIAS...");

    try {
      // 0. LIMPIEZA INICIAL
      await dbHelper.clearDatabaseForTesting();
      print("✅ DB Limpia para pruebas.");

      // ==========================================================
      // PRUEBA 1: REGALOS AUTOMÁTICOS Y RESTRICCIONES (NIGHTCLUB)
      // ==========================================================
      print("⏳ Prueba 1: Comprando Club Nocturno...");
      // Supongamos que el ID del catálogo de un Nightclub es 'clu_5201' (ajusta el ID si en tu JSON es distinto)
      int ncId = await dbHelper.addOwnedProperty('clu_5201'); 
      
      // Verificamos si regaló la Speedo Custom
      final speedoCheck = await db.query('owned_vehicles', where: 'idVeh = ?', whereArgs: ['vapid_speedo3']);
      assert(speedoCheck.isNotEmpty, "❌ FALLO: No se regaló la Speedo Custom");
      
      // Verificamos si se asignó automáticamente al espacio 1
      final speedoSlot = await db.query('ownedVehicles_properties', where: 'idOVeh = ? AND idOProp = ?', whereArgs: [speedoCheck.first['id'], ncId]);
      assert(speedoSlot.isNotEmpty && speedoSlot.first['slotNumb'] == 1, "❌ FALLO: Speedo Custom no se asignó al Slot 1");
      print("✅ Prueba 1 Pasada: Regalos y auto-asignaciones funcionan.");


      // ==========================================================
      // PRUEBA 2: TRADE-IN AUTOMÁTICO DE PROPIEDAD ÚNICA (OFICINAS)
      // ==========================================================
      print("⏳ Prueba 2: Trade-in de Oficinas...");
      // 1. Compra Maze Bank West
      // ignore: unused_local_variable
      int mazeBankId = await dbHelper.addOwnedProperty('off_13101');
      
      // 2. Compramos un auto normal y lo asignamos al slot 1
      int zentornoId = await dbHelper.purchaseVehicle('zentorno');
      await dbHelper.assignVehicleToSlot('off_13101', zentornoId, 1);
      
      // 3. Compramos una mejora (Garaje 1)
      await dbHelper.purchasePropertyUpgrade('off_13101', 'upg_ceo_gar1', 'Office Garage 1', 20);

      // 4. El usuario compra Arcadius (Trade-in automático)
      int arcadiusId = await dbHelper.addOwnedProperty('off_13201');

      // VERIFICACIONES
      final oldOffice = await db.query('owned_properties', where: 'idProp = ?', whereArgs: ['off_13101']);
      assert(oldOffice.isEmpty, "❌ FALLO: Maze Bank West no se borró");

      final newOffice = await db.query('owned_properties', where: 'idProp = ?', whereArgs: ['off_13201']);
      assert(newOffice.isNotEmpty, "❌ FALLO: Arcadius no se registró");

      final movedCar = await db.query('ownedVehicles_properties', where: 'idOVeh = ? AND idOProp = ?', whereArgs: [zentornoId, arcadiusId]);
      assert(movedCar.isNotEmpty, "❌ FALLO: El auto no se mudó a Arcadius");

      final movedUpgrade = await db.query('properties_upgrades', where: 'propertyId = ?', whereArgs: ['off_13201']);
      assert(movedUpgrade.isNotEmpty, "❌ FALLO: La mejora no se mudó a Arcadius");
      print("✅ Prueba 2 Pasada: Trade-in único perfecto.");

      print("⏳ Prueba 3: Autos Huérfanos y Recolector de Basura...");
      // 1. Compramos un departamento (Ej: Eclipse Towers 'apt_16001')
      await dbHelper.addOwnedProperty('apt_16001'); // Ajusta a un ID real de tu JSON
      
      // 2. Compramos un auto y lo asignamos
      int adderId = await dbHelper.purchaseVehicle('adder');
      await dbHelper.assignVehicleToSlot('apt_16001', adderId, 1);

      // 3. El usuario elimina el departamento por error
      await dbHelper.removeOwnedProperty('apt_16001');

      // VERIFICACIONES
      final adderCheck = await db.query('owned_vehicles', where: 'id = ?', whereArgs: [adderId]);
      assert(adderCheck.isNotEmpty, "❌ FALLO: El auto se borró de la existencia (No debería pasar)");

      final ghostLink = await db.query('ownedVehicles_properties', where: 'idOVeh = ?', whereArgs: [adderId]);
      assert(ghostLink.isEmpty, "❌ FALLO: El auto sigue conectado a un garaje fantasma. Falló el Recolector de Basura.");
      print("✅ Prueba 3 Pasada: Recolector de basura libera a los autos.");

      // ==========================================================
      // FIN DE LAS PRUEBAS
      // ==========================================================
      print("🎉 ¡TODAS LAS PRUEBAS UNITARIAS FUERON EXITOSAS! TU BASE DE DATOS ES INDESTRUCTIBLE.");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pruebas Unitarias Pasadas con Éxito"), backgroundColor: Color(0xFF39FF14)),
        );
      }

    } catch (e) {
      print("🚨 ERROR EN LAS PRUEBAS: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🚨 Falló una prueba: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}