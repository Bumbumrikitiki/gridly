import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/models/circuit_line.dart';
import 'package:gridly/services/grid_provider.dart';
import 'package:gridly/services/pdf_service.dart';
import 'package:gridly/services/technical_label_guard.dart';
import 'package:gridly/theme/grid_theme.dart';
import 'package:gridly/widgets/circuit_line_edit_dialog.dart';
import 'package:gridly/widgets/main_mobile_nav_bar.dart';

enum _MobileTopologyAction {
  manageStructures,
  temporarySupply,
  editBuildingName,
  exportPdf,
  addNode,
}

class TopologyScreen extends StatefulWidget {
  const TopologyScreen({super.key});

  @override
  State<TopologyScreen> createState() => _TopologyScreenState();
}

class _TopologyScreenState extends State<TopologyScreen>
    with WidgetsBindingObserver {
  bool _hidePowerReceivers = false;
  bool _showOnlyWarningObservations = false;
  bool _showDistributionBoardTimeline = false;
  bool _showOnlyNodesWithIssues = false;
  final Set<String> _collapsedNodeIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GridProvider>().loadSavedStructures();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(context.read<GridProvider>().flushPendingSnapshotSave());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isNodeExpanded(GridNode node, bool hasChildren) {
    if (!hasChildren) {
      return true;
    }
    return !_collapsedNodeIds.contains(node.id);
  }

  void _toggleNodeExpansion(GridNode node, bool hasChildren) {
    if (!hasChildren) {
      return;
    }

    setState(() {
      if (_collapsedNodeIds.contains(node.id)) {
        _collapsedNodeIds.remove(node.id);
      } else {
        _collapsedNodeIds.add(node.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isMobile = viewportWidth < 600;
    final contentPadding =
        viewportWidth < 380 ? 12.0 : (isMobile ? 14.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: isMobile
            ? const Text(
                'Topologia',
                overflow: TextOverflow.ellipsis,
              )
            : Selector<GridProvider,
                ({String buildingName, String structureName})>(
                selector: (context, provider) => (
                  buildingName: provider.buildingName.isEmpty
                      ? 'nie podano'
                      : provider.buildingName,
                  structureName: provider.currentStructureName,
                ),
                builder: (context, headerData, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Zasilanie placu budowy'),
                      Text(
                        'Struktura: ${headerData.structureName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Plac budowy: ${headerData.buildingName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
        actions: const [],
      ),
      bottomNavigationBar: isMobile
          ? const MainMobileNavBar(currentRoute: '/construction-power')
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Selector<GridProvider, TemporarySupplyConfig>(
                selector: (context, provider) => provider.temporarySupplyConfig,
                builder: (context, config, _) {
                  return _buildTemporarySupplyCard(context, config);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showDistributionBoardTimeline =
                              !_showDistributionBoardTimeline;
                        });
                      },
                      icon: Icon(
                        _showDistributionBoardTimeline
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      label: Text(
                        _showDistributionBoardTimeline
                            ? (isMobile
                                ? 'Ukryj topologię'
                                : 'Ukryj topologię rozdzielnic')
                            : (isMobile
                                ? 'Pokaż topologię'
                                : 'Pokaż topologię rozdzielnic'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Pokaż tylko rozdzielnice'),
                    selected: _hidePowerReceivers,
                    onSelected: (selected) {
                      setState(() {
                        _hidePowerReceivers = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Tylko elementy z problemami'),
                    selected: _showOnlyNodesWithIssues,
                    onSelected: (selected) {
                      setState(() {
                        _showOnlyNodesWithIssues = selected;
                      });
                    },
                  ),
                ],
              ),
              Selector<GridProvider, int>(
                selector: (context, provider) => provider.topologyRevision,
                builder: (context, _, __) {
                  final provider = context.read<GridProvider>();
                  final allNodes = provider.nodes;
                  final observations = _collectConnectionObservations(allNodes);
                  final nodes = _hidePowerReceivers
                      ? allNodes.whereType<DistributionBoard>().toList()
                      : allNodes;
                  final visibleNodeIds = nodes.map((node) => node.id).toSet();
                  final childrenById = <String?, List<GridNode>>{};

                  for (final node in nodes) {
                    final parentId = visibleNodeIds.contains(node.parentId)
                        ? node.parentId
                        : null;
                    childrenById.putIfAbsent(parentId, () => []);
                    childrenById[parentId]!.add(node);
                  }

                  for (final childList in childrenById.values) {
                    childList.sort((a, b) => a.name.compareTo(b.name));
                  }

                  final roots = childrenById[null] ?? [];
                  final nodesWithIssues = allNodes
                      .where((candidate) => _hasNodeIssues(candidate, allNodes))
                      .map((candidate) => candidate.id)
                      .toSet();
                  final filteredRoots = roots
                      .where(
                        (root) =>
                            !_showOnlyNodesWithIssues ||
                            _subtreeHasIssue(
                                root, childrenById, nodesWithIssues),
                      )
                      .toList();

                  if (allNodes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: Text('Brak elementów topologii.')),
                    );
                  }

                  if (nodes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'Brak widocznych węzłów po zastosowaniu filtra.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showDistributionBoardTimeline) ...[
                        const SizedBox(height: 12),
                        _buildDistributionBoardTimeline(context, allNodes),
                      ],
                      if (observations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildObservationsCard(context, observations),
                      ],
                      const SizedBox(height: 12),
                      for (final node in filteredRoots)
                        _buildNode(
                          context,
                          provider,
                          node,
                          allNodes,
                          childrenById,
                          depth: 0,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemporarySupplyCard(
    BuildContext context,
    TemporarySupplyConfig config,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Parametry zasilania tymczasowego',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showTemporarySupplyConfigDialog(context),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Edytuj'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Układ sieci: ${config.networkSystem} | Moc OSD: ${_formatOptionalValue(config.osdConnectionPowerKw, unit: 'kW')} | Zabezpieczenie OSD: ${_formatOptionalValue(config.osdMainProtectionA, unit: 'A')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              'Założenia zwarciowe: Ik ${_formatOptionalValue(config.assumedShortCircuitCurrentKa, unit: 'kA')} | Zs ${_formatOptionalValue(config.assumedLoopImpedanceOhm, unit: 'Ω')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              'Ochrona: RCD 30 mA ${config.rcdRequired ? 'wymagane' : 'niewymagane'} | Uziemienie placu ${config.siteEarthingRequired ? 'wymagane' : 'niewymagane'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTemporarySupplyConfigDialog(BuildContext context) async {
    final provider = context.read<GridProvider>();
    final current = provider.temporarySupplyConfig;

    final osdPowerController = TextEditingController(
      text: current.osdConnectionPowerKw?.toStringAsFixed(1) ?? '',
    );
    final osdProtectionController = TextEditingController(
      text: current.osdMainProtectionA?.toStringAsFixed(0) ?? '',
    );
    final assumedIkController = TextEditingController(
      text: current.assumedShortCircuitCurrentKa?.toStringAsFixed(2) ?? '',
    );
    final assumedZsController = TextEditingController(
      text: current.assumedLoopImpedanceOhm?.toStringAsFixed(3) ?? '',
    );

    var selectedNetworkSystem = current.networkSystem;
    var rcdRequired = current.rcdRequired;
    var siteEarthingRequired = current.siteEarthingRequired;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              title: const Text('Parametry zasilania tymczasowego'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.76,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedNetworkSystem,
                        decoration:
                            const InputDecoration(labelText: 'Układ sieci'),
                        items: const [
                          DropdownMenuItem(value: 'TN-C', child: Text('TN-C')),
                          DropdownMenuItem(value: 'TN-S', child: Text('TN-S')),
                          DropdownMenuItem(
                              value: 'TN-C-S', child: Text('TN-C-S')),
                          DropdownMenuItem(value: 'TT', child: Text('TT')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedNetworkSystem = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: osdPowerController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText:
                              'Moc przyłączeniowa OSD [kW] (opcjonalnie)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: osdProtectionController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText:
                              'Zabezpieczenie przedlicznikowe OSD [A] (opcjonalnie)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: assumedIkController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText:
                              'Założony prąd zwarciowy Ik [kA] (opcjonalnie)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: assumedZsController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText:
                              'Założona impedancja pętli Zs [Ω] (opcjonalnie)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('RCD 30 mA wymagane'),
                        value: rcdRequired,
                        onChanged: (value) {
                          setDialogState(() {
                            rcdRequired = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Uziemienie placu wymagane'),
                        value: siteEarthingRequired,
                        onChanged: (value) {
                          setDialogState(() {
                            siteEarthingRequired = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsedOsdPower = _parseOptionalPositiveNumber(
                      osdPowerController.text,
                    );
                    final parsedOsdProtection = _parseOptionalPositiveNumber(
                      osdProtectionController.text,
                    );
                    final parsedIk = _parseOptionalPositiveNumber(
                      assumedIkController.text,
                    );
                    final parsedZs = _parseOptionalPositiveNumber(
                      assumedZsController.text,
                    );

                    final hasInvalidOsdPower =
                        osdPowerController.text.trim().isNotEmpty &&
                            parsedOsdPower == null;
                    final hasInvalidOsdProtection =
                        osdProtectionController.text.trim().isNotEmpty &&
                            parsedOsdProtection == null;
                    final hasInvalidIk =
                        assumedIkController.text.trim().isNotEmpty &&
                            parsedIk == null;
                    final hasInvalidZs =
                        assumedZsController.text.trim().isNotEmpty &&
                            parsedZs == null;

                    if (hasInvalidOsdPower ||
                        hasInvalidOsdProtection ||
                        hasInvalidIk ||
                        hasInvalidZs) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sprawdź pola liczbowe parametrów zasilania (wartości dodatnie).',
                          ),
                        ),
                      );
                      return;
                    }

                    provider.updateTemporarySupplyConfig(
                      TemporarySupplyConfig(
                        networkSystem: selectedNetworkSystem,
                        osdConnectionPowerKw: parsedOsdPower,
                        osdMainProtectionA: parsedOsdProtection,
                        assumedShortCircuitCurrentKa: parsedIk,
                        assumedLoopImpedanceOhm: parsedZs,
                        rcdRequired: rcdRequired,
                        siteEarthingRequired: siteEarthingRequired,
                      ),
                    );

                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Zapisano parametry zasilania tymczasowego.'),
                      ),
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    osdPowerController.dispose();
    osdProtectionController.dispose();
    assumedIkController.dispose();
    assumedZsController.dispose();
  }

  String _formatOptionalValue(double? value, {required String unit}) {
    if (value == null) {
      return '-';
    }
    return '${value.toStringAsFixed(2)} $unit';
  }

  Future<void> _showStructureManagerDialog(BuildContext context) async {
    await context.read<GridProvider>().loadSavedStructures();
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer<GridProvider>(
          builder: (context, provider, _) {
            final structures = provider.structures;
            final selectedId = provider.currentStructureId;

            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              title: const Text('Topologie rozdzielnic'),
              content: SizedBox(
                width: min(460, MediaQuery.sizeOf(dialogContext).width * 0.92),
                child: provider.isStructuresLoading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showCreateStructureDialog(dialogContext),
                              icon: const Icon(Icons.add),
                              label: const Text('Nowa struktura'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (structures.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Brak zapisanych struktur.'),
                            )
                          else
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: structures.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final structure = structures[index];
                                  final isSelected = structure.id == selectedId;

                                  return ListTile(
                                    tileColor: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.12)
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.transparent,
                                      ),
                                    ),
                                    title: Text(structure.name),
                                    subtitle: Text(
                                      'Aktualizacja: ${_formatStructureDate(structure.updatedAt)}',
                                    ),
                                    onTap: () async {
                                      await provider
                                          .switchStructure(structure.id);
                                      if (context.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: 'Usuń strukturę',
                                      onPressed: () => _confirmDeleteStructure(
                                        dialogContext,
                                        structure.id,
                                        structure.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Zamknij'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateStructureDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: const Text('Nowa struktura'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nazwa struktury',
              hintText: 'np. Etap 1 - rozdzielnice',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<GridProvider>().createNewStructure(
                      controller.text,
                    );
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Utwórz'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _confirmDeleteStructure(
    BuildContext context,
    String structureId,
    String structureName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Usuń strukturę'),
          content: Text(
            'Czy na pewno chcesz usunąć strukturę "$structureName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Usuń'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await context.read<GridProvider>().deleteStructure(structureId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struktura została usunięta.'),
          ),
        );
      }
    }
  }

  String _formatStructureDate(DateTime date) {
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  Future<void> _showBuildingNameDialog(BuildContext context) async {
    final provider = context.read<GridProvider>();
    final controller = TextEditingController(text: provider.buildingName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: const Text('Nazwa placu budowy'),
          content: TextField(
            controller: controller,
            autofocus: true,
            inputFormatters: TechnicalLabelGuard.inputFormatters(),
            decoration: const InputDecoration(
              labelText: 'Nazwa techniczna placu budowy',
              hintText: 'np. BUD-2026-014',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                final buildingName =
                    TechnicalLabelGuard.normalize(controller.text);
                final validationMessage =
                    TechnicalLabelGuard.validateTechnicalLabel(buildingName);

                if (validationMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(validationMessage)),
                  );
                  return;
                }

                provider.setBuildingName(buildingName);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Widget _buildObservationsCard(
    BuildContext context,
    List<_TopologyObservation> observations,
  ) {
    final warningCount = observations
        .where((observation) => observation.level == _ObservationLevel.warning)
        .length;
    final filteredObservations = _showOnlyWarningObservations
        ? observations
            .where(
              (observation) => observation.level == _ObservationLevel.warning,
            )
            .toList()
        : observations;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Obserwacje połączeń i aparatury (${filteredObservations.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Ostrzeżenia: $warningCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('Tylko ostrzeżenia'),
              selected: _showOnlyWarningObservations,
              onSelected: (selected) {
                setState(() {
                  _showOnlyWarningObservations = selected;
                });
              },
            ),
            const SizedBox(height: 8),
            if (filteredObservations.isEmpty)
              Text(
                'Brak obserwacji w bieżącym filtrze.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final observation in filteredObservations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _observationIcon(observation.level),
                      size: 16,
                      color: _observationColor(context, observation.level),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        observation.message,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_TopologyObservation> _collectConnectionObservations(
    List<GridNode> allNodes,
  ) {
    final observations = <_TopologyObservation>[];
    final nodeById = {for (final node in allNodes) node.id: node};
    final childrenByParentId = <String?, List<GridNode>>{};
    for (final node in allNodes) {
      childrenByParentId.putIfAbsent(node.parentId, () => []);
      childrenByParentId[node.parentId]!.add(node);
    }

    final boards = allNodes.whereType<DistributionBoard>().toList();
    final penCount = boards.where((board) => board.isPenSplitPoint).length;
    if (penCount > 1) {
      observations.add(
        _TopologyObservation(
          level: _ObservationLevel.warning,
          message:
              'Wykryto więcej niż jeden punkt podziału PEN. Interpretacja topologii może wymagać dodatkowego potwierdzenia projektowego.',
        ),
      );
    }

    for (final board in boards) {
      final directChildren = childrenByParentId[board.id] ?? const [];
      final directChildIds = directChildren.map((e) => e.id).toSet();
      final assignedIds = <String>{};

      for (final slot in board.protectionSlots) {
        if (!slot.hasCompleteDefinition) {
          observations.add(
            _TopologyObservation(
              level: _ObservationLevel.info,
              message:
                  'Rozdzielnica ${board.name}: część pozycji aparatury nie zawiera pełnych danych (wizualizacja kropek może być pominięta).',
            ),
          );
          break;
        }

        if (slot.isReserve && slot.assignedNodeId != null) {
          observations.add(
            _TopologyObservation(
              level: _ObservationLevel.info,
              message:
                  'Rozdzielnica ${board.name}: pozycja oznaczona jako rezerwa ma jednocześnie przypisanie odbioru.',
            ),
          );
        }

        if (!slot.isReserve &&
            (slot.assignedNodeId == null || slot.assignedNodeId!.isEmpty)) {
          observations.add(
            _TopologyObservation(
              level: _ObservationLevel.info,
              message:
                  'Rozdzielnica ${board.name}: pozycja obsadzona nie ma przypisanego urządzenia lub rozdzielnicy.',
            ),
          );
        }

        if (slot.assignedNodeId != null && slot.assignedNodeId!.isNotEmpty) {
          if (assignedIds.contains(slot.assignedNodeId)) {
            observations.add(
              _TopologyObservation(
                level: _ObservationLevel.warning,
                message:
                    'Rozdzielnica ${board.name}: ten sam odbiór przypisano do więcej niż jednej pozycji aparatury.',
              ),
            );
          }
          assignedIds.add(slot.assignedNodeId!);

          final assignedNode = nodeById[slot.assignedNodeId!];
          if (assignedNode == null) {
            observations.add(
              _TopologyObservation(
                level: _ObservationLevel.warning,
                message:
                    'Rozdzielnica ${board.name}: wykryto przypisanie do elementu, który nie występuje w bieżącej topologii.',
              ),
            );
          } else if (!directChildIds.contains(assignedNode.id)) {
            observations.add(
              _TopologyObservation(
                level: _ObservationLevel.info,
                message:
                    'Rozdzielnica ${board.name}: przypisanie aparatury wskazuje element poza bezpośrednią gałęzią tej rozdzielnicy.',
              ),
            );
          }
        }
      }
    }

    for (final node in allNodes) {
      if (node.isThreePhase && node.cableCores == 3) {
        observations.add(
          _TopologyObservation(
            level: _ObservationLevel.warning,
            message:
                'Element ${node.name}: konfiguracja 3-fazowa z przewodem 3-żyłowym może wskazywać niespójność danych wejściowych.',
          ),
        );
      }
    }

    return observations;
  }

  IconData _observationIcon(_ObservationLevel level) {
    switch (level) {
      case _ObservationLevel.warning:
        return Icons.warning_amber_rounded;
      case _ObservationLevel.info:
        return Icons.info_outline;
    }
  }

  Color _observationColor(BuildContext context, _ObservationLevel level) {
    switch (level) {
      case _ObservationLevel.warning:
        return Colors.orangeAccent;
      case _ObservationLevel.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildDistributionBoardTimeline(
    BuildContext context,
    List<GridNode> allNodes,
  ) {
    final timeline = _collectDistributionBoardTimeline(allNodes);

    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zasilanie placu budowy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('Pokaż tylko rozdzielnice'),
              selected: _hidePowerReceivers,
              onSelected: (selected) {
                setState(() {
                  _hidePowerReceivers = selected;
                });
              },
            ),
            const SizedBox(height: 8),
            if (timeline.isEmpty)
              Text(
                'Brak rozdzielnic do wyświetlenia.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final entry in timeline)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.order.toString(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            entry.parentName == null
                                ? 'Zasilanie główne'
                                : 'Zasilane z: ${entry.parentName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_DistributionBoardTimelineEntry> _collectDistributionBoardTimeline(
    List<GridNode> allNodes,
  ) {
    final boards = allNodes.whereType<DistributionBoard>().toList();
    if (boards.isEmpty) {
      return const [];
    }

    final boardById = {for (final board in boards) board.id: board};
    final childrenById = <String?, List<DistributionBoard>>{};

    for (final board in boards) {
      final normalizedParentId =
          boardById.containsKey(board.parentId) ? board.parentId : null;
      childrenById.putIfAbsent(normalizedParentId, () => []);
      childrenById[normalizedParentId]!.add(board);
    }

    for (final childList in childrenById.values) {
      childList.sort((a, b) => a.name.compareTo(b.name));
    }

    final timeline = <_DistributionBoardTimelineEntry>[];
    final visited = <String>{};

    void visit(DistributionBoard board) {
      if (visited.contains(board.id)) {
        return;
      }

      visited.add(board.id);
      timeline.add(
        _DistributionBoardTimelineEntry(
          order: timeline.length + 1,
          name: board.name,
          parentName: boardById[board.parentId]?.name,
        ),
      );

      final children = childrenById[board.id] ?? const [];
      for (final child in children) {
        visit(child);
      }
    }

    final roots = childrenById[null] ?? const [];
    for (final root in roots) {
      visit(root);
    }

    for (final board in boards) {
      if (!visited.contains(board.id)) {
        visit(board);
      }
    }

    return timeline;
  }

  Widget _buildNode(
    BuildContext context,
    GridProvider provider,
    GridNode node,
    List<GridNode> allNodes,
    Map<String?, List<GridNode>> childrenById, {
    required int depth,
  }) {
    final children = childrenById[node.id] ?? const [];
    final hasChildren = children.isNotEmpty;
    final isExpanded = _isNodeExpanded(node, hasChildren);
    final leftIndent = _resolveNodeIndent(context, depth);
    final tileWidth = _resolveNodeTileWidth(context, depth);
    final powerKw = provider.aggregatePowerKw[node];
    final actualPowerKw = powerKw ?? node.powerKw;
    final ib = _calculateIb(node, actualPowerKw);
    final currentLimits = _resolveNodeCurrentLimits(provider, node);
    final effectiveLimitA = currentLimits.effectiveLimitA;
    final loadRatio = effectiveLimitA == null || effectiveLimitA <= 0
        ? 0.0
        : ib / effectiveLimitA;
    final progressColor = _loadColor(loadRatio, context);

    return Padding(
      padding: EdgeInsets.only(left: leftIndent, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DragTarget<GridNode>(
            onWillAcceptWithDetails: (details) => details.data.id != node.id,
            onAcceptWithDetails: (details) {
              // Opóźnij aktualizację do po zakończeniu bieżącej fazy budowania
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.updateNodeParent(details.data, node);
                _showRecalculateAlert(context);
              });
            },
            builder: (context, candidateData, rejectedData) {
              return LongPressDraggable<GridNode>(
                data: node,
                feedback: Material(
                  elevation: 6,
                  child: _buildTile(
                    context,
                    node,
                    ib,
                    loadRatio,
                    currentLimits,
                    progressColor,
                    tileWidth: tileWidth,
                    hasChildren: hasChildren,
                    isExpanded: isExpanded,
                    onToggleExpansion: () =>
                        _toggleNodeExpansion(node, hasChildren),
                    allNodes: allNodes,
                    isDragging: true,
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildTile(
                    context,
                    node,
                    ib,
                    loadRatio,
                    currentLimits,
                    progressColor,
                    tileWidth: tileWidth,
                    hasChildren: hasChildren,
                    isExpanded: isExpanded,
                    onToggleExpansion: () =>
                        _toggleNodeExpansion(node, hasChildren),
                    allNodes: allNodes,
                    isDragging: true,
                  ),
                ),
                child: _buildTile(
                  context,
                  node,
                  ib,
                  loadRatio,
                  currentLimits,
                  progressColor,
                  tileWidth: tileWidth,
                  hasChildren: hasChildren,
                  isExpanded: isExpanded,
                  onToggleExpansion: () =>
                      _toggleNodeExpansion(node, hasChildren),
                  allNodes: allNodes,
                  isHighlighted: candidateData.isNotEmpty,
                ),
              );
            },
          ),
          if (hasChildren && !isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8),
              child: Text(
                'Zwinięto ${children.length} ${children.length == 1 ? 'element' : 'elementy'} podrzędne',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (hasChildren && isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final child in children)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (node is DistributionBoard &&
                            child is DistributionBoard)
                          _buildCableConnectionTile(
                            context,
                            provider,
                            parent: node,
                            child: child,
                            depth: depth + 1,
                          ),
                        _buildNode(
                          context,
                          provider,
                          child,
                          allNodes,
                          childrenById,
                          depth: depth + 1,
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCableConnectionTile(
    BuildContext context,
    GridProvider provider, {
    required DistributionBoard parent,
    required DistributionBoard child,
    required int depth,
  }) {
    final cableState = _evaluateCableState(provider, child);
    final leftIndent = _resolveNodeIndent(context, depth);
    final tileWidth = _resolveNodeTileWidth(context, depth);
    final stateColor = _cableStateColor(context, cableState.kind);
    final caption =
        '${child.lengthM.toStringAsFixed(0)} m · ${child.crossSectionMm2.toStringAsFixed(1)} mm² · ${child.cableCores} żył · ${GridNode.materialToString(child.material)}';

    return Padding(
      padding: EdgeInsets.only(
        left: leftIndent,
        right: 8,
        bottom: 8,
      ),
      child: SizedBox(
        width: tileWidth,
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showCableSummary(context, parent, child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: stateColor.withValues(alpha: 0.45),
                ),
                color: stateColor.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cable,
                    size: 16,
                    color: stateColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kabel: ${parent.name} → ${child.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edytuj parametry kabla',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () =>
                        _showEditCableDialog(context, provider, parent, child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCableSummary(
    BuildContext context,
    DistributionBoard parent,
    DistributionBoard child,
  ) {
    final provider = Provider.of<GridProvider>(context, listen: false);
    final cableState = _evaluateCableState(provider, child);
    final details =
        'Kabel ${parent.name} → ${child.name}: ${child.lengthM.toStringAsFixed(0)} m, ${child.crossSectionMm2.toStringAsFixed(1)} mm², ${child.cableCores} żył, ${GridNode.materialToString(child.material)}.';

    final riskMessage = switch (cableState.kind) {
      _CableStateKind.warning =>
        'Wskaźnik orientacyjny: parametry mogą sugerować podwyższone obciążenie.',
      _CableStateKind.possibleOverload =>
        'Wskaźnik orientacyjny: parametry mogą sugerować możliwe przeciążenie.',
      _CableStateKind.nominal => null,
    };

    final message = riskMessage == null ? details : '$details $riskMessage';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showEditCableDialog(
    BuildContext context,
    GridProvider provider,
    DistributionBoard parent,
    DistributionBoard child,
  ) async {
    final lengthController = TextEditingController(
      text: child.lengthM.toStringAsFixed(1),
    );
    final crossSectionController = TextEditingController(
      text: child.crossSectionMm2.toStringAsFixed(1),
    );
    var selectedMaterial = child.material;
    var selectedCores = child.cableCores < 4
        ? 4
        : (child.cableCores > 5 ? 5 : child.cableCores);
    final forceFiveCore = _isDownstreamOfPenSplit(
      parent,
      provider.nodes,
      includeSelf: true,
    );
    if (forceFiveCore) {
      selectedCores = 5;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              title: Text('Kabel: ${parent.name} → ${child.name}'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.62,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: lengthController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Długość kabla (m)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: crossSectionController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Przekrój kabla (mm²)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<ConductorMaterial>(
                        initialValue: selectedMaterial,
                        decoration:
                            const InputDecoration(labelText: 'Materiał'),
                        items: const [
                          DropdownMenuItem(
                            value: ConductorMaterial.cu,
                            child: Text('Cu'),
                          ),
                          DropdownMenuItem(
                            value: ConductorMaterial.al,
                            child: Text('Al'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedMaterial = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: selectedCores,
                        decoration:
                            const InputDecoration(labelText: 'Liczba żył'),
                        items: const [
                          DropdownMenuItem(value: 4, child: Text('4-żyłowy')),
                          DropdownMenuItem(value: 5, child: Text('5-żyłowy')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCores = value;
                            });
                          }
                        },
                      ),
                      if (forceFiveCore)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Za punktem podziału PEN dla linii 3-fazowych dostępna jest konfiguracja 5-żyłowa.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final length = _parsePositiveNumber(lengthController.text);
                    final crossSection = _parsePositiveNumber(
                      crossSectionController.text,
                    );

                    if (length == null || crossSection == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wprowadzone dane nie zostały zapisane (nie udało się odczytać wartości liczbowych > 0).',
                          ),
                        ),
                      );
                      return;
                    }

                    if (forceFiveCore && selectedCores == 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Po punkcie podziału PEN dla 3-fazowej rozdzielnicy dostępny jest kabel 5-żyłowy.',
                          ),
                        ),
                      );
                      return;
                    }

                    provider.updateConnectionCable(
                      child,
                      lengthM: length,
                      crossSectionMm2: crossSection,
                      cableCores: selectedCores,
                      material: selectedMaterial,
                    );

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Zaktualizowano kabel: ${parent.name} → ${child.name}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    lengthController.dispose();
    crossSectionController.dispose();
  }

  double? _parsePositiveNumber(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? _parseOptionalPositiveNumber(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return _parsePositiveNumber(normalized);
  }

  int? _parseOptionalNonNegativeInt(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return null;
    }

    return parsed;
  }

  bool _isDownstreamOfPenSplit(
    GridNode node,
    List<GridNode> allNodes, {
    bool includeSelf = false,
  }) {
    final nodesById = {for (final item in allNodes) item.id: item};
    GridNode? current = includeSelf ? node : nodesById[node.parentId];

    while (current != null) {
      if (current is DistributionBoard && current.isPenSplitPoint) {
        return true;
      }
      current = nodesById[current.parentId];
    }

    return false;
  }

  bool _hasPenSplitPoint(List<GridNode> allNodes) {
    return allNodes
        .whereType<DistributionBoard>()
        .any((board) => board.isPenSplitPoint);
  }

  Widget _buildPenSplitBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'PEN ⏚',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  _CableState _evaluateCableState(GridProvider provider, GridNode child) {
    final powerKw = provider.aggregatePowerKw[child] ?? child.powerKw;
    final ib = _calculateIb(child, powerKw);
    final ampPerMm2 = child.material == ConductorMaterial.cu ? 6.0 : 4.0;
    final estimatedCapacity = child.crossSectionMm2 * ampPerMm2;
    final ratio = estimatedCapacity <= 0 ? 9.99 : ib / estimatedCapacity;

    if (ratio >= 1.0) {
      return _CableState(kind: _CableStateKind.possibleOverload, ratio: ratio);
    }
    if (ratio >= 0.8) {
      return _CableState(kind: _CableStateKind.warning, ratio: ratio);
    }
    return _CableState(kind: _CableStateKind.nominal, ratio: ratio);
  }

  Color _cableStateColor(BuildContext context, _CableStateKind kind) {
    switch (kind) {
      case _CableStateKind.possibleOverload:
        return Colors.redAccent;
      case _CableStateKind.warning:
        return Colors.orangeAccent;
      case _CableStateKind.nominal:
        return Theme.of(context).colorScheme.primary;
    }
  }

  _NodeCurrentLimits _resolveNodeCurrentLimits(
    GridProvider provider,
    GridNode node,
  ) {
    final nodeRatedA = node.ratedCurrentA > 0 ? node.ratedCurrentA : null;
    final cableEstimatedA = _estimateCableCurrentCapacity(node);
    double? upstreamProtectionA;

    final parentId = node.parentId;
    if (parentId != null && parentId.isNotEmpty) {
      DistributionBoard? parentBoard;
      for (final candidate in provider.nodes) {
        if (candidate.id == parentId && candidate is DistributionBoard) {
          parentBoard = candidate;
          break;
        }
      }

      if (parentBoard != null) {
        for (final slot in parentBoard.protectionSlots) {
          final slotCurrent = slot.ratedCurrentA;
          final isMatch = !slot.isReserve &&
              slot.assignedNodeId == node.id &&
              (slotCurrent ?? 0) > 0;
          if (!isMatch) {
            continue;
          }

          if (upstreamProtectionA == null) {
            upstreamProtectionA = slotCurrent;
          } else {
            upstreamProtectionA = min(upstreamProtectionA, slotCurrent!);
          }
        }
      }
    }

    final candidateLimits = <double>[];
    if (nodeRatedA != null) {
      candidateLimits.add(nodeRatedA);
    }
    if (upstreamProtectionA != null) {
      candidateLimits.add(upstreamProtectionA);
    }
    if (cableEstimatedA != null) {
      candidateLimits.add(cableEstimatedA);
    }

    final effectiveLimitA =
        candidateLimits.isEmpty ? null : candidateLimits.reduce(min);

    return _NodeCurrentLimits(
      nodeRatedA: nodeRatedA,
      upstreamProtectionA: upstreamProtectionA,
      cableEstimatedA: cableEstimatedA,
      effectiveLimitA: effectiveLimitA,
    );
  }

  double? _estimateCableCurrentCapacity(GridNode node) {
    if (node.crossSectionMm2 <= 0) {
      return null;
    }

    final ampPerMm2 = node.material == ConductorMaterial.cu ? 6.0 : 4.0;
    final estimatedA = node.crossSectionMm2 * ampPerMm2;
    if (estimatedA <= 0) {
      return null;
    }

    return estimatedA;
  }

  String _formatCurrent(double? value) {
    if (value == null) {
      return '-';
    }
    return '${value.toStringAsFixed(1)}A';
  }

  String? _boardSocketSummary(DistributionBoard board) {
    final has230 = board.socketCount230V != null;
    final has400 = board.socketCount400V != null;
    if (!has230 && !has400) {
      return null;
    }

    final count230 = board.socketCount230V?.toString() ?? '-';
    final count400 = board.socketCount400V?.toString() ?? '-';
    return 'Gniazda 230V: $count230 · 400V: $count400';
  }

  Widget _buildTile(
    BuildContext context,
    GridNode node,
    double ib,
    double loadRatio,
    _NodeCurrentLimits currentLimits,
    Color progressColor, {
    required double tileWidth,
    required bool hasChildren,
    required bool isExpanded,
    required VoidCallback onToggleExpansion,
    required List<GridNode> allNodes,
    bool isHighlighted = false,
    bool isDragging = false,
  }) {
    final protectionSummary =
        node is DistributionBoard ? _getProtectionDotsSummary(node) : null;
    final additionalEquipment = node is DistributionBoard
        ? node.additionalEquipment
        : const <BoardAdditionalEquipment>[];
    final socketsSummary =
        node is DistributionBoard ? _boardSocketSummary(node) : null;
    final nodeStatus = _resolveNodeStatus(node, allNodes);

    return SizedBox(
      width: tileWidth,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60, minWidth: 200),
        child: Material(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDragging
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: isDragging ? 2 : 0,
              ),
              boxShadow: isDragging
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    node.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (node is DistributionBoard &&
                                    node.isPenSplitPoint)
                                  _buildPenSplitBadge(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Ib ${ib.toStringAsFixed(1)}A · Limit ${_formatCurrent(currentLimits.effectiveLimitA)} · ${node.cableCores} żył',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (node.location.trim().isNotEmpty)
                        Text(
                          'Lokalizacja: ${node.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      Text(
                        'In ${_formatCurrent(currentLimits.nodeRatedA)} · Zabezp. ${_formatCurrent(currentLimits.upstreamProtectionA)} · Kabel~ ${_formatCurrent(currentLimits.cableEstimatedA)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (socketsSummary != null)
                        Text(
                          socketsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      const SizedBox(height: 4),
                      _buildNodeStatusChip(context, nodeStatus),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 6),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: min(loadRatio, 1.0),
                            color: progressColor,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      if (node is DistributionBoard &&
                          (protectionSummary?.showVisualization ?? false))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildProtectionDots(
                            context,
                            protectionSummary!,
                          ),
                        ),
                      if (node is DistributionBoard &&
                          additionalEquipment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _buildAdditionalEquipmentSymbols(
                            context,
                            additionalEquipment,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasChildren)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onToggleExpansion,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (hasChildren) const SizedBox(width: 4),
                // Action buttons
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleNodeAction(context, node, value);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 14),
                          SizedBox(width: 6),
                          Text('Dodaj', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 14),
                          SizedBox(width: 6),
                          Text('Edytuj', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14),
                          SizedBox(width: 6),
                          Text('Szczegóły', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'replace',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 14),
                          SizedBox(width: 6),
                          Text('Zamień', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 14, color: Colors.red),
                          SizedBox(width: 6),
                          Text('Usuń',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _resolveNodeIndent(BuildContext context, int depth) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final indentStep = viewportWidth < 600 ? 10.0 : 16.0;
    final indent = depth * indentStep;
    if (viewportWidth < 600) {
      return min(indent, 56.0);
    }
    return indent;
  }

  double _resolveNodeTileWidth(BuildContext context, int depth) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (viewportWidth >= 600) {
      return 300;
    }

    final leftIndent = _resolveNodeIndent(context, depth);
    final basePadding = viewportWidth < 380 ? 24.0 : 28.0;
    final availableWidth = viewportWidth - basePadding - leftIndent - 8;
    return availableWidth.clamp(220.0, 320.0).toDouble();
  }

  Color _loadColor(double ratio, BuildContext context) {
    if (ratio >= 1.0) {
      return Colors.redAccent;
    }
    if (ratio < 0.8) {
      return Colors.greenAccent;
    }
    return Theme.of(context).colorScheme.primary;
  }

  _ProtectionDotsSummary _getProtectionDotsSummary(DistributionBoard board) {
    final slots = board.protectionSlots;
    if (slots.isEmpty) {
      return const _ProtectionDotsSummary(
        occupiedCount: 0,
        reserveCount: 0,
        occupiedSingleCount: 0,
        reserveSingleCount: 0,
        occupiedPoleGroups: {},
        reservePoleGroups: {},
        showVisualization: false,
      );
    }

    if (slots.any((slot) => !slot.hasCompleteDefinition)) {
      return const _ProtectionDotsSummary(
        occupiedCount: 0,
        reserveCount: 0,
        occupiedSingleCount: 0,
        reserveSingleCount: 0,
        occupiedPoleGroups: {},
        reservePoleGroups: {},
        showVisualization: false,
      );
    }

    var occupied = 0;
    var reserve = 0;
    var occupiedSingleCount = 0;
    var reserveSingleCount = 0;
    final occupiedPoleGroups = <int, int>{};
    final reservePoleGroups = <int, int>{};

    for (final slot in slots) {
      final poles = slot.type == ProtectionDeviceType.fuseHolder
          ? 1
          : (slot.poleCount <= 0 ? 1 : slot.poleCount);
      final moduleCount = slot.quantity * poles;

      if (slot.isReserve) {
        reserve += moduleCount;
        if (poles == 1) {
          reserveSingleCount += slot.quantity;
        }
      } else {
        occupied += moduleCount;
        if (poles == 1) {
          occupiedSingleCount += slot.quantity;
        }
      }

      if (poles > 1) {
        final target = slot.isReserve ? reservePoleGroups : occupiedPoleGroups;
        target[poles] = (target[poles] ?? 0) + slot.quantity;
      }
    }

    if (occupied + reserve == 0) {
      return const _ProtectionDotsSummary(
        occupiedCount: 0,
        reserveCount: 0,
        occupiedSingleCount: 0,
        reserveSingleCount: 0,
        occupiedPoleGroups: {},
        reservePoleGroups: {},
        showVisualization: false,
      );
    }

    return _ProtectionDotsSummary(
      occupiedCount: occupied,
      reserveCount: reserve,
      occupiedSingleCount: occupiedSingleCount,
      reserveSingleCount: reserveSingleCount,
      occupiedPoleGroups: occupiedPoleGroups,
      reservePoleGroups: reservePoleGroups,
      showVisualization: true,
    );
  }

  Widget _buildProtectionDots(
    BuildContext context,
    _ProtectionDotsSummary summary,
  ) {
    final occupiedColor = Theme.of(context).colorScheme.primary;
    final reserveColor = Theme.of(context).textTheme.bodySmall?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var i = 0; i < summary.occupiedSingleCount; i++)
              Icon(Icons.circle, size: 7, color: occupiedColor),
            for (final entry in summary.occupiedPoleGroups.entries)
              for (var i = 0; i < entry.value; i++)
                _buildPoleFrame(
                  context,
                  poles: entry.key,
                  color: occupiedColor,
                  filled: true,
                ),
            for (var i = 0; i < summary.reserveSingleCount; i++)
              Icon(Icons.circle_outlined, size: 7, color: reserveColor),
            for (final entry in summary.reservePoleGroups.entries)
              for (var i = 0; i < entry.value; i++)
                _buildPoleFrame(
                  context,
                  poles: entry.key,
                  color: reserveColor,
                  filled: false,
                ),
          ],
        ),
        if (summary.occupiedPoleGroups.isNotEmpty ||
            summary.reservePoleGroups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...summary.occupiedPoleGroups.entries.map(
                  (entry) => _buildPoleMarkerChip(
                    context,
                    '${entry.key}P×${entry.value}',
                    filled: true,
                  ),
                ),
                ...summary.reservePoleGroups.entries.map(
                  (entry) => _buildPoleMarkerChip(
                    context,
                    '${entry.key}P×${entry.value}',
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPoleFrame(
    BuildContext context, {
    required int poles,
    Color? color,
    required bool filled,
  }) {
    final borderColor = color ?? Theme.of(context).colorScheme.primary;
    final iconData = filled ? Icons.circle : Icons.circle_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < poles; i++) ...[
            Icon(iconData, size: 7, color: borderColor),
            if (i < poles - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }

  Widget _buildPoleMarkerChip(
    BuildContext context,
    String text, {
    required bool filled,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    final textStyle = Theme.of(context).textTheme.labelSmall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled ? color.withValues(alpha: 0.6) : color,
        ),
      ),
      child: Text(
        text,
        style: textStyle,
      ),
    );
  }

  Widget _buildAdditionalEquipmentSymbols(
    BuildContext context,
    List<BoardAdditionalEquipment> equipment,
  ) {
    final surfaceColor = Theme.of(context).colorScheme.primaryContainer;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final item in equipment)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_additionalEquipmentIcon(item), size: 12),
                const SizedBox(width: 4),
                Text(
                  _additionalEquipmentSymbol(item),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _additionalEquipmentSymbol(BoardAdditionalEquipment item) {
    switch (item) {
      case BoardAdditionalEquipment.subMeter:
        return 'POD-L';
      case BoardAdditionalEquipment.pwpSwitch:
        return 'PWP';
      case BoardAdditionalEquipment.surgeProtection:
        return 'SPD';
    }
  }

  String _additionalEquipmentLabel(BoardAdditionalEquipment item) {
    switch (item) {
      case BoardAdditionalEquipment.subMeter:
        return 'Licznik podlicznik';
      case BoardAdditionalEquipment.pwpSwitch:
        return 'Wyłącznik PWP';
      case BoardAdditionalEquipment.surgeProtection:
        return 'Zabezpieczenie przeciwprzepięciowe';
    }
  }

  IconData _additionalEquipmentIcon(BoardAdditionalEquipment item) {
    switch (item) {
      case BoardAdditionalEquipment.subMeter:
        return Icons.electric_meter;
      case BoardAdditionalEquipment.pwpSwitch:
        return Icons.power_settings_new;
      case BoardAdditionalEquipment.surgeProtection:
        return Icons.bolt;
    }
  }

  bool _hasNodeIssues(GridNode node, List<GridNode> allNodes) {
    final status = _resolveNodeStatus(node, allNodes);
    return status != _NodeQualityStatus.ok;
  }

  bool _subtreeHasIssue(
    GridNode node,
    Map<String?, List<GridNode>> childrenById,
    Set<String> nodesWithIssues,
  ) {
    if (nodesWithIssues.contains(node.id)) {
      return true;
    }

    final children = childrenById[node.id] ?? const [];
    for (final child in children) {
      if (_subtreeHasIssue(child, childrenById, nodesWithIssues)) {
        return true;
      }
    }

    return false;
  }

  _NodeQualityStatus _resolveNodeStatus(
      GridNode node, List<GridNode> allNodes) {
    if (node.powerKw <= 0 || node.lengthM <= 0 || node.crossSectionMm2 <= 0) {
      return _NodeQualityStatus.incomplete;
    }

    if (node is DistributionBoard) {
      if (node.protectionSlots.isEmpty) {
        return _NodeQualityStatus.warning;
      }

      final hasInvalidSlot = node.protectionSlots.any(
        (slot) => !slot.hasCompleteDefinition,
      );
      if (hasInvalidSlot) {
        return _NodeQualityStatus.warning;
      }

      final hasAssignedButMissingNode = node.protectionSlots.any((slot) {
        final assignedId = slot.assignedNodeId;
        if (assignedId == null || assignedId.isEmpty) {
          return false;
        }
        return !allNodes.any((candidate) => candidate.id == assignedId);
      });
      if (hasAssignedButMissingNode) {
        return _NodeQualityStatus.warning;
      }
    }

    return _NodeQualityStatus.ok;
  }

  Widget _buildNodeStatusChip(
    BuildContext context,
    _NodeQualityStatus status,
  ) {
    final (label, color) = switch (status) {
      _NodeQualityStatus.ok => ('Spójny', Colors.green),
      _NodeQualityStatus.warning => ('Do weryfikacji', Colors.orange),
      _NodeQualityStatus.incomplete => ('Braki danych', Colors.redAccent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  double _calculateIb(GridNode node, double powerKw) {
    if (node.isThreePhase) {
      return (powerKw * 1000) / (sqrt(3) * 400);
    }

    return (powerKw * 1000) / 230;
  }

  Future<void> _generateTopologyPdf(BuildContext context) async {
    final provider = Provider.of<GridProvider>(context, listen: false);
    final buildingName =
        provider.buildingName.isEmpty ? 'nie podano' : provider.buildingName;

    if (provider.nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak danych topologii do wygenerowania schematu PDF.'),
        ),
      );
      return;
    }

    try {
      await PdfService.generateTopologyBlockSchematicPdf(
        gridProvider: provider,
        buildingName: buildingName,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wygenerowano schemat blokowy topologii (PDF).'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się wygenerować PDF: $error'),
        ),
      );
    }
  }

  void _showAddNodeFromToolbarDialog(BuildContext context) {
    final provider = Provider.of<GridProvider>(context, listen: false);
    final boards = provider.nodes.whereType<DistributionBoard>().toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (boards.isEmpty) {
      _showAddFirstBoardDialog(context);
      return;
    }

    String selectedParentId = boards.first.id;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            title: const Text('Wybierz rozdzielnicę nadrzędną'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Wskaż, gdzie chcesz dodać nowy element.',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedParentId,
                  decoration: const InputDecoration(
                    labelText: 'Rozdzielnica nadrzędna',
                  ),
                  items: boards
                      .map(
                        (board) => DropdownMenuItem<String>(
                          value: board.id,
                          child: Text(board.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setDialogState(() {
                      selectedParentId = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () {
                  final selectedParent = boards.firstWhere(
                    (board) => board.id == selectedParentId,
                  );
                  Navigator.pop(dialogContext);
                  _showAddTypeDialog(context, selectedParent);
                },
                child: const Text('Dalej'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddFirstBoardDialog(BuildContext context) async {
    final provider = Provider.of<GridProvider>(context, listen: false);
    final nameController = TextEditingController(text: 'RG');
    final locationController = TextEditingController();
    final powerController = TextEditingController(text: '15');
    final lengthController = TextEditingController(text: '1');
    final crossSectionController = TextEditingController(text: '10');
    final ratedCurrentController = TextEditingController(text: '63');
    final socket230Controller = TextEditingController();
    final socket400Controller = TextEditingController();

    var selectedMaterial = ConductorMaterial.cu;
    var selectedCores = 5;
    var isPenSplitPoint = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            title: const Text('Pierwsza rozdzielnica w strukturze'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.72,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'Nazwa rozdzielnicy'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokalizacja (opcjonalnie)',
                        hintText: 'np. Kontener socjalny, poziom 0',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: powerController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Moc [kW]'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ratedCurrentController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Prąd znamionowy In [A]'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: lengthController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Długość kabla [m]'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: crossSectionController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Przekrój kabla [mm²]'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ConductorMaterial>(
                      initialValue: selectedMaterial,
                      decoration:
                          const InputDecoration(labelText: 'Materiał przewodu'),
                      items: const [
                        DropdownMenuItem(
                            value: ConductorMaterial.cu, child: Text('Cu')),
                        DropdownMenuItem(
                            value: ConductorMaterial.al, child: Text('Al')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedMaterial = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedCores,
                      decoration:
                          const InputDecoration(labelText: 'Liczba żył'),
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('4-żyłowy')),
                        DropdownMenuItem(value: 5, child: Text('5-żyłowy')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCores = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: socket230Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Liczba gniazd 230V (opcjonalnie)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: socket400Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Liczba gniazd 400V (opcjonalnie)'),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Punkt podziału PEN'),
                      value: isPenSplitPoint,
                      onChanged: (value) {
                        setDialogState(() {
                          isPenSplitPoint = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () {
                  final normalizedName = nameController.text.trim();
                  final parsedPower =
                      _parsePositiveNumber(powerController.text);
                  final parsedLength =
                      _parsePositiveNumber(lengthController.text);
                  final parsedCrossSection =
                      _parsePositiveNumber(crossSectionController.text);
                  final parsedRatedCurrent =
                      _parsePositiveNumber(ratedCurrentController.text);

                  if (normalizedName.isEmpty ||
                      parsedPower == null ||
                      parsedLength == null ||
                      parsedCrossSection == null ||
                      parsedRatedCurrent == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Uzupełnij poprawnie nazwę i parametry pierwszej rozdzielnicy (wartości > 0).',
                        ),
                      ),
                    );
                    return;
                  }

                  final hasPenSplit = provider.nodes
                      .whereType<DistributionBoard>()
                      .any((board) => board.isPenSplitPoint);
                  if (isPenSplitPoint && hasPenSplit) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Punkt podziału PEN jest już oznaczony w innej rozdzielnicy.',
                        ),
                      ),
                    );
                    return;
                  }

                  final newNode = DistributionBoard(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: normalizedName,
                    location: locationController.text.trim(),
                    powerKw: parsedPower,
                    lengthM: parsedLength,
                    crossSectionMm2: parsedCrossSection,
                    cableCores: selectedCores,
                    ratedCurrentA: parsedRatedCurrent,
                    material: selectedMaterial,
                    isPenSplitPoint: isPenSplitPoint,
                    socketCount230V: _parseOptionalNonNegativeInt(
                      socket230Controller.text,
                    ),
                    socketCount400V: _parseOptionalNonNegativeInt(
                      socket400Controller.text,
                    ),
                  );

                  provider.addNode(newNode);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Dodano pierwszą rozdzielnicę: $normalizedName'),
                    ),
                  );
                },
                child: const Text('Dodaj'),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    locationController.dispose();
    powerController.dispose();
    lengthController.dispose();
    crossSectionController.dispose();
    ratedCurrentController.dispose();
    socket230Controller.dispose();
    socket400Controller.dispose();
  }

  void _handleNodeAction(BuildContext context, GridNode node, String action) {
    switch (action) {
      case 'add':
        _showAddTypeDialog(context, node);
        break;
      case 'edit':
        _showEditNodeDialog(context, node);
        break;
      case 'details':
        _showNodeDetailsDialog(context, node);
        break;
      case 'replace':
        _showReplaceNodeDialog(context, node);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, node);
        break;
    }
  }

  void _showNodeDetailsDialog(BuildContext context, GridNode node) {
    final provider = Provider.of<GridProvider>(context, listen: false);
    final allNodes = provider.nodes;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final nodeType =
            node is DistributionBoard ? 'Rozdzielnica' : 'Odbiornik';
        final cableMaterial =
            node.material == ConductorMaterial.cu ? 'Cu' : 'Al';
        final parentProtectionSlots = allNodes
            .whereType<DistributionBoard>()
            .expand((board) => board.protectionSlots)
            .where((slot) => slot.assignedNodeId == node.id)
            .toList();
        final downstreamNodes = allNodes
            .where((candidate) => candidate.parentId == node.id)
            .toList();
        final usedSlots = node is DistributionBoard
            ? node.protectionSlots.where((slot) => !slot.isReserve).toList()
            : const <BoardProtectionSlot>[];
        final reserveSlots = node is DistributionBoard
            ? node.protectionSlots.where((slot) => slot.isReserve).toList()
            : const <BoardProtectionSlot>[];

        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: Text('Szczegóły: ${node.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Typ: $nodeType'),
                  Text('Moc: ${node.powerKw.toStringAsFixed(2)} kW'),
                  Text(
                    'Kabel: ${node.cableCores} żył | ${node.crossSectionMm2.toStringAsFixed(1)} mm² | ${node.lengthM.toStringAsFixed(1)} m | $cableMaterial',
                  ),
                  Text('In: ${node.ratedCurrentA.toStringAsFixed(0)} A'),
                  const SizedBox(height: 12),
                  const Divider(),
                  Text(
                    'Zabezpieczenie zasilające (${parentProtectionSlots.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (parentProtectionSlots.isEmpty)
                    const Text(
                      'Brak przypisanego zabezpieczenia w rozdzielnicy nadrzędnej.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...parentProtectionSlots.map(
                      (slot) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          title: Text(_protectionSlotTitle(slot)),
                          subtitle:
                              Text(_protectionSlotSubtitle(slot, allNodes)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (node is DistributionBoard) ...[
                    const Divider(),
                    Text(
                      'Podpięte odbiorniki i rozdzielnice (${downstreamNodes.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (downstreamNodes.isEmpty)
                      const Text(
                        'Brak podpiętych elementów podrzędnych.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...downstreamNodes.map(
                        (child) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${child.isThreePhase ? '3F' : '1F'} | ${child.powerKw.toStringAsFixed(2)} kW | In ${child.ratedCurrentA.toStringAsFixed(0)}A',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Kabel: ${child.cableCores} żył | ${child.crossSectionMm2.toStringAsFixed(1)} mm² | ${child.lengthM.toStringAsFixed(1)} m | ${child.material == ConductorMaterial.cu ? 'Cu' : 'Al'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ] else ...[
                    const Divider(),
                    Text(
                      'Obwody odbiornika (${node.circuitLines.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (node.circuitLines.isEmpty)
                      const Text(
                        'Brak przypisanych obwodów.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...node.circuitLines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${line.name} | ${line.protectionType} ${line.protectionCurrentA.toStringAsFixed(0)}A | ${line.cableLength.toStringAsFixed(1)}m | ${line.cableCrossSectionMm2.toStringAsFixed(1)}mm² ${line.cableMaterial}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                  if (node is DistributionBoard) ...[
                    const Divider(),
                    Text(
                      'Zabezpieczenia i rezerwy (${node.protectionSlots.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (node.protectionSlots.isEmpty)
                      const Text(
                        'Brak zdefiniowanych zabezpieczeń.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else ...[
                      Text(
                        'Wykorzystane (${usedSlots.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      if (usedSlots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Brak wykorzystanych zabezpieczeń.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...usedSlots.map((slot) {
                          GridNode? assignedNode;
                          for (final candidate in allNodes) {
                            if (candidate.id == slot.assignedNodeId) {
                              assignedNode = candidate;
                              break;
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _protectionSlotTitle(slot),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _protectionSlotSubtitle(slot, allNodes),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (assignedNode != null &&
                                      assignedNode.circuitLines.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Obwody przypisane:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...assignedNode.circuitLines.map(
                                      (line) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '${line.name} | ${line.protectionType} ${line.protectionCurrentA.toStringAsFixed(0)}A | ${line.cableLength.toStringAsFixed(1)}m | ${line.cableCrossSectionMm2.toStringAsFixed(1)}mm² ${line.cableMaterial}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                    ),
                                  ] else if (assignedNode != null) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Brak przypisanych obwodów.',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 6),
                      Text(
                        'Rezerwy (${reserveSlots.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      if (reserveSlots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Brak zdefiniowanych rezerw.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...reserveSlots.map(
                          (slot) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _protectionSlotTitle(slot),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _protectionSlotSubtitle(slot, allNodes),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTypeDialog(BuildContext context, GridNode parentNode) {
    final provider = Provider.of<GridProvider>(context, listen: false);
    final nodes = provider.nodes;
    final penExists = _hasPenSplitPoint(nodes);
    final downstreamOfPen = _isDownstreamOfPenSplit(
      parentNode,
      nodes,
      includeSelf: true,
    );

    showDialog<void>(
      context: context,
      builder: (context) => _AddTypeDialog(
        parentNode: parentNode,
        parentBoard: parentNode is DistributionBoard ? parentNode : null,
        penSplitAlreadyExists: penExists,
        forceFiveCoreForThreePhase: downstreamOfPen,
        onSave: (submission) async {
          final newNode = submission.node;
          if (newNode is DistributionBoard) {
            if (newNode.isPenSplitPoint && penExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Punkt podziału PEN jest już oznaczony w topologii. Sugerowane jest pozostawienie jednego punktu.',
                  ),
                ),
              );
              return false;
            }
          }

          if (downstreamOfPen &&
              newNode.isThreePhase &&
              newNode.cableCores == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Po punkcie podziału PEN dla odbioru 3-fazowego dostępny jest kabel 5-żyłowy.',
                ),
              ),
            );
            return false;
          }

          BoardProtectionSlot? reserveSlotToUse;
          if (parentNode is DistributionBoard) {
            reserveSlotToUse = await _selectCompatibleReserveSlot(
              context,
              parentNode,
              newNode,
            );
          }

          provider.addNode(newNode, parent: parentNode);

          if (parentNode is DistributionBoard) {
            if (reserveSlotToUse != null) {
              provider.updateProtectionSlot(
                parentNode,
                _assignProtectionSlotToNode(reserveSlotToUse, newNode.id),
              );
            } else if (submission.selectedProtectionSlotId != null) {
              final selectedSlot = parentNode.protectionSlots.firstWhere(
                (slot) => slot.id == submission.selectedProtectionSlotId,
              );
              provider.updateProtectionSlot(
                parentNode,
                _assignProtectionSlotToNode(selectedSlot, newNode.id),
              );
            } else if (submission.newProtectionCurrentA != null) {
              final poleCount = newNode.isThreePhase ? 3 : 1;
              final newSlot = BoardProtectionSlot(
                id: '${DateTime.now().millisecondsSinceEpoch}_auto',
                type: ProtectionDeviceType.overcurrentBreaker,
                quantity: 1,
                poleCount: poleCount,
                ratedCurrentA: submission.newProtectionCurrentA,
                isReserve: false,
                assignedNodeId: newNode.id,
              );
              provider.addProtectionSlot(parentNode, newSlot);
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reserveSlotToUse == null
                    ? 'Dodano: ${newNode.name}'
                    : 'Dodano: ${newNode.name} i wykorzystano rezerwę.',
              ),
            ),
          );
          return true;
        },
      ),
    );
  }

  BoardProtectionSlot _assignProtectionSlotToNode(
    BoardProtectionSlot slot,
    String nodeId,
  ) {
    return BoardProtectionSlot(
      id: slot.id,
      type: slot.type,
      quantity: slot.quantity,
      poleCount: slot.poleCount,
      ratedCurrentA: slot.ratedCurrentA,
      residualCurrentmA: slot.residualCurrentmA,
      fuseLinkSize: slot.fuseLinkSize,
      isReserve: false,
      assignedNodeId: nodeId,
    );
  }

  Future<BoardProtectionSlot?> _selectCompatibleReserveSlot(
    BuildContext context,
    DistributionBoard parentBoard,
    GridNode newNode,
  ) async {
    final compatibleReserves =
        _findCompatibleReserveSlots(parentBoard, newNode);

    if (compatibleReserves.isEmpty) {
      return null;
    }

    if (compatibleReserves.length == 1) {
      final candidate = compatibleReserves.first;
      final shouldUse = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Wykorzystać rezerwę?'),
          content: Text(
            'Znaleziono pasującą rezerwę: ${_protectionSlotTitle(candidate)}. Czy wykorzystać ją dla ${newNode.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nie'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tak'),
            ),
          ],
        ),
      );

      return shouldUse == true ? candidate : null;
    }

    return showDialog<BoardProtectionSlot>(
      context: context,
      builder: (dialogContext) {
        BoardProtectionSlot selectedSlot = compatibleReserves.first;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Wybierz pasującą rezerwę'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Znaleziono kilka zgodnych rezerw dla ${newNode.name}.',
                    ),
                    const SizedBox(height: 12),
                    for (final slot in compatibleReserves)
                      RadioListTile<String>(
                        value: slot.id,
                        groupValue: selectedSlot.id,
                        title: Text(_protectionSlotTitle(slot)),
                        subtitle:
                            const Text('Pozycja rezerwowa w rozdzielnicy'),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            selectedSlot = compatibleReserves.firstWhere(
                              (candidate) => candidate.id == value,
                            );
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Pomiń'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(selectedSlot),
                child: const Text('Wykorzystaj'),
              ),
            ],
          ),
        );
      },
    );
  }

  List<BoardProtectionSlot> _findCompatibleReserveSlots(
    DistributionBoard parentBoard,
    GridNode newNode,
  ) {
    final nodeIb = _calculateIb(newNode, newNode.powerKw);
    final cableEstimatedA = _estimateCableCurrentCapacity(newNode);
    final intrinsicLimitCandidates = <double>[];

    if (newNode.ratedCurrentA > 0) {
      intrinsicLimitCandidates.add(newNode.ratedCurrentA);
    }
    if (cableEstimatedA != null && cableEstimatedA > 0) {
      intrinsicLimitCandidates.add(cableEstimatedA);
    }

    final nodeLimitA = intrinsicLimitCandidates.isEmpty
        ? null
        : intrinsicLimitCandidates.reduce(min);

    return parentBoard.protectionSlots.where((slot) {
      if (!slot.isReserve) {
        return false;
      }
      if (slot.assignedNodeId != null && slot.assignedNodeId!.isNotEmpty) {
        return false;
      }
      if (slot.type == ProtectionDeviceType.residualCurrentDevice) {
        return false;
      }

      final slotCurrent = slot.ratedCurrentA;
      if (slotCurrent == null || slotCurrent <= 0) {
        return false;
      }

      if (!_isSlotPoleCompatibleWithNode(slot, newNode)) {
        return false;
      }

      if (slotCurrent < nodeIb) {
        return false;
      }

      if (nodeLimitA != null && slotCurrent > nodeLimitA) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _isSlotPoleCompatibleWithNode(
    BoardProtectionSlot slot,
    GridNode newNode,
  ) {
    if (newNode.isThreePhase) {
      return slot.poleCount >= 3;
    }

    return slot.poleCount <= 2;
  }

  void _showEditNodeDialog(BuildContext context, GridNode node) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Consumer<GridProvider>(
          builder: (context, provider, _) {
            final lines = node.circuitLines;
            final board = node is DistributionBoard ? node : null;
            final protectionSlots =
                board?.protectionSlots ?? const <BoardProtectionSlot>[];
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              title: Text('Edytuj: ${node.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Parametry węzła',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showEditNodeParametersDialog(
                                      context,
                                      provider,
                                      node,
                                    );
                                  },
                                  icon: const Icon(Icons.tune, size: 16),
                                  label: const Text('Edytuj'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Nazwa: ${node.name}'),
                            Text(
                              'Lokalizacja: ${node.location.trim().isEmpty ? '-' : node.location}',
                            ),
                            Text('Moc: ${node.powerKw.toStringAsFixed(2)} kW'),
                            Text(
                              'Kabel: ${node.cableCores} żył | ${node.crossSectionMm2.toStringAsFixed(1)} mm² | ${node.lengthM.toStringAsFixed(1)} m | ${node.material == ConductorMaterial.cu ? 'Cu' : 'Al'}',
                            ),
                            Text(
                                'In: ${node.ratedCurrentA.toStringAsFixed(0)} A'),
                            if (board != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Gniazda 230V: ${board.socketCount230V?.toString() ?? '-'} | 400V: ${board.socketCount400V?.toString() ?? '-'}',
                              ),
                              Text(
                                board.isPenSplitPoint
                                    ? 'Punkt podziału PEN: tak'
                                    : 'Punkt podziału PEN: nie',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Linie: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '(${lines.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddLineDialog(context, node);
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Dodaj'),
                          ),
                        ],
                      ),
                    ),
                    if (lines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Brak linii',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...lines.map((line) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(line.name),
                            subtitle: Text(
                              '${line.protectionType}${line.protectionCurrentA.toStringAsFixed(0)}A | ${line.cableCrossSectionMm2}mm² ${line.cableMaterial}',
                            ),
                            trailing: PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.pop(context);
                                  _showEditLineDialog(context, node, line);
                                } else if (value == 'delete') {
                                  provider.removeCircuitLine(node, line.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Usunięto linię: ${line.name}'),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edytuj'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Usuń',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    if (board != null) ...[
                      const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Dodatkowe wyposażenie rozdzielnicy',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '(${board.additionalEquipment.length})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showBoardAdditionalEquipmentDialog(
                                  context,
                                  provider,
                                  board,
                                );
                              },
                              icon: const Icon(Icons.tune, size: 16),
                              label: const Text('Edytuj'),
                            ),
                          ],
                        ),
                      ),
                      if (board.additionalEquipment.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Brak zdefiniowanego wyposażenia dodatkowego.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAdditionalEquipmentSymbols(
                            context,
                            board.additionalEquipment,
                          ),
                        ),
                      const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Zabezpieczenia i kieszenie wkładkowe',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '(${protectionSlots.length})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showProtectionSlotDialog(
                                  context,
                                  provider,
                                  board,
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Dodaj'),
                            ),
                          ],
                        ),
                      ),
                      if (protectionSlots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Brak zdefiniowanych zabezpieczeń.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...protectionSlots.map((slot) {
                          GridNode? assignedNode;
                          for (final node in provider.nodes) {
                            if (node.id == slot.assignedNodeId) {
                              assignedNode = node;
                              break;
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(_protectionSlotTitle(slot)),
                                    subtitle: Text(
                                      _protectionSlotSubtitle(
                                          slot, provider.nodes),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showProtectionSlotDialog(
                                            context,
                                            provider,
                                            board,
                                            initialSlot: slot,
                                          );
                                        } else if (value == 'delete') {
                                          provider.removeProtectionSlot(
                                              board, slot.id);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Usunięto pozycję aparatury rozdzielnicy.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 16),
                                              SizedBox(width: 8),
                                              Text('Edytuj'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Usuń',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (assignedNode != null &&
                                      assignedNode.circuitLines.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 8, 16, 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Obwody przypisane:',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          ...assignedNode.circuitLines
                                              .map((line) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          line.name,
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500),
                                                        ),
                                                        Text(
                                                          '${line.protectionType} ${line.protectionCurrentA.toStringAsFixed(0)}A | Długość: ${line.cableLength.toStringAsFixed(1)}m | Kabel: ${line.cableCrossSectionMm2.toStringAsFixed(1)}mm² ${line.cableMaterial}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                      ],
                                                    ),
                                                  )),
                                        ],
                                      ),
                                    )
                                  else if (assignedNode != null)
                                    const Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(16, 8, 16, 4),
                                      child: Text(
                                        'Brak przypisanych obwodów',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zamknij'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditLineDialog(
    BuildContext context,
    GridNode node,
    CircuitLine line,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => CircuitLineEditDialog(
        initialLine: line,
        onSave: (updatedLine) {
          final provider = Provider.of<GridProvider>(context, listen: false);
          provider.updateCircuitLine(node, updatedLine);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Zaktualizowano: ${updatedLine.name}')),
          );
        },
      ),
    );
  }

  void _showAddLineDialog(BuildContext context, GridNode node) {
    showDialog<void>(
      context: context,
      builder: (context) => CircuitLineEditDialog(
        onSave: (line) {
          final provider = Provider.of<GridProvider>(context, listen: false);
          provider.addCircuitLine(node, line);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dodano linię: ${line.name}')),
          );
        },
      ),
    );
  }

  void _showProtectionSlotDialog(
    BuildContext context,
    GridProvider provider,
    DistributionBoard board, {
    BoardProtectionSlot? initialSlot,
  }) {
    final quantityController = TextEditingController(
      text: '${initialSlot?.quantity ?? 1}',
    );
    final ratedCurrentController = TextEditingController(
      text: initialSlot?.ratedCurrentA?.toStringAsFixed(0) ?? '',
    );
    final residualCurrentController = TextEditingController(
      text: initialSlot?.residualCurrentmA?.toStringAsFixed(0) ?? '',
    );

    var selectedType =
        initialSlot?.type ?? ProtectionDeviceType.overcurrentBreaker;
    var selectedPoleCount = initialSlot?.poleCount ?? 1;
    var selectedFuseSize = initialSlot?.fuseLinkSize;
    var isReserve = initialSlot?.isReserve ?? false;
    var assignedNodeId = initialSlot?.assignedNodeId;

    final assignableNodes =
        provider.nodes.where((e) => e.id != board.id).toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              title: Text(
                initialSlot == null
                    ? 'Dodaj aparaturę rozdzielnicy'
                    : 'Edytuj aparaturę rozdzielnicy',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ProtectionDeviceType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Typ aparatu',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ProtectionDeviceType.overcurrentBreaker,
                          child: Text('Wyłącznik nadprądowy (MCB)'),
                        ),
                        DropdownMenuItem(
                          value: ProtectionDeviceType.residualCurrentDevice,
                          child: Text('Wyłącznik różnicowoprądowy (RCD)'),
                        ),
                        DropdownMenuItem(
                          value: ProtectionDeviceType.fuseHolder,
                          child: Text('Rozłącznik bezpiecznikowy'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                          final allowedPoles =
                              selectedType == ProtectionDeviceType.fuseHolder
                                  ? const [1, 3]
                                  : const [1, 2, 3, 4];
                          if (!allowedPoles.contains(selectedPoleCount)) {
                            selectedPoleCount = allowedPoles.first;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ilość aparatów',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedPoleCount,
                      decoration: const InputDecoration(
                        labelText: 'Liczba biegunów',
                      ),
                      items: (selectedType == ProtectionDeviceType.fuseHolder
                              ? const [1, 3]
                              : const [1, 2, 3, 4])
                          .map(
                            (poles) => DropdownMenuItem<int>(
                              value: poles,
                              child: Text('${poles}P'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedPoleCount = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ratedCurrentController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            selectedType == ProtectionDeviceType.fuseHolder
                                ? 'Prąd wkładki [A]'
                                : 'Prąd znamionowy [A]',
                      ),
                    ),
                    if (selectedType ==
                        ProtectionDeviceType.residualCurrentDevice) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: residualCurrentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prąd różnicowy [mA]',
                        ),
                      ),
                    ],
                    if (selectedType == ProtectionDeviceType.fuseHolder) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFuseSize,
                        decoration: const InputDecoration(
                          labelText: 'Rozmiar wkładki',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'D01', child: Text('D01')),
                          DropdownMenuItem(value: 'D02', child: Text('D02')),
                          DropdownMenuItem(value: 'NH00', child: Text('NH00')),
                          DropdownMenuItem(value: 'NH1', child: Text('NH1')),
                          DropdownMenuItem(value: 'NH2', child: Text('NH2')),
                          DropdownMenuItem(value: 'NH3', child: Text('NH3')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedFuseSize = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isReserve,
                      title: const Text('Pozycja rezerwowa'),
                      onChanged: (value) {
                        setDialogState(() {
                          isReserve = value ?? false;
                          if (isReserve) {
                            assignedNodeId = null;
                          }
                        });
                      },
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: assignedNodeId,
                      decoration: const InputDecoration(
                        labelText: 'Przypisanie urządzenia / rozdzielnicy',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Brak przypisania'),
                        ),
                        ...assignableNodes.map(
                          (node) => DropdownMenuItem<String?>(
                            value: node.id,
                            child: Text(node.name),
                          ),
                        ),
                      ],
                      onChanged: isReserve
                          ? null
                          : (value) {
                              setDialogState(() {
                                assignedNodeId = value;
                              });
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final quantity =
                        int.tryParse(quantityController.text.trim());
                    final ratedCurrent = _parsePositiveNumber(
                      ratedCurrentController.text,
                    );
                    final residualCurrent = _parsePositiveNumber(
                      residualCurrentController.text,
                    );

                    if (quantity == null || quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wprowadzone dane nie zostały zapisane (ilość musi być większa od 0).',
                          ),
                        ),
                      );
                      return;
                    }

                    if (ratedCurrent == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            selectedType == ProtectionDeviceType.fuseHolder
                                ? 'Wprowadzone dane nie zostały zapisane (brak wartości prądu wkładki).'
                                : 'Wprowadzone dane nie zostały zapisane (brak wartości prądu znamionowego).',
                          ),
                        ),
                      );
                      return;
                    }

                    if (selectedType ==
                            ProtectionDeviceType.residualCurrentDevice &&
                        residualCurrent == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wprowadzone dane nie zostały zapisane (brak wartości prądu różnicowego).',
                          ),
                        ),
                      );
                      return;
                    }

                    if (selectedType == ProtectionDeviceType.fuseHolder &&
                        (selectedFuseSize == null ||
                            selectedFuseSize!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wprowadzone dane nie zostały zapisane (brak rozmiaru wkładki).',
                          ),
                        ),
                      );
                      return;
                    }

                    final slot = BoardProtectionSlot(
                      id: initialSlot?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      type: selectedType,
                      quantity: quantity,
                      poleCount: selectedPoleCount,
                      ratedCurrentA: ratedCurrent,
                      residualCurrentmA: selectedType ==
                              ProtectionDeviceType.residualCurrentDevice
                          ? residualCurrent
                          : null,
                      fuseLinkSize:
                          selectedType == ProtectionDeviceType.fuseHolder
                              ? selectedFuseSize
                              : null,
                      isReserve: isReserve,
                      assignedNodeId: isReserve ? null : assignedNodeId,
                    );

                    if (initialSlot == null) {
                      provider.addProtectionSlot(board, slot);
                    } else {
                      provider.updateProtectionSlot(board, slot);
                    }

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Zaktualizowano konfigurację aparatury rozdzielnicy.'),
                      ),
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBoardAdditionalEquipmentDialog(
    BuildContext context,
    GridProvider provider,
    DistributionBoard board,
  ) {
    final selected = board.additionalEquipment.toSet();
    const allOptions = [
      BoardAdditionalEquipment.subMeter,
      BoardAdditionalEquipment.pwpSwitch,
      BoardAdditionalEquipment.surgeProtection,
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              title: Text('Wyposażenie: ${board.name}'),
              content: SizedBox(
                width: min(380, MediaQuery.sizeOf(dialogContext).width * 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in allOptions)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(option),
                        title: Text(_additionalEquipmentLabel(option)),
                        subtitle: Text(
                          'Symbol: ${_additionalEquipmentSymbol(option)}',
                        ),
                        secondary: Icon(_additionalEquipmentIcon(option)),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selected.add(option);
                            } else {
                              selected.remove(option);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.updateBoardAdditionalEquipment(
                      board,
                      selected.toList(),
                    );
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Zaktualizowano wyposażenie dodatkowe rozdzielnicy.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _protectionSlotTitle(BoardProtectionSlot slot) {
    final poles = ' ${slot.poleCount}P';

    switch (slot.type) {
      case ProtectionDeviceType.overcurrentBreaker:
        return 'Wyłącznik nadprądowy$poles ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A';
      case ProtectionDeviceType.residualCurrentDevice:
        return 'Wyłącznik różnicowoprądowy$poles ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A/${slot.residualCurrentmA?.toStringAsFixed(0) ?? '-'}mA';
      case ProtectionDeviceType.fuseHolder:
        return 'Rozłącznik bezpiecznikowy$poles ${slot.fuseLinkSize ?? '-'} ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A';
    }
  }

  String _protectionSlotSubtitle(
    BoardProtectionSlot slot,
    List<GridNode> allNodes,
  ) {
    GridNode? assignedNode;
    for (final node in allNodes) {
      if (node.id == slot.assignedNodeId) {
        assignedNode = node;
        break;
      }
    }

    final assignmentText = assignedNode == null
        ? 'Brak przypisania'
        : 'Przypisanie: ${assignedNode.name}';

    final modules = slot.type == ProtectionDeviceType.fuseHolder
        ? slot.quantity
        : slot.quantity * slot.poleCount;

    final polesText = slot.type == ProtectionDeviceType.fuseHolder
        ? ''
        : ' · Bieguny: ${slot.poleCount}P';

    return 'Aparaty: ${slot.quantity}$polesText · Moduły: $modules · ${slot.isReserve ? 'Rezerwa' : 'Obsadzone'} · $assignmentText';
  }

  void _showReplaceNodeDialog(BuildContext context, GridNode node) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: const Text('Zamień węzeł'),
          content:
              const Text('Funkcja zamiany węzła - implementacja w toku...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditNodeParametersDialog(
    BuildContext context,
    GridProvider provider,
    GridNode node,
  ) async {
    final nameController = TextEditingController(text: node.name);
    final locationController =
        TextEditingController(text: node.location.trim());
    final powerController = TextEditingController(
      text: node.powerKw.toStringAsFixed(2),
    );
    final lengthController = TextEditingController(
      text: node.lengthM.toStringAsFixed(1),
    );
    final crossSectionController = TextEditingController(
      text: node.crossSectionMm2.toStringAsFixed(1),
    );
    final ratedCurrentController = TextEditingController(
      text: node.ratedCurrentA.toStringAsFixed(0),
    );
    final socket230Controller = TextEditingController(
      text: node is DistributionBoard && node.socketCount230V != null
          ? node.socketCount230V.toString()
          : '',
    );
    final socket400Controller = TextEditingController(
      text: node is DistributionBoard && node.socketCount400V != null
          ? node.socketCount400V.toString()
          : '',
    );

    var selectedMaterial = node.material;
    var selectedCores = node.cableCores;
    var isThreePhaseReceiver =
        node is PowerReceiver ? node.isThreePhaseReceiver : node.isThreePhase;
    var isPenSplitPoint = node is DistributionBoard && node.isPenSplitPoint;
    final forceFiveCore =
        node.isThreePhase && _isDownstreamOfPenSplit(node, provider.nodes);

    if (forceFiveCore && selectedCores < 5) {
      selectedCores = 5;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isThreePhase =
                node is DistributionBoard ? true : isThreePhaseReceiver;
            final availableCores = isThreePhase
                ? (forceFiveCore ? const [5] : const [4, 5])
                : const [3];

            if (!availableCores.contains(selectedCores)) {
              selectedCores = availableCores.first;
            }

            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              title: Text('Parametry: ${node.name}'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nazwa'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lokalizacja (opcjonalnie)',
                          hintText: 'np. Rozdzielnia główna, sektor B',
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (node is PowerReceiver) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Odbiornik 3-fazowy'),
                          value: isThreePhaseReceiver,
                          onChanged: (value) {
                            setDialogState(() {
                              isThreePhaseReceiver = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: powerController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Moc [kW]'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ratedCurrentController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Prąd znamionowy In [A]'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: lengthController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Długość kabla [m]'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: crossSectionController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Przekrój kabla [mm²]'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<ConductorMaterial>(
                        initialValue: selectedMaterial,
                        decoration: const InputDecoration(
                            labelText: 'Materiał przewodu'),
                        items: const [
                          DropdownMenuItem(
                              value: ConductorMaterial.cu, child: Text('Cu')),
                          DropdownMenuItem(
                              value: ConductorMaterial.al, child: Text('Al')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedMaterial = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: selectedCores,
                        decoration:
                            const InputDecoration(labelText: 'Liczba żył'),
                        items: availableCores
                            .map(
                              (cores) => DropdownMenuItem<int>(
                                value: cores,
                                child: Text('${cores}-żyłowy'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCores = value;
                            });
                          }
                        },
                      ),
                      if (forceFiveCore)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Za punktem podziału PEN dla linii 3-fazowych dostępna jest konfiguracja 5-żyłowa.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (node is DistributionBoard) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: socket230Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Liczba gniazd 230V'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: socket400Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Liczba gniazd 400V'),
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Punkt podziału PEN'),
                          value: isPenSplitPoint,
                          onChanged: (value) {
                            setDialogState(() {
                              isPenSplitPoint = value ?? false;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsedPower =
                        _parsePositiveNumber(powerController.text);
                    final parsedLength =
                        _parsePositiveNumber(lengthController.text);
                    final parsedCrossSection =
                        _parsePositiveNumber(crossSectionController.text);
                    final parsedRatedCurrent =
                        _parsePositiveNumber(ratedCurrentController.text);
                    final normalizedName = nameController.text.trim();

                    if (normalizedName.isEmpty ||
                        parsedPower == null ||
                        parsedLength == null ||
                        parsedCrossSection == null ||
                        parsedRatedCurrent == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Uzupełnij poprawnie nazwę oraz wszystkie parametry liczbowe (wartości > 0).',
                          ),
                        ),
                      );
                      return;
                    }

                    if (isThreePhase && forceFiveCore && selectedCores != 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Za punktem podziału PEN dla linii 3-fazowych dostępny jest kabel 5-żyłowy.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (node is DistributionBoard &&
                        isPenSplitPoint &&
                        provider.nodes.whereType<DistributionBoard>().any(
                            (board) =>
                                board.id != node.id && board.isPenSplitPoint)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Punkt podziału PEN jest już oznaczony w innej rozdzielnicy.',
                          ),
                        ),
                      );
                      return;
                    }

                    provider.updateNodeConfiguration(
                      node,
                      name: normalizedName,
                      location: locationController.text,
                      powerKw: parsedPower,
                      lengthM: parsedLength,
                      crossSectionMm2: parsedCrossSection,
                      cableCores: selectedCores,
                      ratedCurrentA: parsedRatedCurrent,
                      material: selectedMaterial,
                      isPenSplitPoint:
                          node is DistributionBoard ? isPenSplitPoint : null,
                      socketCount230V: node is DistributionBoard
                          ? _parseOptionalNonNegativeInt(
                              socket230Controller.text)
                          : null,
                      socketCount400V: node is DistributionBoard
                          ? _parseOptionalNonNegativeInt(
                              socket400Controller.text)
                          : null,
                      isThreePhaseReceiver:
                          node is PowerReceiver ? isThreePhaseReceiver : null,
                    );

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Zaktualizowano parametry węzła: ${node.name}'),
                      ),
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    locationController.dispose();
    powerController.dispose();
    lengthController.dispose();
    crossSectionController.dispose();
    ratedCurrentController.dispose();
    socket230Controller.dispose();
    socket400Controller.dispose();
  }

  void _showDeleteConfirmDialog(BuildContext context, GridNode node) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: const Text('Usuń węzeł?'),
          content: Text(
            'Czy na pewno chcesz usunąć węzeł "${node.name}"? '
            'Wszystkie węzły podrzędne zostaną również usunięte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                final provider =
                    Provider.of<GridProvider>(context, listen: false);
                provider.removeNode(node);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Usunięto węzeł: ${node.name}')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Usuń'),
            ),
          ],
        );
      },
    );
  }

  void _showRecalculateAlert(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: const Text('Informacja'),
          content: const Text(
            'Po zmianie zasilania wcześniejsze wyniki weryfikacji pętli zwarcia mogą być nieaktualne.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }
}

class _DistributionBoardTimelineEntry {
  final int order;
  final String name;
  final String? parentName;

  const _DistributionBoardTimelineEntry({
    required this.order,
    required this.name,
    required this.parentName,
  });
}

enum _CableStateKind { nominal, warning, possibleOverload }

class _CableState {
  final _CableStateKind kind;
  final double ratio;

  const _CableState({required this.kind, required this.ratio});
}

class _ProtectionDotsSummary {
  final int occupiedCount;
  final int reserveCount;
  final int occupiedSingleCount;
  final int reserveSingleCount;
  final Map<int, int> occupiedPoleGroups;
  final Map<int, int> reservePoleGroups;
  final bool showVisualization;

  const _ProtectionDotsSummary({
    required this.occupiedCount,
    required this.reserveCount,
    required this.occupiedSingleCount,
    required this.reserveSingleCount,
    required this.occupiedPoleGroups,
    required this.reservePoleGroups,
    required this.showVisualization,
  });
}

class _NodeCurrentLimits {
  final double? nodeRatedA;
  final double? upstreamProtectionA;
  final double? cableEstimatedA;
  final double? effectiveLimitA;

  const _NodeCurrentLimits({
    required this.nodeRatedA,
    required this.upstreamProtectionA,
    required this.cableEstimatedA,
    required this.effectiveLimitA,
  });
}

enum _ObservationLevel { info, warning }

enum _NodeQualityStatus { ok, warning, incomplete }

class _TopologyObservation {
  final _ObservationLevel level;
  final String message;

  const _TopologyObservation({
    required this.level,
    required this.message,
  });
}

class _DevicePreset {
  final String id;
  final String name;
  final double powerKw;
  final double lengthM;
  final double crossSectionMm2;
  final double ratedCurrentA;
  final int cableCores;
  final bool isThreePhase;

  const _DevicePreset({
    required this.id,
    required this.name,
    required this.powerKw,
    required this.lengthM,
    required this.crossSectionMm2,
    required this.ratedCurrentA,
    required this.cableCores,
    required this.isThreePhase,
  });
}

class _AddTypeDialog extends StatefulWidget {
  final GridNode parentNode;
  final DistributionBoard? parentBoard;
  final bool penSplitAlreadyExists;
  final bool forceFiveCoreForThreePhase;
  final Future<bool> Function(_AddNodeSubmission) onSave;

  const _AddTypeDialog({
    required this.parentNode,
    required this.parentBoard,
    required this.penSplitAlreadyExists,
    required this.forceFiveCoreForThreePhase,
    required this.onSave,
  });

  @override
  State<_AddTypeDialog> createState() => _AddTypeDialogState();
}

class _AddTypeDialogState extends State<_AddTypeDialog> {
  String _selectedType = 'odbiornik'; // odbiornik, rozdzielnica
  String _selectedBoardKind = 'rb'; // rg, rb, ro
  String _selectedDevicePresetId = 'custom';
  bool _isDeviceThreePhase = false;
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _powerController;
  late TextEditingController _lengthController;
  late TextEditingController _crossSectionController;
  late TextEditingController _ratedCurrentController;
  late TextEditingController _newProtectionCurrentController;
  late TextEditingController _socket230CountController;
  late TextEditingController _socket400CountController;
  int _selectedCableCores = 3;
  ConductorMaterial? _selectedMaterial;
  bool _isPenSplitPoint = false;
  String _selectedProtectionSource = 'existing';
  String? _selectedProtectionSlotId;

  static const List<_DevicePreset> _devicePresets = [
    _DevicePreset(
      id: 'lighting_site',
      name: 'Oświetlenie placu budowy',
      powerKw: 1.5,
      lengthM: 30,
      crossSectionMm2: 1.5,
      ratedCurrentA: 10,
      cableCores: 3,
      isThreePhase: false,
    ),
    _DevicePreset(
      id: 'sockets_230',
      name: 'Obwód gniazd 230V',
      powerKw: 3.5,
      lengthM: 25,
      crossSectionMm2: 2.5,
      ratedCurrentA: 16,
      cableCores: 3,
      isThreePhase: false,
    ),
    _DevicePreset(
      id: 'tool_container',
      name: 'Kontener narzędziowy',
      powerKw: 5.0,
      lengthM: 35,
      crossSectionMm2: 4,
      ratedCurrentA: 25,
      cableCores: 3,
      isThreePhase: false,
    ),
    _DevicePreset(
      id: 'mixer_3f',
      name: 'Betoniarka 3F',
      powerKw: 4.0,
      lengthM: 20,
      crossSectionMm2: 4,
      ratedCurrentA: 16,
      cableCores: 4,
      isThreePhase: true,
    ),
    _DevicePreset(
      id: 'pump_3f',
      name: 'Pompa odwodnieniowa 3F',
      powerKw: 5.5,
      lengthM: 30,
      crossSectionMm2: 6,
      ratedCurrentA: 20,
      cableCores: 4,
      isThreePhase: true,
    ),
    _DevicePreset(
      id: 'welder_3f',
      name: 'Spawarka 3F',
      powerKw: 8.0,
      lengthM: 25,
      crossSectionMm2: 6,
      ratedCurrentA: 32,
      cableCores: 4,
      isThreePhase: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _powerController = TextEditingController(text: '5');
    _lengthController = TextEditingController(text: '25');
    _crossSectionController = TextEditingController(text: '1.5');
    _ratedCurrentController = TextEditingController(text: '10');
    _newProtectionCurrentController = TextEditingController(text: '16');
    _socket230CountController = TextEditingController();
    _socket400CountController = TextEditingController();

    for (final controller in [
      _nameController,
      _locationController,
      _powerController,
      _lengthController,
      _crossSectionController,
      _ratedCurrentController,
      _newProtectionCurrentController,
      _socket230CountController,
      _socket400CountController,
    ]) {
      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }

    final availableSlots = _availableAssignableProtectionSlots;
    if (availableSlots.isEmpty) {
      _selectedProtectionSource = 'new';
    } else {
      _selectedProtectionSource = 'existing';
      // Nie ustawiaj automatycznie - user musi wybrać
      _selectedProtectionSlotId = null;
    }

    _applyDevicePreset(null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _powerController.dispose();
    _lengthController.dispose();
    _crossSectionController.dispose();
    _ratedCurrentController.dispose();
    _newProtectionCurrentController.dispose();
    _socket230CountController.dispose();
    _socket400CountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dodaj nowy element',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                // Type Selection
                Wrap(
                  spacing: 8,
                  children: [
                    _typeButton('Odbiornik', 'odbiornik'),
                    _typeButton('Rozdzielnica', 'rozdzielnica'),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nazwa',
                    hintText: _nameHint,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokalizacja (opcjonalnie)',
                    hintText: 'np. Segment C, parter',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                if (_selectedType == 'rozdzielnica') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBoardKind,
                    decoration: const InputDecoration(
                      labelText: 'Typ rozdzielnicy',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'rg',
                        child: Text('RG — rozdzielnica główna'),
                      ),
                      DropdownMenuItem(
                        value: 'rb',
                        child: Text('RB — rozdzielnica budowlana'),
                      ),
                      DropdownMenuItem(
                        value: 'ro',
                        child: Text('RO — rozdzielnica odbiorcza'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedBoardKind = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _socket230CountController,
                          decoration: const InputDecoration(
                            labelText: 'Gniazda 230V (opcjonalnie)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _socket400CountController,
                          decoration: const InputDecoration(
                            labelText: 'Gniazda 400V (opcjonalnie)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                if (_selectedType == 'odbiornik') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDevicePresetId,
                    decoration: const InputDecoration(
                      labelText: 'Najczęściej podłączane urządzenia',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'custom',
                        child: Text('Własna konfiguracja'),
                      ),
                      ..._devicePresets.map(
                        (preset) => DropdownMenuItem<String>(
                          value: preset.id,
                          child: Text(preset.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDevicePresetId = value;
                          _applyDevicePreset(
                            value == 'custom'
                                ? null
                                : _devicePresets.firstWhere(
                                    (preset) => preset.id == value,
                                  ),
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool>(
                    initialValue: _isDeviceThreePhase,
                    decoration: const InputDecoration(
                      labelText: 'Zasilanie',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text('1-fazowe (1F)'),
                      ),
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text('3-fazowe (3F)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _isDeviceThreePhase = value;
                        if (_isDeviceThreePhase) {
                          _selectedCableCores =
                              widget.forceFiveCoreForThreePhase ? 5 : 4;
                        } else {
                          _selectedCableCores = 3;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Power and Length (for non-line types)
                if (_selectedType != 'linia') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _powerController,
                          decoration: const InputDecoration(
                            labelText: 'Moc (kW)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lengthController,
                          decoration: const InputDecoration(
                            labelText: 'Długość (m)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _crossSectionController,
                          decoration: const InputDecoration(
                            labelText: 'Przekrój (mm²)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ratedCurrentController,
                          decoration: const InputDecoration(
                            labelText: 'In (A)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCableCores,
                    decoration: const InputDecoration(
                      labelText: 'Liczba żył kabla',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableCores
                        .map(
                          (cores) => DropdownMenuItem<int>(
                            value: cores,
                            child: Text('$cores-żyłowy'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCableCores = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ConductorMaterial>(
                    initialValue: _selectedMaterial,
                    decoration: const InputDecoration(
                      labelText: 'Materiał żyły kabla',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ConductorMaterial.cu,
                        child: Text('Cu'),
                      ),
                      DropdownMenuItem(
                        value: ConductorMaterial.al,
                        child: Text('Al'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMaterial = value;
                      });
                    },
                  ),
                  if (_selectedType == 'rozdzielnica' &&
                      widget.forceFiveCoreForThreePhase)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Po punkcie podziału PEN dla rozdzielnicy 3-fazowej dostępny jest kabel 5-żyłowy.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (widget.parentBoard != null) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProtectionSource,
                      decoration: const InputDecoration(
                        labelText: 'Zabezpieczenie w rozdzielnicy nadrzędnej',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'existing',
                          child: Text('Wybierz istniejące zabezpieczenie'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'new',
                          child: Text('Utwórz nowe zabezpieczenie'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedProtectionSource = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_selectedProtectionSource == 'existing') ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProtectionSlotId,
                        decoration: const InputDecoration(
                          labelText: 'Wybór zabezpieczenia',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableAssignableProtectionSlots
                            .map(
                              (slot) => DropdownMenuItem<String>(
                                value: slot.id,
                                child: Text(_protectionSlotTitle(slot)),
                              ),
                            )
                            .toList(),
                        onChanged: _availableAssignableProtectionSlots.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedProtectionSlotId = value;
                                });
                              },
                      ),
                      if (_availableAssignableProtectionSlots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Brak wolnych zabezpieczeń do przypisania. Wybierz opcję utworzenia nowego.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (_selectedProtectionSource == 'new') ...[
                      TextField(
                        controller: _newProtectionCurrentController,
                        decoration: const InputDecoration(
                          labelText: 'Prąd nowego zabezpieczenia [A]',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (_selectedType == 'rozdzielnica')
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isPenSplitPoint,
                      title: const Text('Punkt podziału PEN + uziemienie'),
                      subtitle: widget.penSplitAlreadyExists
                          ? const Text(
                              'W topologii oznaczono już punkt podziału PEN.',
                            )
                          : const Text(
                              'Oznacz rozdzielnicę jako punkt podziału PEN.',
                            ),
                      onChanged: widget.penSplitAlreadyExists
                          ? null
                          : (value) {
                              setState(() {
                                _isPenSplitPoint = value ?? false;
                              });
                            },
                    ),
                ],

                const SizedBox(height: 16),

                if (!_canSubmit && _submitDisabledReason != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _submitDisabledReason!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orangeAccent,
                            ),
                      ),
                    ),
                  ),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: !_canSubmit
                          ? null
                          : () async {
                              if (_selectedType != 'rozdzielnica' &&
                                  _nameController.text.trim().isEmpty) {
                                return;
                              }

                              final parsedPower = _parsePositiveNumber(
                                _powerController.text,
                              );
                              final parsedLength = _parsePositiveNumber(
                                _lengthController.text,
                              );
                              final parsedCrossSection = _parsePositiveNumber(
                                _crossSectionController.text,
                              );
                              final parsedRatedCurrent = _parsePositiveNumber(
                                _ratedCurrentController.text,
                              );

                              if (_selectedType != 'linia' &&
                                  (parsedPower == null ||
                                      parsedLength == null ||
                                      parsedCrossSection == null ||
                                      parsedRatedCurrent == null)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Uzupełnij poprawnie parametry kabla i węzła (wartości > 0).',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final requiresParentProtection =
                                  widget.parentBoard != null &&
                                      _selectedType != 'linia';

                              if (requiresParentProtection) {
                                if (_selectedProtectionSource == 'existing') {
                                  if (_availableAssignableProtectionSlots
                                          .isEmpty ||
                                      _selectedProtectionSlotId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Wybierz zabezpieczenie lub utwórz nowe w rozdzielnicy nadrzędnej.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                } else {
                                  final newProtectionCurrent =
                                      _parsePositiveNumber(
                                    _newProtectionCurrentController.text,
                                  );
                                  if (newProtectionCurrent == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Podaj poprawny prąd nowego zabezpieczenia (wartość > 0).',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }
                              }

                              GridNode newNode;
                              final id = DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();

                              if (_selectedType == 'odbiornik') {
                                newNode = PowerReceiver(
                                  id: id,
                                  name: _nameController.text.trim(),
                                  location: _locationController.text.trim(),
                                  powerKw: parsedPower ?? 5,
                                  lengthM: parsedLength ?? 25,
                                  crossSectionMm2: parsedCrossSection ?? 1.5,
                                  cableCores: _selectedCableCores,
                                  ratedCurrentA: parsedRatedCurrent ?? 10,
                                  material: _selectedMaterial!,
                                  isThreePhaseReceiver: _isDeviceThreePhase,
                                );
                              } else {
                                final defaultName = _defaultBoardName;
                                final boardName =
                                    _nameController.text.trim().isEmpty
                                        ? defaultName
                                        : _nameController.text.trim();
                                newNode = DistributionBoard(
                                  id: id,
                                  name: boardName,
                                  location: _locationController.text.trim(),
                                  powerKw: parsedPower ?? 5,
                                  lengthM: parsedLength ?? 25,
                                  crossSectionMm2: parsedCrossSection ?? 1.5,
                                  cableCores: _selectedCableCores,
                                  ratedCurrentA: parsedRatedCurrent ?? 10,
                                  material: _selectedMaterial!,
                                  isPenSplitPoint: _isPenSplitPoint,
                                  socketCount230V: _parseOptionalNonNegativeInt(
                                    _socket230CountController.text,
                                  ),
                                  socketCount400V: _parseOptionalNonNegativeInt(
                                    _socket400CountController.text,
                                  ),
                                );
                              }

                              final submission = _AddNodeSubmission(
                                node: newNode,
                                selectedProtectionSlotId:
                                    requiresParentProtection &&
                                            _selectedProtectionSource ==
                                                'existing'
                                        ? _selectedProtectionSlotId
                                        : null,
                                newProtectionCurrentA:
                                    requiresParentProtection &&
                                            _selectedProtectionSource == 'new'
                                        ? _parsePositiveNumber(
                                            _newProtectionCurrentController
                                                .text,
                                          )
                                        : null,
                              );

                              final didSave = await widget.onSave(submission);
                              if (didSave && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridTheme.electricYellow,
                        foregroundColor: GridTheme.deepNavy,
                      ),
                      child: const Text('Dodaj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label, String type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = type;
          if (_selectedType == 'rozdzielnica') {
            _selectedCableCores = widget.forceFiveCoreForThreePhase ? 5 : 4;
            _selectedBoardKind = 'rb';
            _selectedDevicePresetId = 'custom';
            _isDeviceThreePhase = true;
          } else {
            if (_selectedType == 'odbiornik') {
              _applyDevicePreset(null);
            } else {
              _selectedCableCores = 3;
              _selectedDevicePresetId = 'custom';
              _isDeviceThreePhase = false;
              _isPenSplitPoint = false;
            }
          }
        });
      },
      backgroundColor:
          isSelected ? GridTheme.electricYellow : Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? GridTheme.deepNavy : Colors.white,
      ),
    );
  }

  List<int> get _availableCores {
    if (_selectedType == 'rozdzielnica') {
      return widget.forceFiveCoreForThreePhase ? [5] : [4, 5];
    }
    if (_selectedType == 'odbiornik') {
      if (_isDeviceThreePhase) {
        return widget.forceFiveCoreForThreePhase ? [5] : [4, 5];
      }
      return [3];
    }
    return [3, 4, 5];
  }

  List<BoardProtectionSlot> get _availableAssignableProtectionSlots {
    final parentBoard = widget.parentBoard;
    if (parentBoard == null) {
      return const [];
    }

    return parentBoard.protectionSlots
        .where(
          (slot) =>
              !slot.isReserve &&
              (slot.assignedNodeId == null || slot.assignedNodeId!.isEmpty),
        )
        .toList();
  }

  String _protectionSlotTitle(BoardProtectionSlot slot) {
    final poles = ' ${slot.poleCount}P';

    switch (slot.type) {
      case ProtectionDeviceType.overcurrentBreaker:
        return 'Wyłącznik nadprądowy$poles ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A';
      case ProtectionDeviceType.residualCurrentDevice:
        return 'Wyłącznik różnicowoprądowy$poles ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A/${slot.residualCurrentmA?.toStringAsFixed(0) ?? '-'}mA';
      case ProtectionDeviceType.fuseHolder:
        return 'Rozłącznik bezpiecznikowy$poles ${slot.fuseLinkSize ?? '-'} ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A';
    }
  }

  bool get _canSubmit {
    if (_selectedType != 'rozdzielnica' &&
        _nameController.text.trim().isEmpty) {
      return false;
    }

    if (_selectedType != 'linia') {
      final parsedPower = _parsePositiveNumber(_powerController.text);
      final parsedLength = _parsePositiveNumber(_lengthController.text);
      final parsedCrossSection =
          _parsePositiveNumber(_crossSectionController.text);
      final parsedRatedCurrent =
          _parsePositiveNumber(_ratedCurrentController.text);

      if (parsedPower == null ||
          parsedLength == null ||
          parsedCrossSection == null ||
          parsedRatedCurrent == null) {
        return false;
      }

      if (_selectedMaterial == null) {
        return false;
      }
    }

    final requiresParentProtection =
        widget.parentBoard != null && _selectedType != 'linia';

    if (!requiresParentProtection) {
      return true;
    }

    if (_selectedProtectionSource == 'existing') {
      if (_availableAssignableProtectionSlots.isEmpty ||
          _selectedProtectionSlotId == null) {
        return false;
      }
      return _availableAssignableProtectionSlots.any(
        (slot) => slot.id == _selectedProtectionSlotId,
      );
    }

    return _parsePositiveNumber(_newProtectionCurrentController.text) != null;
  }

  String? get _submitDisabledReason {
    if (_selectedType != 'rozdzielnica' &&
        _nameController.text.trim().isEmpty) {
      return 'Proszę uzupełnić rubrykę: Nazwa.';
    }

    if (_selectedType != 'linia') {
      final parsedPower = _parsePositiveNumber(_powerController.text);
      if (parsedPower == null) {
        return 'Proszę uzupełnić rubrykę: Moc [kW] (wartość > 0).';
      }

      final parsedLength = _parsePositiveNumber(_lengthController.text);
      if (parsedLength == null) {
        return 'Proszę uzupełnić rubrykę: Długość (m) (wartość > 0).';
      }

      final parsedCrossSection =
          _parsePositiveNumber(_crossSectionController.text);
      if (parsedCrossSection == null) {
        return 'Proszę uzupełnić rubrykę: Przekrój (mm²) (wartość > 0).';
      }

      final parsedRatedCurrent =
          _parsePositiveNumber(_ratedCurrentController.text);
      if (parsedRatedCurrent == null) {
        return 'Proszę uzupełnić rubrykę: In (A) (wartość > 0).';
      }

      if (_selectedMaterial == null) {
        return 'Proszę uzupełnić rubrykę: Materiał żyły kabla.';
      }
    }

    final requiresParentProtection =
        widget.parentBoard != null && _selectedType != 'linia';

    if (!requiresParentProtection) {
      return null;
    }

    if (_selectedProtectionSource == 'existing') {
      if (_availableAssignableProtectionSlots.isEmpty) {
        return 'Brak wolnych zabezpieczeń. Wybierz opcję: Utwórz nowe zabezpieczenie.';
      }
      if (_selectedProtectionSlotId == null) {
        return 'Proszę uzupełnić rubrykę: Wybór zabezpieczenia.';
      }
      final exists = _availableAssignableProtectionSlots.any(
        (slot) => slot.id == _selectedProtectionSlotId,
      );
      if (!exists) {
        return 'Wybrane zabezpieczenie jest niedostępne. Wybierz je ponownie.';
      }
      return null;
    }

    if (_parsePositiveNumber(_newProtectionCurrentController.text) == null) {
      return 'Proszę uzupełnić rubrykę: Prąd nowego zabezpieczenia [A] (wartość > 0).';
    }

    return null;
  }

  double? _parsePositiveNumber(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  int? _parseOptionalNonNegativeInt(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return null;
    }

    return parsed;
  }

  String get _defaultBoardName {
    switch (_selectedBoardKind) {
      case 'rg':
        return 'RG';
      case 'ro':
        return 'RO-1';
      case 'rb':
      default:
        return 'RB-1';
    }
  }

  String get _nameHint {
    switch (_selectedType) {
      case 'rozdzielnica':
        return 'np. RG, RB-1, RO-2';
      case 'odbiornik':
      default:
        return 'np. Betoniarka 3F, Gniazda kontenera';
    }
  }

  void _applyDevicePreset(_DevicePreset? preset) {
    if (preset == null) {
      _selectedDevicePresetId = 'custom';
      _isDeviceThreePhase = false;
      _powerController.text = '3.5';
      _lengthController.text = '25';
      _crossSectionController.text = '2.5';
      _ratedCurrentController.text = '16';
      _selectedCableCores = 3;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = 'Odbiornik';
      }
      return;
    }

    _selectedDevicePresetId = preset.id;
    _isDeviceThreePhase = preset.isThreePhase;
    _nameController.text = preset.name;
    _powerController.text = preset.powerKw.toStringAsFixed(1);
    _lengthController.text = preset.lengthM.toStringAsFixed(0);
    _crossSectionController.text = preset.crossSectionMm2.toStringAsFixed(1);
    _ratedCurrentController.text = preset.ratedCurrentA.toStringAsFixed(0);
    _selectedCableCores =
        (_isDeviceThreePhase && widget.forceFiveCoreForThreePhase)
            ? 5
            : preset.cableCores;
  }
}

class _AddNodeSubmission {
  final GridNode node;
  final String? selectedProtectionSlotId;
  final double? newProtectionCurrentA;

  const _AddNodeSubmission({
    required this.node,
    required this.selectedProtectionSlotId,
    required this.newProtectionCurrentA,
  });
}
