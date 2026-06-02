// App-wide SQLite handle (sqflite). Currently backs only the Quick Shoot upload
// queue (`pending_photos`); future local tables register their schema here in
// [_onCreate] / [_onUpgrade] so there's a single versioned database file.
//
// Lazy singleton — the first caller opens the DB; everyone after shares it.

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'gang_roll.db';
  static const _version = 1;

  Database? _db;

  /// Opens (once) and returns the shared database.
  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _fileName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_photos (
        id TEXT PRIMARY KEY,
        local_path TEXT NOT NULL,
        moment_id TEXT NOT NULL,
        moment_name TEXT NOT NULL,
        status TEXT NOT NULL,
        captured_at INTEGER NOT NULL,
        uploaded_at INTEGER,
        remote_url TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_status ON pending_photos(status)',
    );
    await db.execute(
      'CREATE INDEX idx_moment ON pending_photos(moment_id)',
    );
    await db.execute(
      'CREATE INDEX idx_captured ON pending_photos(captured_at DESC)',
    );
  }

  // No migrations yet (v1). Future schema bumps branch on [oldVersion] here.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}
}
