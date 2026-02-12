import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/services/grid_provider.dart';
import 'package:gridly/services/pdf_service.dart';
import 'package:gridly/services/technical_label_guard.dart';

Future<void> showPdfReportDialog(BuildContext context) async {
  final textController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Generuj Raport PDF'),
        content: TextField(
          controller: textController,
          inputFormatters: TechnicalLabelGuard.inputFormatters(),
          decoration: const InputDecoration(
            hintText: 'Nazwa budowy',
            labelText: 'Nazwa budowy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              final buildingName =
                  TechnicalLabelGuard.normalize(textController.text);
              final validationMessage =
                  TechnicalLabelGuard.validateTechnicalLabel(buildingName);

              if (validationMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(validationMessage)),
                );
                return;
              }

              Navigator.of(context).pop();

              final gridProvider = context.read<GridProvider>();
              gridProvider.setBuildingName(buildingName);
              await PdfService.generateSiteReport(
                gridProvider: gridProvider,
                buildingName: buildingName,
              );
            },
            child: const Text('Generuj'),
          ),
        ],
      );
    },
  );

  textController.dispose();
}
