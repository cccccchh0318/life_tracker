import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'life_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        due_date TEXT,
        is_completed INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        start_time TEXT,
        end_time TEXT,
        is_all_day INTEGER DEFAULT 0,
        color INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE checkin_habits (
        id TEXT PRIMARY KEY,
        name TEXT,
        icon TEXT,
        color INTEGER,
        target_days INTEGER DEFAULT 7,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE checkin_records (
        id TEXT PRIMARY KEY,
        habit_id TEXT,
        date TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE diet_records (
        id TEXT PRIMARY KEY,
        meal_type TEXT,
        food_name TEXT,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        record_date TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fitness_records (
        id TEXT PRIMARY KEY,
        workout_type TEXT,
        duration INTEGER,
        calories INTEGER,
        sets INTEGER,
        reps INTEGER,
        weight REAL,
        note TEXT,
        record_date TEXT
      )
    ''');
  }

  // ─── tasks ───────────────────────────────────────────────────────────────

  Future<int> insertTask(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('tasks', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTask(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('tasks', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllTasks() async {
    final db = await database;
    return db.query('tasks', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> queryTasksByDate(String dateStr) async {
    final db = await database;
    return db.query(
      'tasks',
      where: 'due_date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );
  }

  // ─── schedules ───────────────────────────────────────────────────────────

  Future<int> insertSchedule(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('schedules', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSchedule(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('schedules', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteSchedule(String id) async {
    final db = await database;
    return db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllSchedules() async {
    final db = await database;
    return db.query('schedules', orderBy: 'start_time ASC');
  }

  Future<List<Map<String, dynamic>>> querySchedulesByDate(String dateStr) async {
    final db = await database;
    return db.query(
      'schedules',
      where: 'start_time LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'start_time ASC',
    );
  }

  // ─── checkin_habits ──────────────────────────────────────────────────────

  Future<int> insertCheckinHabit(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('checkin_habits', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCheckinHabit(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('checkin_habits', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteCheckinHabit(String id) async {
    final db = await database;
    return db.delete('checkin_habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllCheckinHabits() async {
    final db = await database;
    return db.query('checkin_habits', orderBy: 'created_at ASC');
  }

  Future<List<Map<String, dynamic>>> queryCheckinHabitsByDate(String dateStr) async {
    final db = await database;
    return db.query(
      'checkin_habits',
      where: 'created_at LIKE ?',
      whereArgs: ['$dateStr%'],
    );
  }

  // ─── checkin_records ─────────────────────────────────────────────────────

  Future<int> insertCheckinRecord(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('checkin_records', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCheckinRecord(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('checkin_records', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteCheckinRecord(String id) async {
    final db = await database;
    return db.delete('checkin_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllCheckinRecords() async {
    final db = await database;
    return db.query('checkin_records', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> queryCheckinRecordsByDate(String dateStr) async {
    final db = await database;
    return db.query(
      'checkin_records',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> queryCheckinRecordsByHabit(String habitId) async {
    final db = await database;
    return db.query(
      'checkin_records',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
  }

  // ─── diet_records ────────────────────────────────────────────────────────

  Future<int> insertDietRecord(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('diet_records', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateDietRecord(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('diet_records', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteDietRecord(String id) async {
    final db = await database;
    return db.delete('diet_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllDietRecords() async {
    final db = await database;
    return db.query('diet_records', orderBy: 'record_date DESC');
  }

  Future<List<Map<String, dynamic>>> queryDietRecordsByDate(String dateStr) async {
    final db = await database;
    return db.query(
      'diet_records',
      where: 'record_date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'record_date DESC',
    );
  }

  // ─── fitness_records ─────────────────────────────────────────────────────

  Future<int> insertFitnessRecord(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('fitness_records', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateFitnessRecord(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('fitness_records', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteFitnessRecord(String id) async {
    final db = await database;
    return db.delete('fitness_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllFitnessRecords() async {
    final db = await database;
    return db.query('fitness_records', orderBy: 'record_date DESC');
  }

  Future<List<Map<String, dynamic>>> queryFitnessRecordsByDate(String dateStr) async {
    final db = await database;
    return db.query(
      'fitness_records',
      where: 'record_date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'record_date DESC',
    );
  }
}
