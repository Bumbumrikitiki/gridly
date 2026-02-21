import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gridly/multitool/label_generator/models/label_models.dart';
import 'package:flutter/material.dart' as material;

class LabelPdfService {
  /// Konwersja mm na punkty PDF (1mm = 2.834 punktu)
  static const double mmToPoints = 2.834645669;

  /// Generuje PDF z etykietami w skali 1:1
  static Future<pw.Document> generateLabels(
    List<Label> labels, {
    bool fillA4Page = false,
    double safeMarginMm = 0,
  }) async {
    final pdf = pw.Document();

    for (final label in labels) {
      if (label.blocks.isEmpty) {
        continue;
      }

      // Oblicz wymiary w punktach PDF
      final widthPoints = label.totalWidthMm * mmToPoints;
      final heightPoints = label.height.heightMm * mmToPoints;

      if (fillA4Page) {
        final pageFormat = PdfPageFormat.a4.landscape;
        final safeMarginPoints = safeMarginMm * mmToPoints;
        final usableWidth = pageFormat.width - (safeMarginPoints * 2);
        final usableHeight = pageFormat.height - (safeMarginPoints * 2);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.all(safeMarginPoints),
            build: (context) {
              final columns = (usableWidth / widthPoints).ceil().clamp(1, 1000);
              final rows = (usableHeight / heightPoints).ceil().clamp(1, 1000);

              return pw.Stack(
                children: [
                  for (var row = 0; row < rows; row++)
                    for (var col = 0; col < columns; col++)
                      pw.Positioned(
                        left: col * widthPoints,
                        top: row * heightPoints,
                        child: _buildLabel(label, widthPoints, heightPoints),
                      ),
                ],
              );
            },
          ),
        );

        continue;
      }

      // Margines dla linii pomocniczych
      final marginPoints = 5.0 * mmToPoints;

      // Stwórz customowy format strony z marginesami
      final pageFormat = PdfPageFormat(
        widthPoints + (marginPoints * 2),
        heightPoints + (marginPoints * 2),
        marginAll: marginPoints,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(marginPoints),
          build: (context) {
            return pw.Stack(
              children: [
                // Linie pomocnicze do wycięcia
                _buildCutLines(widthPoints, heightPoints),

                // Główna etykieta
                pw.Positioned(
                  left: 0,
                  top: 0,
                  child: _buildLabel(label, widthPoints, heightPoints),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  /// Buduje linie pomocnicze do wycięcia
  static pw.Widget _buildCutLines(double widthPoints, double heightPoints) {
    const dashColor = PdfColors.grey300;

    return pw.Stack(
      children: [
        // Linia górna
        pw.Positioned(
          left: 0,
          top: 0,
          child: pw.Container(
            width: widthPoints,
            height: 0.5,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: dashColor,
                  width: 0.5,
                  style: pw.BorderStyle.dashed,
                ),
              ),
            ),
          ),
        ),
        // Linia dolna
        pw.Positioned(
          left: 0,
          top: heightPoints,
          child: pw.Container(
            width: widthPoints,
            height: 0.5,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: dashColor,
                  width: 0.5,
                  style: pw.BorderStyle.dashed,
                ),
              ),
            ),
          ),
        ),
        // Linia lewa
        pw.Positioned(
          left: 0,
          top: 0,
          child: pw.Container(
            width: 0.5,
            height: heightPoints,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                  color: dashColor,
                  width: 0.5,
                  style: pw.BorderStyle.dashed,
                ),
              ),
            ),
          ),
        ),
        // Linia prawa
        pw.Positioned(
          left: widthPoints,
          top: 0,
          child: pw.Container(
            width: 0.5,
            height: heightPoints,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                  color: dashColor,
                  width: 0.5,
                  style: pw.BorderStyle.dashed,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Buduje główną etykietę z blokami
  static pw.Widget _buildLabel(
    Label label,
    double widthPoints,
    double heightPoints,
  ) {
    return pw.Container(
      width: widthPoints,
      height: heightPoints,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.0),
      ),
      child: pw.Row(
        children: label.blocks.map((block) {
          return _buildBlock(block, heightPoints);
        }).toList(),
      ),
    );
  }

  /// Buduje pojedynczy blok etykiety
  static pw.Widget _buildBlock(LabelBlock block, double heightPoints) {
    final blockWidthPoints = block.widthMm * mmToPoints;

    // Konwersja koloru Flutter na PdfColor
    final pdfColor = _convertColor(block.backgroundColor);

    final textColor = _textColorForBackground(block.backgroundColor);

    return pw.Container(
      width: blockWidthPoints,
      height: heightPoints,
      decoration: pw.BoxDecoration(
        color: pdfColor,
        border: pw.Border(
          right: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      child: pw.Center(
        child: block.isVerticalText
            ? pw.Transform.rotate(
                angle: -1.5708, // -90 stopni w radianach
                child: pw.Text(
                  block.text,
                  style: pw.TextStyle(
                    fontSize: _calculateFontSize(block, heightPoints),
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              )
            : pw.Text(
                block.text,
                style: pw.TextStyle(
                  fontSize: _calculateFontSize(block, heightPoints),
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
      ),
    );
  }

  /// Oblicza optymalny rozmiar czcionki
  static double _calculateFontSize(LabelBlock block, double heightPoints) {
    // Bazowy rozmiar zależy od wysokości
    final baseSize = heightPoints * 0.35;

    // Dla tekstu pionowego, uwzględnij szerokość
    if (block.isVerticalText) {
      final blockWidthPoints = block.widthMm * mmToPoints;
      return baseSize.clamp(6.0, blockWidthPoints * 0.4);
    }

    return baseSize.clamp(6.0, 14.0);
  }

  /// Konwertuje kolor Flutter na PdfColor
  static PdfColor _convertColor(material.Color color) {
    return PdfColor(color.red / 255.0, color.green / 255.0, color.blue / 255.0);
  }

  static PdfColor _textColorForBackground(material.Color background) {
    return background.computeLuminance() > 0.5
        ? PdfColors.black
        : PdfColors.white;
  }

  /// Generuje i wyświetla podgląd PDF
  static Future<void> showPreview(
    material.BuildContext context,
    List<Label> labels, {
    bool fillA4Page = false,
    double safeMarginMm = 0,
  }) async {
    final printableLabels = labels.where((label) => label.blocks.isNotEmpty).toList();
    if (printableLabels.isEmpty) {
      return;
    }

    final pdf = await generateLabels(
      printableLabels,
      fillA4Page: fillA4Page,
      safeMarginMm: safeMarginMm,
    );

    await material.Navigator.of(context).push(
      material.MaterialPageRoute(
        builder: (context) => PdfPreview(
          build: (format) => pdf.save(),
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName: printableLabels.length == 1
              ? 'etykieta.pdf'
              : 'etykiety.pdf',
        ),
      ),
    );
  }
}
