import 'package:cloud_firestore/cloud_firestore.dart';

/// Coerces the various shapes a Firestore/JSON date can arrive as (Firestore
/// [Timestamp], epoch millis, ISO-8601 string, or already-a-[DateTime]) into a
/// [DateTime]. Returns null for missing/unparseable values.
///
/// Keeps model mappers pure and unit-testable: tests can pass a plain
/// [DateTime] or int without having to build a [Timestamp].
DateTime? dateFromFirestore(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
