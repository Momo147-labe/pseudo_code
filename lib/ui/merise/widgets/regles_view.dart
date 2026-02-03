import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../theme.dart';

class ReglesView extends StatelessWidget {
  final AppTheme theme;
  const ReglesView({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final primaryColor = const Color(0xFF1E88E5);

    return Container(
      color: ThemeColors.editorBg(theme),
      child: PdfPreview(
        build: (format) async {
          final data = await rootBundle.load('assets/merise.pdf');
          return data.buffer.asUint8List();
        },
        useActions: false,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        maxPageWidth: 800,
        pdfFileName: "merise.pdf",
        scrollViewDecoration: BoxDecoration(color: ThemeColors.editorBg(theme)),
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        loadingWidget: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      ),
    );
  }
}
