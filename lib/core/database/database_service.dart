import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../../shared/models/customer_model.dart';
import '../../shared/models/vehicle_model.dart';
import '../../shared/models/appointment_model.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/models/feedback_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        profile_image_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Vehicles table
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        color TEXT NOT NULL,
        license_plate TEXT NOT NULL,
        vin TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Appointments table
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        vehicle_id TEXT NOT NULL,
        workshop_id TEXT NOT NULL,
        workshop_name TEXT NOT NULL,
        service_type TEXT NOT NULL,
        appointment_date TEXT NOT NULL,
        appointment_time TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        estimated_duration INTEGER,
        actual_duration INTEGER,
        total_cost REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        appointment_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        workshop_id TEXT NOT NULL,
        workshop_name TEXT NOT NULL,
        invoice_number TEXT NOT NULL,
        total_amount REAL NOT NULL,
        tax_amount REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        final_amount REAL NOT NULL,
        status TEXT NOT NULL,
        payment_method TEXT,
        payment_date TEXT,
        due_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id),
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Invoice items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        description TEXT,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id)
      )
    ''');

    // Feedback table
    await db.execute('''
      CREATE TABLE feedback (
        id TEXT PRIMARY KEY,
        appointment_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        workshop_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        service_quality INTEGER NOT NULL,
        timeliness INTEGER NOT NULL,
        communication INTEGER NOT NULL,
        value_for_money INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id),
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        appointment_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Workshops table (cached data)
    await db.execute('''
      CREATE TABLE workshops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        rating REAL DEFAULT 0,
        review_count INTEGER DEFAULT 0,
        latitude REAL,
        longitude REAL,
        services TEXT,
        image_url TEXT,
        is_favorite INTEGER DEFAULT 0,
        last_visited TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Customer operations
  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert(
      'customers', 
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<Customer?> getCurrentCustomer() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      limit: 1,
      orderBy: 'updated_at DESC',
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }


  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> clearCustomerData() async {
    final db = await database;
    await db.delete('customers');
    await db.delete('vehicles');
    await db.delete('appointments');
    await db.delete('invoices');
    await db.delete('invoice_items');
    await db.delete('feedback');
    await db.delete('notifications');
  }


  // Vehicle operations
  Future<void> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getCustomerVehicles(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vehicles',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
  }

  // Appointment operations
  Future<void> insertAppointment(Appointment appointment) async {
    final db = await database;
    await db.insert('appointments', appointment.toMap());
  }

  Future<List<Appointment>> getCustomerAppointments(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'appointment_date DESC, appointment_time DESC',
    );
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<Appointment?> getAppointment(String appointmentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
    if (maps.isNotEmpty) {
      return Appointment.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateAppointment(Appointment appointment) async {
    final db = await database;
    await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  // Invoice operations
  Future<void> insertInvoice(Invoice invoice) async {
    final db = await database;
    await db.insert('invoices', invoice.toMap());
  }

  Future<List<Invoice>> getCustomerInvoices(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Invoice.fromMap(maps[i]));
  }

  Future<Invoice?> getInvoice(String invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    return null;
  }

  // Feedback operations
  Future<void> insertFeedback(Feedback feedback) async {
    final db = await database;
    await db.insert('feedback', feedback.toMap());
  }

  Future<List<Feedback>> getCustomerFeedback(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'feedback',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Feedback.fromMap(maps[i]));
  }

  // Notification operations
  Future<void> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    await db.insert('notifications', notification);
  }

  Future<List<Map<String, dynamic>>> getCustomerNotifications(
    String customerId,
  ) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Workshop operations
  Future<void> insertWorkshop(Map<String, dynamic> workshop) async {
    final db = await database;
    await db.insert('workshops', workshop);
  }

  Future<List<Map<String, dynamic>>> getWorkshops() async {
    final db = await database;
    return await db.query('workshops', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getWorkshop(String workshopId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workshops',
      where: 'id = ?',
      whereArgs: [workshopId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> updateWorkshop(Map<String, dynamic> workshop) async {
    final db = await database;
    await db.update(
      'workshops',
      workshop,
      where: 'id = ?',
      whereArgs: [workshop['id']],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
