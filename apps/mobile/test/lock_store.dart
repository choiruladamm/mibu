import 'package:mibu/data/repositories/app_lock_repository.dart';

/// In-memory [LockStore]: tests never touch the real keychain / Keystore.
class MemoryLockStore implements LockStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();
}
