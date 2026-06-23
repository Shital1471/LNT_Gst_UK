// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CompanyProfilesTable extends CompanyProfiles
    with TableInfo<$CompanyProfilesTable, CompanyProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompanyProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gstNumberMeta = const VerificationMeta(
    'gstNumber',
  );
  @override
  late final GeneratedColumn<String> gstNumber = GeneratedColumn<String>(
    'gst_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactNumberMeta = const VerificationMeta(
    'contactNumber',
  );
  @override
  late final GeneratedColumn<String> contactNumber = GeneratedColumn<String>(
    'contact_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankAccountNameMeta = const VerificationMeta(
    'bankAccountName',
  );
  @override
  late final GeneratedColumn<String> bankAccountName = GeneratedColumn<String>(
    'bank_account_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankAccountNumberMeta = const VerificationMeta(
    'bankAccountNumber',
  );
  @override
  late final GeneratedColumn<String> bankAccountNumber =
      GeneratedColumn<String>(
        'bank_account_number',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bankIfscCodeMeta = const VerificationMeta(
    'bankIfscCode',
  );
  @override
  late final GeneratedColumn<String> bankIfscCode = GeneratedColumn<String>(
    'bank_ifsc_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signaturePathMeta = const VerificationMeta(
    'signaturePath',
  );
  @override
  late final GeneratedColumn<String> signaturePath = GeneratedColumn<String>(
    'signature_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultGstPercentageMeta =
      const VerificationMeta('defaultGstPercentage');
  @override
  late final GeneratedColumn<double> defaultGstPercentage =
      GeneratedColumn<double>(
        'default_gst_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(5.0),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    gstNumber,
    contactNumber,
    email,
    bankAccountName,
    bankName,
    bankAccountNumber,
    bankIfscCode,
    logoPath,
    signaturePath,
    defaultGstPercentage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'company_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompanyProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('gst_number')) {
      context.handle(
        _gstNumberMeta,
        gstNumber.isAcceptableOrUnknown(data['gst_number']!, _gstNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_gstNumberMeta);
    }
    if (data.containsKey('contact_number')) {
      context.handle(
        _contactNumberMeta,
        contactNumber.isAcceptableOrUnknown(
          data['contact_number']!,
          _contactNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactNumberMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('bank_account_name')) {
      context.handle(
        _bankAccountNameMeta,
        bankAccountName.isAcceptableOrUnknown(
          data['bank_account_name']!,
          _bankAccountNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bankAccountNameMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('bank_account_number')) {
      context.handle(
        _bankAccountNumberMeta,
        bankAccountNumber.isAcceptableOrUnknown(
          data['bank_account_number']!,
          _bankAccountNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bankAccountNumberMeta);
    }
    if (data.containsKey('bank_ifsc_code')) {
      context.handle(
        _bankIfscCodeMeta,
        bankIfscCode.isAcceptableOrUnknown(
          data['bank_ifsc_code']!,
          _bankIfscCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bankIfscCodeMeta);
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('signature_path')) {
      context.handle(
        _signaturePathMeta,
        signaturePath.isAcceptableOrUnknown(
          data['signature_path']!,
          _signaturePathMeta,
        ),
      );
    }
    if (data.containsKey('default_gst_percentage')) {
      context.handle(
        _defaultGstPercentageMeta,
        defaultGstPercentage.isAcceptableOrUnknown(
          data['default_gst_percentage']!,
          _defaultGstPercentageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompanyProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanyProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      gstNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gst_number'],
      )!,
      contactNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_number'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      bankAccountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account_name'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      bankAccountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account_number'],
      )!,
      bankIfscCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_ifsc_code'],
      )!,
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      signaturePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_path'],
      ),
      defaultGstPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_gst_percentage'],
      )!,
    );
  }

  @override
  $CompanyProfilesTable createAlias(String alias) {
    return $CompanyProfilesTable(attachedDatabase, alias);
  }
}

class CompanyProfile extends DataClass implements Insertable<CompanyProfile> {
  final int id;
  final String name;
  final String address;
  final String gstNumber;
  final String contactNumber;
  final String email;
  final String bankAccountName;
  final String bankName;
  final String bankAccountNumber;
  final String bankIfscCode;
  final String? logoPath;
  final String? signaturePath;
  final double defaultGstPercentage;
  const CompanyProfile({
    required this.id,
    required this.name,
    required this.address,
    required this.gstNumber,
    required this.contactNumber,
    required this.email,
    required this.bankAccountName,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankIfscCode,
    this.logoPath,
    this.signaturePath,
    required this.defaultGstPercentage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['gst_number'] = Variable<String>(gstNumber);
    map['contact_number'] = Variable<String>(contactNumber);
    map['email'] = Variable<String>(email);
    map['bank_account_name'] = Variable<String>(bankAccountName);
    map['bank_name'] = Variable<String>(bankName);
    map['bank_account_number'] = Variable<String>(bankAccountNumber);
    map['bank_ifsc_code'] = Variable<String>(bankIfscCode);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    if (!nullToAbsent || signaturePath != null) {
      map['signature_path'] = Variable<String>(signaturePath);
    }
    map['default_gst_percentage'] = Variable<double>(defaultGstPercentage);
    return map;
  }

  CompanyProfilesCompanion toCompanion(bool nullToAbsent) {
    return CompanyProfilesCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      gstNumber: Value(gstNumber),
      contactNumber: Value(contactNumber),
      email: Value(email),
      bankAccountName: Value(bankAccountName),
      bankName: Value(bankName),
      bankAccountNumber: Value(bankAccountNumber),
      bankIfscCode: Value(bankIfscCode),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      signaturePath: signaturePath == null && nullToAbsent
          ? const Value.absent()
          : Value(signaturePath),
      defaultGstPercentage: Value(defaultGstPercentage),
    );
  }

  factory CompanyProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanyProfile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      gstNumber: serializer.fromJson<String>(json['gstNumber']),
      contactNumber: serializer.fromJson<String>(json['contactNumber']),
      email: serializer.fromJson<String>(json['email']),
      bankAccountName: serializer.fromJson<String>(json['bankAccountName']),
      bankName: serializer.fromJson<String>(json['bankName']),
      bankAccountNumber: serializer.fromJson<String>(json['bankAccountNumber']),
      bankIfscCode: serializer.fromJson<String>(json['bankIfscCode']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      signaturePath: serializer.fromJson<String?>(json['signaturePath']),
      defaultGstPercentage: serializer.fromJson<double>(
        json['defaultGstPercentage'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'gstNumber': serializer.toJson<String>(gstNumber),
      'contactNumber': serializer.toJson<String>(contactNumber),
      'email': serializer.toJson<String>(email),
      'bankAccountName': serializer.toJson<String>(bankAccountName),
      'bankName': serializer.toJson<String>(bankName),
      'bankAccountNumber': serializer.toJson<String>(bankAccountNumber),
      'bankIfscCode': serializer.toJson<String>(bankIfscCode),
      'logoPath': serializer.toJson<String?>(logoPath),
      'signaturePath': serializer.toJson<String?>(signaturePath),
      'defaultGstPercentage': serializer.toJson<double>(defaultGstPercentage),
    };
  }

  CompanyProfile copyWith({
    int? id,
    String? name,
    String? address,
    String? gstNumber,
    String? contactNumber,
    String? email,
    String? bankAccountName,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfscCode,
    Value<String?> logoPath = const Value.absent(),
    Value<String?> signaturePath = const Value.absent(),
    double? defaultGstPercentage,
  }) => CompanyProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    gstNumber: gstNumber ?? this.gstNumber,
    contactNumber: contactNumber ?? this.contactNumber,
    email: email ?? this.email,
    bankAccountName: bankAccountName ?? this.bankAccountName,
    bankName: bankName ?? this.bankName,
    bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
    bankIfscCode: bankIfscCode ?? this.bankIfscCode,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    signaturePath: signaturePath.present
        ? signaturePath.value
        : this.signaturePath,
    defaultGstPercentage: defaultGstPercentage ?? this.defaultGstPercentage,
  );
  CompanyProfile copyWithCompanion(CompanyProfilesCompanion data) {
    return CompanyProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      gstNumber: data.gstNumber.present ? data.gstNumber.value : this.gstNumber,
      contactNumber: data.contactNumber.present
          ? data.contactNumber.value
          : this.contactNumber,
      email: data.email.present ? data.email.value : this.email,
      bankAccountName: data.bankAccountName.present
          ? data.bankAccountName.value
          : this.bankAccountName,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      bankAccountNumber: data.bankAccountNumber.present
          ? data.bankAccountNumber.value
          : this.bankAccountNumber,
      bankIfscCode: data.bankIfscCode.present
          ? data.bankIfscCode.value
          : this.bankIfscCode,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      signaturePath: data.signaturePath.present
          ? data.signaturePath.value
          : this.signaturePath,
      defaultGstPercentage: data.defaultGstPercentage.present
          ? data.defaultGstPercentage.value
          : this.defaultGstPercentage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanyProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('gstNumber: $gstNumber, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('email: $email, ')
          ..write('bankAccountName: $bankAccountName, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccountNumber: $bankAccountNumber, ')
          ..write('bankIfscCode: $bankIfscCode, ')
          ..write('logoPath: $logoPath, ')
          ..write('signaturePath: $signaturePath, ')
          ..write('defaultGstPercentage: $defaultGstPercentage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    gstNumber,
    contactNumber,
    email,
    bankAccountName,
    bankName,
    bankAccountNumber,
    bankIfscCode,
    logoPath,
    signaturePath,
    defaultGstPercentage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanyProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.gstNumber == this.gstNumber &&
          other.contactNumber == this.contactNumber &&
          other.email == this.email &&
          other.bankAccountName == this.bankAccountName &&
          other.bankName == this.bankName &&
          other.bankAccountNumber == this.bankAccountNumber &&
          other.bankIfscCode == this.bankIfscCode &&
          other.logoPath == this.logoPath &&
          other.signaturePath == this.signaturePath &&
          other.defaultGstPercentage == this.defaultGstPercentage);
}

class CompanyProfilesCompanion extends UpdateCompanion<CompanyProfile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String> gstNumber;
  final Value<String> contactNumber;
  final Value<String> email;
  final Value<String> bankAccountName;
  final Value<String> bankName;
  final Value<String> bankAccountNumber;
  final Value<String> bankIfscCode;
  final Value<String?> logoPath;
  final Value<String?> signaturePath;
  final Value<double> defaultGstPercentage;
  const CompanyProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.gstNumber = const Value.absent(),
    this.contactNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.bankAccountName = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankAccountNumber = const Value.absent(),
    this.bankIfscCode = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.signaturePath = const Value.absent(),
    this.defaultGstPercentage = const Value.absent(),
  });
  CompanyProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String address,
    required String gstNumber,
    required String contactNumber,
    required String email,
    required String bankAccountName,
    required String bankName,
    required String bankAccountNumber,
    required String bankIfscCode,
    this.logoPath = const Value.absent(),
    this.signaturePath = const Value.absent(),
    this.defaultGstPercentage = const Value.absent(),
  }) : name = Value(name),
       address = Value(address),
       gstNumber = Value(gstNumber),
       contactNumber = Value(contactNumber),
       email = Value(email),
       bankAccountName = Value(bankAccountName),
       bankName = Value(bankName),
       bankAccountNumber = Value(bankAccountNumber),
       bankIfscCode = Value(bankIfscCode);
  static Insertable<CompanyProfile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? gstNumber,
    Expression<String>? contactNumber,
    Expression<String>? email,
    Expression<String>? bankAccountName,
    Expression<String>? bankName,
    Expression<String>? bankAccountNumber,
    Expression<String>? bankIfscCode,
    Expression<String>? logoPath,
    Expression<String>? signaturePath,
    Expression<double>? defaultGstPercentage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (gstNumber != null) 'gst_number': gstNumber,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (email != null) 'email': email,
      if (bankAccountName != null) 'bank_account_name': bankAccountName,
      if (bankName != null) 'bank_name': bankName,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (bankIfscCode != null) 'bank_ifsc_code': bankIfscCode,
      if (logoPath != null) 'logo_path': logoPath,
      if (signaturePath != null) 'signature_path': signaturePath,
      if (defaultGstPercentage != null)
        'default_gst_percentage': defaultGstPercentage,
    });
  }

  CompanyProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? address,
    Value<String>? gstNumber,
    Value<String>? contactNumber,
    Value<String>? email,
    Value<String>? bankAccountName,
    Value<String>? bankName,
    Value<String>? bankAccountNumber,
    Value<String>? bankIfscCode,
    Value<String?>? logoPath,
    Value<String?>? signaturePath,
    Value<double>? defaultGstPercentage,
  }) {
    return CompanyProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfscCode: bankIfscCode ?? this.bankIfscCode,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      defaultGstPercentage: defaultGstPercentage ?? this.defaultGstPercentage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (gstNumber.present) {
      map['gst_number'] = Variable<String>(gstNumber.value);
    }
    if (contactNumber.present) {
      map['contact_number'] = Variable<String>(contactNumber.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (bankAccountName.present) {
      map['bank_account_name'] = Variable<String>(bankAccountName.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (bankAccountNumber.present) {
      map['bank_account_number'] = Variable<String>(bankAccountNumber.value);
    }
    if (bankIfscCode.present) {
      map['bank_ifsc_code'] = Variable<String>(bankIfscCode.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (signaturePath.present) {
      map['signature_path'] = Variable<String>(signaturePath.value);
    }
    if (defaultGstPercentage.present) {
      map['default_gst_percentage'] = Variable<double>(
        defaultGstPercentage.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompanyProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('gstNumber: $gstNumber, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('email: $email, ')
          ..write('bankAccountName: $bankAccountName, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccountNumber: $bankAccountNumber, ')
          ..write('bankIfscCode: $bankIfscCode, ')
          ..write('logoPath: $logoPath, ')
          ..write('signaturePath: $signaturePath, ')
          ..write('defaultGstPercentage: $defaultGstPercentage')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'UNIQUE',
  );
  static const VerificationMeta _invoiceDateMeta = const VerificationMeta(
    'invoiceDate',
  );
  @override
  late final GeneratedColumn<DateTime> invoiceDate = GeneratedColumn<DateTime>(
    'invoice_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookingRefMeta = const VerificationMeta(
    'bookingRef',
  );
  @override
  late final GeneratedColumn<String> bookingRef = GeneratedColumn<String>(
    'booking_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingDateMeta = const VerificationMeta(
    'bookingDate',
  );
  @override
  late final GeneratedColumn<DateTime> bookingDate = GeneratedColumn<DateTime>(
    'booking_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerAddressMeta = const VerificationMeta(
    'customerAddress',
  );
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
    'customer_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerGstNumberMeta = const VerificationMeta(
    'customerGstNumber',
  );
  @override
  late final GeneratedColumn<String> customerGstNumber =
      GeneratedColumn<String>(
        'customer_gst_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customerContactNumberMeta =
      const VerificationMeta('customerContactNumber');
  @override
  late final GeneratedColumn<String> customerContactNumber =
      GeneratedColumn<String>(
        'customer_contact_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tourTripMeta = const VerificationMeta(
    'tourTrip',
  );
  @override
  late final GeneratedColumn<String> tourTrip = GeneratedColumn<String>(
    'tour_trip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _travelDateMeta = const VerificationMeta(
    'travelDate',
  );
  @override
  late final GeneratedColumn<DateTime> travelDate = GeneratedColumn<DateTime>(
    'travel_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noOfDaysMeta = const VerificationMeta(
    'noOfDays',
  );
  @override
  late final GeneratedColumn<int> noOfDays = GeneratedColumn<int>(
    'no_of_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noOfVehiclesMeta = const VerificationMeta(
    'noOfVehicles',
  );
  @override
  late final GeneratedColumn<int> noOfVehicles = GeneratedColumn<int>(
    'no_of_vehicles',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coordinatorNameMeta = const VerificationMeta(
    'coordinatorName',
  );
  @override
  late final GeneratedColumn<String> coordinatorName = GeneratedColumn<String>(
    'coordinator_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subTotalMeta = const VerificationMeta(
    'subTotal',
  );
  @override
  late final GeneratedColumn<double> subTotal = GeneratedColumn<double>(
    'sub_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cgstMeta = const VerificationMeta('cgst');
  @override
  late final GeneratedColumn<double> cgst = GeneratedColumn<double>(
    'cgst',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sgstMeta = const VerificationMeta('sgst');
  @override
  late final GeneratedColumn<double> sgst = GeneratedColumn<double>(
    'sgst',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalGstMeta = const VerificationMeta(
    'totalGst',
  );
  @override
  late final GeneratedColumn<double> totalGst = GeneratedColumn<double>(
    'total_gst',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grandTotalMeta = const VerificationMeta(
    'grandTotal',
  );
  @override
  late final GeneratedColumn<double> grandTotal = GeneratedColumn<double>(
    'grand_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _advancePaidMeta = const VerificationMeta(
    'advancePaid',
  );
  @override
  late final GeneratedColumn<double> advancePaid = GeneratedColumn<double>(
    'advance_paid',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _amountPaidInWordsMeta = const VerificationMeta(
    'amountPaidInWords',
  );
  @override
  late final GeneratedColumn<String> amountPaidInWords =
      GeneratedColumn<String>(
        'amount_paid_in_words',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _templateTypeMeta = const VerificationMeta(
    'templateType',
  );
  @override
  late final GeneratedColumn<String> templateType = GeneratedColumn<String>(
    'template_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('tourism'),
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _docxPathMeta = const VerificationMeta(
    'docxPath',
  );
  @override
  late final GeneratedColumn<String> docxPath = GeneratedColumn<String>(
    'docx_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdDateMeta = const VerificationMeta(
    'createdDate',
  );
  @override
  late final GeneratedColumn<DateTime> createdDate = GeneratedColumn<DateTime>(
    'created_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateSchemaJsonMeta =
      const VerificationMeta('templateSchemaJson');
  @override
  late final GeneratedColumn<String> templateSchemaJson =
      GeneratedColumn<String>(
        'template_schema_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fieldValuesJsonMeta = const VerificationMeta(
    'fieldValuesJson',
  );
  @override
  late final GeneratedColumn<String> fieldValuesJson = GeneratedColumn<String>(
    'field_values_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceNumber,
    invoiceDate,
    dueDate,
    bookingRef,
    bookingDate,
    customerName,
    customerAddress,
    customerGstNumber,
    customerContactNumber,
    tourTrip,
    travelDate,
    noOfDays,
    noOfVehicles,
    coordinatorName,
    subTotal,
    cgst,
    sgst,
    totalGst,
    grandTotal,
    advancePaid,
    amountPaidInWords,
    templateType,
    pdfPath,
    docxPath,
    createdDate,
    templateSchemaJson,
    fieldValuesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Invoice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('invoice_date')) {
      context.handle(
        _invoiceDateMeta,
        invoiceDate.isAcceptableOrUnknown(
          data['invoice_date']!,
          _invoiceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceDateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('booking_ref')) {
      context.handle(
        _bookingRefMeta,
        bookingRef.isAcceptableOrUnknown(data['booking_ref']!, _bookingRefMeta),
      );
    }
    if (data.containsKey('booking_date')) {
      context.handle(
        _bookingDateMeta,
        bookingDate.isAcceptableOrUnknown(
          data['booking_date']!,
          _bookingDateMeta,
        ),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('customer_address')) {
      context.handle(
        _customerAddressMeta,
        customerAddress.isAcceptableOrUnknown(
          data['customer_address']!,
          _customerAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerAddressMeta);
    }
    if (data.containsKey('customer_gst_number')) {
      context.handle(
        _customerGstNumberMeta,
        customerGstNumber.isAcceptableOrUnknown(
          data['customer_gst_number']!,
          _customerGstNumberMeta,
        ),
      );
    }
    if (data.containsKey('customer_contact_number')) {
      context.handle(
        _customerContactNumberMeta,
        customerContactNumber.isAcceptableOrUnknown(
          data['customer_contact_number']!,
          _customerContactNumberMeta,
        ),
      );
    }
    if (data.containsKey('tour_trip')) {
      context.handle(
        _tourTripMeta,
        tourTrip.isAcceptableOrUnknown(data['tour_trip']!, _tourTripMeta),
      );
    }
    if (data.containsKey('travel_date')) {
      context.handle(
        _travelDateMeta,
        travelDate.isAcceptableOrUnknown(data['travel_date']!, _travelDateMeta),
      );
    }
    if (data.containsKey('no_of_days')) {
      context.handle(
        _noOfDaysMeta,
        noOfDays.isAcceptableOrUnknown(data['no_of_days']!, _noOfDaysMeta),
      );
    }
    if (data.containsKey('no_of_vehicles')) {
      context.handle(
        _noOfVehiclesMeta,
        noOfVehicles.isAcceptableOrUnknown(
          data['no_of_vehicles']!,
          _noOfVehiclesMeta,
        ),
      );
    }
    if (data.containsKey('coordinator_name')) {
      context.handle(
        _coordinatorNameMeta,
        coordinatorName.isAcceptableOrUnknown(
          data['coordinator_name']!,
          _coordinatorNameMeta,
        ),
      );
    }
    if (data.containsKey('sub_total')) {
      context.handle(
        _subTotalMeta,
        subTotal.isAcceptableOrUnknown(data['sub_total']!, _subTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subTotalMeta);
    }
    if (data.containsKey('cgst')) {
      context.handle(
        _cgstMeta,
        cgst.isAcceptableOrUnknown(data['cgst']!, _cgstMeta),
      );
    } else if (isInserting) {
      context.missing(_cgstMeta);
    }
    if (data.containsKey('sgst')) {
      context.handle(
        _sgstMeta,
        sgst.isAcceptableOrUnknown(data['sgst']!, _sgstMeta),
      );
    } else if (isInserting) {
      context.missing(_sgstMeta);
    }
    if (data.containsKey('total_gst')) {
      context.handle(
        _totalGstMeta,
        totalGst.isAcceptableOrUnknown(data['total_gst']!, _totalGstMeta),
      );
    } else if (isInserting) {
      context.missing(_totalGstMeta);
    }
    if (data.containsKey('grand_total')) {
      context.handle(
        _grandTotalMeta,
        grandTotal.isAcceptableOrUnknown(data['grand_total']!, _grandTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_grandTotalMeta);
    }
    if (data.containsKey('advance_paid')) {
      context.handle(
        _advancePaidMeta,
        advancePaid.isAcceptableOrUnknown(
          data['advance_paid']!,
          _advancePaidMeta,
        ),
      );
    }
    if (data.containsKey('amount_paid_in_words')) {
      context.handle(
        _amountPaidInWordsMeta,
        amountPaidInWords.isAcceptableOrUnknown(
          data['amount_paid_in_words']!,
          _amountPaidInWordsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaidInWordsMeta);
    }
    if (data.containsKey('template_type')) {
      context.handle(
        _templateTypeMeta,
        templateType.isAcceptableOrUnknown(
          data['template_type']!,
          _templateTypeMeta,
        ),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('docx_path')) {
      context.handle(
        _docxPathMeta,
        docxPath.isAcceptableOrUnknown(data['docx_path']!, _docxPathMeta),
      );
    }
    if (data.containsKey('created_date')) {
      context.handle(
        _createdDateMeta,
        createdDate.isAcceptableOrUnknown(
          data['created_date']!,
          _createdDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdDateMeta);
    }
    if (data.containsKey('template_schema_json')) {
      context.handle(
        _templateSchemaJsonMeta,
        templateSchemaJson.isAcceptableOrUnknown(
          data['template_schema_json']!,
          _templateSchemaJsonMeta,
        ),
      );
    }
    if (data.containsKey('field_values_json')) {
      context.handle(
        _fieldValuesJsonMeta,
        fieldValuesJson.isAcceptableOrUnknown(
          data['field_values_json']!,
          _fieldValuesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      )!,
      invoiceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invoice_date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      bookingRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_ref'],
      ),
      bookingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}booking_date'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address'],
      )!,
      customerGstNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_gst_number'],
      ),
      customerContactNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_contact_number'],
      ),
      tourTrip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tour_trip'],
      ),
      travelDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}travel_date'],
      ),
      noOfDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}no_of_days'],
      ),
      noOfVehicles: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}no_of_vehicles'],
      ),
      coordinatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coordinator_name'],
      ),
      subTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sub_total'],
      )!,
      cgst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cgst'],
      )!,
      sgst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sgst'],
      )!,
      totalGst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_gst'],
      )!,
      grandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grand_total'],
      )!,
      advancePaid: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}advance_paid'],
      )!,
      amountPaidInWords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_paid_in_words'],
      )!,
      templateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_type'],
      )!,
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      docxPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}docx_path'],
      ),
      createdDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_date'],
      )!,
      templateSchemaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_schema_json'],
      ),
      fieldValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_values_json'],
      ),
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final int id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String? bookingRef;
  final DateTime? bookingDate;
  final String customerName;
  final String customerAddress;
  final String? customerGstNumber;
  final String? customerContactNumber;
  final String? tourTrip;
  final DateTime? travelDate;
  final int? noOfDays;
  final int? noOfVehicles;
  final String? coordinatorName;
  final double subTotal;
  final double cgst;
  final double sgst;
  final double totalGst;
  final double grandTotal;
  final double advancePaid;
  final String amountPaidInWords;
  final String templateType;
  final String? pdfPath;
  final String? docxPath;
  final DateTime createdDate;
  final String? templateSchemaJson;
  final String? fieldValuesJson;
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    this.bookingRef,
    this.bookingDate,
    required this.customerName,
    required this.customerAddress,
    this.customerGstNumber,
    this.customerContactNumber,
    this.tourTrip,
    this.travelDate,
    this.noOfDays,
    this.noOfVehicles,
    this.coordinatorName,
    required this.subTotal,
    required this.cgst,
    required this.sgst,
    required this.totalGst,
    required this.grandTotal,
    required this.advancePaid,
    required this.amountPaidInWords,
    required this.templateType,
    this.pdfPath,
    this.docxPath,
    required this.createdDate,
    this.templateSchemaJson,
    this.fieldValuesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['invoice_date'] = Variable<DateTime>(invoiceDate);
    map['due_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || bookingRef != null) {
      map['booking_ref'] = Variable<String>(bookingRef);
    }
    if (!nullToAbsent || bookingDate != null) {
      map['booking_date'] = Variable<DateTime>(bookingDate);
    }
    map['customer_name'] = Variable<String>(customerName);
    map['customer_address'] = Variable<String>(customerAddress);
    if (!nullToAbsent || customerGstNumber != null) {
      map['customer_gst_number'] = Variable<String>(customerGstNumber);
    }
    if (!nullToAbsent || customerContactNumber != null) {
      map['customer_contact_number'] = Variable<String>(customerContactNumber);
    }
    if (!nullToAbsent || tourTrip != null) {
      map['tour_trip'] = Variable<String>(tourTrip);
    }
    if (!nullToAbsent || travelDate != null) {
      map['travel_date'] = Variable<DateTime>(travelDate);
    }
    if (!nullToAbsent || noOfDays != null) {
      map['no_of_days'] = Variable<int>(noOfDays);
    }
    if (!nullToAbsent || noOfVehicles != null) {
      map['no_of_vehicles'] = Variable<int>(noOfVehicles);
    }
    if (!nullToAbsent || coordinatorName != null) {
      map['coordinator_name'] = Variable<String>(coordinatorName);
    }
    map['sub_total'] = Variable<double>(subTotal);
    map['cgst'] = Variable<double>(cgst);
    map['sgst'] = Variable<double>(sgst);
    map['total_gst'] = Variable<double>(totalGst);
    map['grand_total'] = Variable<double>(grandTotal);
    map['advance_paid'] = Variable<double>(advancePaid);
    map['amount_paid_in_words'] = Variable<String>(amountPaidInWords);
    map['template_type'] = Variable<String>(templateType);
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    if (!nullToAbsent || docxPath != null) {
      map['docx_path'] = Variable<String>(docxPath);
    }
    map['created_date'] = Variable<DateTime>(createdDate);
    if (!nullToAbsent || templateSchemaJson != null) {
      map['template_schema_json'] = Variable<String>(templateSchemaJson);
    }
    if (!nullToAbsent || fieldValuesJson != null) {
      map['field_values_json'] = Variable<String>(fieldValuesJson);
    }
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      invoiceNumber: Value(invoiceNumber),
      invoiceDate: Value(invoiceDate),
      dueDate: Value(dueDate),
      bookingRef: bookingRef == null && nullToAbsent
          ? const Value.absent()
          : Value(bookingRef),
      bookingDate: bookingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(bookingDate),
      customerName: Value(customerName),
      customerAddress: Value(customerAddress),
      customerGstNumber: customerGstNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(customerGstNumber),
      customerContactNumber: customerContactNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(customerContactNumber),
      tourTrip: tourTrip == null && nullToAbsent
          ? const Value.absent()
          : Value(tourTrip),
      travelDate: travelDate == null && nullToAbsent
          ? const Value.absent()
          : Value(travelDate),
      noOfDays: noOfDays == null && nullToAbsent
          ? const Value.absent()
          : Value(noOfDays),
      noOfVehicles: noOfVehicles == null && nullToAbsent
          ? const Value.absent()
          : Value(noOfVehicles),
      coordinatorName: coordinatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(coordinatorName),
      subTotal: Value(subTotal),
      cgst: Value(cgst),
      sgst: Value(sgst),
      totalGst: Value(totalGst),
      grandTotal: Value(grandTotal),
      advancePaid: Value(advancePaid),
      amountPaidInWords: Value(amountPaidInWords),
      templateType: Value(templateType),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      docxPath: docxPath == null && nullToAbsent
          ? const Value.absent()
          : Value(docxPath),
      createdDate: Value(createdDate),
      templateSchemaJson: templateSchemaJson == null && nullToAbsent
          ? const Value.absent()
          : Value(templateSchemaJson),
      fieldValuesJson: fieldValuesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldValuesJson),
    );
  }

  factory Invoice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<int>(json['id']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      invoiceDate: serializer.fromJson<DateTime>(json['invoiceDate']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      bookingRef: serializer.fromJson<String?>(json['bookingRef']),
      bookingDate: serializer.fromJson<DateTime?>(json['bookingDate']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerAddress: serializer.fromJson<String>(json['customerAddress']),
      customerGstNumber: serializer.fromJson<String?>(
        json['customerGstNumber'],
      ),
      customerContactNumber: serializer.fromJson<String?>(
        json['customerContactNumber'],
      ),
      tourTrip: serializer.fromJson<String?>(json['tourTrip']),
      travelDate: serializer.fromJson<DateTime?>(json['travelDate']),
      noOfDays: serializer.fromJson<int?>(json['noOfDays']),
      noOfVehicles: serializer.fromJson<int?>(json['noOfVehicles']),
      coordinatorName: serializer.fromJson<String?>(json['coordinatorName']),
      subTotal: serializer.fromJson<double>(json['subTotal']),
      cgst: serializer.fromJson<double>(json['cgst']),
      sgst: serializer.fromJson<double>(json['sgst']),
      totalGst: serializer.fromJson<double>(json['totalGst']),
      grandTotal: serializer.fromJson<double>(json['grandTotal']),
      advancePaid: serializer.fromJson<double>(json['advancePaid']),
      amountPaidInWords: serializer.fromJson<String>(json['amountPaidInWords']),
      templateType: serializer.fromJson<String>(json['templateType']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      docxPath: serializer.fromJson<String?>(json['docxPath']),
      createdDate: serializer.fromJson<DateTime>(json['createdDate']),
      templateSchemaJson: serializer.fromJson<String?>(
        json['templateSchemaJson'],
      ),
      fieldValuesJson: serializer.fromJson<String?>(json['fieldValuesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'invoiceDate': serializer.toJson<DateTime>(invoiceDate),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'bookingRef': serializer.toJson<String?>(bookingRef),
      'bookingDate': serializer.toJson<DateTime?>(bookingDate),
      'customerName': serializer.toJson<String>(customerName),
      'customerAddress': serializer.toJson<String>(customerAddress),
      'customerGstNumber': serializer.toJson<String?>(customerGstNumber),
      'customerContactNumber': serializer.toJson<String?>(
        customerContactNumber,
      ),
      'tourTrip': serializer.toJson<String?>(tourTrip),
      'travelDate': serializer.toJson<DateTime?>(travelDate),
      'noOfDays': serializer.toJson<int?>(noOfDays),
      'noOfVehicles': serializer.toJson<int?>(noOfVehicles),
      'coordinatorName': serializer.toJson<String?>(coordinatorName),
      'subTotal': serializer.toJson<double>(subTotal),
      'cgst': serializer.toJson<double>(cgst),
      'sgst': serializer.toJson<double>(sgst),
      'totalGst': serializer.toJson<double>(totalGst),
      'grandTotal': serializer.toJson<double>(grandTotal),
      'advancePaid': serializer.toJson<double>(advancePaid),
      'amountPaidInWords': serializer.toJson<String>(amountPaidInWords),
      'templateType': serializer.toJson<String>(templateType),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'docxPath': serializer.toJson<String?>(docxPath),
      'createdDate': serializer.toJson<DateTime>(createdDate),
      'templateSchemaJson': serializer.toJson<String?>(templateSchemaJson),
      'fieldValuesJson': serializer.toJson<String?>(fieldValuesJson),
    };
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    Value<String?> bookingRef = const Value.absent(),
    Value<DateTime?> bookingDate = const Value.absent(),
    String? customerName,
    String? customerAddress,
    Value<String?> customerGstNumber = const Value.absent(),
    Value<String?> customerContactNumber = const Value.absent(),
    Value<String?> tourTrip = const Value.absent(),
    Value<DateTime?> travelDate = const Value.absent(),
    Value<int?> noOfDays = const Value.absent(),
    Value<int?> noOfVehicles = const Value.absent(),
    Value<String?> coordinatorName = const Value.absent(),
    double? subTotal,
    double? cgst,
    double? sgst,
    double? totalGst,
    double? grandTotal,
    double? advancePaid,
    String? amountPaidInWords,
    String? templateType,
    Value<String?> pdfPath = const Value.absent(),
    Value<String?> docxPath = const Value.absent(),
    DateTime? createdDate,
    Value<String?> templateSchemaJson = const Value.absent(),
    Value<String?> fieldValuesJson = const Value.absent(),
  }) => Invoice(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    dueDate: dueDate ?? this.dueDate,
    bookingRef: bookingRef.present ? bookingRef.value : this.bookingRef,
    bookingDate: bookingDate.present ? bookingDate.value : this.bookingDate,
    customerName: customerName ?? this.customerName,
    customerAddress: customerAddress ?? this.customerAddress,
    customerGstNumber: customerGstNumber.present
        ? customerGstNumber.value
        : this.customerGstNumber,
    customerContactNumber: customerContactNumber.present
        ? customerContactNumber.value
        : this.customerContactNumber,
    tourTrip: tourTrip.present ? tourTrip.value : this.tourTrip,
    travelDate: travelDate.present ? travelDate.value : this.travelDate,
    noOfDays: noOfDays.present ? noOfDays.value : this.noOfDays,
    noOfVehicles: noOfVehicles.present ? noOfVehicles.value : this.noOfVehicles,
    coordinatorName: coordinatorName.present
        ? coordinatorName.value
        : this.coordinatorName,
    subTotal: subTotal ?? this.subTotal,
    cgst: cgst ?? this.cgst,
    sgst: sgst ?? this.sgst,
    totalGst: totalGst ?? this.totalGst,
    grandTotal: grandTotal ?? this.grandTotal,
    advancePaid: advancePaid ?? this.advancePaid,
    amountPaidInWords: amountPaidInWords ?? this.amountPaidInWords,
    templateType: templateType ?? this.templateType,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    docxPath: docxPath.present ? docxPath.value : this.docxPath,
    createdDate: createdDate ?? this.createdDate,
    templateSchemaJson: templateSchemaJson.present
        ? templateSchemaJson.value
        : this.templateSchemaJson,
    fieldValuesJson: fieldValuesJson.present
        ? fieldValuesJson.value
        : this.fieldValuesJson,
  );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      invoiceDate: data.invoiceDate.present
          ? data.invoiceDate.value
          : this.invoiceDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      bookingRef: data.bookingRef.present
          ? data.bookingRef.value
          : this.bookingRef,
      bookingDate: data.bookingDate.present
          ? data.bookingDate.value
          : this.bookingDate,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      customerGstNumber: data.customerGstNumber.present
          ? data.customerGstNumber.value
          : this.customerGstNumber,
      customerContactNumber: data.customerContactNumber.present
          ? data.customerContactNumber.value
          : this.customerContactNumber,
      tourTrip: data.tourTrip.present ? data.tourTrip.value : this.tourTrip,
      travelDate: data.travelDate.present
          ? data.travelDate.value
          : this.travelDate,
      noOfDays: data.noOfDays.present ? data.noOfDays.value : this.noOfDays,
      noOfVehicles: data.noOfVehicles.present
          ? data.noOfVehicles.value
          : this.noOfVehicles,
      coordinatorName: data.coordinatorName.present
          ? data.coordinatorName.value
          : this.coordinatorName,
      subTotal: data.subTotal.present ? data.subTotal.value : this.subTotal,
      cgst: data.cgst.present ? data.cgst.value : this.cgst,
      sgst: data.sgst.present ? data.sgst.value : this.sgst,
      totalGst: data.totalGst.present ? data.totalGst.value : this.totalGst,
      grandTotal: data.grandTotal.present
          ? data.grandTotal.value
          : this.grandTotal,
      advancePaid: data.advancePaid.present
          ? data.advancePaid.value
          : this.advancePaid,
      amountPaidInWords: data.amountPaidInWords.present
          ? data.amountPaidInWords.value
          : this.amountPaidInWords,
      templateType: data.templateType.present
          ? data.templateType.value
          : this.templateType,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      docxPath: data.docxPath.present ? data.docxPath.value : this.docxPath,
      createdDate: data.createdDate.present
          ? data.createdDate.value
          : this.createdDate,
      templateSchemaJson: data.templateSchemaJson.present
          ? data.templateSchemaJson.value
          : this.templateSchemaJson,
      fieldValuesJson: data.fieldValuesJson.present
          ? data.fieldValuesJson.value
          : this.fieldValuesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('bookingRef: $bookingRef, ')
          ..write('bookingDate: $bookingDate, ')
          ..write('customerName: $customerName, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('customerGstNumber: $customerGstNumber, ')
          ..write('customerContactNumber: $customerContactNumber, ')
          ..write('tourTrip: $tourTrip, ')
          ..write('travelDate: $travelDate, ')
          ..write('noOfDays: $noOfDays, ')
          ..write('noOfVehicles: $noOfVehicles, ')
          ..write('coordinatorName: $coordinatorName, ')
          ..write('subTotal: $subTotal, ')
          ..write('cgst: $cgst, ')
          ..write('sgst: $sgst, ')
          ..write('totalGst: $totalGst, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('advancePaid: $advancePaid, ')
          ..write('amountPaidInWords: $amountPaidInWords, ')
          ..write('templateType: $templateType, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('docxPath: $docxPath, ')
          ..write('createdDate: $createdDate, ')
          ..write('templateSchemaJson: $templateSchemaJson, ')
          ..write('fieldValuesJson: $fieldValuesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    invoiceNumber,
    invoiceDate,
    dueDate,
    bookingRef,
    bookingDate,
    customerName,
    customerAddress,
    customerGstNumber,
    customerContactNumber,
    tourTrip,
    travelDate,
    noOfDays,
    noOfVehicles,
    coordinatorName,
    subTotal,
    cgst,
    sgst,
    totalGst,
    grandTotal,
    advancePaid,
    amountPaidInWords,
    templateType,
    pdfPath,
    docxPath,
    createdDate,
    templateSchemaJson,
    fieldValuesJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.invoiceNumber == this.invoiceNumber &&
          other.invoiceDate == this.invoiceDate &&
          other.dueDate == this.dueDate &&
          other.bookingRef == this.bookingRef &&
          other.bookingDate == this.bookingDate &&
          other.customerName == this.customerName &&
          other.customerAddress == this.customerAddress &&
          other.customerGstNumber == this.customerGstNumber &&
          other.customerContactNumber == this.customerContactNumber &&
          other.tourTrip == this.tourTrip &&
          other.travelDate == this.travelDate &&
          other.noOfDays == this.noOfDays &&
          other.noOfVehicles == this.noOfVehicles &&
          other.coordinatorName == this.coordinatorName &&
          other.subTotal == this.subTotal &&
          other.cgst == this.cgst &&
          other.sgst == this.sgst &&
          other.totalGst == this.totalGst &&
          other.grandTotal == this.grandTotal &&
          other.advancePaid == this.advancePaid &&
          other.amountPaidInWords == this.amountPaidInWords &&
          other.templateType == this.templateType &&
          other.pdfPath == this.pdfPath &&
          other.docxPath == this.docxPath &&
          other.createdDate == this.createdDate &&
          other.templateSchemaJson == this.templateSchemaJson &&
          other.fieldValuesJson == this.fieldValuesJson);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<int> id;
  final Value<String> invoiceNumber;
  final Value<DateTime> invoiceDate;
  final Value<DateTime> dueDate;
  final Value<String?> bookingRef;
  final Value<DateTime?> bookingDate;
  final Value<String> customerName;
  final Value<String> customerAddress;
  final Value<String?> customerGstNumber;
  final Value<String?> customerContactNumber;
  final Value<String?> tourTrip;
  final Value<DateTime?> travelDate;
  final Value<int?> noOfDays;
  final Value<int?> noOfVehicles;
  final Value<String?> coordinatorName;
  final Value<double> subTotal;
  final Value<double> cgst;
  final Value<double> sgst;
  final Value<double> totalGst;
  final Value<double> grandTotal;
  final Value<double> advancePaid;
  final Value<String> amountPaidInWords;
  final Value<String> templateType;
  final Value<String?> pdfPath;
  final Value<String?> docxPath;
  final Value<DateTime> createdDate;
  final Value<String?> templateSchemaJson;
  final Value<String?> fieldValuesJson;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoiceDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.bookingRef = const Value.absent(),
    this.bookingDate = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.customerGstNumber = const Value.absent(),
    this.customerContactNumber = const Value.absent(),
    this.tourTrip = const Value.absent(),
    this.travelDate = const Value.absent(),
    this.noOfDays = const Value.absent(),
    this.noOfVehicles = const Value.absent(),
    this.coordinatorName = const Value.absent(),
    this.subTotal = const Value.absent(),
    this.cgst = const Value.absent(),
    this.sgst = const Value.absent(),
    this.totalGst = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.advancePaid = const Value.absent(),
    this.amountPaidInWords = const Value.absent(),
    this.templateType = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.docxPath = const Value.absent(),
    this.createdDate = const Value.absent(),
    this.templateSchemaJson = const Value.absent(),
    this.fieldValuesJson = const Value.absent(),
  });
  InvoicesCompanion.insert({
    this.id = const Value.absent(),
    required String invoiceNumber,
    required DateTime invoiceDate,
    required DateTime dueDate,
    this.bookingRef = const Value.absent(),
    this.bookingDate = const Value.absent(),
    required String customerName,
    required String customerAddress,
    this.customerGstNumber = const Value.absent(),
    this.customerContactNumber = const Value.absent(),
    this.tourTrip = const Value.absent(),
    this.travelDate = const Value.absent(),
    this.noOfDays = const Value.absent(),
    this.noOfVehicles = const Value.absent(),
    this.coordinatorName = const Value.absent(),
    required double subTotal,
    required double cgst,
    required double sgst,
    required double totalGst,
    required double grandTotal,
    this.advancePaid = const Value.absent(),
    required String amountPaidInWords,
    this.templateType = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.docxPath = const Value.absent(),
    required DateTime createdDate,
    this.templateSchemaJson = const Value.absent(),
    this.fieldValuesJson = const Value.absent(),
  }) : invoiceNumber = Value(invoiceNumber),
       invoiceDate = Value(invoiceDate),
       dueDate = Value(dueDate),
       customerName = Value(customerName),
       customerAddress = Value(customerAddress),
       subTotal = Value(subTotal),
       cgst = Value(cgst),
       sgst = Value(sgst),
       totalGst = Value(totalGst),
       grandTotal = Value(grandTotal),
       amountPaidInWords = Value(amountPaidInWords),
       createdDate = Value(createdDate);
  static Insertable<Invoice> custom({
    Expression<int>? id,
    Expression<String>? invoiceNumber,
    Expression<DateTime>? invoiceDate,
    Expression<DateTime>? dueDate,
    Expression<String>? bookingRef,
    Expression<DateTime>? bookingDate,
    Expression<String>? customerName,
    Expression<String>? customerAddress,
    Expression<String>? customerGstNumber,
    Expression<String>? customerContactNumber,
    Expression<String>? tourTrip,
    Expression<DateTime>? travelDate,
    Expression<int>? noOfDays,
    Expression<int>? noOfVehicles,
    Expression<String>? coordinatorName,
    Expression<double>? subTotal,
    Expression<double>? cgst,
    Expression<double>? sgst,
    Expression<double>? totalGst,
    Expression<double>? grandTotal,
    Expression<double>? advancePaid,
    Expression<String>? amountPaidInWords,
    Expression<String>? templateType,
    Expression<String>? pdfPath,
    Expression<String>? docxPath,
    Expression<DateTime>? createdDate,
    Expression<String>? templateSchemaJson,
    Expression<String>? fieldValuesJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (dueDate != null) 'due_date': dueDate,
      if (bookingRef != null) 'booking_ref': bookingRef,
      if (bookingDate != null) 'booking_date': bookingDate,
      if (customerName != null) 'customer_name': customerName,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (customerGstNumber != null) 'customer_gst_number': customerGstNumber,
      if (customerContactNumber != null)
        'customer_contact_number': customerContactNumber,
      if (tourTrip != null) 'tour_trip': tourTrip,
      if (travelDate != null) 'travel_date': travelDate,
      if (noOfDays != null) 'no_of_days': noOfDays,
      if (noOfVehicles != null) 'no_of_vehicles': noOfVehicles,
      if (coordinatorName != null) 'coordinator_name': coordinatorName,
      if (subTotal != null) 'sub_total': subTotal,
      if (cgst != null) 'cgst': cgst,
      if (sgst != null) 'sgst': sgst,
      if (totalGst != null) 'total_gst': totalGst,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (advancePaid != null) 'advance_paid': advancePaid,
      if (amountPaidInWords != null) 'amount_paid_in_words': amountPaidInWords,
      if (templateType != null) 'template_type': templateType,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (docxPath != null) 'docx_path': docxPath,
      if (createdDate != null) 'created_date': createdDate,
      if (templateSchemaJson != null)
        'template_schema_json': templateSchemaJson,
      if (fieldValuesJson != null) 'field_values_json': fieldValuesJson,
    });
  }

  InvoicesCompanion copyWith({
    Value<int>? id,
    Value<String>? invoiceNumber,
    Value<DateTime>? invoiceDate,
    Value<DateTime>? dueDate,
    Value<String?>? bookingRef,
    Value<DateTime?>? bookingDate,
    Value<String>? customerName,
    Value<String>? customerAddress,
    Value<String?>? customerGstNumber,
    Value<String?>? customerContactNumber,
    Value<String?>? tourTrip,
    Value<DateTime?>? travelDate,
    Value<int?>? noOfDays,
    Value<int?>? noOfVehicles,
    Value<String?>? coordinatorName,
    Value<double>? subTotal,
    Value<double>? cgst,
    Value<double>? sgst,
    Value<double>? totalGst,
    Value<double>? grandTotal,
    Value<double>? advancePaid,
    Value<String>? amountPaidInWords,
    Value<String>? templateType,
    Value<String?>? pdfPath,
    Value<String?>? docxPath,
    Value<DateTime>? createdDate,
    Value<String?>? templateSchemaJson,
    Value<String?>? fieldValuesJson,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      bookingRef: bookingRef ?? this.bookingRef,
      bookingDate: bookingDate ?? this.bookingDate,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerGstNumber: customerGstNumber ?? this.customerGstNumber,
      customerContactNumber:
          customerContactNumber ?? this.customerContactNumber,
      tourTrip: tourTrip ?? this.tourTrip,
      travelDate: travelDate ?? this.travelDate,
      noOfDays: noOfDays ?? this.noOfDays,
      noOfVehicles: noOfVehicles ?? this.noOfVehicles,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      subTotal: subTotal ?? this.subTotal,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      totalGst: totalGst ?? this.totalGst,
      grandTotal: grandTotal ?? this.grandTotal,
      advancePaid: advancePaid ?? this.advancePaid,
      amountPaidInWords: amountPaidInWords ?? this.amountPaidInWords,
      templateType: templateType ?? this.templateType,
      pdfPath: pdfPath ?? this.pdfPath,
      docxPath: docxPath ?? this.docxPath,
      createdDate: createdDate ?? this.createdDate,
      templateSchemaJson: templateSchemaJson ?? this.templateSchemaJson,
      fieldValuesJson: fieldValuesJson ?? this.fieldValuesJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (invoiceDate.present) {
      map['invoice_date'] = Variable<DateTime>(invoiceDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (bookingRef.present) {
      map['booking_ref'] = Variable<String>(bookingRef.value);
    }
    if (bookingDate.present) {
      map['booking_date'] = Variable<DateTime>(bookingDate.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (customerGstNumber.present) {
      map['customer_gst_number'] = Variable<String>(customerGstNumber.value);
    }
    if (customerContactNumber.present) {
      map['customer_contact_number'] = Variable<String>(
        customerContactNumber.value,
      );
    }
    if (tourTrip.present) {
      map['tour_trip'] = Variable<String>(tourTrip.value);
    }
    if (travelDate.present) {
      map['travel_date'] = Variable<DateTime>(travelDate.value);
    }
    if (noOfDays.present) {
      map['no_of_days'] = Variable<int>(noOfDays.value);
    }
    if (noOfVehicles.present) {
      map['no_of_vehicles'] = Variable<int>(noOfVehicles.value);
    }
    if (coordinatorName.present) {
      map['coordinator_name'] = Variable<String>(coordinatorName.value);
    }
    if (subTotal.present) {
      map['sub_total'] = Variable<double>(subTotal.value);
    }
    if (cgst.present) {
      map['cgst'] = Variable<double>(cgst.value);
    }
    if (sgst.present) {
      map['sgst'] = Variable<double>(sgst.value);
    }
    if (totalGst.present) {
      map['total_gst'] = Variable<double>(totalGst.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<double>(grandTotal.value);
    }
    if (advancePaid.present) {
      map['advance_paid'] = Variable<double>(advancePaid.value);
    }
    if (amountPaidInWords.present) {
      map['amount_paid_in_words'] = Variable<String>(amountPaidInWords.value);
    }
    if (templateType.present) {
      map['template_type'] = Variable<String>(templateType.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (docxPath.present) {
      map['docx_path'] = Variable<String>(docxPath.value);
    }
    if (createdDate.present) {
      map['created_date'] = Variable<DateTime>(createdDate.value);
    }
    if (templateSchemaJson.present) {
      map['template_schema_json'] = Variable<String>(templateSchemaJson.value);
    }
    if (fieldValuesJson.present) {
      map['field_values_json'] = Variable<String>(fieldValuesJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('bookingRef: $bookingRef, ')
          ..write('bookingDate: $bookingDate, ')
          ..write('customerName: $customerName, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('customerGstNumber: $customerGstNumber, ')
          ..write('customerContactNumber: $customerContactNumber, ')
          ..write('tourTrip: $tourTrip, ')
          ..write('travelDate: $travelDate, ')
          ..write('noOfDays: $noOfDays, ')
          ..write('noOfVehicles: $noOfVehicles, ')
          ..write('coordinatorName: $coordinatorName, ')
          ..write('subTotal: $subTotal, ')
          ..write('cgst: $cgst, ')
          ..write('sgst: $sgst, ')
          ..write('totalGst: $totalGst, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('advancePaid: $advancePaid, ')
          ..write('amountPaidInWords: $amountPaidInWords, ')
          ..write('templateType: $templateType, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('docxPath: $docxPath, ')
          ..write('createdDate: $createdDate, ')
          ..write('templateSchemaJson: $templateSchemaJson, ')
          ..write('fieldValuesJson: $fieldValuesJson')
          ..write(')'))
        .toString();
  }
}

class $InvoiceItemsTable extends InvoiceItems
    with TableInfo<$InvoiceItemsTable, InvoiceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<int> invoiceId = GeneratedColumn<int>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noOfVehiclesMeta = const VerificationMeta(
    'noOfVehicles',
  );
  @override
  late final GeneratedColumn<int> noOfVehicles = GeneratedColumn<int>(
    'no_of_vehicles',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemDateMeta = const VerificationMeta(
    'itemDate',
  );
  @override
  late final GeneratedColumn<DateTime> itemDate = GeneratedColumn<DateTime>(
    'item_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromToMeta = const VerificationMeta('fromTo');
  @override
  late final GeneratedColumn<String> fromTo = GeneratedColumn<String>(
    'from_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityDaysMeta = const VerificationMeta(
    'quantityDays',
  );
  @override
  late final GeneratedColumn<double> quantityDays = GeneratedColumn<double>(
    'quantity_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    description,
    noOfVehicles,
    itemDate,
    fromTo,
    quantityDays,
    rate,
    amount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('no_of_vehicles')) {
      context.handle(
        _noOfVehiclesMeta,
        noOfVehicles.isAcceptableOrUnknown(
          data['no_of_vehicles']!,
          _noOfVehiclesMeta,
        ),
      );
    }
    if (data.containsKey('item_date')) {
      context.handle(
        _itemDateMeta,
        itemDate.isAcceptableOrUnknown(data['item_date']!, _itemDateMeta),
      );
    }
    if (data.containsKey('from_to')) {
      context.handle(
        _fromToMeta,
        fromTo.isAcceptableOrUnknown(data['from_to']!, _fromToMeta),
      );
    }
    if (data.containsKey('quantity_days')) {
      context.handle(
        _quantityDaysMeta,
        quantityDays.isAcceptableOrUnknown(
          data['quantity_days']!,
          _quantityDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityDaysMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invoice_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      noOfVehicles: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}no_of_vehicles'],
      ),
      itemDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}item_date'],
      ),
      fromTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_to'],
      ),
      quantityDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_days'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $InvoiceItemsTable createAlias(String alias) {
    return $InvoiceItemsTable(attachedDatabase, alias);
  }
}

class InvoiceItem extends DataClass implements Insertable<InvoiceItem> {
  final int id;
  final int invoiceId;
  final String description;
  final int? noOfVehicles;
  final DateTime? itemDate;
  final String? fromTo;
  final double quantityDays;
  final double rate;
  final double amount;
  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.description,
    this.noOfVehicles,
    this.itemDate,
    this.fromTo,
    required this.quantityDays,
    required this.rate,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<int>(invoiceId);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || noOfVehicles != null) {
      map['no_of_vehicles'] = Variable<int>(noOfVehicles);
    }
    if (!nullToAbsent || itemDate != null) {
      map['item_date'] = Variable<DateTime>(itemDate);
    }
    if (!nullToAbsent || fromTo != null) {
      map['from_to'] = Variable<String>(fromTo);
    }
    map['quantity_days'] = Variable<double>(quantityDays);
    map['rate'] = Variable<double>(rate);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  InvoiceItemsCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      description: Value(description),
      noOfVehicles: noOfVehicles == null && nullToAbsent
          ? const Value.absent()
          : Value(noOfVehicles),
      itemDate: itemDate == null && nullToAbsent
          ? const Value.absent()
          : Value(itemDate),
      fromTo: fromTo == null && nullToAbsent
          ? const Value.absent()
          : Value(fromTo),
      quantityDays: Value(quantityDays),
      rate: Value(rate),
      amount: Value(amount),
    );
  }

  factory InvoiceItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItem(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<int>(json['invoiceId']),
      description: serializer.fromJson<String>(json['description']),
      noOfVehicles: serializer.fromJson<int?>(json['noOfVehicles']),
      itemDate: serializer.fromJson<DateTime?>(json['itemDate']),
      fromTo: serializer.fromJson<String?>(json['fromTo']),
      quantityDays: serializer.fromJson<double>(json['quantityDays']),
      rate: serializer.fromJson<double>(json['rate']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<int>(invoiceId),
      'description': serializer.toJson<String>(description),
      'noOfVehicles': serializer.toJson<int?>(noOfVehicles),
      'itemDate': serializer.toJson<DateTime?>(itemDate),
      'fromTo': serializer.toJson<String?>(fromTo),
      'quantityDays': serializer.toJson<double>(quantityDays),
      'rate': serializer.toJson<double>(rate),
      'amount': serializer.toJson<double>(amount),
    };
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    String? description,
    Value<int?> noOfVehicles = const Value.absent(),
    Value<DateTime?> itemDate = const Value.absent(),
    Value<String?> fromTo = const Value.absent(),
    double? quantityDays,
    double? rate,
    double? amount,
  }) => InvoiceItem(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    description: description ?? this.description,
    noOfVehicles: noOfVehicles.present ? noOfVehicles.value : this.noOfVehicles,
    itemDate: itemDate.present ? itemDate.value : this.itemDate,
    fromTo: fromTo.present ? fromTo.value : this.fromTo,
    quantityDays: quantityDays ?? this.quantityDays,
    rate: rate ?? this.rate,
    amount: amount ?? this.amount,
  );
  InvoiceItem copyWithCompanion(InvoiceItemsCompanion data) {
    return InvoiceItem(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      description: data.description.present
          ? data.description.value
          : this.description,
      noOfVehicles: data.noOfVehicles.present
          ? data.noOfVehicles.value
          : this.noOfVehicles,
      itemDate: data.itemDate.present ? data.itemDate.value : this.itemDate,
      fromTo: data.fromTo.present ? data.fromTo.value : this.fromTo,
      quantityDays: data.quantityDays.present
          ? data.quantityDays.value
          : this.quantityDays,
      rate: data.rate.present ? data.rate.value : this.rate,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItem(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('description: $description, ')
          ..write('noOfVehicles: $noOfVehicles, ')
          ..write('itemDate: $itemDate, ')
          ..write('fromTo: $fromTo, ')
          ..write('quantityDays: $quantityDays, ')
          ..write('rate: $rate, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceId,
    description,
    noOfVehicles,
    itemDate,
    fromTo,
    quantityDays,
    rate,
    amount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItem &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.description == this.description &&
          other.noOfVehicles == this.noOfVehicles &&
          other.itemDate == this.itemDate &&
          other.fromTo == this.fromTo &&
          other.quantityDays == this.quantityDays &&
          other.rate == this.rate &&
          other.amount == this.amount);
}

class InvoiceItemsCompanion extends UpdateCompanion<InvoiceItem> {
  final Value<int> id;
  final Value<int> invoiceId;
  final Value<String> description;
  final Value<int?> noOfVehicles;
  final Value<DateTime?> itemDate;
  final Value<String?> fromTo;
  final Value<double> quantityDays;
  final Value<double> rate;
  final Value<double> amount;
  const InvoiceItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.description = const Value.absent(),
    this.noOfVehicles = const Value.absent(),
    this.itemDate = const Value.absent(),
    this.fromTo = const Value.absent(),
    this.quantityDays = const Value.absent(),
    this.rate = const Value.absent(),
    this.amount = const Value.absent(),
  });
  InvoiceItemsCompanion.insert({
    this.id = const Value.absent(),
    required int invoiceId,
    required String description,
    this.noOfVehicles = const Value.absent(),
    this.itemDate = const Value.absent(),
    this.fromTo = const Value.absent(),
    required double quantityDays,
    required double rate,
    required double amount,
  }) : invoiceId = Value(invoiceId),
       description = Value(description),
       quantityDays = Value(quantityDays),
       rate = Value(rate),
       amount = Value(amount);
  static Insertable<InvoiceItem> custom({
    Expression<int>? id,
    Expression<int>? invoiceId,
    Expression<String>? description,
    Expression<int>? noOfVehicles,
    Expression<DateTime>? itemDate,
    Expression<String>? fromTo,
    Expression<double>? quantityDays,
    Expression<double>? rate,
    Expression<double>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (description != null) 'description': description,
      if (noOfVehicles != null) 'no_of_vehicles': noOfVehicles,
      if (itemDate != null) 'item_date': itemDate,
      if (fromTo != null) 'from_to': fromTo,
      if (quantityDays != null) 'quantity_days': quantityDays,
      if (rate != null) 'rate': rate,
      if (amount != null) 'amount': amount,
    });
  }

  InvoiceItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? invoiceId,
    Value<String>? description,
    Value<int?>? noOfVehicles,
    Value<DateTime?>? itemDate,
    Value<String?>? fromTo,
    Value<double>? quantityDays,
    Value<double>? rate,
    Value<double>? amount,
  }) {
    return InvoiceItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      noOfVehicles: noOfVehicles ?? this.noOfVehicles,
      itemDate: itemDate ?? this.itemDate,
      fromTo: fromTo ?? this.fromTo,
      quantityDays: quantityDays ?? this.quantityDays,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<int>(invoiceId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (noOfVehicles.present) {
      map['no_of_vehicles'] = Variable<int>(noOfVehicles.value);
    }
    if (itemDate.present) {
      map['item_date'] = Variable<DateTime>(itemDate.value);
    }
    if (fromTo.present) {
      map['from_to'] = Variable<String>(fromTo.value);
    }
    if (quantityDays.present) {
      map['quantity_days'] = Variable<double>(quantityDays.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('description: $description, ')
          ..write('noOfVehicles: $noOfVehicles, ')
          ..write('itemDate: $itemDate, ')
          ..write('fromTo: $fromTo, ')
          ..write('quantityDays: $quantityDays, ')
          ..write('rate: $rate, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

class $InvoiceTemplatesTable extends InvoiceTemplates
    with TableInfo<$InvoiceTemplatesTable, InvoiceTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemaJsonMeta = const VerificationMeta(
    'schemaJson',
  );
  @override
  late final GeneratedColumn<String> schemaJson = GeneratedColumn<String>(
    'schema_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdDateMeta = const VerificationMeta(
    'createdDate',
  );
  @override
  late final GeneratedColumn<DateTime> createdDate = GeneratedColumn<DateTime>(
    'created_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    schemaJson,
    createdDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('schema_json')) {
      context.handle(
        _schemaJsonMeta,
        schemaJson.isAcceptableOrUnknown(data['schema_json']!, _schemaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_schemaJsonMeta);
    }
    if (data.containsKey('created_date')) {
      context.handle(
        _createdDateMeta,
        createdDate.isAcceptableOrUnknown(
          data['created_date']!,
          _createdDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      schemaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema_json'],
      )!,
      createdDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_date'],
      )!,
    );
  }

  @override
  $InvoiceTemplatesTable createAlias(String alias) {
    return $InvoiceTemplatesTable(attachedDatabase, alias);
  }
}

class InvoiceTemplate extends DataClass implements Insertable<InvoiceTemplate> {
  final int id;
  final String name;
  final String? description;
  final String schemaJson;
  final DateTime createdDate;
  const InvoiceTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.schemaJson,
    required this.createdDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['schema_json'] = Variable<String>(schemaJson);
    map['created_date'] = Variable<DateTime>(createdDate);
    return map;
  }

  InvoiceTemplatesCompanion toCompanion(bool nullToAbsent) {
    return InvoiceTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      schemaJson: Value(schemaJson),
      createdDate: Value(createdDate),
    );
  }

  factory InvoiceTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      schemaJson: serializer.fromJson<String>(json['schemaJson']),
      createdDate: serializer.fromJson<DateTime>(json['createdDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'schemaJson': serializer.toJson<String>(schemaJson),
      'createdDate': serializer.toJson<DateTime>(createdDate),
    };
  }

  InvoiceTemplate copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? schemaJson,
    DateTime? createdDate,
  }) => InvoiceTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    schemaJson: schemaJson ?? this.schemaJson,
    createdDate: createdDate ?? this.createdDate,
  );
  InvoiceTemplate copyWithCompanion(InvoiceTemplatesCompanion data) {
    return InvoiceTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      schemaJson: data.schemaJson.present
          ? data.schemaJson.value
          : this.schemaJson,
      createdDate: data.createdDate.present
          ? data.createdDate.value
          : this.createdDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('schemaJson: $schemaJson, ')
          ..write('createdDate: $createdDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, schemaJson, createdDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.schemaJson == this.schemaJson &&
          other.createdDate == this.createdDate);
}

class InvoiceTemplatesCompanion extends UpdateCompanion<InvoiceTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> schemaJson;
  final Value<DateTime> createdDate;
  const InvoiceTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.schemaJson = const Value.absent(),
    this.createdDate = const Value.absent(),
  });
  InvoiceTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required String schemaJson,
    required DateTime createdDate,
  }) : name = Value(name),
       schemaJson = Value(schemaJson),
       createdDate = Value(createdDate);
  static Insertable<InvoiceTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? schemaJson,
    Expression<DateTime>? createdDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (schemaJson != null) 'schema_json': schemaJson,
      if (createdDate != null) 'created_date': createdDate,
    });
  }

  InvoiceTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? schemaJson,
    Value<DateTime>? createdDate,
  }) {
    return InvoiceTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schemaJson: schemaJson ?? this.schemaJson,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (schemaJson.present) {
      map['schema_json'] = Variable<String>(schemaJson.value);
    }
    if (createdDate.present) {
      map['created_date'] = Variable<DateTime>(createdDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('schemaJson: $schemaJson, ')
          ..write('createdDate: $createdDate')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CompanyProfilesTable companyProfiles = $CompanyProfilesTable(
    this,
  );
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceItemsTable invoiceItems = $InvoiceItemsTable(this);
  late final $InvoiceTemplatesTable invoiceTemplates = $InvoiceTemplatesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    companyProfiles,
    invoices,
    invoiceItems,
    invoiceTemplates,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invoice_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CompanyProfilesTableCreateCompanionBuilder =
    CompanyProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String address,
      required String gstNumber,
      required String contactNumber,
      required String email,
      required String bankAccountName,
      required String bankName,
      required String bankAccountNumber,
      required String bankIfscCode,
      Value<String?> logoPath,
      Value<String?> signaturePath,
      Value<double> defaultGstPercentage,
    });
typedef $$CompanyProfilesTableUpdateCompanionBuilder =
    CompanyProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> address,
      Value<String> gstNumber,
      Value<String> contactNumber,
      Value<String> email,
      Value<String> bankAccountName,
      Value<String> bankName,
      Value<String> bankAccountNumber,
      Value<String> bankIfscCode,
      Value<String?> logoPath,
      Value<String?> signaturePath,
      Value<double> defaultGstPercentage,
    });

class $$CompanyProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CompanyProfilesTable> {
  $$CompanyProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstNumber => $composableBuilder(
    column: $table.gstNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccountNumber => $composableBuilder(
    column: $table.bankAccountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankIfscCode => $composableBuilder(
    column: $table.bankIfscCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signaturePath => $composableBuilder(
    column: $table.signaturePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultGstPercentage => $composableBuilder(
    column: $table.defaultGstPercentage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompanyProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompanyProfilesTable> {
  $$CompanyProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstNumber => $composableBuilder(
    column: $table.gstNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccountNumber => $composableBuilder(
    column: $table.bankAccountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankIfscCode => $composableBuilder(
    column: $table.bankIfscCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signaturePath => $composableBuilder(
    column: $table.signaturePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultGstPercentage => $composableBuilder(
    column: $table.defaultGstPercentage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompanyProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompanyProfilesTable> {
  $$CompanyProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get gstNumber =>
      $composableBuilder(column: $table.gstNumber, builder: (column) => column);

  GeneratedColumn<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get bankAccountName => $composableBuilder(
    column: $table.bankAccountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get bankAccountNumber => $composableBuilder(
    column: $table.bankAccountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankIfscCode => $composableBuilder(
    column: $table.bankIfscCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<String> get signaturePath => $composableBuilder(
    column: $table.signaturePath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultGstPercentage => $composableBuilder(
    column: $table.defaultGstPercentage,
    builder: (column) => column,
  );
}

class $$CompanyProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompanyProfilesTable,
          CompanyProfile,
          $$CompanyProfilesTableFilterComposer,
          $$CompanyProfilesTableOrderingComposer,
          $$CompanyProfilesTableAnnotationComposer,
          $$CompanyProfilesTableCreateCompanionBuilder,
          $$CompanyProfilesTableUpdateCompanionBuilder,
          (
            CompanyProfile,
            BaseReferences<
              _$AppDatabase,
              $CompanyProfilesTable,
              CompanyProfile
            >,
          ),
          CompanyProfile,
          PrefetchHooks Function()
        > {
  $$CompanyProfilesTableTableManager(
    _$AppDatabase db,
    $CompanyProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompanyProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompanyProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompanyProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> gstNumber = const Value.absent(),
                Value<String> contactNumber = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> bankAccountName = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<String> bankAccountNumber = const Value.absent(),
                Value<String> bankIfscCode = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String?> signaturePath = const Value.absent(),
                Value<double> defaultGstPercentage = const Value.absent(),
              }) => CompanyProfilesCompanion(
                id: id,
                name: name,
                address: address,
                gstNumber: gstNumber,
                contactNumber: contactNumber,
                email: email,
                bankAccountName: bankAccountName,
                bankName: bankName,
                bankAccountNumber: bankAccountNumber,
                bankIfscCode: bankIfscCode,
                logoPath: logoPath,
                signaturePath: signaturePath,
                defaultGstPercentage: defaultGstPercentage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String address,
                required String gstNumber,
                required String contactNumber,
                required String email,
                required String bankAccountName,
                required String bankName,
                required String bankAccountNumber,
                required String bankIfscCode,
                Value<String?> logoPath = const Value.absent(),
                Value<String?> signaturePath = const Value.absent(),
                Value<double> defaultGstPercentage = const Value.absent(),
              }) => CompanyProfilesCompanion.insert(
                id: id,
                name: name,
                address: address,
                gstNumber: gstNumber,
                contactNumber: contactNumber,
                email: email,
                bankAccountName: bankAccountName,
                bankName: bankName,
                bankAccountNumber: bankAccountNumber,
                bankIfscCode: bankIfscCode,
                logoPath: logoPath,
                signaturePath: signaturePath,
                defaultGstPercentage: defaultGstPercentage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompanyProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompanyProfilesTable,
      CompanyProfile,
      $$CompanyProfilesTableFilterComposer,
      $$CompanyProfilesTableOrderingComposer,
      $$CompanyProfilesTableAnnotationComposer,
      $$CompanyProfilesTableCreateCompanionBuilder,
      $$CompanyProfilesTableUpdateCompanionBuilder,
      (
        CompanyProfile,
        BaseReferences<_$AppDatabase, $CompanyProfilesTable, CompanyProfile>,
      ),
      CompanyProfile,
      PrefetchHooks Function()
    >;
typedef $$InvoicesTableCreateCompanionBuilder =
    InvoicesCompanion Function({
      Value<int> id,
      required String invoiceNumber,
      required DateTime invoiceDate,
      required DateTime dueDate,
      Value<String?> bookingRef,
      Value<DateTime?> bookingDate,
      required String customerName,
      required String customerAddress,
      Value<String?> customerGstNumber,
      Value<String?> customerContactNumber,
      Value<String?> tourTrip,
      Value<DateTime?> travelDate,
      Value<int?> noOfDays,
      Value<int?> noOfVehicles,
      Value<String?> coordinatorName,
      required double subTotal,
      required double cgst,
      required double sgst,
      required double totalGst,
      required double grandTotal,
      Value<double> advancePaid,
      required String amountPaidInWords,
      Value<String> templateType,
      Value<String?> pdfPath,
      Value<String?> docxPath,
      required DateTime createdDate,
      Value<String?> templateSchemaJson,
      Value<String?> fieldValuesJson,
    });
typedef $$InvoicesTableUpdateCompanionBuilder =
    InvoicesCompanion Function({
      Value<int> id,
      Value<String> invoiceNumber,
      Value<DateTime> invoiceDate,
      Value<DateTime> dueDate,
      Value<String?> bookingRef,
      Value<DateTime?> bookingDate,
      Value<String> customerName,
      Value<String> customerAddress,
      Value<String?> customerGstNumber,
      Value<String?> customerContactNumber,
      Value<String?> tourTrip,
      Value<DateTime?> travelDate,
      Value<int?> noOfDays,
      Value<int?> noOfVehicles,
      Value<String?> coordinatorName,
      Value<double> subTotal,
      Value<double> cgst,
      Value<double> sgst,
      Value<double> totalGst,
      Value<double> grandTotal,
      Value<double> advancePaid,
      Value<String> amountPaidInWords,
      Value<String> templateType,
      Value<String?> pdfPath,
      Value<String?> docxPath,
      Value<DateTime> createdDate,
      Value<String?> templateSchemaJson,
      Value<String?> fieldValuesJson,
    });

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoicesTable, Invoice> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItem>>
  _invoiceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invoiceItems,
    aliasName: 'invoices__id__invoice_items__invoice_id',
  );

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager(
      $_db,
      $_db.invoiceItems,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingRef => $composableBuilder(
    column: $table.bookingRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get bookingDate => $composableBuilder(
    column: $table.bookingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerGstNumber => $composableBuilder(
    column: $table.customerGstNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerContactNumber => $composableBuilder(
    column: $table.customerContactNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tourTrip => $composableBuilder(
    column: $table.tourTrip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get travelDate => $composableBuilder(
    column: $table.travelDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noOfDays => $composableBuilder(
    column: $table.noOfDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noOfVehicles => $composableBuilder(
    column: $table.noOfVehicles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coordinatorName => $composableBuilder(
    column: $table.coordinatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cgst => $composableBuilder(
    column: $table.cgst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sgst => $composableBuilder(
    column: $table.sgst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalGst => $composableBuilder(
    column: $table.totalGst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get advancePaid => $composableBuilder(
    column: $table.advancePaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountPaidInWords => $composableBuilder(
    column: $table.amountPaidInWords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docxPath => $composableBuilder(
    column: $table.docxPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateSchemaJson => $composableBuilder(
    column: $table.templateSchemaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldValuesJson => $composableBuilder(
    column: $table.fieldValuesJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> invoiceItemsRefs(
    Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f,
  ) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableFilterComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingRef => $composableBuilder(
    column: $table.bookingRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get bookingDate => $composableBuilder(
    column: $table.bookingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerGstNumber => $composableBuilder(
    column: $table.customerGstNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerContactNumber => $composableBuilder(
    column: $table.customerContactNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tourTrip => $composableBuilder(
    column: $table.tourTrip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get travelDate => $composableBuilder(
    column: $table.travelDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noOfDays => $composableBuilder(
    column: $table.noOfDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noOfVehicles => $composableBuilder(
    column: $table.noOfVehicles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coordinatorName => $composableBuilder(
    column: $table.coordinatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cgst => $composableBuilder(
    column: $table.cgst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sgst => $composableBuilder(
    column: $table.sgst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalGst => $composableBuilder(
    column: $table.totalGst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get advancePaid => $composableBuilder(
    column: $table.advancePaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountPaidInWords => $composableBuilder(
    column: $table.amountPaidInWords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docxPath => $composableBuilder(
    column: $table.docxPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateSchemaJson => $composableBuilder(
    column: $table.templateSchemaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldValuesJson => $composableBuilder(
    column: $table.fieldValuesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get invoiceDate => $composableBuilder(
    column: $table.invoiceDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get bookingRef => $composableBuilder(
    column: $table.bookingRef,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get bookingDate => $composableBuilder(
    column: $table.bookingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerGstNumber => $composableBuilder(
    column: $table.customerGstNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerContactNumber => $composableBuilder(
    column: $table.customerContactNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tourTrip =>
      $composableBuilder(column: $table.tourTrip, builder: (column) => column);

  GeneratedColumn<DateTime> get travelDate => $composableBuilder(
    column: $table.travelDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noOfDays =>
      $composableBuilder(column: $table.noOfDays, builder: (column) => column);

  GeneratedColumn<int> get noOfVehicles => $composableBuilder(
    column: $table.noOfVehicles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coordinatorName => $composableBuilder(
    column: $table.coordinatorName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subTotal =>
      $composableBuilder(column: $table.subTotal, builder: (column) => column);

  GeneratedColumn<double> get cgst =>
      $composableBuilder(column: $table.cgst, builder: (column) => column);

  GeneratedColumn<double> get sgst =>
      $composableBuilder(column: $table.sgst, builder: (column) => column);

  GeneratedColumn<double> get totalGst =>
      $composableBuilder(column: $table.totalGst, builder: (column) => column);

  GeneratedColumn<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get advancePaid => $composableBuilder(
    column: $table.advancePaid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amountPaidInWords => $composableBuilder(
    column: $table.amountPaidInWords,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<String> get docxPath =>
      $composableBuilder(column: $table.docxPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateSchemaJson => $composableBuilder(
    column: $table.templateSchemaJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldValuesJson => $composableBuilder(
    column: $table.fieldValuesJson,
    builder: (column) => column,
  );

  Expression<T> invoiceItemsRefs<T extends Object>(
    Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f,
  ) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceItems,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoicesTable,
          Invoice,
          $$InvoicesTableFilterComposer,
          $$InvoicesTableOrderingComposer,
          $$InvoicesTableAnnotationComposer,
          $$InvoicesTableCreateCompanionBuilder,
          $$InvoicesTableUpdateCompanionBuilder,
          (Invoice, $$InvoicesTableReferences),
          Invoice,
          PrefetchHooks Function({bool invoiceItemsRefs})
        > {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> invoiceNumber = const Value.absent(),
                Value<DateTime> invoiceDate = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<String?> bookingRef = const Value.absent(),
                Value<DateTime?> bookingDate = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerAddress = const Value.absent(),
                Value<String?> customerGstNumber = const Value.absent(),
                Value<String?> customerContactNumber = const Value.absent(),
                Value<String?> tourTrip = const Value.absent(),
                Value<DateTime?> travelDate = const Value.absent(),
                Value<int?> noOfDays = const Value.absent(),
                Value<int?> noOfVehicles = const Value.absent(),
                Value<String?> coordinatorName = const Value.absent(),
                Value<double> subTotal = const Value.absent(),
                Value<double> cgst = const Value.absent(),
                Value<double> sgst = const Value.absent(),
                Value<double> totalGst = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<double> advancePaid = const Value.absent(),
                Value<String> amountPaidInWords = const Value.absent(),
                Value<String> templateType = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> docxPath = const Value.absent(),
                Value<DateTime> createdDate = const Value.absent(),
                Value<String?> templateSchemaJson = const Value.absent(),
                Value<String?> fieldValuesJson = const Value.absent(),
              }) => InvoicesCompanion(
                id: id,
                invoiceNumber: invoiceNumber,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                bookingRef: bookingRef,
                bookingDate: bookingDate,
                customerName: customerName,
                customerAddress: customerAddress,
                customerGstNumber: customerGstNumber,
                customerContactNumber: customerContactNumber,
                tourTrip: tourTrip,
                travelDate: travelDate,
                noOfDays: noOfDays,
                noOfVehicles: noOfVehicles,
                coordinatorName: coordinatorName,
                subTotal: subTotal,
                cgst: cgst,
                sgst: sgst,
                totalGst: totalGst,
                grandTotal: grandTotal,
                advancePaid: advancePaid,
                amountPaidInWords: amountPaidInWords,
                templateType: templateType,
                pdfPath: pdfPath,
                docxPath: docxPath,
                createdDate: createdDate,
                templateSchemaJson: templateSchemaJson,
                fieldValuesJson: fieldValuesJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String invoiceNumber,
                required DateTime invoiceDate,
                required DateTime dueDate,
                Value<String?> bookingRef = const Value.absent(),
                Value<DateTime?> bookingDate = const Value.absent(),
                required String customerName,
                required String customerAddress,
                Value<String?> customerGstNumber = const Value.absent(),
                Value<String?> customerContactNumber = const Value.absent(),
                Value<String?> tourTrip = const Value.absent(),
                Value<DateTime?> travelDate = const Value.absent(),
                Value<int?> noOfDays = const Value.absent(),
                Value<int?> noOfVehicles = const Value.absent(),
                Value<String?> coordinatorName = const Value.absent(),
                required double subTotal,
                required double cgst,
                required double sgst,
                required double totalGst,
                required double grandTotal,
                Value<double> advancePaid = const Value.absent(),
                required String amountPaidInWords,
                Value<String> templateType = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> docxPath = const Value.absent(),
                required DateTime createdDate,
                Value<String?> templateSchemaJson = const Value.absent(),
                Value<String?> fieldValuesJson = const Value.absent(),
              }) => InvoicesCompanion.insert(
                id: id,
                invoiceNumber: invoiceNumber,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                bookingRef: bookingRef,
                bookingDate: bookingDate,
                customerName: customerName,
                customerAddress: customerAddress,
                customerGstNumber: customerGstNumber,
                customerContactNumber: customerContactNumber,
                tourTrip: tourTrip,
                travelDate: travelDate,
                noOfDays: noOfDays,
                noOfVehicles: noOfVehicles,
                coordinatorName: coordinatorName,
                subTotal: subTotal,
                cgst: cgst,
                sgst: sgst,
                totalGst: totalGst,
                grandTotal: grandTotal,
                advancePaid: advancePaid,
                amountPaidInWords: amountPaidInWords,
                templateType: templateType,
                pdfPath: pdfPath,
                docxPath: docxPath,
                createdDate: createdDate,
                templateSchemaJson: templateSchemaJson,
                fieldValuesJson: fieldValuesJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (invoiceItemsRefs) db.invoiceItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoiceItemsRefs)
                    await $_getPrefetchedData<
                      Invoice,
                      $InvoicesTable,
                      InvoiceItem
                    >(
                      currentTable: table,
                      referencedTable: $$InvoicesTableReferences
                          ._invoiceItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$InvoicesTableReferences(
                        db,
                        table,
                        p0,
                      ).invoiceItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.invoiceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoicesTable,
      Invoice,
      $$InvoicesTableFilterComposer,
      $$InvoicesTableOrderingComposer,
      $$InvoicesTableAnnotationComposer,
      $$InvoicesTableCreateCompanionBuilder,
      $$InvoicesTableUpdateCompanionBuilder,
      (Invoice, $$InvoicesTableReferences),
      Invoice,
      PrefetchHooks Function({bool invoiceItemsRefs})
    >;
typedef $$InvoiceItemsTableCreateCompanionBuilder =
    InvoiceItemsCompanion Function({
      Value<int> id,
      required int invoiceId,
      required String description,
      Value<int?> noOfVehicles,
      Value<DateTime?> itemDate,
      Value<String?> fromTo,
      required double quantityDays,
      required double rate,
      required double amount,
    });
typedef $$InvoiceItemsTableUpdateCompanionBuilder =
    InvoiceItemsCompanion Function({
      Value<int> id,
      Value<int> invoiceId,
      Value<String> description,
      Value<int?> noOfVehicles,
      Value<DateTime?> itemDate,
      Value<String?> fromTo,
      Value<double> quantityDays,
      Value<double> rate,
      Value<double> amount,
    });

final class $$InvoiceItemsTableReferences
    extends BaseReferences<_$AppDatabase, $InvoiceItemsTable, InvoiceItem> {
  $$InvoiceItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('invoice_items__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<int>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noOfVehicles => $composableBuilder(
    column: $table.noOfVehicles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get itemDate => $composableBuilder(
    column: $table.itemDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromTo => $composableBuilder(
    column: $table.fromTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityDays => $composableBuilder(
    column: $table.quantityDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noOfVehicles => $composableBuilder(
    column: $table.noOfVehicles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get itemDate => $composableBuilder(
    column: $table.itemDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromTo => $composableBuilder(
    column: $table.fromTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityDays => $composableBuilder(
    column: $table.quantityDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noOfVehicles => $composableBuilder(
    column: $table.noOfVehicles,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get itemDate =>
      $composableBuilder(column: $table.itemDate, builder: (column) => column);

  GeneratedColumn<String> get fromTo =>
      $composableBuilder(column: $table.fromTo, builder: (column) => column);

  GeneratedColumn<double> get quantityDays => $composableBuilder(
    column: $table.quantityDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceItemsTable,
          InvoiceItem,
          $$InvoiceItemsTableFilterComposer,
          $$InvoiceItemsTableOrderingComposer,
          $$InvoiceItemsTableAnnotationComposer,
          $$InvoiceItemsTableCreateCompanionBuilder,
          $$InvoiceItemsTableUpdateCompanionBuilder,
          (InvoiceItem, $$InvoiceItemsTableReferences),
          InvoiceItem,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$InvoiceItemsTableTableManager(_$AppDatabase db, $InvoiceItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> invoiceId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> noOfVehicles = const Value.absent(),
                Value<DateTime?> itemDate = const Value.absent(),
                Value<String?> fromTo = const Value.absent(),
                Value<double> quantityDays = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<double> amount = const Value.absent(),
              }) => InvoiceItemsCompanion(
                id: id,
                invoiceId: invoiceId,
                description: description,
                noOfVehicles: noOfVehicles,
                itemDate: itemDate,
                fromTo: fromTo,
                quantityDays: quantityDays,
                rate: rate,
                amount: amount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int invoiceId,
                required String description,
                Value<int?> noOfVehicles = const Value.absent(),
                Value<DateTime?> itemDate = const Value.absent(),
                Value<String?> fromTo = const Value.absent(),
                required double quantityDays,
                required double rate,
                required double amount,
              }) => InvoiceItemsCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                description: description,
                noOfVehicles: noOfVehicles,
                itemDate: itemDate,
                fromTo: fromTo,
                quantityDays: quantityDays,
                rate: rate,
                amount: amount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvoiceItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable: $$InvoiceItemsTableReferences
                                    ._invoiceIdTable(db),
                                referencedColumn: $$InvoiceItemsTableReferences
                                    ._invoiceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvoiceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceItemsTable,
      InvoiceItem,
      $$InvoiceItemsTableFilterComposer,
      $$InvoiceItemsTableOrderingComposer,
      $$InvoiceItemsTableAnnotationComposer,
      $$InvoiceItemsTableCreateCompanionBuilder,
      $$InvoiceItemsTableUpdateCompanionBuilder,
      (InvoiceItem, $$InvoiceItemsTableReferences),
      InvoiceItem,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$InvoiceTemplatesTableCreateCompanionBuilder =
    InvoiceTemplatesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      required String schemaJson,
      required DateTime createdDate,
    });
typedef $$InvoiceTemplatesTableUpdateCompanionBuilder =
    InvoiceTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<String> schemaJson,
      Value<DateTime> createdDate,
    });

class $$InvoiceTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceTemplatesTable> {
  $$InvoiceTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvoiceTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceTemplatesTable> {
  $$InvoiceTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvoiceTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceTemplatesTable> {
  $$InvoiceTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdDate => $composableBuilder(
    column: $table.createdDate,
    builder: (column) => column,
  );
}

class $$InvoiceTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvoiceTemplatesTable,
          InvoiceTemplate,
          $$InvoiceTemplatesTableFilterComposer,
          $$InvoiceTemplatesTableOrderingComposer,
          $$InvoiceTemplatesTableAnnotationComposer,
          $$InvoiceTemplatesTableCreateCompanionBuilder,
          $$InvoiceTemplatesTableUpdateCompanionBuilder,
          (
            InvoiceTemplate,
            BaseReferences<
              _$AppDatabase,
              $InvoiceTemplatesTable,
              InvoiceTemplate
            >,
          ),
          InvoiceTemplate,
          PrefetchHooks Function()
        > {
  $$InvoiceTemplatesTableTableManager(
    _$AppDatabase db,
    $InvoiceTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> schemaJson = const Value.absent(),
                Value<DateTime> createdDate = const Value.absent(),
              }) => InvoiceTemplatesCompanion(
                id: id,
                name: name,
                description: description,
                schemaJson: schemaJson,
                createdDate: createdDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required String schemaJson,
                required DateTime createdDate,
              }) => InvoiceTemplatesCompanion.insert(
                id: id,
                name: name,
                description: description,
                schemaJson: schemaJson,
                createdDate: createdDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvoiceTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvoiceTemplatesTable,
      InvoiceTemplate,
      $$InvoiceTemplatesTableFilterComposer,
      $$InvoiceTemplatesTableOrderingComposer,
      $$InvoiceTemplatesTableAnnotationComposer,
      $$InvoiceTemplatesTableCreateCompanionBuilder,
      $$InvoiceTemplatesTableUpdateCompanionBuilder,
      (
        InvoiceTemplate,
        BaseReferences<_$AppDatabase, $InvoiceTemplatesTable, InvoiceTemplate>,
      ),
      InvoiceTemplate,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CompanyProfilesTableTableManager get companyProfiles =>
      $$CompanyProfilesTableTableManager(_db, _db.companyProfiles);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db, _db.invoiceItems);
  $$InvoiceTemplatesTableTableManager get invoiceTemplates =>
      $$InvoiceTemplatesTableTableManager(_db, _db.invoiceTemplates);
}
