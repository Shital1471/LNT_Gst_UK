import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/database_provider.dart';
import '../services/pdf_generator.dart';
import '../services/docx_generator.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  final List<InvoiceItem> items;
  final CompanyProfile company;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    required this.items,
    required this.company,
  });

  @override
  ConsumerState<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  Uint8List? _pdfBytes;
  Uint8List? _docxBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateAndSaveDocs();
  }

  Future<void> _generateAndSaveDocs() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Generate PDF and DOCX bytes
      final pdf = await PdfGeneratorService.generateInvoicePdf(
        invoice: widget.invoice,
        items: widget.items,
        company: widget.company,
      );
      final docx = await DocxGeneratorService.generateInvoiceDocx(
        invoice: widget.invoice,
        items: widget.items,
        company: widget.company,
      );

      setState(() {
        _pdfBytes = pdf;
        _docxBytes = docx;
      });

      // 2. Save both files to local storage (auto-save history requirement)
      final docDir = await getApplicationDocumentsDirectory();
      final invoicesFolder = Directory(p.join(docDir.path, 'invoices'));
      if (!await invoicesFolder.exists()) {
        await invoicesFolder.create(recursive: true);
      }

      final pdfPath = p.join(invoicesFolder.path, '${widget.invoice.invoiceNumber}.pdf');
      final docxPath = p.join(invoicesFolder.path, '${widget.invoice.invoiceNumber}.docx');

      await File(pdfPath).writeAsBytes(pdf);
      await File(docxPath).writeAsBytes(docx);

      // 3. Update database record with document paths
      final db = ref.read(databaseProvider);
      await (db.update(db.invoices)..where((t) => t.id.equals(widget.invoice.id))).write(
        InvoicesCompanion(
          pdfPath: Value(pdfPath),
          docxPath: Value(docxPath),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error compiling document: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF Document',
        fileName: '${widget.invoice.invoiceNumber}.pdf',
      );
      if (path != null) {
        await File(path).writeAsBytes(_pdfBytes!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF saved successfully to $path'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadDocx() async {
    if (_docxBytes == null) return;
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Word Document',
        fileName: '${widget.invoice.invoiceNumber}.docx',
      );
      if (path != null) {
        await File(path).writeAsBytes(_docxBytes!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('DOCX saved successfully to $path'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving DOCX: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareInvoice() async {
    if (_pdfBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, '${widget.invoice.invoiceNumber}.pdf'));
      await tempFile.writeAsBytes(_pdfBytes!);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Invoice ${widget.invoice.invoiceNumber} for ${widget.invoice.customerName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber} Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Invoice',
            onPressed: _shareInvoice,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _downloadPdf,
          ),
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Export Word (DOCX)',
            onPressed: _downloadDocx,
          ),
        ],
      ),
      body: _isSaving || _pdfBytes == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Compiling PDF and DOCX Layouts... Please wait'),
                ],
              ),
            )
          : Row(
              children: [
                // PDF Viewer
                Expanded(
                  flex: 3,
                  child: PdfPreview(
                    build: (format) => _pdfBytes!,
                    useActions: false, // We use our own custom Material 3 Action panel on the right
                    allowPrinting: true,
                    allowSharing: true,
                  ),
                ),
                
                // Action Control Center
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(left: BorderSide(color: Colors.grey.shade300)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Document Actions',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepBlue),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Printing.layoutPdf(onLayout: (_) => _pdfBytes!),
                        icon: const Icon(Icons.print),
                        label: const Text('Print PDF'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _downloadPdf,
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _downloadDocx,
                        icon: const Icon(Icons.edit_document, color: AppTheme.primaryGreen),
                        label: const Text('Download DOCX'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _shareInvoice,
                        icon: const Icon(Icons.send),
                        label: const Text('Share / Email'),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Storage Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _metaRow('Total Amount', 'Rs. ${widget.invoice.grandTotal.toStringAsFixed(2)}'),
                      _metaRow('Advance Paid', 'Rs. ${widget.invoice.advancePaid.toStringAsFixed(2)}'),
                      _metaRow('Balance Due', 'Rs. ${(widget.invoice.grandTotal - widget.invoice.advancePaid).toStringAsFixed(2)}'),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepBlue),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Done & Return'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _metaRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}
