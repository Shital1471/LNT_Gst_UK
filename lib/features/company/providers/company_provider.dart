import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class CompanyProfileNotifier extends StateNotifier<AsyncValue<CompanyProfile?>> {
  final AppDatabase _db;

  CompanyProfileNotifier(this._db) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await (_db.select(_db.companyProfiles)..limit(1)).getSingleOrNull();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveProfile({
    required String name,
    required String address,
    required String gstNumber,
    required String contactNumber,
    required String email,
    required String bankAccountName,
    required String bankName,
    required String bankAccountNumber,
    required String bankIfscCode,
    String? logoPath,
    String? signaturePath,
    required double defaultGstPercentage,
  }) async {
    final companion = CompanyProfilesCompanion(
      name: Value(name),
      address: Value(address),
      gstNumber: Value(gstNumber),
      contactNumber: Value(contactNumber),
      email: Value(email),
      bankAccountName: Value(bankAccountName),
      bankName: Value(bankName),
      bankAccountNumber: Value(bankAccountNumber),
      bankIfscCode: Value(bankIfscCode),
      logoPath: Value(logoPath),
      signaturePath: Value(signaturePath),
      defaultGstPercentage: Value(defaultGstPercentage),
    );

    final existing = await (_db.select(_db.companyProfiles)..limit(1)).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.companyProfiles).insert(companion);
    } else {
      await (_db.update(_db.companyProfiles)..where((t) => t.id.equals(existing.id))).write(companion);
    }
    await loadProfile();
  }
}

final companyProfileStateProvider = StateNotifierProvider<CompanyProfileNotifier, AsyncValue<CompanyProfile?>>((ref) {
  final db = ref.watch(databaseProvider);
  return CompanyProfileNotifier(db);
});
