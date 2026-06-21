import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class CompanyProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get gstNumber => text()();
  TextColumn get contactNumber => text()();
  TextColumn get email => text()();
  TextColumn get bankAccountName => text()();
  TextColumn get bankName => text()();
  TextColumn get bankAccountNumber => text()();
  TextColumn get bankIfscCode => text()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get signaturePath => text().nullable()();
  RealColumn get defaultGstPercentage => real().withDefault(const Constant(5.0))();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().customConstraint('UNIQUE')();
  DateTimeColumn get invoiceDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get bookingRef => text().nullable()();
  DateTimeColumn get bookingDate => dateTime().nullable()();
  TextColumn get customerName => text()();
  TextColumn get customerAddress => text()();
  TextColumn get customerGstNumber => text().nullable()();
  TextColumn get customerContactNumber => text().nullable()();
  
  // Tourism specific header fields
  TextColumn get tourTrip => text().nullable()();
  DateTimeColumn get travelDate => dateTime().nullable()();
  IntColumn get noOfDays => integer().nullable()();
  IntColumn get noOfVehicles => integer().nullable()();
  TextColumn get coordinatorName => text().nullable()();
  
  // Calculations
  RealColumn get subTotal => real()();
  RealColumn get cgst => real()();
  RealColumn get sgst => real()();
  RealColumn get totalGst => real()();
  RealColumn get grandTotal => real()();
  RealColumn get advancePaid => real().withDefault(const Constant(0.0))();
  TextColumn get amountPaidInWords => text()();
  
  // Customization
  TextColumn get templateType => text().withDefault(const Constant('tourism'))(); // 'tourism' or 'standard'
  TextColumn get pdfPath => text().nullable()();
  TextColumn get docxPath => text().nullable()();
  DateTimeColumn get createdDate => dateTime()();
}

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get description => text()();
  IntColumn get noOfVehicles => integer().nullable()(); // Nullable if standard line item
  DateTimeColumn get itemDate => dateTime().nullable()();
  TextColumn get fromTo => text().nullable()();
  RealColumn get quantityDays => real()(); // Days in tourism, Qty in standard
  RealColumn get rate => real()();
  RealColumn get amount => real()();
}

@DriftDatabase(tables: [CompanyProfiles, Invoices, InvoiceItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gst_invoice.db'));
    return NativeDatabase.createInBackground(file);
  });
}
