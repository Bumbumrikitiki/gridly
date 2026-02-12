import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gridly/services/grid_provider.dart';
import 'package:gridly/models/grid_models.dart';

class PdfService {
  static Future<void> generateSiteReport({
    required GridProvider gridProvider,
    required String buildingName,
  }) async {
    final pdf = pw.Document();

    final nodes = gridProvider.nodes;
    final aggregatePowers = gridProvider.aggregatePowerKw;
    final aggregateDrops = gridProvider.aggregateVoltageDrop;

    // Filter only DistributionBoard nodes for the table
    final boards = nodes.whereType<DistributionBoard>().toList();
    final observations = _collectNeutralObservations(nodes, boards);
    final warningObservationsCount =
        observations.where(_isWarningObservation).length;

    // Find PEN split points
    final penSplitPoints =
        boards.where((board) => board.isPenSplitPoint).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'GRIDLY ELECTRICAL CHECKER - RAPORT KONFIGURACJI ZASILANIA',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Data: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Budowa:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(buildingName),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          ),

          // Technical Table
          pw.Text(
            'ZESTAWIENIE TECHNICZNEGO ROZDZIELNIC',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Nazwa',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Przekrój\n[mm²]',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Materiał',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Liczba żył',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Moc\n[kW]',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'dU [%]',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Data rows
              for (final board in boards)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        board.name,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        board.crossSectionMm2.toStringAsFixed(1),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        board.material == ConductorMaterial.cu ? 'Cu' : 'Al',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${board.cableCores}-żyłowy',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        (aggregatePowers[board] ?? board.powerKw)
                            .toStringAsFixed(2),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        _calculateVoltageDropPercent(
                          aggregateDrops[board] ?? 0.0,
                          board.isThreePhase,
                        ).toStringAsFixed(2),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Distribution board equipment section
          pw.Text(
            'APARATURA ROZDZIELNICY',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          for (final board in boards) ...[
            pw.Text(
              board.name,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              board.additionalEquipment.isEmpty
                  ? 'Wyposażenie dodatkowe: brak danych.'
                  : 'Wyposażenie dodatkowe: ${board.additionalEquipment.map(_additionalEquipmentPdfLabel).join(' | ')}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            if (board.protectionSlots.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  'Brak zdefiniowanych pozycji aparatury.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _cellHeader('Typ aparatu'),
                      _cellHeader('Ilość'),
                      _cellHeader('Wartość znamionowa'),
                      _cellHeader('Status'),
                      _cellHeader('Przypisanie'),
                    ],
                  ),
                  for (final slot in board.protectionSlots)
                    pw.TableRow(
                      children: [
                        _cellBody(_protectionTypeLabel(slot.type)),
                        _cellBody('${slot.quantity}'),
                        _cellBody(_protectionValueLabel(slot)),
                        _cellBody(slot.isReserve ? 'Rezerwa' : 'Obsadzone'),
                        _cellBody(
                          _resolveAssignedNodeName(nodes, slot.assignedNodeId),
                        ),
                      ],
                    ),
                ],
              ),
            pw.SizedBox(height: 10),
          ],
          pw.SizedBox(height: 10),

          // Neutral observations section
          pw.Text(
            'OBSERWACJE TOPOLOGII I APARATURY',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Liczba obserwacji: ${observations.length} | Ostrzeżenia: $warningObservationsCount',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          if (observations.isEmpty)
            pw.Text(
              'Brak dodatkowych obserwacji na podstawie bieżących danych.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final observation in observations)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '• $observation',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Podsumowanie wyposażenia dodatkowego rozdzielnic:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final board in boards)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(
                    '• ${board.name}: ${_additionalEquipmentSummary(board)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Safety Section
          pw.Text(
            'SEKCJA INFORMACYJNA',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey700),
            ),
            child: pw.Text(
              'Niniejszy raport ma charakter orientacyjny i informacyjny. Nie stanowi porady wykonawczej ani gwarancji zgodności instalacji.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 8),
          if (penSplitPoints.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '⚠️  PUNKT PODZIAŁU PEN - INFORMACJA:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Lokalizacja: ${penSplitPoints.map((b) => b.name).join(", ")}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '• Parametry uziemienia szyny PE mogą wymagać dodatkowej weryfikacji terenowej',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Wartość rezystancji uziemienia może wymagać odrębnego potwierdzenia pomiarowego',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Konfiguracja przewodów PE i N za punktem podziału wymaga zgodności z przyjętym układem sieci',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Liczba żył przewodu za punktem podziału wpływa na wynik orientacyjny',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            )
          else
            pw.Text(
              'Brak punktów podziału PEN w konfiguracji.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          pw.SizedBox(height: 20),

          // Signature Section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PODPIS I DATA',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Data: _________________',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Podpis Inżyniera: _________________',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static double _calculateVoltageDropPercent(double dropV, bool isThreePhase) {
    final voltage = isThreePhase ? 400.0 : 230.0;
    return (dropV / voltage) * 100;
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cellBody(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static String _protectionTypeLabel(ProtectionDeviceType type) {
    switch (type) {
      case ProtectionDeviceType.overcurrentBreaker:
        return 'Wyłącznik nadprądowy (MCB)';
      case ProtectionDeviceType.residualCurrentDevice:
        return 'Wyłącznik różnicowoprądowy (RCD)';
      case ProtectionDeviceType.fuseHolder:
        return 'Kieszeń wkładki bezpiecznikowej';
    }
  }

  static String _protectionValueLabel(BoardProtectionSlot slot) {
    switch (slot.type) {
      case ProtectionDeviceType.overcurrentBreaker:
        return slot.ratedCurrentA == null
            ? 'Brak danych'
            : '${slot.ratedCurrentA!.toStringAsFixed(0)} A';
      case ProtectionDeviceType.residualCurrentDevice:
        if (slot.ratedCurrentA == null || slot.residualCurrentmA == null) {
          return 'Brak danych';
        }
        return '${slot.ratedCurrentA!.toStringAsFixed(0)} A / ${slot.residualCurrentmA!.toStringAsFixed(0)} mA';
      case ProtectionDeviceType.fuseHolder:
        return slot.fuseLinkSize?.isNotEmpty == true
            ? slot.fuseLinkSize!
            : 'Brak danych';
    }
  }

  static String _additionalEquipmentPdfLabel(BoardAdditionalEquipment item) {
    switch (item) {
      case BoardAdditionalEquipment.subMeter:
        return 'POD-L (licznik podlicznik)';
      case BoardAdditionalEquipment.pwpSwitch:
        return 'PWP (wyłącznik PWP)';
      case BoardAdditionalEquipment.surgeProtection:
        return 'SPD (zabezpieczenie przeciwprzepięciowe)';
    }
  }

  static String _additionalEquipmentSummary(DistributionBoard board) {
    if (board.additionalEquipment.isEmpty) {
      return 'brak danych';
    }
    return board.additionalEquipment
        .map(_additionalEquipmentPdfLabel)
        .join(', ');
  }

  static String _resolveAssignedNodeName(
    List<GridNode> nodes,
    String? assignedNodeId,
  ) {
    if (assignedNodeId == null || assignedNodeId.isEmpty) {
      return 'Brak przypisania';
    }

    for (final node in nodes) {
      if (node.id == assignedNodeId) {
        return node.name;
      }
    }

    return 'Brak przypisania';
  }

  static List<String> _collectNeutralObservations(
    List<GridNode> nodes,
    List<DistributionBoard> boards,
  ) {
    final observations = <String>[];
    final nodeById = {for (final node in nodes) node.id: node};
    final childrenByParentId = <String?, List<GridNode>>{};
    for (final node in nodes) {
      childrenByParentId.putIfAbsent(node.parentId, () => []);
      childrenByParentId[node.parentId]!.add(node);
    }

    final penCount = boards.where((board) => board.isPenSplitPoint).length;
    if (penCount > 1) {
      observations.add(
        'Wykryto więcej niż jeden punkt podziału PEN; interpretacja topologii może wymagać dodatkowego potwierdzenia projektowego.',
      );
    }

    for (final board in boards) {
      final directChildren = childrenByParentId[board.id] ?? const [];
      final directChildIds = directChildren.map((e) => e.id).toSet();
      final assignedIds = <String>{};

      for (final slot in board.protectionSlots) {
        if (!slot.hasCompleteDefinition) {
          observations.add(
            'Rozdzielnica ${board.name}: część pozycji aparatury nie zawiera pełnych danych.',
          );
          break;
        }

        if (slot.isReserve && slot.assignedNodeId != null) {
          observations.add(
            'Rozdzielnica ${board.name}: pozycja oznaczona jako rezerwa ma jednocześnie przypisanie odbioru.',
          );
        }

        if (!slot.isReserve &&
            (slot.assignedNodeId == null || slot.assignedNodeId!.isEmpty)) {
          observations.add(
            'Rozdzielnica ${board.name}: pozycja obsadzona nie ma przypisanego odbioru.',
          );
        }

        if (slot.assignedNodeId != null && slot.assignedNodeId!.isNotEmpty) {
          if (assignedIds.contains(slot.assignedNodeId)) {
            observations.add(
              'Rozdzielnica ${board.name}: ten sam odbiór przypisano do więcej niż jednej pozycji aparatury.',
            );
          }
          assignedIds.add(slot.assignedNodeId!);

          final assignedNode = nodeById[slot.assignedNodeId!];
          if (assignedNode == null) {
            observations.add(
              'Rozdzielnica ${board.name}: wykryto przypisanie do elementu nieobecnego w bieżącej topologii.',
            );
          } else if (!directChildIds.contains(assignedNode.id)) {
            observations.add(
              'Rozdzielnica ${board.name}: przypisanie aparatury wskazuje element poza bezpośrednią gałęzią.',
            );
          }
        }
      }
    }

    for (final node in nodes) {
      if (node.isThreePhase && node.cableCores == 3) {
        observations.add(
          'Element ${node.name}: konfiguracja 3-fazowa z przewodem 3-żyłowym może wskazywać niespójność danych.',
        );
      }
    }

    return observations;
  }

  static bool _isWarningObservation(String observation) {
    final text = observation.toLowerCase();
    const warningKeywords = [
      'więcej niż jeden punkt podziału pen',
      'nie zawiera pełnych danych',
      'rezerwa ma jednocześnie przypisanie',
      'obsadzona nie ma przypisanego odbioru',
      'więcej niż jednej pozycji',
      'nieobecnego w bieżącej topologii',
      'poza bezpośrednią gałęzią',
      'niespójność danych',
    ];
    return warningKeywords.any(text.contains);
  }

  /// Generuje raport PDF dla modułu oceny orientacyjnej obwodu
  static Future<void> generateCircuitAssessmentReport({
    required String buildingName,
    required double crossSection,
    required String material,
    required double power,
    required double voltage,
    required bool isThreePhase,
    required double length,
    required double nominalCurrent,
    required double maxCurrent,
    required double calculatedCurrent,
    required double voltageDrop,
    required double shortCircuitCurrent,
    required String requiredStrength,
    required String protectionType,
    required double impedance,
    required double voltageDropLimitPercent,
    required bool isAutoImpedance,
    required double? zext,
    required double? peCrossSection,
    required bool isAllowed,
    required bool isPartialResult,
  }) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (context) => [
          // Nagłówek
          pw.Center(
            child: pw.Text(
              'GRIDLY ELECTRICAL CHECKER - RAPORT OCENY ORIENTACYJNEJ OBWODU',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Data: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Budowa:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(buildingName),
            ],
          ),
          pw.SizedBox(height: 20),

          // Status ogólny
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: isPartialResult
                  ? PdfColors.orange100
                  : (isAllowed ? PdfColors.green100 : PdfColors.red100),
              border: pw.Border.all(
                color: isPartialResult
                    ? PdfColors.orange
                    : (isAllowed ? PdfColors.green : PdfColors.red),
                width: 2,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text(
                isPartialResult
                    ? 'WYNIK CZĘŚCIOWY: BRAK DANYCH ZWARCIOWYCH'
                    : (isAllowed
                        ? 'WYNIK ORIENTACYJNY: W ZAKRESIE WSKAŹNIKA'
                        : 'WYNIK ORIENTACYJNY: POZA ZAKRESEM WSKAŹNIKA'),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: isPartialResult
                      ? PdfColors.orange900
                      : (isAllowed ? PdfColors.green900 : PdfColors.red900),
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Parametry kabla
          pw.Text(
            'PARAMETRY KABLA',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildParameterTable([
            ['Przekrój', '${crossSection.toStringAsFixed(1)} mm²'],
            ['Materiał', material],
            ['Długość', '${length.toStringAsFixed(0)} m'],
            [
              'Napięcie',
              '${voltage.toStringAsFixed(0)} V (${isThreePhase ? "3-faz" : "1-faz"})'
            ],
            ['Moc obciążenia', '${power.toStringAsFixed(1)} kW'],
          ]),
          pw.SizedBox(height: 20),

          // Analiza zwarcia
          pw.Text(
            'ANALIZA ZWARCIA',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildParameterTable([
            ['Impedancja pętli', '${impedance.toStringAsFixed(3)} Ω'],
            if (isAutoImpedance && zext != null)
              ['Zext', '${zext.toStringAsFixed(2)} Ω'],
            if (isAutoImpedance && peCrossSection != null)
              ['Przekrój PE', '${peCrossSection.toStringAsFixed(1)} mm²'],
            [
              'Prąd zwarcia',
              '${(shortCircuitCurrent / 1000).toStringAsFixed(2)} kA'
            ],
            ['Wymagana wytrzymałość', requiredStrength],
            ['Charakterystyka', protectionType],
          ]),
          pw.SizedBox(height: 20),

          // Wyniki
          pw.Text(
            'PODSUMOWANIE',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildParameterTable([
            ['Obciążalność kabla', '${maxCurrent.toStringAsFixed(1)} A'],
            ['Zabezpieczenie In', '${nominalCurrent.toStringAsFixed(0)} A'],
            ['Prąd obliczeniowy', '${calculatedCurrent.toStringAsFixed(1)} A'],
            [
              'Spadek napięcia',
              '${voltageDrop.toStringAsFixed(2)}% / limit ${voltageDropLimitPercent.toStringAsFixed(0)}% ${voltageDrop <= voltageDropLimitPercent ? "✓" : "✗"}'
            ],
            [
              'Status orientacyjny',
              isPartialResult
                  ? 'WYNIK CZĘŚCIOWY - UZUPEŁNIJ ZS/ZEXT'
                  : (isAllowed
                      ? 'W ZAKRESIE WSKAŹNIKA ✓'
                      : 'POZA ZAKRESEM WSKAŹNIKA ✗')
            ],
          ]),
          pw.SizedBox(height: 32),

          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'Uwaga: raport ma charakter orientacyjny (decision support) i nie zastępuje dokumentacji projektowej, pomiarów odbiorczych ani decyzji osoby z uprawnieniami.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 16),

          // Podpis
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Data: _________________'),
                  pw.SizedBox(height: 16),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Podpis: _________________'),
                  pw.SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildParameterTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows
          .map(
            (row) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(row[1]),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
