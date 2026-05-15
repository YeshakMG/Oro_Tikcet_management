import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;

void main() async {
  final docsDir = Directory('docs');
  final pdfsDir = Directory('docs/pdfs');

  if (!pdfsDir.existsSync()) {
    pdfsDir.createSync(recursive: true);
  }

  final markdownFiles = [
    'README.md',
    'docs/BUSINESS_FLOWS.md',
    'docs/API_DOCUMENTATION.md',
    'docs/USER_GUIDE.md',
    'docs/DEVELOPMENT_GUIDE.md',
    'docs/MODULES.md',
    'docs/README.md',
  ];

  for (final filePath in markdownFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      final pdfFileName = path.basenameWithoutExtension(filePath) + '.pdf';
      final pdfPath = path.join(pdfsDir.path, pdfFileName);

      await generatePdf(content, pdfPath, path.basename(filePath));
      print('Generated: $pdfPath');
    }
  }

  // Generate combined documentation
  await generateCombinedPdf(pdfsDir.path);
  print('Documentation PDF generation completed!');
}

Future<void> generatePdf(String markdownContent, String outputPath, String title) async {
  final pdf = pw.Document();

  // Convert markdown to basic text (simple conversion)
  final textContent = markdownToText(markdownContent);

  // Split content into paragraphs for better page handling
  final paragraphs = textContent.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(title.replaceAll('.md', '').replaceAll('_', ' ').toUpperCase(),
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 20),
        ...paragraphs.map((paragraph) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(paragraph.trim(),
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
        )),
      ],
    ),
  );

  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());
}

Future<void> generateCombinedPdf(String pdfsDir) async {
  final pdf = pw.Document();
  final files = [
    'README.pdf',
    'BUSINESS_FLOWS.pdf',
    'API_DOCUMENTATION.pdf',
    'USER_GUIDE.pdf',
    'DEVELOPMENT_GUIDE.pdf',
    'MODULES.pdf',
  ];

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('ORO TICKET APP - COMPLETE DOCUMENTATION',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 30),
        pw.Text('This document contains the complete documentation for the Oro Ticket App project.',
            style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),
        pw.Text('Generated on: ${DateTime.now().toString()}',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 30),
        pw.Text('Contents:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...files.map((file) => pw.Bullet(
          text: file.replaceAll('.pdf', '').replaceAll('_', ' '),
          style: const pw.TextStyle(fontSize: 11),
        )),
      ],
    ),
  );

  final combinedPdfPath = path.join(pdfsDir, 'ORO_TICKET_APP_COMPLETE_DOCUMENTATION.pdf');
  final file = File(combinedPdfPath);
  await file.writeAsBytes(await pdf.save());
  print('Generated combined documentation: $combinedPdfPath');
}

String markdownToText(String markdown) {
  // Simple markdown to text conversion
  String text = markdown;

  // Remove markdown headers formatting
  text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

  // Remove markdown links
  text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');

  // Remove markdown bold/italic
  text = text.replaceAll(RegExp(r'\*\*([^\*]+)\*\*'), r'$1');
  text = text.replaceAll(RegExp(r'\*([^\*]+)\*'), r'$1');

  // Remove code blocks
  text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
  text = text.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

  // Remove list markers
  text = text.replaceAll(RegExp(r'^[\s]*[-\*\+]\s+', multiLine: true), '');

  // Clean up extra whitespace
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return text.trim();
}