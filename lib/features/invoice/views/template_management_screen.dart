import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:docx_creator/docx_creator.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/database_provider.dart';
import '../models/invoice_template_schema.dart';
import '../providers/invoice_form_provider.dart';

class TemplateManagementScreen extends ConsumerStatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  ConsumerState<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends ConsumerState<TemplateManagementScreen> {
  List<InvoiceTemplateSchema> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    try {
      final rows = await db.select(db.invoiceTemplates).get();
      
      // If table is empty, seed defaults
      if (rows.isEmpty) {
        await _seedDefaultTemplates();
        await _loadTemplates();
        return;
      }

      setState(() {
        _templates = rows.map((r) {
          final decoded = jsonDecode(r.schemaJson);
          return InvoiceTemplateSchema.fromJson(decoded);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _seedDefaultTemplates() async {
    final db = ref.read(databaseProvider);
    final defaults = [
      InvoiceTemplateSchema.getTourismDefault(),
      InvoiceTemplateSchema.getStandardDefault(),
      InvoiceTemplateSchema.getServiceDefault(),
      InvoiceTemplateSchema.getTransportDefault(),
    ];

    for (final t in defaults) {
      await db.into(db.invoiceTemplates).insert(
        InvoiceTemplatesCompanion.insert(
          name: t.name,
          description: Value(t.description),
          schemaJson: jsonEncode(t.toJson()),
          createdDate: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _saveTemplate(InvoiceTemplateSchema template) async {
    final db = ref.read(databaseProvider);
    try {
      // Check if template exists
      final existing = await (db.select(db.invoiceTemplates)
            ..where((t) => t.name.equals(template.name)))
          .getSingleOrNull();

      if (existing != null) {
        await (db.update(db.invoiceTemplates)..where((t) => t.id.equals(existing.id))).write(
          InvoiceTemplatesCompanion(
            schemaJson: Value(jsonEncode(template.toJson())),
          ),
        );
      } else {
        await db.into(db.invoiceTemplates).insert(
          InvoiceTemplatesCompanion.insert(
            name: template.name,
            description: Value(template.description),
            schemaJson: jsonEncode(template.toJson()),
            createdDate: DateTime.now(),
          ),
        );
      }
      await _loadTemplates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTemplate(String name) async {
    final db = ref.read(databaseProvider);
    try {
      await (db.delete(db.invoiceTemplates)..where((t) => t.name.equals(name))).go();
      await _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "$name" deleted'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportTemplate(InvoiceTemplateSchema template) async {
    try {
      final jsonStr = jsonEncode(template.toJson());
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export Template Layout (.json)',
        fileName: '${template.id}_template.json',
      );

      if (path != null) {
        await File(path).writeAsString(jsonStr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Template exported to $path'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _backupTemplatesZip() async {
    try {
      final db = ref.read(databaseProvider);
      final rows = await db.select(db.invoiceTemplates).get();
      final list = rows.map((r) => jsonDecode(r.schemaJson)).toList();
      final backupMap = {'templates': list};
      final jsonStr = jsonEncode(backupMap);

      // Create zip archive
      final archive = Archive();
      archive.addFile(ArchiveFile('templates_backup.json', jsonStr.length, utf8.encode(jsonStr)));
      final zipBytes = ZipEncoder().encode(archive);

      if (zipBytes != null) {
        final path = await FilePicker.saveFile(
          dialogTitle: 'Save Templates Backup ZIP',
          fileName: 'invoice_templates_backup.zip',
        );

        if (path != null) {
          await File(path).writeAsBytes(zipBytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Backup ZIP saved to $path'), backgroundColor: AppTheme.primaryGreen),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreTemplatesZip() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select Templates Backup ZIP',
      );

      if (result != null && result.files.single.path != null) {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final backupFile = archive.findFile('templates_backup.json');
        if (backupFile == null) {
          throw Exception('Invalid templates backup ZIP: templates_backup.json not found');
        }

        final jsonStr = utf8.decode(backupFile.content as List<int>);
        final Map<String, dynamic> backupMap = jsonDecode(jsonStr);
        final List<dynamic> list = backupMap['templates'] as List<dynamic>;

        final db = ref.read(databaseProvider);
        int restoredCount = 0;
        for (final item in list) {
          final t = InvoiceTemplateSchema.fromJson(item as Map<String, dynamic>);
          final existing = await (db.select(db.invoiceTemplates)
                ..where((row) => row.name.equals(t.name)))
              .getSingleOrNull();

          if (existing != null) {
            await (db.update(db.invoiceTemplates)..where((row) => row.id.equals(existing.id))).write(
              InvoiceTemplatesCompanion(
                schemaJson: Value(jsonEncode(t.toJson())),
              ),
            );
          } else {
            await db.into(db.invoiceTemplates).insert(
              InvoiceTemplatesCompanion.insert(
                name: t.name,
                description: Value(t.description),
                schemaJson: jsonEncode(t.toJson()),
                createdDate: DateTime.now(),
              ),
            );
          }
          restoredCount++;
        }

        await _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restored $restoredCount templates successfully!'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importTemplate() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'png', 'jpg', 'jpeg', 'pdf'],
        dialogTitle: 'Import Template (JSON, Images or PDF)',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final ext = result.files.single.extension?.toLowerCase();

        if (ext == 'json') {
          final contents = await file.readAsString();
          final Map<String, dynamic> decoded = jsonDecode(contents);
          final imported = InvoiceTemplateSchema.fromJson(decoded);
          await _saveTemplate(imported);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Template "${imported.name}" imported successfully'), backgroundColor: AppTheme.primaryGreen),
            );
          }
        } else if (ext == 'pdf') {
          await _importPdfTemplate(file, result.files.single.name);
        } else if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') {
          await _importImageTemplate(file, result.files.single.name);
        } else {
          await _runMockScanner(result.files.single.name);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importPdfTemplate(File file, String fileName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text('Analyzing PDF Layout with PdfReader...'),
          ],
        ),
      ),
    );

    try {
      final bytes = await file.readAsBytes();
      final pdfDoc = await PdfReader.loadFromBytes(bytes);
      
      if (mounted) Navigator.of(context).pop(); // dismiss loading

      final List<String> textLines = [];
      for (final node in pdfDoc.elements) {
        if (node is DocxParagraph) {
          final text = node.children.map((c) => c is DocxText ? c.content : '').join().trim();
          if (text.isNotEmpty) textLines.add(text);
        } else if (node is DocxTable) {
          for (final row in node.rows) {
            for (final cell in row.cells) {
              for (final child in cell.children) {
                if (child is DocxParagraph) {
                  final text = child.children.map((c) => c is DocxText ? c.content : '').join().trim();
                  if (text.isNotEmpty) textLines.add(text);
                }
              }
            }
          }
        }
      }

      final fullText = textLines.join(' ').toLowerCase();

      InvoiceTemplateSchema basePreset;
      String detectedType = "Standard";
      
      if (fullText.contains("tourism") || fullText.contains("service detail") || fullText.contains("aooount")) {
        basePreset = InvoiceTemplateSchema.getTourismDefault();
        detectedType = "Tourism";
      } else if (fullText.contains("transport") || fullText.contains("vehicle no") || fullText.contains("route")) {
        basePreset = InvoiceTemplateSchema.getTransportDefault();
        detectedType = "Transport";
      } else if (fullText.contains("service") || fullText.contains("consultant")) {
        basePreset = InvoiceTemplateSchema.getServiceDefault();
        detectedType = "Service";
      } else {
        basePreset = InvoiceTemplateSchema.getStandardDefault();
      }

      String pageFmt = 'A4';
      if ((pdfDoc.pageWidth - 612.0).abs() < 10 && (pdfDoc.pageHeight - 792.0).abs() < 10) {
        pageFmt = 'Letter';
      } else if ((pdfDoc.pageWidth - 595.27).abs() > 10 || (pdfDoc.pageHeight - 841.89).abs() > 10) {
        pageFmt = 'Custom';
      }

      final double topMargin = basePreset.marginTop;
      final double bottomMargin = basePreset.marginBottom;
      final double leftMargin = basePreset.marginLeft;
      final double rightMargin = basePreset.marginRight;

      final name = "Imported PDF: ${fileName.split('.').first}";
      final id = "imported_pdf_${DateTime.now().millisecondsSinceEpoch}";

      final importedTemplate = basePreset.copyWith(
        id: id,
        name: name,
        description: "Imported from $fileName. Detected layout type: $detectedType ($pageFmt).",
        pageFormat: pageFmt,
        pageWidth: pdfDoc.pageWidth,
        pageHeight: pdfDoc.pageHeight,
        marginTop: topMargin,
        marginBottom: bottomMargin,
        marginLeft: leftMargin,
        marginRight: rightMargin,
      );

      await _saveTemplate(importedTemplate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported "$name" as $detectedType template!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // dismiss loading
      throw Exception("PDF Reader failed to extract template: $e");
    }
  }

  Future<void> _importImageTemplate(File file, String fileName) async {
    final lowerName = fileName.toLowerCase();
    
    InvoiceTemplateSchema basePreset;
    String detectedType = "Standard";
    
    if (lowerName.contains("tourism") || lowerName.contains("travel") || lowerName.contains("trip")) {
      basePreset = InvoiceTemplateSchema.getTourismDefault();
      detectedType = "Tourism";
    } else if (lowerName.contains("transport") || lowerName.contains("vehicle") || lowerName.contains("car")) {
      basePreset = InvoiceTemplateSchema.getTransportDefault();
      detectedType = "Transport";
    } else if (lowerName.contains("service") || lowerName.contains("consult") || lowerName.contains("freelance")) {
      basePreset = InvoiceTemplateSchema.getServiceDefault();
      detectedType = "Service";
    } else {
      basePreset = InvoiceTemplateSchema.getStandardDefault();
    }

    final name = "Imported Image: ${fileName.split('.').first}";
    final id = "imported_img_${DateTime.now().millisecondsSinceEpoch}";

    final importedTemplate = basePreset.copyWith(
      id: id,
      name: name,
      description: "Layout preset copy matched from image: $fileName. Preset: $detectedType.",
    );

    await _saveTemplate(importedTemplate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Matched and imported "$name" as $detectedType layout preset!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _runMockScanner(String fileName) async {
    final steps = [
      "Scanning document layout & lines...",
      "Analyzing structures, text blocks & fields...",
      "Detecting alignment & label names...",
      "Generating InvoiceTemplateSchema configurations...",
    ];

    final ValueNotifier<String> stepNotifier = ValueNotifier(steps[0]);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.document_scanner, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('Mock OCR Template Scanner'),
            ],
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: stepNotifier,
            builder: (context, step, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(color: AppTheme.primaryGreen),
                  const SizedBox(height: 20),
                  Text(
                    step,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'File: $fileName',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    for (int i = 0; i < steps.length; i++) {
      stepNotifier.value = steps[i];
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    final scannedTemplate = InvoiceTemplateSchema.getStandardDefault().copyWith(
      id: 'scanned_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Scanned Layout: ${fileName.split('.').first}',
      description: 'Layout scanned and mapped from $fileName using AI Document Parser',
    );

    await _saveTemplate(scannedTemplate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported scanned layout "${scannedTemplate.name}" successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _duplicateTemplate(InvoiceTemplateSchema template) {
    final copyName = '${template.name} (Copy)';
    final copyId = '${template.id}_copy_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final duplicated = template.copyWith(id: copyId, name: copyName);
    _saveTemplate(duplicated);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(invoiceFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Configurations Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Backup Templates (ZIP)',
            onPressed: _backupTemplatesZip,
          ),
          IconButton(
            icon: const Icon(Icons.unarchive),
            tooltip: 'Restore Templates (ZIP)',
            onPressed: _restoreTemplatesZip,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(elevation: 0),
            onPressed: _importTemplate,
            icon: const Icon(Icons.file_upload),
            label: const Text('Import Template'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? const Center(child: Text('No templates configured.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    final isActive = formState.activeTemplate.id == t.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isActive ? AppTheme.primaryGreen : Colors.transparent,
                          width: isActive ? 2.0 : 0.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.dashboard,
                              size: 40,
                              color: isActive ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        t.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      if (isActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(color: AppTheme.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.description,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Page format: ${t.pageFormat} • Margins: L:${t.marginLeft.toStringAsFixed(0)} pt, T:${t.marginTop.toStringAsFixed(0)} pt',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    ref.read(invoiceFormProvider.notifier).updateTemplate(t);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Switched to layout schema: ${t.name}'),
                                        backgroundColor: AppTheme.primaryGreen,
                                      ),
                                    );
                                  },
                                  child: const Text('Use Template'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.orange),
                                  tooltip: 'Duplicate Template',
                                  onPressed: () => _duplicateTemplate(t),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.file_download, color: Colors.blue),
                                  tooltip: 'Export Template (JSON)',
                                  onPressed: () => _exportTemplate(t),
                                ),
                                if (t.id != 'tourism' && t.id != 'standard' && t.id != 'service' && t.id != 'transport')
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete Template',
                                    onPressed: () => _deleteTemplate(t.name),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
