import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/game_rules.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // DOUBLE IDENTITY REGISTRY (VEHICLE <-> PROPERTY)
  static const Map<String, String> _dualIdentityRegistry = {
    'rune_kosatka': 'lvp_4001',
    'benefactor_terbyte': 'lvp_4201',
    'mammoth_avenger': 'lvp_4101',
    'trailerlarge': 'lvp_4301',
    'mtl_brickade2': 'lvp_3001',
  };

  // SLOTS FOR SPECIAL WAREHOUSE VEHICLES
  static const Map<String, int> _specialWarehouseSlots = {
    'jobuilt_phantom2': 1,
    'imponte_ruiner2': 2,
    'coil_voltic2': 3,
    'nagasaki_blazer5': 4,
    'karin_technical2': 5,
    'mtl_wastelander': 6,
    'boxville2': 7,
    'dune4': 8,
  };

  // SLOTS FOR FACILITY VEHICLES
  static const Map<String, int> _facilitySpecialSlots = {
    'khanjali': 9,
    'chernobog': 10,
    'riot2': 11,
    'mammoth_thruster': 12,
  };

  // SLOTS FOR NIGHTCLUB VEHICLES
  static const Map<String, int> _nightclubSpecialSlots = {
    'vapid_speedo3': 1,
    'maibatsu_mule3': 2,
    'mtl_pounder2': 3,
    'benefactor_terbyte': 4,
  };

  // SLOTS FOR BUNKER VEHICLES
  static const Map<String, int> _bunkerSpecialSlots = {
    'vomfeuer_trailersmall2': 1,
    'trailerlarge': 2,
    'caddy': 3,
  };

  // SLOTS FOR KOSATKA-RELATED VEHICLES
  static const Map<String, Map<String, dynamic>> _kosatkaRegistry = {
    'seasparrow2': {'prop': 'lvp_4001', 'slot': 1},
    'kraken_avisa': {'prop': 'lvp_4001', 'slot': 2},
    'pegassi_toreador': {'prop': 'lvp_4001', 'slot': 3},
  };

  // SLOTS FOR TERRORBYTE-RELATED VEHICLES
  static const Map<String, Map<String, dynamic>> _terbyteRegistry = {
    'pegassi_oppressor2': {'prop': 'lvp_4201', 'slot': 1},
  };

  // SLOTS FOR ACIDLAB-RELATED VEHICLES
  static const Map<String, Map<String, dynamic>> _acidlabRegistry = {
    'maibatsu_manchez3': {'prop': 'lvp_3001', 'slot': 1},
  };

  // SLOTS FOR ARENA WAR VEHICLES
  static const Map<String, int> _arenaSpecialSlots = {'rcbandito': 11};

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gtaoTracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // MASTER PROPERTY CATALOG
    await db.execute('''
      CREATE TABLE properties (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL DEFAULT 0,
        isLargeVeh INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // MASTER PROPERTY UPGRADES CATALOG
    await db.execute('''
      CREATE TABLE properties_upgrades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        propertyId TEXT NOT NULL,
        upgradeType TEXT NOT NULL,
        level INTEGER DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (propertyId) REFERENCES properties (id) ON DELETE CASCADE
      )
    ''');

    // MASTER VEHICLE CATALOG
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        manufacturer TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        image TEXT,
        storageType TEXT,
        isLargeVeh INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // OBTAINED PROPERTIES BY THE USER
    await db.execute('''
      CREATE TABLE owned_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idProp TEXT NOT NULL,
        slots INTEGER NOT NULL DEFAULT 0,
        slotType TEXT,
        idPropUp INTEGER,
        specStorage TEXT,
        isVirtual INTEGER NOT NULL DEFAULT 0,
        consecutive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (idProp) REFERENCES properties (id),
        FOREIGN KEY (idPropUp) REFERENCES properties_upgrades (id)
      )
    ''');

    // OBTAINED VEHICLES BY THE USER
    await db.execute('''
      CREATE TABLE owned_vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idVeh TEXT NOT NULL,
        consecutive INTEGER NOT NULL DEFAULT 1,
        tag TEXT,
        FOREIGN KEY (idVeh) REFERENCES vehicles (id)
      )
    ''');

    // OWNED VEHICLES ASSIGNED TO PROPERTIES
    await db.execute('''
      CREATE TABLE ownedVehicles_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idOVeh INTEGER NOT NULL,
        idOProp INTEGER NOT NULL,
        slotNumb INTEGER NOT NULL,
        FOREIGN KEY (idOVeh) REFERENCES owned_vehicles (id) ON DELETE CASCADE,
        FOREIGN KEY (idOProp) REFERENCES owned_properties (id) ON DELETE CASCADE
      )
    ''');

    // WISHLISTED VEHICLES
    await db.execute('''
      CREATE TABLE wishlisted_vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idVeh TEXT NOT NULL,
        FOREIGN KEY (idVeh) REFERENCES vehicles (id)
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final String propsJson = await rootBundle.loadString(
      'assets/data/properties.json',
    );
    final List<dynamic> propsData = json.decode(propsJson);

    await db.transaction((txn) async {
      for (var p in propsData) {
        await txn.insert('properties', {
          'id': p['id'],
          'type': p['type'],
          'name': p['name'],
          'capacity': p['capacity'] ?? 0,
          'isLargeVeh': (p['isLargeVeh'] ?? false) ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    final String vehsJson = await rootBundle.loadString(
      'assets/data/vehicles.json',
    );

    final List<dynamic> vehsData = json.decode(vehsJson);
    await db.transaction((txn) async {
      for (var v in vehsData) {
        final bool large =
            (v['extras'] is List) && v['extras'].contains('isLargeVeh');
        await txn.insert('vehicles', {
          'id': v['id'],
          'manufacturer': v['manufacturer'],
          'name': v['name'],
          'category': v['category'],
          'image': v['image'],
          'storageType': v['storageType'],
          'isLargeVeh': large ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      print("Actualizando base de datos a la versión " + newVersion.toString());
      await _seedData(db);
    }
  }

  Future<int> purchaseVehicle(
    String vehicleId, {
    bool isSystemAction = false,
  }) async {
    if ((vehicleId == 'maibatsu_manchez3' || vehicleId == 'vapid_speedo3') &&
        !isSystemAction) {
      throw Exception(
        "Este vehículo se obtiene comprando su respectiva propiedad.",
      );
    }

    final db = await instance.database;

    // 1. DUPLICATED VEHICLE CHECK
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM owned_vehicles WHERE idVeh = ?',
      [vehicleId],
    );
    int nextConsecutive = (countResult.first['total'] as int) + 1;

    final int ownedVehId = await db.insert('owned_vehicles', {
      'idVeh': vehicleId,
      'consecutive': nextConsecutive,
    });

    await db.delete(
      'wishlisted_vehicles',
      where: 'idVeh = ?',
      whereArgs: [vehicleId],
    );

    // 2. DOUBLE IDENTITY CHECK (VEHICLE <-> PROPERTY)
    if (_dualIdentityRegistry.containsKey(vehicleId)) {
      final String twinPropId = _dualIdentityRegistry[vehicleId]!;

      final List<Map<String, dynamic>> checkProp = await db.query(
        'owned_properties',
        where: 'idProp = ?',
        whereArgs: [twinPropId],
        limit: 1,
      );

      if (checkProp.isEmpty) {
        print("Doble Identidad: Auto-comprando propiedad $twinPropId");
        await addOwnedProperty(twinPropId);
      }
    }

    // 3. IS SPECIAL WAREHOUSE VEHICLE
    if (_specialWarehouseSlots.containsKey(vehicleId)) {
      final List<Map<String, dynamic>> ownedWarehouse = await db.rawQuery('''
      SELECT op.id 
      FROM owned_properties op
      JOIN properties p ON op.idProp = p.id
      WHERE p.type = 'Vehicle Warehouses'
      LIMIT 1
    ''');

      if (ownedWarehouse.isNotEmpty) {
        final int targetSlot = _specialWarehouseSlots[vehicleId]!;
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedWarehouse.first['id'],
          'slotNumb': targetSlot,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        print("Auto-asignado $vehicleId al slot $targetSlot del Almacén");
      }
    }

    // 4. IS KOSATKA-RELATED VEHICLE
    if (_kosatkaRegistry.containsKey(vehicleId)) {
      final String targetPropId = _kosatkaRegistry[vehicleId]!['prop'];
      final int targetSlot = _kosatkaRegistry[vehicleId]!['slot'];
      final List<Map<String, dynamic>> ownedKosatka = await db.query(
        'owned_properties',
        where: 'idProp = ?',
        whereArgs: [targetPropId],
        limit: 1,
      );

      if (ownedKosatka.isNotEmpty) {
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedKosatka.first['id'],
          'slotNumb': targetSlot,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        print("Auto-asignado $vehicleId al Kosatka (Slot $targetSlot)");
      }
    }

    // 5. IS TERRORBYTE-RELATED VEHICLE
    if (_terbyteRegistry.containsKey(vehicleId)) {
      final String targetPropId = _terbyteRegistry[vehicleId]!['prop'];
      final int targetSlot = _terbyteRegistry[vehicleId]!['slot'];
      final List<Map<String, dynamic>> ownedKosatka = await db.query(
        'owned_properties',
        where: 'idProp = ?',
        whereArgs: [targetPropId],
        limit: 1,
      );

      if (ownedKosatka.isNotEmpty) {
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedKosatka.first['id'],
          'slotNumb': targetSlot,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        print("Auto-asignado $vehicleId al Terrorbyte (Slot $targetSlot)");
      }
    }

    // 6. IS ACIDLAB-RELATED VEHICLE
    if (_acidlabRegistry.containsKey(vehicleId)) {
      final String targetPropId = _acidlabRegistry[vehicleId]!['prop'];
      final int targetSlot = _acidlabRegistry[vehicleId]!['slot'];
      final List<Map<String, dynamic>> ownedKosatka = await db.query(
        'owned_properties',
        where: 'idProp = ?',
        whereArgs: [targetPropId],
        limit: 1,
      );

      if (ownedKosatka.isNotEmpty) {
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedKosatka.first['id'],
          'slotNumb': targetSlot,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        print(
          "Auto-asignado $vehicleId al Laboratorio de Acido (Slot $targetSlot)",
        );
      }
    }

    // 7. IS FACILITY SPECIAL VEHICLE
    if (_facilitySpecialSlots.containsKey(vehicleId)) {
      final List<Map<String, dynamic>> ownedFacility = await db.rawQuery('''
        SELECT op.id 
        FROM owned_properties op
        JOIN properties p ON op.idProp = p.id
        WHERE p.type = 'Facilities'
        LIMIT 1
      ''');

      if (ownedFacility.isNotEmpty) {
        final int targetSlot = _facilitySpecialSlots[vehicleId]!;
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedFacility.first['id'],
          'slotNumb': targetSlot,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        print(
          "Auto-asignado $vehicleId al slot $targetSlot de las Instalaciones",
        );
      }
    }

    // 8. IS NIGHTCLUB SPECIAL VEHICLE
    if (_nightclubSpecialSlots.containsKey(vehicleId)) {
      final List<Map<String, dynamic>> ownedNightclub = await db.rawQuery(
        "SELECT op.id FROM owned_properties op JOIN properties p ON op.idProp = p.id WHERE p.type = 'Nightclubs' LIMIT 1",
      );
      if (ownedNightclub.isNotEmpty) {
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedNightclub.first['id'],
          'slotNumb': _nightclubSpecialSlots[vehicleId]!,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // 9. IS BUNKER SPECIAL VEHICLE
    if (_bunkerSpecialSlots.containsKey(vehicleId)) {
      final List<Map<String, dynamic>> ownedBunker = await db.rawQuery(
        "SELECT op.id FROM owned_properties op JOIN properties p ON op.idProp = p.id WHERE p.type = 'Bunkers' LIMIT 1",
      );
      if (ownedBunker.isNotEmpty) {
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedBunker.first['id'],
          'slotNumb': _bunkerSpecialSlots[vehicleId]!,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // 10. CADDY SPECIAL CHECK
    if (vehicleId == 'caddy') {
      final List<Map<String, dynamic>> checkBunker = await db.rawQuery(
        "SELECT op.id FROM owned_properties op JOIN properties p ON op.idProp = p.id WHERE p.type = 'Bunkers' LIMIT 1",
      );
      if (checkBunker.isEmpty) {
        throw Exception(
          "Necesitas comprar un Búnker antes de poder adquirir el Caddy.",
        );
      }
    }

    // 11. MULE CUSTOM AND POUNDER CUSTOM SPECIAL CHECK
    if (vehicleId == 'maibatsu_mule3' || vehicleId == 'mtl_pounder2') {
      final List<Map<String, dynamic>> checkNightclub = await db.rawQuery(
        "SELECT op.id FROM owned_properties op JOIN properties p ON op.idProp = p.id WHERE p.type = 'Nightclubs' LIMIT 1",
      );
      if (checkNightclub.isEmpty) {
        throw Exception(
          "Necesitas comprar un Club Nocturno antes de poder adquirir este vehículo de reparto.",
        );
      }
    }

    // 12. REQUIREMENT FOR RC BANDITO
    if (vehicleId == 'rcbandito') {
      final List<Map<String, dynamic>> checkArena = await db.rawQuery(
        "SELECT op.id FROM owned_properties op JOIN properties p ON op.idProp = p.id WHERE p.type = 'Arena Workshop' LIMIT 1",
      );
      if (checkArena.isEmpty) {
        throw Exception(
          "Necesitas comprar el Taller de la Arena antes de poder adquirir el RC Bandito.",
        );
      }
    }

    // 13. AUTO-ASSIGNEMENT OF RC BANDITO
    if (_arenaSpecialSlots.containsKey(vehicleId)) {
      final List<Map<String, dynamic>> ownedArena = await db.rawQuery(
        "SELECT op.id FROM owned_properties op JOIN properties p ON op.idProp = p.id WHERE p.type = 'Arena Workshop' LIMIT 1",
      );
      if (ownedArena.isNotEmpty) {
        await db.insert('ownedVehicles_properties', {
          'idOVeh': ownedVehId,
          'idOProp': ownedArena.first['id'],
          'slotNumb': _arenaSpecialSlots[vehicleId]!,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    return ownedVehId;
  }

  Future<int> addOwnedProperty(String catalogId, {String? oldCatalogId}) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> catalog = await db.query(
      'properties',
      where: 'id = ?',
      whereArgs: [catalogId],
    );
    if (catalog.isEmpty) return -1;

    String propType = catalog.first['type'];
    int defaultCapacity = catalog.first['capacity'] ?? 0;

    int limit = GameRules.propertyLimits[propType] ?? 0;

    if (limit == 1 || oldCatalogId != null) {
      final List<Map<String, dynamic>> existingOwned = await db.rawQuery(
        '''
      SELECT op.id, op.idProp 
      FROM owned_properties op
      JOIN properties p ON op.idProp = p.id
      WHERE ${oldCatalogId != null ? 'op.idProp = ?' : 'p.type = ?'}
      LIMIT 1
    ''',
        [oldCatalogId ?? propType],
      );

      if (existingOwned.isNotEmpty) {
        int ownedId = existingOwned.first['id'] as int;
        String actualOldCatalogId = existingOwned.first['idProp'] as String;

        await db.update(
          'properties_upgrades',
          {'propertyId': catalogId},
          where: 'propertyId = ?',
          whereArgs: [actualOldCatalogId],
        );

        await db.update(
          'owned_properties',
          {'idProp': catalogId, 'slots': defaultCapacity},
          where: 'id = ?',
          whereArgs: [ownedId],
        );

        await db.delete(
          'ownedVehicles_properties',
          where: 'idOProp = ? AND slotNumb > ?',
          whereArgs: [ownedId, defaultCapacity],
        );

        print("Mudanza exitosa: De $actualOldCatalogId a $catalogId");
        return ownedId;
      }
    }

    final int newOwnedPropId = await db.insert('owned_properties', {
      'idProp': catalogId,
      'slots': defaultCapacity,
      'isVirtual': 0,
      'consecutive': 1,
    });

    // 1. IS VEHICLE WAREHOUSE? -> ASSIGN ORPHAN WAREHOUSE VEHICLES
    if (propType == 'Vehicle Warehouses') {
      final List<String> specialIds = _specialWarehouseSlots.keys.toList();
      final List<Map<String, dynamic>> orphans = await db.query(
        'owned_vehicles',
        where: 'idVeh IN (${specialIds.map((id) => "'$id'").join(',')})',
      );
      for (var veh in orphans) {
        await db.insert('ownedVehicles_properties', {
          'idOVeh': veh['id'],
          'idOProp': newOwnedPropId,
          'slotNumb': _specialWarehouseSlots[veh['idVeh']]!,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // 2. IS KOSATKA CATALOG PROPERTY?
    if (catalogId == 'lvp_4001') {
      for (var entry in _kosatkaRegistry.entries) {
        final List<Map<String, dynamic>> orphan = await db.query(
          'owned_vehicles',
          where: 'idVeh = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (orphan.isNotEmpty) {
          await db.insert(
            'ownedVehicles_properties',
            {
              'idOVeh': orphan.first['id'],
              'idOProp': newOwnedPropId,
              'slotNumb': entry.value['slot'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    // 3. IS TERRORBYTE CATALOG PROPERTY?
    if (catalogId == 'lvp_4201') {
      for (var entry in _terbyteRegistry.entries) {
        final List<Map<String, dynamic>> orphan = await db.query(
          'owned_vehicles',
          where: 'idVeh = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (orphan.isNotEmpty) {
          await db.insert(
            'ownedVehicles_properties',
            {
              'idOVeh': orphan.first['id'],
              'idOProp': newOwnedPropId,
              'slotNumb': entry.value['slot'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    // 4. IS ACIDLAB CATALOG PROPERTY?
    if (catalogId == 'lvp_3001') {
      for (var entry in _acidlabRegistry.entries) {
        final List<Map<String, dynamic>> orphan = await db.query(
          'owned_vehicles',
          where: 'idVeh = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (orphan.isNotEmpty) {
          await db.insert(
            'ownedVehicles_properties',
            {
              'idOVeh': orphan.first['id'],
              'idOProp': newOwnedPropId,
              'slotNumb': entry.value['slot'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    // 5. DOUBLE IDENTITY CHECK
    if (_dualIdentityRegistry.containsValue(catalogId)) {
      final String twinVehId = _dualIdentityRegistry.entries
          .firstWhere((entry) => entry.value == catalogId)
          .key;
      final List<Map<String, dynamic>> checkVeh = await db.query(
        'owned_vehicles',
        where: 'idVeh = ?',
        whereArgs: [twinVehId],
        limit: 1,
      );
      if (checkVeh.isEmpty) await purchaseVehicle(twinVehId);
    }

    // 6. GIVE MANCHEZ SCOUT C
    if (catalogId == 'lvp_3001') {
      final List<Map<String, dynamic>> checkManchez = await db.query(
        'owned_vehicles',
        where: 'idVeh = ?',
        whereArgs: ['maibatsu_manchez3'],
        limit: 1,
      );
      if (checkManchez.isEmpty)
        await purchaseVehicle('maibatsu_manchez3', isSystemAction: true);
    }

    // 7. FACILITIES CATALOG PROPERTY?
    if (propType == 'Facilities') {
      for (var entry in _facilitySpecialSlots.entries) {
        final List<Map<String, dynamic>> orphan = await db.query(
          'owned_vehicles',
          where: 'idVeh = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (orphan.isNotEmpty) {
          await db.insert(
            'ownedVehicles_properties',
            {
              'idOVeh': orphan.first['id'],
              'idOProp': newOwnedPropId,
              'slotNumb': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    // 8. NIGHTCLUB RULES
    if (propType == 'Nightclubs') {
      for (var entry in _nightclubSpecialSlots.entries) {
        final List<Map<String, dynamic>> orphan = await db.query(
          'owned_vehicles',
          where: 'idVeh = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (orphan.isNotEmpty) {
          await db.insert(
            'ownedVehicles_properties',
            {
              'idOVeh': orphan.first['id'],
              'idOProp': newOwnedPropId,
              'slotNumb': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      final List<Map<String, dynamic>> checkSpeedo = await db.query(
        'owned_vehicles',
        where: 'idVeh = ?',
        whereArgs: ['vapid_speedo3'],
        limit: 1,
      );
      if (checkSpeedo.isEmpty)
        await purchaseVehicle('vapid_speedo3', isSystemAction: true);
    }

    // 9. BUNKER ASSIGN ORPHANS
    if (propType == 'Bunkers') {
      for (var entry in _bunkerSpecialSlots.entries) {
        final List<Map<String, dynamic>> orphan = await db.query(
          'owned_vehicles',
          where: 'idVeh = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (orphan.isNotEmpty) {
          await db.insert(
            'ownedVehicles_properties',
            {
              'idOVeh': orphan.first['id'],
              'idOProp': newOwnedPropId,
              'slotNumb': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    // 10. ARENA WAR ASSIGN ORPHANS
    if (propType == 'Arena Workshop') {
      for (var entry in _arenaSpecialSlots.entries) {
        final List<Map<String, dynamic>> orphan = await db.query(
          'owned_vehicles',
          where: 'idVeh = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        if (orphan.isNotEmpty) {
          await db.insert(
            'ownedVehicles_properties',
            {
              'idOVeh': orphan.first['id'],
              'idOProp': newOwnedPropId,
              'slotNumb': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    return newOwnedPropId;
  }

  Future<Map<String, dynamic>> getPropertyImpact(String catalogId) async {
    final db = await instance.database;
    final owned = await db.query(
      'owned_properties',
      where: 'idProp = ?',
      whereArgs: [catalogId],
      limit: 1,
    );

    if (owned.isEmpty) return {'cars': 0, 'upgrades': 0};

    int ownedId = owned.first['id'] as int;
    final cars = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ownedVehicles_properties WHERE idOProp = ?',
      [ownedId],
    );
    final upgs = await db.rawQuery(
      'SELECT COUNT(*) as count FROM properties_upgrades WHERE propertyId = ?',
      [catalogId],
    );

    return {
      'cars': cars.first['count'] as int,
      'upgrades': upgs.first['count'] as int,
    };
  }

  Future<void> executeExplicitTradeIn(
    String oldCatalogId,
    String newCatalogId,
  ) async {
    final db = await instance.database;

    final owned = await db.query(
      'owned_properties',
      where: 'idProp = ?',
      whereArgs: [oldCatalogId],
      limit: 1,
    );
    if (owned.isEmpty) return;
    int ownedId = owned.first['id'] as int;

    final newCatalog = await db.query(
      'properties',
      where: 'id = ?',
      whereArgs: [newCatalogId],
      limit: 1,
    );
    if (newCatalog.isEmpty) return;
    int newCapacity = newCatalog.first['capacity'] as int;

    await db.update(
      'properties_upgrades',
      {'propertyId': newCatalogId},
      where: 'propertyId = ?',
      whereArgs: [oldCatalogId],
    );

    await db.update(
      'owned_properties',
      {'idProp': newCatalogId, 'slots': newCapacity},
      where: 'id = ?',
      whereArgs: [ownedId],
    );

    print("Mudanza explícita completada de $oldCatalogId a $newCatalogId");
  }

  Future<List<Map<String, dynamic>>> getVehiclesWithOwnership() async {
    final db = await instance.database;
    return await db.rawQuery('''
    SELECT 
      v.*, 
      COUNT(ov.id) as ownedCount, -- Contamos cuántos tiene el usuario
      (CASE WHEN COUNT(ov.id) > 0 THEN 1 ELSE 0 END) as isOwned
    FROM vehicles v
    LEFT JOIN owned_vehicles ov ON v.id = ov.idVeh
    GROUP BY v.id -- Colapsamos por el ID del modelo
  ''');
  }

  Future<void> removeOwnedVehicle(String catalogId) async {
    final db = await instance.database;

    // BLOCK VEHICLE IF IT'S THE MANCHETZ SCOUT C OR SPEEDO CUSTOM
    if (catalogId == 'maibatsu_manchez3' || catalogId == 'vapid_speedo3') {
      throw Exception(
        "Este vehículo viene con una propiedad y no se puede vender individualmente.",
      );
    }

    //  REMOVE MANCHEZ SCOUT C IF USER SELLS ACIDLAB SINCE IT'S THE ONLY WAY TO GET IT AND COMES WITH THE LAB
    if (catalogId == 'mtl_brickade2') {
      await db.delete(
        'owned_vehicles',
        where: 'idVeh = ?',
        whereArgs: ['maibatsu_manchez3'],
      );
      print("Manchez Scout C eliminada junto con el Brickade 6x6.");
    }

    await db.delete(
      'owned_vehicles',
      where: 'idVeh = ?',
      whereArgs: [catalogId],
    );

    if (_dualIdentityRegistry.containsKey(catalogId)) {
      final String twinPropId = _dualIdentityRegistry[catalogId]!;

      await db.delete(
        'owned_properties',
        where: 'idProp = ?',
        whereArgs: [twinPropId],
      );
      print(
        "Doble Identidad: Propiedad $twinPropId eliminada junto con el vehículo.",
      );
    }
  }

  Future<void> checkDatabaseStats() async {
    final db = await instance.database;
    final numVehicles = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM vehicles'),
    );
    final numProperties = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM properties'),
    );
    print(
      '--- DB STATS: $numVehicles Vehículos | $numProperties Propiedades ---',
    );
  }

  Future<List<Map<String, dynamic>>> getOwnedServiceVehicles() async {
    final db = await instance.database;
    return await db.query('owned_properties', where: 'isVirtual = 1');
  }

Future<void> assignVehicleToSlot(
  String propertyId,
  int ownedVehicleId,
  int slotNumb,
) async {
  final db = await instance.database;

  final propRow = await db.query(
    'owned_properties',
    where: 'idProp = ?',
    whereArgs: [propertyId],
    limit: 1,
  );

  if (propRow.isEmpty) return;
  final int idOProp = propRow.first['id'] as int;

  await db.delete(
    'ownedVehicles_properties',
    where: 'idOProp = ? AND slotNumb = ?',
    whereArgs: [idOProp, slotNumb],
  );

  await db.insert('ownedVehicles_properties', {
    'idOVeh': ownedVehicleId,
    'idOProp': idOProp,
    'slotNumb': slotNumb,
  });
}

  Future<void> removeVehicleFromSlot(String propertyId, int slotNumb) async {
    final db = await instance.database;
    final propRow = await db.query(
      'owned_properties',
      where: 'idProp = ?',
      limit: 1,
      whereArgs: [propertyId],
    );

    if (propRow.isNotEmpty) {
      final int idOProp = propRow.first['id'] as int;
      await db.delete(
        'ownedVehicles_properties',
        where: 'idOProp = ? AND slotNumb = ?',
        whereArgs: [idOProp, slotNumb],
      );
    }
  }

  Future<void> removeOwnedProperty(String catalogId) async {
    final db = await instance.database;

    // MAP TYPE OF PROPERTY
    final List<Map<String, dynamic>> propToDelete = await db.query(
      'properties',
      where: 'id = ?',
      whereArgs: [catalogId],
    );
    String propType = propToDelete.isNotEmpty ? propToDelete.first['type'] : '';

    // 1. DELETE PROPERTY
    await db.delete(
      'owned_properties',
      where: 'idProp = ?',
      whereArgs: [catalogId],
    );

    // 2. DOUBLE IDENTITY
    if (_dualIdentityRegistry.containsValue(catalogId)) {
      final String twinVehId = _dualIdentityRegistry.entries
          .firstWhere((entry) => entry.value == catalogId)
          .key;

      await db.delete(
        'owned_vehicles',
        where: 'idVeh = ?',
        whereArgs: [twinVehId],
      );
      print(
        "Doble Identidad: Vehículo $twinVehId eliminado junto con la propiedad $catalogId.",
      );
    }

    // 3. DELETE MANCHEZ SCOUT C OR SPEEDO CUSTOM
    if (catalogId == 'lvp_3001') {
      await db.delete(
        'owned_vehicles',
        where: 'idVeh = ?',
        whereArgs: ['maibatsu_manchez3'],
      );
    }
    if (propType == 'Nightclubs') {
      await db.delete(
        'owned_vehicles',
        where: 'idVeh = ?',
        whereArgs: ['vapid_speedo3'],
      );
      print("Speedo Custom eliminada junto con el Club Nocturno.");
    }

    // 4. ¡LIBERAR LOS AUTOS HUÉRFANOS! (El toque mágico)
    await cleanOrphanedData();
  }

  Future<void> updateVehicleTag(int ownedId, String newTag) async {
    final db = await instance.database;
    await db.update(
      'owned_vehicles',
      {'tag': newTag},
      where: 'id = ?',
      whereArgs: [ownedId],
    );
  }

  Future<void> purchasePropertyUpgrade(
    String propertyCatalogId,
    String upgradeId,
    String upgradeType,
    int addedCapacity,
  ) async {
    final db = await instance.database;

    final ownedProp = await db.query(
      'owned_properties',
      where: 'idProp = ?',
      whereArgs: [propertyCatalogId],
      limit: 1,
    );

    if (ownedProp.isEmpty) {
      throw Exception(
        "No puedes comprar mejoras para una propiedad que aún no tienes.",
      );
    }

    int currentSlots = ownedProp.first['slots'] as int;

    await db.insert('properties_upgrades', {
      'propertyId': propertyCatalogId,
      'upgradeType': upgradeType,
      'level': 1,
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    if (addedCapacity > 0) {
      int newTotalSlots = currentSlots + addedCapacity;

      await db.update(
        'owned_properties',
        {'slots': newTotalSlots},
        where: 'idProp = ?',
        whereArgs: [propertyCatalogId],
      );
      print(
        "¡Mejora $upgradeId comprada! Capacidad de $propertyCatalogId aumentada a $newTotalSlots.",
      );
    }
  }

  Future<List<String>> getOwnedUpgradesForProperty(
    String propertyCatalogId,
  ) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> upgrades = await db.query(
      'properties_upgrades',
      columns: ['upgradeType'],
      where: 'propertyId = ?',
      whereArgs: [propertyCatalogId],
    );
    return upgrades.map((u) => u['upgradeType'] as String).toList();
  }

  Future<void> toggleWishlist(
    String vehicleCatalogId,
    bool isCurrentlyWishlisted,
  ) async {
    final db = await instance.database;

    if (isCurrentlyWishlisted) {
      await db.delete(
        'wishlisted_vehicles',
        where: 'idVeh = ?',
        whereArgs: [vehicleCatalogId],
      );
    } else {
      await db.insert('wishlisted_vehicles', {
        'idVeh': vehicleCatalogId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, dynamic>>> getUserPropertiesSummary() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        op.id as ownedPropId,
        p.id as catalogId,
        p.name,
        p.type,
        op.slots as totalCapacity,
        (SELECT COUNT(*) FROM ownedVehicles_properties ovp WHERE ovp.idOProp = op.id) as occupiedSlots
      FROM owned_properties op
      JOIN properties p ON op.idProp = p.id
      ORDER BY p.type, p.name
    ''');
  }

  Future<List<Map<String, dynamic>>> getUserVehiclesInventory() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        ov.id as ownedVehicleId,
        v.id as catalogId,
        v.name,
        v.manufacturer,
        v.image,
        v.category,
        ov.tag,
        ov.consecutive,
        p.name as garageName,
        ovp.slotNumb
      FROM owned_vehicles ov
      JOIN vehicles v ON ov.idVeh = v.id
      LEFT JOIN ownedVehicles_properties ovp ON ov.id = ovp.idOVeh
      LEFT JOIN owned_properties op ON ovp.idOProp = op.id
      LEFT JOIN properties p ON op.idProp = p.id
      ORDER BY p.name, ovp.slotNumb ASC, v.name
    ''');
  }

  Future<void> importFromAIGeneratedJSON(
    String jsonString, {
    String? forcedPropertyId,
  }) async {
    final db = await instance.database;
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> garages = data['garages'] ?? [];

    final String vehResponse = await rootBundle.loadString(
      'assets/data/vehicles.json',
    );
    final List<dynamic> catalogData = json.decode(vehResponse);

    final String upgResponse = await rootBundle.loadString(
      'assets/data/upgrades.json',
    );
    final List<dynamic> upgradesData = json.decode(upgResponse);

    for (var garage in garages) {
      String gName = garage['garage_name'];
      List<dynamic> slots = garage['slots'] ?? [];

      String propId = forcedPropertyId ?? '';

      if (propId.isEmpty && gName != 'Desconocido') {
        final List<Map<String, dynamic>> propSearch = await db.rawQuery(
          "SELECT id FROM properties WHERE name LIKE ? LIMIT 1",
          ['%$gName%'],
        );
        if (propSearch.isNotEmpty) {
          propId = propSearch.first['id'];
        }
      }

      if (propId.isNotEmpty) {
        final List<Map<String, dynamic>> checkProp = await db.query(
          'owned_properties',
          where: 'idProp = ?',
          whereArgs: [propId],
          limit: 1,
        );
        if (checkProp.isEmpty) {
          await addOwnedProperty(propId);
        }
      }

      for (var vehicleData in slots) {
        String vNameInput = vehicleData['car_name'].toLowerCase().trim();
        int slotNumb = vehicleData['slot'];
        String? foundVehId;

        for (var v in catalogData) {
          final String baseName = (v['name'] ?? '').toLowerCase();
          final String nameEs = (v['displayName']?['es'] ?? '').toLowerCase();
          final String nameEn = (v['displayName']?['en'] ?? '').toLowerCase();

          if (baseName.contains(vNameInput) ||
              nameEs.contains(vNameInput) ||
              nameEn.contains(vNameInput)) {
            foundVehId = v['id'];
            break;
          }
        }

        if (foundVehId != null && propId.isNotEmpty) {
          final propQuery = await db.rawQuery(
            'SELECT op.slots, p.type, p.id FROM owned_properties op JOIN properties p ON op.idProp = p.id WHERE op.idProp = ? LIMIT 1',
            [propId],
          );

          if (propQuery.isNotEmpty) {
            int currentSlots = propQuery.first['slots'] as int;
            String propType = propQuery.first['type'] as String;
            String catalogId = propQuery.first['id'] as String;

            if (_isSlotReservedForAnotherVehicle(propType, catalogId, foundVehId, slotNumb)) {
              print("ALERTA IA: Intento de colocar $foundVehId en el slot reservado $slotNumb de $propType. Ignorando posición para proteger el garaje.");
              continue; 
            }

            if (slotNumb > currentSlots) {
              List<dynamic> relevantUpgrades = upgradesData
                  .where((u) => u['propertyType'] == propType)
                  .toList();

              for (var upgrade in relevantUpgrades) {
                final alreadyOwned = await db.query(
                  'properties_upgrades',
                  where: 'propertyId = ? AND upgradeType = ?',
                  whereArgs: [propId, upgrade['id']],
                );

                if (alreadyOwned.isEmpty) {
                  print(
                    "IA Auto-comprando mejora ${upgrade['name']} para $propId",
                  );

                  await purchasePropertyUpgrade(
                    propId,
                    upgrade['id'],
                    upgrade['id'],
                    upgrade['addedCapacity'] ?? 0,
                  );
                  currentSlots += (upgrade['addedCapacity'] ?? 0) as int;
                }
                if (currentSlots >= slotNumb) break;
              }
            }
          }
          await purchaseVehicle(foundVehId);

          final List<Map<String, dynamic>> lastOwned = await db.rawQuery(
            "SELECT id FROM owned_vehicles WHERE idVeh = ? ORDER BY id DESC LIMIT 1",
            [foundVehId],
          );

          if (lastOwned.isNotEmpty) {
            int recentOwnedId = lastOwned.first['id'] as int;
            await assignVehicleToSlot(propId, recentOwnedId, slotNumb);
          }
        }
      }
    }
  }

  bool _isSlotReservedForAnotherVehicle(
    String propType,
    String propCatalogId,
    String vehicleId,
    int slotNumb,
  ) {
    if (propType == 'Arena Workshop' &&
        _arenaSpecialSlots.containsValue(slotNumb)) {
      return _arenaSpecialSlots[vehicleId] != slotNumb;
    }
    if (propType == 'Facilities' &&
        _facilitySpecialSlots.containsValue(slotNumb)) {
      return _facilitySpecialSlots[vehicleId] != slotNumb;
    }
    if (propType == 'Vehicle Warehouses' &&
        _specialWarehouseSlots.containsValue(slotNumb)) {
      return _specialWarehouseSlots[vehicleId] != slotNumb;
    }
    if (propType == 'Nightclubs' &&
        _nightclubSpecialSlots.containsValue(slotNumb)) {
      return _nightclubSpecialSlots[vehicleId] != slotNumb;
    }
    if (propType == 'Bunkers' && _bunkerSpecialSlots.containsValue(slotNumb)) {
      return _bunkerSpecialSlots[vehicleId] != slotNumb;
    }
    if (propCatalogId == 'lvp_4001' &&
        _kosatkaRegistry.values.any((v) => v['slot'] == slotNumb)) {
      return _kosatkaRegistry[vehicleId]?['slot'] != slotNumb;
    }
    return false;
  }

  Future<void> cleanOrphanedData() async {
    final db = await instance.database;

    await db.rawDelete('''
      DELETE FROM ownedVehicles_properties 
      WHERE idOProp NOT IN (SELECT id FROM owned_properties)
    ''');

    await db.rawDelete('''
      DELETE FROM properties_upgrades 
      WHERE propertyId NOT IN (SELECT idProp FROM owned_properties)
    ''');

    print("🧹 Limpieza completada: Datos huérfanos eliminados.");
  }

  Future<Map<String, dynamic>?> checkTradeInStatus(String newPropertyId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> newProp = await db.query(
      'properties',
      where: 'id = ?',
      whereArgs: [newPropertyId],
    );
    if (newProp.isEmpty) return null;

    String propType = newProp.first['type'];
    String newPropName = newProp.first['name'];

    int limit = GameRules.propertyLimits[propType] ?? 0;

    if (limit == 1) {
      final List<Map<String, dynamic>> existing = await db.rawQuery(
        '''
        SELECT op.id, op.idProp, p.name 
        FROM owned_properties op
        JOIN properties p ON op.idProp = p.id
        WHERE p.type = ?
      ''',
        [propType],
      );

      if (existing.isNotEmpty && existing.first['idProp'] != newPropertyId) {
        int oldOwnedId = existing.first['id'] as int;

        final cars = await db.rawQuery(
          'SELECT COUNT(*) as count FROM ownedVehicles_properties WHERE idOProp = ?',
          [oldOwnedId],
        );
        final upgs = await db.rawQuery(
          'SELECT COUNT(*) as count FROM properties_upgrades WHERE propertyId = ?',
          [existing.first['idProp']],
        );

        return {
          'oldName': existing.first['name'],
          'newName': newPropName,
          'carCount': cars.first['count'] as int,
          'upgCount': upgs.first['count'] as int,
        };
      }
    }
    return null;
  }

  Future<String> createFullBackupJson() async {
    final db = await instance.database;
    final ownedProps = await db.query('owned_properties');
    final ownedVehs = await db.query('owned_vehicles');
    final assignments = await db.query('ownedVehicles_properties');
    final upgrades = await db.query('properties_upgrades');
    final wishlist = await db.query('wishlisted_vehicles');

    Map<String, dynamic> backup = {
      "version": 1,
      "date": DateTime.now().toIso8601String(),
      "owned_properties": ownedProps,
      "owned_vehicles": ownedVehs,
      "assignments": assignments,
      "upgrades": upgrades,
      "wishlist": wishlist,
    };

    return jsonEncode(backup);
  }

  Future<void> restoreFromFullBackup(String jsonString) async {
    final db = await instance.database;
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await db.transaction((txn) async {
      await txn.delete('ownedVehicles_properties');
      await txn.delete('owned_vehicles');
      await txn.delete('owned_properties');
      await txn.delete('properties_upgrades');
      await txn.delete('wishlisted_vehicles');

      for (var row in data['owned_properties']) {
        await txn.insert('owned_properties', row);
      }

      for (var row in data['owned_vehicles']) {
        await txn.insert('owned_vehicles', row);
      }

      for (var row in data['assignments']) {
        await txn.insert('ownedVehicles_properties', row);
      }

      for (var row in data['upgrades']) {
        await txn.insert('properties_upgrades', row);
      }

      for (var row in data['wishlist']) {
        await txn.insert('wishlisted_vehicles', row);
      }
    });

    print("Restauración completa finalizada.");
  }

  // ONLY 4 TESTS - CLEAR INVENTORY TABLES
  Future<void> clearDatabaseForTesting() async {
    final db = await instance.database;
    await db.delete('ownedVehicles_properties');
    await db.delete('owned_vehicles');
    await db.delete('owned_properties');
  }
}
