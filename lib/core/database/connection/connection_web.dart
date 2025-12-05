import 'package:drift/drift.dart';
import 'package:drift/web.dart';

DatabaseConnection connect() {
  return DatabaseConnection(
    WebDatabase.withStorage(
      DriftWebStorage.indexedDb('erp_dot_db'),
    ),
  );
}
