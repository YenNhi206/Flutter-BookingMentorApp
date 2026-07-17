import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// ============================================================================
/// SƠ ĐỒ ERD (Entity-Relationship Diagram) - dạng ASCII, dùng để đưa vào báo cáo
/// ============================================================================
///
///   users                     stores                    categories
///   ─────────────             ─────────────              ─────────────
///   id (PK)                   id (PK)                    id (PK)
///   full_name                 name                        name
///   email (UNIQUE)            address                     emoji
///   password_hash             lat, lng
///   phone                     rating
///   address                   image
///   avatar
///      │                          │                            │
///      │                          │ 1..N                       │ 1..N
///      │                          ▼                            ▼
///      │                     ┌──────────────────────────────────────┐
///      │                     │                 foods                │
///      │                     │──────────────────────────────────────│
///      │                     │ id (PK)                              │
///      │                     │ store_id     (FK → stores.id)        │
///      │                     │ category_id  (FK → categories.id)    │
///      │                     │ name, description, price             │
///      │                     │ image, emoji, rating, is_available   │
///      │                     │ kcal, ready_minutes, serve_temp      │
///      │                     │ flavour_tags (CSV)                   │
///      │                     └──────────────────────────────────────┘
///      │                          ▲                    ▲        ▲
///      │ 1..N                     │ N..1               │        │
///      ▼                          │                     │        │
///   favourites ───────────────────┘                     │        │
///   ─────────────                                        │        │
///   id (PK)                                               │        │
///   user_id  (FK → users.id)                              │        │
///   food_id  (FK → foods.id)                              │        │
///                                                          │        │
///   cart_items ───────────────────────────────────────────┘        │
///   ─────────────                                                  │
///   id (PK)                                                        │
///   user_id  (FK → users.id)                                       │
///   food_id  (FK → foods.id)                                       │
///   quantity, size, note                                           │
///                                                                    │
///   orders                          order_items ──────────────────┘
///   ─────────────                   ─────────────
///   id (PK)                         id (PK)
///   order_code (vd "IC-1041") 1..1  order_id (FK → orders.id)
///   user_id (FK → users.id)  1..N   food_id  (FK → foods.id)
///   subtotal, discount, total       quantity
///   status, payment_method          price_at_order
///   card_last4, created_at
///      │
///      │ 1..1
///      ▼
///   vouchers
///   ─────────────
///   id (PK)
///   order_id (FK → orders.id, UNIQUE)
///   code, qr_data, expires_at, is_redeemed
///
///   notifications                   messages
///   ─────────────                   ─────────────
///   id (PK)                         id (PK)
///   user_id (FK → users.id)         user_id  (FK → users.id)
///   title, body                     store_id (FK → stores.id)
///   is_read, created_at             content, is_from_user, is_read, created_at
/// ============================================================================

/// Singleton quản lý kết nối SQLite cho toàn bộ app Scoops.
///
/// Tự tạo schema và seed dữ liệu mẫu (4 cửa hàng, 6 danh mục, 24 món,
/// 1 user demo) ở lần khởi chạy đầu tiên, để app có dữ liệu thật ngay khi
/// demo mà không cần thao tác nhập liệu thủ công.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static const int _version = 5;
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return openDatabase(
        'scoops.db',
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scoops.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
    await _seedData(db);
  }

  /// Nâng cấp từ schema v1 (chưa có kcal/tags/voucher, đơn hàng theo mô hình
  /// giao hàng) lên v2 (mô hình nhận tại cửa hàng qua voucher QR). `orders`/
  /// `order_items` bị đổi cấu trúc cột (bỏ delivery_fee/address, thêm
  /// order_code/card_last4) nên xoá-tạo-lại đơn giản và an toàn hơn ALTER
  /// từng cột - chấp nhận mất lịch sử đơn hàng cũ vì đây vẫn là môi trường
  /// dev/demo, chưa có dữ liệu người dùng thật cần giữ.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE foods ADD COLUMN kcal INTEGER NOT NULL DEFAULT 150");
      await db.execute("ALTER TABLE foods ADD COLUMN ready_minutes INTEGER NOT NULL DEFAULT 5");
      await db.execute("ALTER TABLE foods ADD COLUMN serve_temp TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE foods ADD COLUMN flavour_tags TEXT NOT NULL DEFAULT ''");
      await _backfillFoodExtras(db);

      await db.execute('DROP TABLE IF EXISTS order_items');
      await db.execute('DROP TABLE IF EXISTS orders');
      await _createOrderTables(db);
      await _createVoucherTable(db);
    }

    if (oldVersion < 3) {
      await db.execute("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'customer'");
      await db.execute('ALTER TABLE users ADD COLUMN store_id TEXT');
      await _seedDemoOwners(db);
    }

    // v3 chỉ seed sẵn 1 tài khoản owner (store_1) - v4 bổ sung thêm owner
    // cho 3 cửa hàng còn lại để so sánh/test phân quyền giữa nhiều quán.
    if (oldVersion < 4) {
      await _seedDemoOwners(db);
    }

    // v4 có 4 cửa hàng demo - quá rối cho phạm vi đồ án (khách không phân
    // biệt được món của quán nào, dễ trùng tên món giữa các quán). v5 gộp
    // hết về lại đúng 1 cửa hàng: món của 3 quán kia chuyển hết về
    // `store_1`, xoá 3 quán + 3 tài khoản owner demo không còn cần nữa.
    if (oldVersion < 5) {
      await db.update(
        'foods',
        {'store_id': 'store_1'},
        where: 'store_id IN (?, ?, ?)',
        whereArgs: ['store_2', 'store_3', 'store_4'],
      );
      await db.delete('stores', where: 'id IN (?, ?, ?)', whereArgs: ['store_2', 'store_3', 'store_4']);
      await db.delete(
        'users',
        where: 'id IN (?, ?, ?)',
        whereArgs: ['user_owner_demo_2', 'user_owner_demo_3', 'user_owner_demo_4'],
      );
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        avatar TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT 'customer',
        store_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE stores (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        rating REAL NOT NULL DEFAULT 4.5,
        image TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL REFERENCES stores(id),
        category_id TEXT NOT NULL REFERENCES categories(id),
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL,
        image TEXT NOT NULL DEFAULT '',
        emoji TEXT NOT NULL DEFAULT '',
        rating REAL NOT NULL DEFAULT 4.5,
        is_available INTEGER NOT NULL DEFAULT 1,
        kcal INTEGER NOT NULL DEFAULT 150,
        ready_minutes INTEGER NOT NULL DEFAULT 5,
        serve_temp TEXT NOT NULL DEFAULT '',
        flavour_tags TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE favourites (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        food_id TEXT NOT NULL REFERENCES foods(id),
        UNIQUE(user_id, food_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        food_id TEXT NOT NULL REFERENCES foods(id),
        quantity INTEGER NOT NULL DEFAULT 1,
        size TEXT NOT NULL DEFAULT 'medium',
        note TEXT NOT NULL DEFAULT ''
      )
    ''');

    await _createOrderTables(db);
    await _createVoucherTable(db);

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        title TEXT NOT NULL,
        body TEXT NOT NULL DEFAULT '',
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        store_id TEXT NOT NULL REFERENCES stores(id),
        content TEXT NOT NULL,
        is_from_user INTEGER NOT NULL DEFAULT 1,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createOrderTables(Database db) async {
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_code TEXT NOT NULL,
        user_id TEXT NOT NULL REFERENCES users(id),
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'paid',
        payment_method TEXT NOT NULL DEFAULT 'card',
        card_last4 TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL REFERENCES orders(id),
        food_id TEXT NOT NULL REFERENCES foods(id),
        quantity INTEGER NOT NULL DEFAULT 1,
        price_at_order REAL NOT NULL
      )
    ''');
  }

  Future<void> _createVoucherTable(Database db) async {
    await db.execute('''
      CREATE TABLE vouchers (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL UNIQUE REFERENCES orders(id),
        code TEXT NOT NULL,
        qr_data TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        is_redeemed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Băm mật khẩu demo bằng SHA-256 - dùng chung logic với [AuthService]
  /// (tách hàm riêng ở đây để seed không phải phụ thuộc ngược vào service).
  String _hash(String plain) => sha256.convert(utf8.encode(plain)).toString();

  /// Tài khoản chủ quán demo, gắn sẵn với `store_1` - để chấm bài/test tính
  /// năng phân quyền ngay mà không cần đăng ký chủ quán mới. App chỉ có
  /// đúng 1 cửa hàng (xem [_seedData]) nên chỉ cần 1 owner demo.
  List<Map<String, Object?>> _demoOwnerRows() => [
        {
          'id': 'user_owner_demo',
          'full_name': 'Scoops Owner Demo',
          'email': 'owner@scoops.com',
          'password_hash': _hash('123456'),
          'phone': '0909876543',
          'address': '45 Lê Lợi, Quận 1, TP.HCM',
          'avatar': '',
          'role': 'owner',
          'store_id': 'store_1',
        },
      ];

  void _insertDemoOwners(Batch batch) {
    for (final row in _demoOwnerRows()) {
      batch.insert('users', row);
    }
  }

  /// Dùng khi nâng cấp từ schema cũ lên v3/v4 - lúc này các store đã tồn
  /// tại sẵn từ trước nên chỉ cần chèn thêm user, bỏ qua owner nào đã có.
  Future<void> _seedDemoOwners(Database db) async {
    for (final row in _demoOwnerRows()) {
      await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// Thông số dinh dưỡng/chuẩn bị/hương vị cho từng món, khoá theo food id -
  /// dùng chung cho cả lúc seed lần đầu ([_seedData]) và lúc nâng cấp từ
  /// schema cũ ([_backfillFoodExtras]) để không lặp lại 1 bảng dữ liệu 2 nơi.
  static const Map<String, (int kcal, int readyMinutes, String serveTemp, String flavourTags)> _foodExtras = {
    'food_1': (180, 3, '-2°C', 'Sugary,Creamy,Classic'),
    'food_2': (210, 3, '-2°C', 'Sugary,Rich,Classic'),
    'food_3': (170, 3, '-2°C', 'Fruity,Sweet,Light'),
    'food_4': (195, 3, '-2°C', 'Minty,Refreshing,Playful'),
    'food_5': (320, 5, 'Chilled', 'Sugary,Rich,Classic'),
    'food_6': (380, 8, 'Hot', 'Rich,Indulgent,Warm'),
    'food_7': (340, 5, 'Chilled', 'Creamy,Rich,Tangy'),
    'food_8': (290, 5, 'Chilled', 'Earthy,Light,Refreshing'),
    'food_9': (160, 2, 'Warm', 'Sugary,Crunchy,Classic'),
    'food_10': (150, 2, 'Warm', 'Wholesome,Chewy,Mild'),
    'food_11': (190, 2, 'Warm', 'Rich,Crunchy,Indulgent'),
    'food_12': (175, 2, 'Warm', 'Nutty,Sweet,Crunchy'),
    'food_13': (240, 2, 'Room temp', 'Sugary,Fluffy,Classic'),
    'food_14': (260, 2, 'Room temp', 'Rich,Fluffy,Playful'),
    'food_15': (250, 2, 'Room temp', 'Fruity,Sweet,Playful'),
    'food_16': (255, 2, 'Room temp', 'Sugary,Playful,Sweet'),
    'food_17': (220, 4, 'Iced', 'Creamy,Sweet,Trendy'),
    'food_18': (190, 4, 'Hot', 'Earthy,Creamy,Calm'),
    'food_19': (110, 3, 'Iced', 'Bold,Energizing,Classic'),
    'food_20': (90, 3, 'Iced', 'Fruity,Refreshing,Zesty'),
    'food_21': (270, 4, 'Warm', 'Buttery,Flaky,Classic'),
    'food_22': (310, 4, 'Warm', 'Rich,Flaky,Indulgent'),
    'food_23': (350, 6, 'Warm', 'Sugary,Spiced,Comforting'),
    'food_24': (280, 5, 'Chilled', 'Fruity,Creamy,Light'),
  };

  Future<void> _backfillFoodExtras(Database db) async {
    final batch = db.batch();
    for (final entry in _foodExtras.entries) {
      final (kcal, readyMinutes, serveTemp, flavourTags) = entry.value;
      batch.update(
        'foods',
        {
          'kcal': kcal,
          'ready_minutes': readyMinutes,
          'serve_temp': serveTemp,
          'flavour_tags': flavourTags,
        },
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now();
    final batch = db.batch();

    // ── 1 user demo ─────────────────────────────────────────────
    batch.insert('users', {
      'id': 'user_demo',
      'full_name': 'Scoops Demo',
      'email': 'demo@scoops.com',
      'password_hash': _hash('123456'),
      'phone': '0901234567',
      'address': '12 Nguyễn Huệ, Quận 1, TP.HCM',
      'avatar': '',
    });

    _insertDemoOwners(batch);

    // ── 6 danh mục ──────────────────────────────────────────────
    const categories = [
      {'id': 'cat_ice_cream', 'name': 'Ice Cream', 'emoji': '🍦'},
      {'id': 'cat_cakes', 'name': 'Cakes', 'emoji': '🍰'},
      {'id': 'cat_cookies', 'name': 'Cookies', 'emoji': '🍪'},
      {'id': 'cat_donuts', 'name': 'Donuts', 'emoji': '🍩'},
      {'id': 'cat_drinks', 'name': 'Drinks', 'emoji': '🧋'},
      {'id': 'cat_pastries', 'name': 'Pastries', 'emoji': '🥐'},
    ];
    for (final c in categories) {
      batch.insert('categories', c);
    }

    // ── 1 cửa hàng duy nhất (toạ độ thật khu vực TP.HCM) ───────
    const stores = [
      {
        'id': 'store_1',
        'name': 'Scoops District 1',
        'address': '45 Lê Lợi, Quận 1, TP.HCM',
        'lat': 10.7769,
        'lng': 106.7009,
        'rating': 4.8,
        'image': '',
      },
    ];
    for (final s in stores) {
      batch.insert('stores', s);
    }

    // ── 24 món (4 món / danh mục), tất cả cùng thuộc `store_1` ─
    final foods = <Map<String, Object?>>[
      // Ice Cream
      _food('food_1', 'store_1', 'cat_ice_cream', 'Vanilla Scoop',
          'Kem vani béo mịn, ủ lạnh truyền thống.', 5.00, '🍦', 4.7),
      _food('food_2', 'store_1', 'cat_ice_cream', 'Chocolate Scoop',
          'Kem socola đậm vị từ cacao nguyên chất.', 5.00, '🍨', 4.8),
      _food('food_3', 'store_1', 'cat_ice_cream', 'Strawberry Scoop',
          'Kem dâu tươi, vị chua ngọt hài hoà.', 5.00, '🍓', 4.6),
      _food('food_4', 'store_1', 'cat_ice_cream', 'Mint Choco Scoop',
          'Kem bạc hà mát lạnh xen socola chip.', 5.50, '🍧', 4.5),
      // Cakes
      _food('food_5', 'store_1', 'cat_cakes', 'Red Velvet Slice',
          'Bánh red velvet mềm ẩm phủ kem phô mai.', 6.00, '🍰', 4.7),
      _food('food_6', 'store_1', 'cat_cakes', 'Choco Lava Cake',
          'Bánh socola chảy nhân nóng hổi.', 6.50, '🍫', 4.9),
      _food('food_7', 'store_1', 'cat_cakes', 'Cheesecake Slice',
          'Cheesecake New York béo ngậy.', 6.00, '🍰', 4.6),
      _food('food_8', 'store_1', 'cat_cakes', 'Matcha Cake',
          'Bánh trà xanh Nhật Bản thanh nhẹ.', 6.50, '🍵', 4.5),
      // Cookies
      _food('food_9', 'store_1', 'cat_cookies', 'Choco Chip Cookie',
          'Cookie bơ giòn rụm với chip socola.', 3.00, '🍪', 4.6),
      _food('food_10', 'store_1', 'cat_cookies', 'Oatmeal Cookie',
          'Cookie yến mạch nho khô tốt cho sức khoẻ.', 3.00, '🍭', 4.4),
      _food('food_11', 'store_1', 'cat_cookies', 'Double Choco Cookie',
          'Cookie socola kép đậm đà.', 3.50, '🍪', 4.7),
      _food('food_12', 'store_1', 'cat_cookies', 'Peanut Butter Cookie',
          'Cookie bơ đậu phộng thơm béo.', 3.50, '🥜', 4.5),
      // Donuts
      _food('food_13', 'store_1', 'cat_donuts', 'Glazed Donut',
          'Donut phủ đường glaze cổ điển.', 2.50, '🍩', 4.5),
      _food('food_14', 'store_1', 'cat_donuts', 'Choco Donut',
          'Donut phủ socola đen bóng.', 2.50, '🍩', 4.6),
      _food('food_15', 'store_1', 'cat_donuts', 'Strawberry Donut',
          'Donut phủ kem dâu hồng dễ thương.', 2.80, '🍓', 4.4),
      _food('food_16', 'store_1', 'cat_donuts', 'Sprinkle Donut',
          'Donut rắc hạt đường màu sặc sỡ.', 2.80, '🍩', 4.6),
      // Drinks
      _food('food_17', 'store_1', 'cat_drinks', 'Milk Tea',
          'Trà sữa trân châu đường đen.', 4.00, '🧋', 4.7),
      _food('food_18', 'store_1', 'cat_drinks', 'Matcha Latte',
          'Matcha latte sữa tươi thơm béo.', 4.50, '🍵', 4.6),
      _food('food_19', 'store_1', 'cat_drinks', 'Iced Coffee',
          'Cà phê đá truyền thống đậm đà.', 3.50, '☕', 4.5),
      _food('food_20', 'store_1', 'cat_drinks', 'Fresh Lemonade',
          'Nước chanh tươi mát lạnh giải nhiệt.', 3.00, '🍋', 4.4),
      // Pastries
      _food('food_21', 'store_1', 'cat_pastries', 'Croissant',
          'Bánh sừng bò bơ Pháp nhiều lớp giòn xốp.', 3.50, '🥐', 4.6),
      _food('food_22', 'store_1', 'cat_pastries', 'Pain au Chocolat',
          'Bánh sừng bò nhân socola tan chảy.', 4.00, '🥐', 4.7),
      _food('food_23', 'store_1', 'cat_pastries', 'Cinnamon Roll',
          'Bánh cuộn quế phủ kem phô mai.', 4.20, '🧁', 4.5),
      _food('food_24', 'store_1', 'cat_pastries', 'Fruit Tart',
          'Tart trái cây tươi phủ kem custard.', 5.00, '🥧', 4.8),
    ];
    for (final f in foods) {
      batch.insert('foods', f);
    }

    // ── Thông báo chào mừng mặc định cho user demo ─────────────
    batch.insert('notifications', {
      'id': 'notif_welcome',
      'user_id': 'user_demo',
      'title': 'Welcome to Scoops! 🍦',
      'body': 'Explore our sweet menu and enjoy 10% off your first order.',
      'is_read': 0,
      'created_at': now.toIso8601String(),
    });

    await batch.commit(noResult: true);
  }

  Map<String, Object?> _food(
    String id,
    String storeId,
    String categoryId,
    String name,
    String description,
    double price,
    String emoji,
    double rating,
  ) {
    final extra = _foodExtras[id]!;
    return {
      'id': id,
      'store_id': storeId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image': '',
      'emoji': emoji,
      'rating': rating,
      'is_available': 1,
      'kcal': extra.$1,
      'ready_minutes': extra.$2,
      'serve_temp': extra.$3,
      'flavour_tags': extra.$4,
    };
  }

  /// Xoá sạch dữ liệu giao dịch (giỏ hàng, đơn hàng, thông báo, chat) của 1
  /// user - dùng khi cần reset trạng thái để test hoặc đăng xuất sâu.
  Future<void> resetUserData(String userId) async {
    final db = await database;
    await db.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('favourites', where: 'user_id = ?', whereArgs: [userId]);
  }
}
