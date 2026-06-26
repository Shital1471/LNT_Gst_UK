import 'dart:convert';

class TextStyleSchema {
  final double fontSize;
  final String fontWeight; // 'normal', 'bold'
  final String fontFamily; // 'Times New Roman', 'Helvetica', 'Courier', 'Arial'
  final String textColor; // Hex color code
  final double lineHeight;
  final double letterSpacing;

  TextStyleSchema({
    required this.fontSize,
    required this.fontWeight,
    required this.fontFamily,
    required this.textColor,
    this.lineHeight = 1.2,
    this.letterSpacing = 0.0,
  });

  TextStyleSchema copyWith({
    double? fontSize,
    String? fontWeight,
    String? fontFamily,
    String? textColor,
    double? lineHeight,
    double? letterSpacing,
  }) {
    return TextStyleSchema(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'fontWeight': fontWeight,
    'fontFamily': fontFamily,
    'textColor': textColor,
    'lineHeight': lineHeight,
    'letterSpacing': letterSpacing,
  };

  factory TextStyleSchema.fromJson(Map<String, dynamic> json) => TextStyleSchema(
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 9.0,
    fontWeight: json['fontWeight'] as String? ?? 'normal',
    fontFamily: json['fontFamily'] as String? ?? 'Times New Roman',
    textColor: json['textColor'] as String? ?? '#000000',
    lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
    letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
  );
}

class TableColumnSchema {
  final String id;
  final String label;
  final bool isVisible;
  final double width; // in points
  final String alignment; // 'left', 'center', 'right'
  final String dataType; // 'text', 'number', 'currency', 'date'
  final int orderIndex;
  final bool isWidthFlexible;

  TableColumnSchema({
    required this.id,
    required this.label,
    this.isVisible = true,
    required this.width,
    this.alignment = 'left',
    this.dataType = 'text',
    required this.orderIndex,
    this.isWidthFlexible = false,
  });

  TableColumnSchema copyWith({
    String? id,
    String? label,
    bool? isVisible,
    double? width,
    String? alignment,
    String? dataType,
    int? orderIndex,
    bool? isWidthFlexible,
  }) => TableColumnSchema(
    id: id ?? this.id,
    label: label ?? this.label,
    isVisible: isVisible ?? this.isVisible,
    width: width ?? this.width,
    alignment: alignment ?? this.alignment,
    dataType: dataType ?? this.dataType,
    orderIndex: orderIndex ?? this.orderIndex,
    isWidthFlexible: isWidthFlexible ?? this.isWidthFlexible,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'isVisible': isVisible,
    'width': width,
    'alignment': alignment,
    'dataType': dataType,
    'orderIndex': orderIndex,
    'isWidthFlexible': isWidthFlexible,
  };

  factory TableColumnSchema.fromJson(Map<String, dynamic> json) => TableColumnSchema(
    id: json['id'] as String,
    label: json['label'] as String,
    isVisible: json['isVisible'] as bool? ?? true,
    width: (json['width'] as num?)?.toDouble() ?? 50.0,
    alignment: json['alignment'] as String? ?? 'left',
    dataType: json['dataType'] as String? ?? 'text',
    orderIndex: json['orderIndex'] as int? ?? 0,
    isWidthFlexible: json['isWidthFlexible'] as bool? ?? false,
  );
}

class FooterSectionSchema {
  final String id;
  final String title;
  final String alignment; // 'left', 'center', 'right'
  final double widthPercent;
  final double height;
  final bool isVisible;
  final int orderIndex;

  FooterSectionSchema({
    required this.id,
    required this.title,
    this.alignment = 'left',
    required this.widthPercent,
    this.height = 80.0,
    this.isVisible = true,
    required this.orderIndex,
  });

  FooterSectionSchema copyWith({
    String? id,
    String? title,
    String? alignment,
    double? widthPercent,
    double? height,
    bool? isVisible,
    int? orderIndex,
  }) => FooterSectionSchema(
    id: id ?? this.id,
    title: title ?? this.title,
    alignment: alignment ?? this.alignment,
    widthPercent: widthPercent ?? this.widthPercent,
    height: height ?? this.height,
    isVisible: isVisible ?? this.isVisible,
    orderIndex: orderIndex ?? this.orderIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'alignment': alignment,
    'widthPercent': widthPercent,
    'height': height,
    'isVisible': isVisible,
    'orderIndex': orderIndex,
  };

  factory FooterSectionSchema.fromJson(Map<String, dynamic> json) => FooterSectionSchema(
    id: json['id'] as String,
    title: json['title'] as String,
    alignment: json['alignment'] as String? ?? 'left',
    widthPercent: (json['widthPercent'] as num?)?.toDouble() ?? 33.3,
    height: (json['height'] as num?)?.toDouble() ?? 80.0,
    isVisible: json['isVisible'] as bool? ?? true,
    orderIndex: json['orderIndex'] as int? ?? 0,
  );
}

class HeaderConfigSchema {
  final double logoSize; // size scale factor (e.g. 1.0)
  final String logoPosition; // 'left', 'center', 'right'
  final bool logoIsVisible;
  final double companyNameSize;
  final double headerHeight;
  final String headerLayout; // 'split', 'centered', 'stacked'
  final double headerSpacing;
  final String headerAlignment; // 'left', 'center', 'right'

  HeaderConfigSchema({
    this.logoSize = 1.0,
    this.logoPosition = 'center',
    this.logoIsVisible = true,
    this.companyNameSize = 12.0,
    this.headerHeight = 110.0,
    this.headerLayout = 'split',
    this.headerSpacing = 8.0,
    this.headerAlignment = 'left',
  });

  HeaderConfigSchema copyWith({
    double? logoSize,
    String? logoPosition,
    bool? logoIsVisible,
    double? companyNameSize,
    double? headerHeight,
    String? headerLayout,
    double? headerSpacing,
    String? headerAlignment,
  }) => HeaderConfigSchema(
    logoSize: logoSize ?? this.logoSize,
    logoPosition: logoPosition ?? this.logoPosition,
    logoIsVisible: logoIsVisible ?? this.logoIsVisible,
    companyNameSize: companyNameSize ?? this.companyNameSize,
    headerHeight: headerHeight ?? this.headerHeight,
    headerLayout: headerLayout ?? this.headerLayout,
    headerSpacing: headerSpacing ?? this.headerSpacing,
    headerAlignment: headerAlignment ?? this.headerAlignment,
  );

  Map<String, dynamic> toJson() => {
    'logoSize': logoSize,
    'logoPosition': logoPosition,
    'logoIsVisible': logoIsVisible,
    'companyNameSize': companyNameSize,
    'headerHeight': headerHeight,
    'headerLayout': headerLayout,
    'headerSpacing': headerSpacing,
    'headerAlignment': headerAlignment,
  };

  factory HeaderConfigSchema.fromJson(Map<String, dynamic> json) => HeaderConfigSchema(
    logoSize: (json['logoSize'] as num?)?.toDouble() ?? 1.0,
    logoPosition: json['logoPosition'] as String? ?? 'center',
    logoIsVisible: json['logoIsVisible'] as bool? ?? true,
    companyNameSize: (json['companyNameSize'] as num?)?.toDouble() ?? 12.0,
    headerHeight: (json['headerHeight'] as num?)?.toDouble() ?? 110.0,
    headerLayout: json['headerLayout'] as String? ?? 'split',
    headerSpacing: (json['headerSpacing'] as num?)?.toDouble() ?? 8.0,
    headerAlignment: json['headerAlignment'] as String? ?? 'left',
  );
}

class FieldSchema {
  final String id;
  final String label;
  final String valueType; // 'text', 'number', 'date', 'currency', 'dropdown', 'checkbox', 'time', 'radio', 'multiline'
  final dynamic defaultValue;
  final bool isVisible;
  final bool isCustom;
  final List<String>? dropdownOptions;
  
  // Layout positions for Drag & Drop Visual Editor
  final double? posX;
  final double? posY;
  final double? width;
  final double? height;
  final String alignment; // 'left', 'center', 'right'
  final double fontSize;
  final String fontWeight; // 'normal', 'bold'
  final String textColor; // HEX color code e.g. '#000000'

  FieldSchema({
    required this.id,
    required this.label,
    required this.valueType,
    this.defaultValue,
    this.isVisible = true,
    this.isCustom = false,
    this.dropdownOptions,
    this.posX,
    this.posY,
    this.width,
    this.height,
    this.alignment = 'left',
    this.fontSize = 9.0,
    this.fontWeight = 'normal',
    this.textColor = '#000000',
  });

  FieldSchema copyWith({
    String? id,
    String? label,
    String? valueType,
    dynamic defaultValue,
    bool? isVisible,
    bool? isCustom,
    List<String>? dropdownOptions,
    double? posX,
    double? posY,
    double? width,
    double? height,
    String? alignment,
    double? fontSize,
    String? fontWeight,
    String? textColor,
  }) {
    return FieldSchema(
      id: id ?? this.id,
      label: label ?? this.label,
      valueType: valueType ?? this.valueType,
      defaultValue: defaultValue ?? this.defaultValue,
      isVisible: isVisible ?? this.isVisible,
      isCustom: isCustom ?? this.isCustom,
      dropdownOptions: dropdownOptions ?? this.dropdownOptions,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      alignment: alignment ?? this.alignment,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textColor: textColor ?? this.textColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'valueType': valueType,
      'defaultValue': defaultValue,
      'isVisible': isVisible,
      'isCustom': isCustom,
      'dropdownOptions': dropdownOptions,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
      'alignment': alignment,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'textColor': textColor,
    };
  }

  factory FieldSchema.fromJson(Map<String, dynamic> json) {
    return FieldSchema(
      id: json['id'] as String,
      label: json['label'] as String,
      valueType: json['valueType'] as String,
      defaultValue: json['defaultValue'],
      isVisible: json['isVisible'] as bool? ?? true,
      isCustom: json['isCustom'] as bool? ?? false,
      dropdownOptions: (json['dropdownOptions'] as List<dynamic>?)?.map((e) => e as String).toList(),
      posX: (json['posX'] as num?)?.toDouble(),
      posY: (json['posY'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      alignment: json['alignment'] as String? ?? 'left',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 9.0,
      fontWeight: json['fontWeight'] as String? ?? 'normal',
      textColor: json['textColor'] as String? ?? '#000000',
    );
  }
}

class SectionSchema {
  final String id;
  final String title;
  final bool isVisible;
  final int orderIndex;
  final List<FieldSchema> fields;

  SectionSchema({
    required this.id,
    required this.title,
    this.isVisible = true,
    required this.orderIndex,
    required this.fields,
  });

  SectionSchema copyWith({
    String? id,
    String? title,
    bool? isVisible,
    int? orderIndex,
    List<FieldSchema>? fields,
  }) {
    return SectionSchema(
      id: id ?? this.id,
      title: title ?? this.title,
      isVisible: isVisible ?? this.isVisible,
      orderIndex: orderIndex ?? this.orderIndex,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isVisible': isVisible,
      'orderIndex': orderIndex,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }

  factory SectionSchema.fromJson(Map<String, dynamic> json) {
    return SectionSchema(
      id: json['id'] as String,
      title: json['title'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      orderIndex: json['orderIndex'] as int? ?? 0,
      fields: (json['fields'] as List<dynamic>)
          .map((f) => FieldSchema.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InvoiceTemplateSchema {
  final String id;
  final String name;
  final String description;
  final String pageFormat; // 'A4', 'Letter', 'Custom'
  final double pageWidth; // points
  final double pageHeight; // points
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final String layoutPreset; // 'compact', 'standard', 'large_print'
  final double baseFontSize;
  final List<SectionSchema> sections;
  
  // Custom Designer layout engine properties
  final Map<String, TextStyleSchema> typography;
  final double sectionGap;
  final double subsectionGap;
  final double tableGap;
  final double footerGap;
  final HeaderConfigSchema headerConfig;
  final List<TableColumnSchema> tableColumns;
  final List<FooterSectionSchema> footerSections;

  InvoiceTemplateSchema({
    required this.id,
    required this.name,
    required this.description,
    this.pageFormat = 'A4',
    this.pageWidth = 595.27,
    this.pageHeight = 841.89,
    this.marginTop = 24.0,
    this.marginBottom = 24.0,
    this.marginLeft = 24.0,
    this.marginRight = 24.0,
    this.layoutPreset = 'standard',
    this.baseFontSize = 10.0,
    required this.sections,
    required this.typography,
    this.sectionGap = 12.0,
    this.subsectionGap = 6.0,
    this.tableGap = 12.0,
    this.footerGap = 12.0,
    required this.headerConfig,
    required this.tableColumns,
    required this.footerSections,
  });

  InvoiceTemplateSchema copyWith({
    String? id,
    String? name,
    String? description,
    String? pageFormat,
    double? pageWidth,
    double? pageHeight,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    String? layoutPreset,
    double? baseFontSize,
    List<SectionSchema>? sections,
    Map<String, TextStyleSchema>? typography,
    double? sectionGap,
    double? subsectionGap,
    double? tableGap,
    double? footerGap,
    HeaderConfigSchema? headerConfig,
    List<TableColumnSchema>? tableColumns,
    List<FooterSectionSchema>? footerSections,
  }) {
    return InvoiceTemplateSchema(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pageFormat: pageFormat ?? this.pageFormat,
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      layoutPreset: layoutPreset ?? this.layoutPreset,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      sections: sections ?? this.sections,
      typography: typography ?? this.typography,
      sectionGap: sectionGap ?? this.sectionGap,
      subsectionGap: subsectionGap ?? this.subsectionGap,
      tableGap: tableGap ?? this.tableGap,
      footerGap: footerGap ?? this.footerGap,
      headerConfig: headerConfig ?? this.headerConfig,
      tableColumns: tableColumns ?? this.tableColumns,
      footerSections: footerSections ?? this.footerSections,
    );
  }

  // Recalculates and adjusts widths to prevent bounds/page overflow
  InvoiceTemplateSchema adjustColumnWidths() {
    final double contentWidth = pageWidth - marginLeft - marginRight;
    
    // Sum widths of visible columns
    final visibleCols = tableColumns.where((c) => c.isVisible).toList();
    if (visibleCols.isEmpty) return this;

    final flexibleCols = visibleCols.where((c) => c.isWidthFlexible).toList();
    final fixedCols = visibleCols.where((c) => !c.isWidthFlexible).toList();

    double fixedWidthSum = 0;
    for (final col in fixedCols) {
      // Ensure column respects bounds: min 20, max contentWidth
      double colW = col.width;
      if (colW < 20) colW = 20;
      if (colW > contentWidth - 40) colW = contentWidth - 40;
      fixedWidthSum += colW;
    }

    double remainingWidth = contentWidth - fixedWidthSum;
    if (remainingWidth < 20 * flexibleCols.length) {
      // If remaining width doesn't satisfy min flexible widths, scale down fixed columns proportionally
      final double scale = (contentWidth - 20 * flexibleCols.length) / (fixedWidthSum == 0 ? 1.0 : fixedWidthSum);
      fixedWidthSum = 0;
      final updatedColumns = tableColumns.map((col) {
        if (!col.isVisible) return col;
        if (!col.isWidthFlexible) {
          double scaledW = col.width * scale;
          if (scaledW < 20) scaledW = 20;
          fixedWidthSum += scaledW;
          return col.copyWith(width: scaledW);
        } else {
          return col.copyWith(width: 20.0);
        }
      }).toList();

      return copyWith(tableColumns: updatedColumns);
    } else {
      // Allocate remaining width evenly among flexible columns
      final double flexW = remainingWidth / (flexibleCols.isEmpty ? 1.0 : flexibleCols.length);
      final updatedColumns = tableColumns.map((col) {
        if (!col.isVisible) return col;
        if (col.isWidthFlexible) {
          return col.copyWith(width: flexW);
        } else {
          double colW = col.width;
          if (colW < 20) colW = 20;
          if (colW > contentWidth - 40) colW = contentWidth - 40;
          return col.copyWith(width: colW);
        }
      }).toList();

      return copyWith(tableColumns: updatedColumns);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pageFormat': pageFormat,
      'pageWidth': pageWidth,
      'pageHeight': pageHeight,
      'marginTop': marginTop,
      'marginBottom': marginBottom,
      'marginLeft': marginLeft,
      'marginRight': marginRight,
      'layoutPreset': layoutPreset,
      'baseFontSize': baseFontSize,
      'sections': sections.map((s) => s.toJson()).toList(),
      'typography': typography.map((key, value) => MapEntry(key, value.toJson())),
      'sectionGap': sectionGap,
      'subsectionGap': subsectionGap,
      'tableGap': tableGap,
      'footerGap': footerGap,
      'headerConfig': headerConfig.toJson(),
      'tableColumns': tableColumns.map((c) => c.toJson()).toList(),
      'footerSections': footerSections.map((f) => f.toJson()).toList(),
    };
  }

  factory InvoiceTemplateSchema.fromJson(Map<String, dynamic> json) {
    // Deserialize typography
    final Map<String, dynamic>? tyMap = json['typography'] as Map<String, dynamic>?;
    final Map<String, TextStyleSchema> typography = {};
    if (tyMap != null) {
      tyMap.forEach((key, val) {
        typography[key] = TextStyleSchema.fromJson(val as Map<String, dynamic>);
      });
    } else {
      // Apply defaults depending on template ID
      typography.addAll(getDefaultTypography(json['id'] as String? ?? 'standard'));
    }

    // Deserialize table columns
    final List<dynamic>? colsList = json['tableColumns'] as List<dynamic>?;
    final List<TableColumnSchema> tableColumns = [];
    if (colsList != null) {
      tableColumns.addAll(colsList.map((c) => TableColumnSchema.fromJson(c as Map<String, dynamic>)));
    } else {
      tableColumns.addAll(getDefaultTableColumns(json['id'] as String? ?? 'standard'));
    }

    // Deserialize footer sections
    final List<dynamic>? footerList = json['footerSections'] as List<dynamic>?;
    final List<FooterSectionSchema> footerSections = [];
    if (footerList != null) {
      footerSections.addAll(footerList.map((f) => FooterSectionSchema.fromJson(f as Map<String, dynamic>)));
    } else {
      footerSections.addAll(getDefaultFooterSections());
    }

    return InvoiceTemplateSchema(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      pageFormat: json['pageFormat'] as String? ?? 'A4',
      pageWidth: (json['pageWidth'] as num?)?.toDouble() ?? 595.27,
      pageHeight: (json['pageHeight'] as num?)?.toDouble() ?? 841.89,
      marginTop: (json['marginTop'] as num?)?.toDouble() ?? 24.0,
      marginBottom: (json['marginBottom'] as num?)?.toDouble() ?? 24.0,
      marginLeft: (json['marginLeft'] as num?)?.toDouble() ?? 24.0,
      marginRight: (json['marginRight'] as num?)?.toDouble() ?? 24.0,
      layoutPreset: json['layoutPreset'] as String? ?? 'standard',
      baseFontSize: (json['baseFontSize'] as num?)?.toDouble() ?? 10.0,
      sections: (json['sections'] as List<dynamic>)
          .map((s) => SectionSchema.fromJson(s as Map<String, dynamic>))
          .toList(),
      typography: typography,
      sectionGap: (json['sectionGap'] as num?)?.toDouble() ?? 12.0,
      subsectionGap: (json['subsectionGap'] as num?)?.toDouble() ?? 6.0,
      tableGap: (json['tableGap'] as num?)?.toDouble() ?? 12.0,
      footerGap: (json['footerGap'] as num?)?.toDouble() ?? 12.0,
      headerConfig: json['headerConfig'] != null
          ? HeaderConfigSchema.fromJson(json['headerConfig'] as Map<String, dynamic>)
          : HeaderConfigSchema(),
      tableColumns: tableColumns,
      footerSections: footerSections,
    );
  }

  static InvoiceTemplateSchema getPreset(String type) {
    switch (type) {
      case 'tourism':
        return getTourismDefault();
      case 'service':
        return getServiceDefault();
      case 'transport':
        return getTransportDefault();
      case 'standard':
      default:
        return getStandardDefault();
    }
  }

  static Map<String, TextStyleSchema> getDefaultTypography(String id) {
    final font = (id == 'tourism') ? 'Times New Roman' : 'Helvetica';
    return {
      'header': TextStyleSchema(fontSize: 12, fontWeight: 'bold', fontFamily: font, textColor: '#0B3B60'),
      'subheader': TextStyleSchema(fontSize: 6.5, fontWeight: 'bold', fontFamily: font, textColor: '#E57A25'),
      'section_title': TextStyleSchema(fontSize: 8, fontWeight: 'bold', fontFamily: font, textColor: '#499F34'),
      'subsection_title': TextStyleSchema(fontSize: 8, fontWeight: 'bold', fontFamily: font, textColor: '#000000'),
      'body': TextStyleSchema(fontSize: 7.5, fontWeight: 'normal', fontFamily: font, textColor: '#000000'),
      'table_header': TextStyleSchema(fontSize: 7.5, fontWeight: 'bold', fontFamily: font, textColor: '#FFFFFF'),
      'table_data': TextStyleSchema(fontSize: 7.5, fontWeight: 'normal', fontFamily: font, textColor: '#000000'),
      'footer': TextStyleSchema(fontSize: 6.5, fontWeight: 'normal', fontFamily: font, textColor: '#000000'),
    };
  }

  static List<TableColumnSchema> getDefaultTableColumns(String id) {
    if (id == 'tourism') {
      return [
        TableColumnSchema(id: 's_no', label: 'S No.', width: 25.0, alignment: 'center', dataType: 'number', orderIndex: 0),
        TableColumnSchema(id: 'description', label: 'Description of Service', width: 135.0, alignment: 'left', dataType: 'text', orderIndex: 1, isWidthFlexible: true),
        TableColumnSchema(id: 'no_of_vehicles', label: 'No. of Vehicles', width: 55.0, alignment: 'center', dataType: 'number', orderIndex: 2),
        TableColumnSchema(id: 'date', label: 'Date', width: 65.0, alignment: 'center', dataType: 'date', orderIndex: 3),
        TableColumnSchema(id: 'from_to', label: 'From-To', width: 110.0, alignment: 'left', dataType: 'text', orderIndex: 4),
        TableColumnSchema(id: 'qty', label: 'Qty/Days', width: 41.27, alignment: 'center', dataType: 'number', orderIndex: 5),
        TableColumnSchema(id: 'rate', label: 'Rate (Rs.)', width: 55.0, alignment: 'right', dataType: 'currency', orderIndex: 6),
        TableColumnSchema(id: 'amount', label: 'Amt (Rs.)', width: 65.0, alignment: 'right', dataType: 'currency', orderIndex: 7),
      ];
    } else if (id == 'transport') {
      return [
        TableColumnSchema(id: 's_no', label: 'S No.', width: 25.0, alignment: 'center', dataType: 'number', orderIndex: 0),
        TableColumnSchema(id: 'description', label: 'Service Description', width: 135.0, alignment: 'left', dataType: 'text', orderIndex: 1, isWidthFlexible: true),
        TableColumnSchema(id: 'no_of_vehicles', label: 'Vehicle No', width: 55.0, alignment: 'center', dataType: 'text', orderIndex: 2),
        TableColumnSchema(id: 'date', label: 'Delivery Date', width: 45.0, alignment: 'center', dataType: 'date', orderIndex: 3),
        TableColumnSchema(id: 'from_to', label: 'Route', width: 110.0, alignment: 'left', dataType: 'text', orderIndex: 4),
        TableColumnSchema(id: 'qty', label: 'Qty', width: 35.0, alignment: 'center', dataType: 'number', orderIndex: 5),
        TableColumnSchema(id: 'rate', label: 'Rate (Rs.)', width: 45.0, alignment: 'right', dataType: 'currency', orderIndex: 6),
        TableColumnSchema(id: 'amount', label: 'Amt (Rs.)', width: 50.0, alignment: 'right', dataType: 'currency', orderIndex: 7),
      ];
    } else {
      // standard / service
      return [
        TableColumnSchema(id: 's_no', label: 'S No.', width: 30.0, alignment: 'center', dataType: 'number', orderIndex: 0),
        TableColumnSchema(id: 'description', label: 'Description of Goods / Services', width: 250.0, alignment: 'left', dataType: 'text', orderIndex: 1, isWidthFlexible: true),
        TableColumnSchema(id: 'qty', label: 'Qty', width: 50.0, alignment: 'center', dataType: 'number', orderIndex: 2),
        TableColumnSchema(id: 'rate', label: 'Rate (Rs.)', width: 60.0, alignment: 'right', dataType: 'currency', orderIndex: 3),
        TableColumnSchema(id: 'amount', label: 'Amt (Rs.)', width: 70.0, alignment: 'right', dataType: 'currency', orderIndex: 4),
      ];
    }
  }

  static List<FooterSectionSchema> getDefaultFooterSections() {
    return [
      FooterSectionSchema(id: 'terms_conditions', title: 'Terms & Conditions', widthPercent: 40.0, orderIndex: 0),
      FooterSectionSchema(id: 'bank_details', title: 'Bank Details', widthPercent: 30.0, orderIndex: 1),
      FooterSectionSchema(id: 'signature', title: 'Signature Area', widthPercent: 30.0, orderIndex: 2),
    ];
  }

  static InvoiceTemplateSchema getTourismDefault() {
    return InvoiceTemplateSchema(
      id: 'tourism',
      name: 'LN Tourism Invoice',
      description: 'Specialized layout for Tours & Travels with Booking and Vehicles info',
      typography: getDefaultTypography('tourism'),
      headerConfig: HeaderConfigSchema(logoSize: 1.0, logoPosition: 'center', headerHeight: 110.0, headerLayout: 'split'),
      tableColumns: getDefaultTableColumns('tourism'),
      footerSections: getDefaultFooterSections(),
      sections: [
        SectionSchema(
          id: 'company_details',
          title: 'Company Details',
          orderIndex: 0,
          fields: [
            FieldSchema(id: 'company_name', label: 'Company Name', valueType: 'text', fontSize: 12, fontWeight: 'bold', textColor: '#0B3B60', defaultValue: 'LN TOURISM PRIVATE LIMITED', posX: 22, posY: 32, width: 230, height: 16),
            FieldSchema(id: 'company_tagline', label: 'Company Tagline', valueType: 'text', fontSize: 6.5, fontWeight: 'bold', textColor: '#E57A25', defaultValue: 'TOURS & TRAVELS | CAR RENTAL | TRANSPORT SOLUTIONS', posX: 22, posY: 46, width: 230, height: 10),
            FieldSchema(id: 'company_phone', label: 'Phone', valueType: 'text', defaultValue: '+91 88588 73018', posX: 22, posY: 78, width: 230, height: 10),
            FieldSchema(id: 'company_email', label: 'Email', valueType: 'text', defaultValue: 'abhishek@lntourism.com', posX: 22, posY: 88, width: 340, height: 10),
            FieldSchema(id: 'company_website', label: 'Website', valueType: 'text', defaultValue: 'www.lntourism.com', posX: 22, posY: 88, width: 340, height: 10),
            FieldSchema(id: 'company_address', label: 'Office Address', valueType: 'text', defaultValue: 'Jakhan Chowk, Rajpur Rd, Near Petrol Pump, Dehradun, Uttarakhand-248001', posX: 22, posY: 98, width: 340, height: 20),
          ],
        ),
        SectionSchema(
          id: 'customer_details',
          title: 'BILL TO',
          orderIndex: 1,
          fields: [
            FieldSchema(id: 'customer_name', label: 'Name / Company', valueType: 'text', fontWeight: 'bold', posX: 104, posY: 172, width: 181, height: 10),
            FieldSchema(id: 'customer_address', label: 'Address', valueType: 'text', posX: 104, posY: 186, width: 181, height: 10),
            FieldSchema(id: 'customer_city_state_pin', label: 'City / State / PIN', valueType: 'text', posX: 104, posY: 200, width: 181, height: 10),
            FieldSchema(id: 'customer_gst', label: 'GSTIN', valueType: 'text', posX: 104, posY: 214, width: 181, height: 10),
            FieldSchema(id: 'customer_phone', label: 'Contact No.', valueType: 'text', posX: 104, posY: 228, width: 181, height: 10),
          ],
        ),
        SectionSchema(
          id: 'invoice_info',
          title: 'Invoice Details',
          orderIndex: 2,
          fields: [
            FieldSchema(id: 'invoice_number', label: 'Invoice No.', valueType: 'text', fontWeight: 'bold', posX: 460, posY: 62, width: 100, height: 10, fontSize: 6.5),
            FieldSchema(id: 'invoice_date', label: 'Invoice Date', valueType: 'date', posX: 460, posY: 73, width: 100, height: 10, fontSize: 6.5),
            FieldSchema(id: 'booking_ref', label: 'Booking Ref.', valueType: 'text', posX: 460, posY: 84, width: 100, height: 10, fontSize: 6.5),
            FieldSchema(id: 'booking_date', label: 'Booking Date', valueType: 'date', posX: 460, posY: 95, width: 100, height: 10, fontSize: 6.5),
            FieldSchema(id: 'company_pan', label: 'PAN No.', valueType: 'text', defaultValue: 'AAGCL7813B', posX: 460, posY: 106, width: 100, height: 10, fontSize: 6.5, fontWeight: 'bold'),
            FieldSchema(id: 'company_gst_in', label: 'GSTIN', valueType: 'text', defaultValue: '05AAGCL7813B1ZU', posX: 460, posY: 117, width: 100, height: 10, fontSize: 6.5, fontWeight: 'bold'),
          ],
        ),
        SectionSchema(
          id: 'service_details',
          title: 'SERVICE DETAIL 8',
          orderIndex: 3,
          fields: [
            FieldSchema(id: 'tour_trip', label: 'Tour / Trip', valueType: 'text', posX: 395, posY: 172, width: 176, height: 10),
            FieldSchema(id: 'travel_date', label: 'Travel Date', valueType: 'date', posX: 395, posY: 186, width: 176, height: 10),
            FieldSchema(id: 'no_of_days', label: 'No. of Days', valueType: 'number', posX: 395, posY: 200, width: 176, height: 10),
            FieldSchema(id: 'no_of_vehicles', label: 'No. of Vehicles', valueType: 'number', posX: 395, posY: 214, width: 176, height: 10),
            FieldSchema(id: 'coordinator_name', label: 'Co-ordinator Name', valueType: 'text', posX: 395, posY: 228, width: 176, height: 10),
          ],
        ),
        SectionSchema(
          id: 'items_table',
          title: 'Service Items Table',
          orderIndex: 4,
          fields: [], // Handled dynamically by table columns
        ),
        SectionSchema(
          id: 'tax_summary',
          title: 'Tax Summary',
          orderIndex: 5,
          fields: [],
        ),
        SectionSchema(
          id: 'payment_info',
          title: 'BANK DETAIL 8',
          orderIndex: 6,
          fields: [
            FieldSchema(id: 'bank_account_name', label: 'Account Name', valueType: 'text', defaultValue: 'LN Tourism Private Limited', posX: 285, posY: 574, width: 90, height: 10, fontSize: 6.5),
            FieldSchema(id: 'bank_name', label: 'Bank Name', valueType: 'text', defaultValue: 'State Bank of India', posX: 285, posY: 585, width: 90, height: 10, fontSize: 6.5),
            FieldSchema(id: 'bank_account_no', label: 'Account No.', valueType: 'text', defaultValue: '45103469416', posX: 285, posY: 596, width: 90, height: 10, fontSize: 6.5),
            FieldSchema(id: 'bank_ifsc', label: 'IFSC Code', valueType: 'text', defaultValue: 'SBIN0017056', posX: 285, posY: 607, width: 90, height: 10, fontSize: 6.5),
            FieldSchema(id: 'bank_branch', label: 'Branch', valueType: 'text', defaultValue: 'Dehradun', posX: 285, posY: 618, width: 90, height: 10, fontSize: 6.5),
          ],
        ),
        SectionSchema(
          id: 'terms_conditions',
          title: 'TERM & CONDITION 8',
          orderIndex: 7,
          fields: [
            FieldSchema(
              id: 'terms_text',
              label: 'Terms',
              valueType: 'text',
              defaultValue: '1. Payment to be made within 7 days from invoice date.\n2. Extra charges (State Tax, Night Halt, Extra Km) will be charged as per actual.\n3. Vehicle will be provided as per the itinerary only.\n4. No refund for unused days or cancellations post journey.\n5. All disputes are subject to Dehradun jurisdiction only.',
              posX: 28, posY: 574, width: 170, height: 75, fontSize: 5.5,
            ),
          ],
        ),
        SectionSchema(
          id: 'signature',
          title: 'Authorized Signatory',
          orderIndex: 8,
          fields: [
            FieldSchema(id: 'signatory_title', label: 'Signatory Title', valueType: 'text', defaultValue: 'AUTHORISED SIGNATORY', posX: 388, posY: 648, width: 185, height: 10, fontSize: 6.5),
          ],
        ),
      ],
    );
  }

  static InvoiceTemplateSchema getStandardDefault() {
    return InvoiceTemplateSchema(
      id: 'standard',
      name: 'Standard GST Invoice',
      description: 'Clean professional standard business template',
      typography: getDefaultTypography('standard'),
      headerConfig: HeaderConfigSchema(),
      tableColumns: getDefaultTableColumns('standard'),
      footerSections: getDefaultFooterSections(),
      sections: [
        SectionSchema(
          id: 'company_details',
          title: 'Company Details',
          orderIndex: 0,
          fields: [
            FieldSchema(id: 'company_name', label: 'Company Name', valueType: 'text', fontSize: 16, fontWeight: 'bold', textColor: '#0B3B60'),
            FieldSchema(id: 'company_phone', label: 'Phone', valueType: 'text'),
            FieldSchema(id: 'company_email', label: 'Email', valueType: 'text'),
            FieldSchema(id: 'company_address', label: 'Address', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'customer_details',
          title: 'Customer Details',
          orderIndex: 1,
          fields: [
            FieldSchema(id: 'customer_name', label: 'Billing Name', valueType: 'text', fontWeight: 'bold'),
            FieldSchema(id: 'customer_address', label: 'Billing Address', valueType: 'text'),
            FieldSchema(id: 'customer_gst', label: 'Customer GSTIN', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'invoice_info',
          title: 'Invoice Information',
          orderIndex: 2,
          fields: [
            FieldSchema(id: 'invoice_number', label: 'Invoice No.', valueType: 'text', fontWeight: 'bold'),
            FieldSchema(id: 'invoice_date', label: 'Date', valueType: 'date'),
            FieldSchema(id: 'due_date', label: 'Due Date', valueType: 'date'),
          ],
        ),
        SectionSchema(
          id: 'items_table',
          title: 'Line Items',
          orderIndex: 3,
          fields: [],
        ),
        SectionSchema(
          id: 'tax_summary',
          title: 'Taxation Summary',
          orderIndex: 4,
          fields: [],
        ),
        SectionSchema(
          id: 'payment_info',
          title: 'Bank & Payments',
          orderIndex: 5,
          fields: [
            FieldSchema(id: 'bank_name', label: 'Bank Name', valueType: 'text'),
            FieldSchema(id: 'bank_account_no', label: 'Account Number', valueType: 'text'),
            FieldSchema(id: 'bank_ifsc', label: 'IFSC Code', valueType: 'text'),
            FieldSchema(id: 'bank_branch', label: 'Branch', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'terms_conditions',
          title: 'Terms & Conditions',
          orderIndex: 6,
          fields: [
            FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text', defaultValue: '1. Subject to local jurisdiction.\n2. E&OE.'),
          ],
        ),
        SectionSchema(
          id: 'signature',
          title: 'Signature',
          orderIndex: 7,
          fields: [
            FieldSchema(id: 'signatory_title', label: 'Authorized Signee', valueType: 'text', defaultValue: 'AUTHORIZED SIGNATORY'),
          ],
        ),
      ],
    );
  }

  static InvoiceTemplateSchema getServiceDefault() {
    return InvoiceTemplateSchema(
      id: 'service',
      name: 'Service Invoice',
      description: 'Designed for consultants and service providers (no shipping/quantity columns needed)',
      typography: getDefaultTypography('service'),
      headerConfig: HeaderConfigSchema(headerLayout: 'centered'),
      tableColumns: [
        TableColumnSchema(id: 's_no', label: 'S No.', width: 30.0, alignment: 'center', dataType: 'number', orderIndex: 0),
        TableColumnSchema(id: 'description', label: 'Description of Services', width: 300.0, alignment: 'left', dataType: 'text', orderIndex: 1, isWidthFlexible: true),
        TableColumnSchema(id: 'rate', label: 'Rate (Rs.)', width: 80.0, alignment: 'right', dataType: 'currency', orderIndex: 2),
        TableColumnSchema(id: 'amount', label: 'Amt (Rs.)', width: 90.0, alignment: 'right', dataType: 'currency', orderIndex: 3),
      ],
      footerSections: getDefaultFooterSections(),
      sections: [
        SectionSchema(
          id: 'company_details',
          title: 'Company Info',
          orderIndex: 0,
          fields: [
            FieldSchema(id: 'company_name', label: 'Company Name', valueType: 'text', fontSize: 16, fontWeight: 'bold', textColor: '#499F34'),
            FieldSchema(id: 'company_address', label: 'Address', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'customer_details',
          title: 'Client Info',
          orderIndex: 1,
          fields: [
            FieldSchema(id: 'customer_name', label: 'Client Name', valueType: 'text', fontWeight: 'bold'),
            FieldSchema(id: 'customer_address', label: 'Client Address', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'invoice_info',
          title: 'Billing Details',
          orderIndex: 2,
          fields: [
            FieldSchema(id: 'invoice_number', label: 'Invoice No.', valueType: 'text', fontWeight: 'bold'),
            FieldSchema(id: 'invoice_date', label: 'Date', valueType: 'date'),
            FieldSchema(id: 'project_name', label: 'Project Name', valueType: 'text', isCustom: true),
          ],
        ),
        SectionSchema(
          id: 'items_table',
          title: 'Services Rendered',
          orderIndex: 3,
          fields: [],
        ),
        SectionSchema(
          id: 'tax_summary',
          title: 'Summary',
          orderIndex: 4,
          fields: [],
        ),
        SectionSchema(
          id: 'terms_conditions',
          title: 'Terms',
          orderIndex: 5,
          fields: [
            FieldSchema(id: 'terms_text', label: 'Terms', valueType: 'text', defaultValue: 'Thank you for your business!'),
          ],
        ),
      ],
    );
  }

  static InvoiceTemplateSchema getTransportDefault() {
    return InvoiceTemplateSchema(
      id: 'transport',
      name: 'Transport Invoice',
      description: 'Dedicated transport invoice layout tracking vehicle and delivery metrics',
      typography: getDefaultTypography('transport'),
      headerConfig: HeaderConfigSchema(headerLayout: 'split'),
      tableColumns: getDefaultTableColumns('transport'),
      footerSections: getDefaultFooterSections(),
      sections: [
        SectionSchema(
          id: 'company_details',
          title: 'Carrier Details',
          orderIndex: 0,
          fields: [
            FieldSchema(id: 'company_name', label: 'Carrier Name', valueType: 'text', fontSize: 16, fontWeight: 'bold', textColor: '#0B3B60'),
            FieldSchema(id: 'company_phone', label: 'Phone', valueType: 'text'),
            FieldSchema(id: 'company_address', label: 'Address', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'customer_details',
          title: 'Consignee / Consignor',
          orderIndex: 1,
          fields: [
            FieldSchema(id: 'customer_name', label: 'Customer Name', valueType: 'text', fontWeight: 'bold'),
            FieldSchema(id: 'customer_address', label: 'Address', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'invoice_info',
          title: 'Consignment Info',
          orderIndex: 2,
          fields: [
            FieldSchema(id: 'invoice_number', label: 'Bilty / Invoice No.', valueType: 'text', fontWeight: 'bold'),
            FieldSchema(id: 'invoice_date', label: 'Date', valueType: 'date'),
            FieldSchema(id: 'vehicle_number', label: 'Vehicle Number', valueType: 'text', isCustom: true),
            FieldSchema(id: 'delivery_date', label: 'Delivery Date', valueType: 'date', isCustom: true),
            FieldSchema(id: 'po_number', label: 'PO Number', valueType: 'text', isCustom: true),
          ],
        ),
        SectionSchema(
          id: 'items_table',
          title: 'Load Details',
          orderIndex: 3,
          fields: [],
        ),
        SectionSchema(
          id: 'tax_summary',
          title: 'Calculation Summary',
          orderIndex: 4,
          fields: [],
        ),
        SectionSchema(
          id: 'payment_info',
          title: 'Bank & Payments',
          orderIndex: 5,
          fields: [
            FieldSchema(id: 'bank_name', label: 'Bank Name', valueType: 'text'),
            FieldSchema(id: 'bank_account_no', label: 'Account Number', valueType: 'text'),
            FieldSchema(id: 'bank_ifsc', label: 'IFSC Code', valueType: 'text'),
            FieldSchema(id: 'bank_branch', label: 'Branch', valueType: 'text'),
          ],
        ),
        SectionSchema(
          id: 'signature',
          title: 'Signatory',
          orderIndex: 6,
          fields: [
            FieldSchema(id: 'signatory_title', label: 'Authorized Person', valueType: 'text', defaultValue: 'AUTHORIZED SIGNATORY'),
          ],
        ),
      ],
    );
  }
}
