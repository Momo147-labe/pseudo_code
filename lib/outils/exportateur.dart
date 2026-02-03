import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class Exportateur {
  static Future<void> exporterPDF(String titre, String code) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titre,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Text(
                  code,
                  style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> exporterImage(BuildContext context, String code) async {
    // Note: To export a widget as image, we need a separate widget or a global key.
    // For now, we'll suggest using a simpler method or capturing the current editor view if possible.
    // However, screenshotting a specific string can be done by rendering it in a hidden RepaintBoundary.

    final controller = ScreenshotController();

    // We create a temporary overlay or just a captured widget
    final capturedWidget = Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pseudo-Code",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(),
          Text(
            code,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );

    Uint8List? imageBytes = await controller.captureFromWidget(capturedWidget);

    if (imageBytes != null) {
      // Save it as a file or share it
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/algorithme.png').create();
      await file.writeAsBytes(imageBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image générée ! Enregistrée dans ${file.path}"),
        ),
      );
    }
  }
}
