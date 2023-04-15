import 'dart:async';
import 'ble_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BrewChartData extends ChangeNotifier {
  final BLEDataHandler bleHandler;
  final List<FlSpot> brewPoints = <FlSpot>[];
  final List<FlSpot> brewPointsGhost = <FlSpot>[];
  DateTime? firstAdditionTime;
  bool _isUpdating = false;
  double weight = 0.0;
  bool _isSmartStartEnabled = false;
  String _profileName = '';
  String _coffee = '';
  double _coffeeWeight = 0.0;
  String _comment = '';

  StreamSubscription? _streamSubscription;

  List<FlSpot> get brewPointsData => brewPoints;
  List<FlSpot> get brewPointsGhostData => brewPointsGhost;
  double get currentWeight => weight;
  String get profileName => _profileName;
  String get coffee => _coffee;
  double get coffeeWeight => _coffeeWeight;
  String get comment => _comment;

  BrewChartData({required this.bleHandler}) {
    _startUpdating();
  }

  void clear() {
    brewPoints.clear();
    firstAdditionTime = null;
    _streamSubscription?.cancel();
    notifyListeners();
  }

  void start() {
    _isUpdating = true;
  }

  void smartStart() {
    _isSmartStartEnabled = true;
  }

  void stop() {
    _isUpdating = false;
  }

  void _startUpdating() {
    bleHandler.updateDataCallback = (double value) {
      _updateData(value);
    };
  }

  void _updateData(double value) {
    weight = value;

    if (_isSmartStartEnabled && weight > 1.0) {
      _isUpdating = true;
      _isSmartStartEnabled = false;
    }

    if (!_isUpdating) {
      notifyListeners();
      return;
    }

    DateTime currentTime = DateTime.now();
    firstAdditionTime ??= currentTime;

    double elapsedTimeInSeconds =
        currentTime.difference(firstAdditionTime!).inMilliseconds.toDouble();

    brewPoints.add(FlSpot(elapsedTimeInSeconds / 1000, value));
    notifyListeners(); // Notify listeners about the change
  }

  Future<Database> _getDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'brew_points.db');
    return openDatabase(path);
  }

  Future<void> _createProfileLineDataTable(
      Database db, String tableName) async {
    return db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS $tableName');
      await txn.execute('''
        CREATE TABLE $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          time_elapsed REAL,
          value REAL
        )
      ''');
    });
  }

  Future<void> _createProfilesInfoTable(Database db) async {
    return db.execute('''
      CREATE TABLE IF NOT EXISTS recepies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        date_created TEXT,
        coffee TEXT,
        coffee_weight REAL,
        comment TEXT
      )
    ''');
  }

  Future<void> saveProfile([String? name]) async {
    final database = await _getDatabase();
    final safeName = name ?? '${DateTime.now().toIso8601String()}';
    final tableName =
        'profile_${safeName.replaceAll(RegExp('[^0-9a-zA-Z]'), '_')}';

    // Create profile data table
    await _createProfileLineDataTable(database, tableName);

    // Create profileNames table if it doesn't exist
    await _createProfilesInfoTable(database);

    database.insert('recepies', {
      'name': safeName,
      'date_created': DateTime.now().toIso8601String(),
      'coffee': _coffee,
      'coffee_weight': _coffeeWeight,
      'comment': _comment,
    });

    final batch = database.batch();

    for (FlSpot point in brewPoints) {
      batch.insert(tableName, {
        'time_elapsed': point.x,
        'value': point.y,
      });
    }

    // Commit the batch
    await batch.commit(noResult: true);
  }

  Future<void> loadGhostLine(String name) async {
    _loadLine(name, isGhost: true);
  }

  Future<void> loadProfile(String name) async {
    _loadLine(name);
  }

  Future<void> _loadLine(String name, {bool isGhost = false}) async {
    final safeName = name.replaceAll(RegExp('[^0-9a-zA-Z]'), '_');
    final tableName = 'profile_$safeName';

    final Database db = await _getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(tableName);

    List<FlSpot> targetList = isGhost ? brewPointsGhost : brewPoints;

    targetList.clear();
    for (var item in maps) {
      targetList.add(FlSpot(item['time_elapsed'], item['value']));
    }
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final Database db = await _getDatabase();
    return await db.query('recepies');
  }
}
