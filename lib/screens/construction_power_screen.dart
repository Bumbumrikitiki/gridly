import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/models/circuit_line.dart';
import 'package:gridly/services/grid_provider.dart';
import 'package:gridly/services/technical_label_guard.dart';
import 'package:gridly/theme/grid_theme.dart';
import 'package:gridly/widgets/circuit_line_edit_dialog.dart';

class ConstructionPowerScreen extends StatefulWidget {
  const ConstructionPowerScreen({super.key});

  @override
  State<ConstructionPowerScreen> createState() => _ConstructionPowerScreenState();
}

class _ConstructionPowerScreenState extends State<ConstructionPowerScreen> {
  bool _hidePowerReceivers = false;
  bool _showOnlyWarningObservations = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GridProvider>(
          builder: (context, provider, _) {
            final buildingName = provider.buildingName.isEmpty
                ? 'nie podano'
                : provider.buildingName;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Struktura rozdzielnic'),
                Text(
                  'Budowa: $buildingName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () => _showBuildingNameDialog(context),
            tooltip: 'Edytuj nazwę budowy',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNodeDialog(context),
            tooltip: 'Dodaj węzeł',
          ),
        ],
      ),
      body: Consumer<GridProvider>(
        builder: (context, provider, _) {
          final allNodes = provider.nodes;
          final observations = _collectConnectionObservations(allNodes);
          final nodes = _hidePowerReceivers
              ? allNodes.whereType<DistributionBoard>().toList()
              : allNodes;
          final visibleNodeIds = nodes.map((node) => node.id).toSet();
          final childrenById = <String?, List<GridNode>>{};

          for (final node in nodes) {
            final parentId =
                visibleNodeIds.contains(node.parentId) ? node.parentId : null;
            childrenById.putIfAbsent(parentId, () => []);
            childrenById[parentId]!.add(node);
          }

          for (final childList in childrenById.values) {
            childList.sort((a, b) => a.name.compareTo(b.name));
          }

          final roots = childrenById[null] ?? [];

          if (allNodes.isEmpty) {
            return const Center(child: Text('No nodes available.'));
          }

          if (nodes.isEmpty) {
            return Center(
              child: Text(
                'Brak widocznych węzłów po zastosowaniu filtra.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDistributionBoardTimeline(context, allNodes),
                  if (observations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildObservationsCard(context, observations),
                  ],
                  const SizedBox(height: 12),
                  _buildRootDropTarget(context, provider),
                  const SizedBox(height: 12),
                  for (final node in roots)
                    _buildNode(context, provider, node, childrenById, depth: 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBuildingNameDialog(BuildContext context) async {
    final provider = context.read<GridProvider>();
    final controller = TextEditingController(text: provider.buildingName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nazwa budowy'),
          content: TextField(
            controller: controller,
            autofocus: true,
            inputFormatters: TechnicalLabelGuard.inputFormatters(),
            decoration: const InputDecoration(
              labelText: 'Nazwa techniczna budowy',
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
              'Struktura rozdzielnic',
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

  Widget _buildRootDropTarget(BuildContext context, GridProvider provider) {
    return DragTarget<GridNode>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        // Opóźnij aktualizację do po zakończeniu bieżącej fazy budowania
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.updateNodeParent(details.data, null);
          _showRecalculateAlert(context);
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return SizedBox(
          width: 300,
          height: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'Main supply',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(
    BuildContext context,
    GridProvider provider,
    GridNode node,
    Map<String?, List<GridNode>> childrenById, {
    required int depth,
  }) {
    final children = childrenById[node.id] ?? const [];
    final powerKw = provider.aggregatePowerKw[node];
    final actualPowerKw = powerKw ?? node.powerKw;
    final ib = _calculateIb(node, actualPowerKw);
    final loadRatio = node.ratedCurrentA == 0 ? 0.0 : ib / node.ratedCurrentA;
    final progressColor = _loadColor(loadRatio, context);

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, bottom: 12),
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
                    progressColor,
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
                    progressColor,
                    isDragging: true,
                  ),
                ),
                child: _buildTile(
                  context,
                  node,
                  ib,
                  loadRatio,
                  progressColor,
                  isHighlighted: candidateData.isNotEmpty,
                ),
              );
            },
          ),
          if (children.isNotEmpty)
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
    final stateColor = _cableStateColor(context, cableState.kind);
    final caption =
        '${child.lengthM.toStringAsFixed(0)} m · ${child.crossSectionMm2.toStringAsFixed(1)} mm² · ${child.cableCores} żył · ${GridNode.materialToString(child.material)}';

    return Padding(
      padding: EdgeInsets.only(
        left: depth * 16.0,
        right: 8,
        bottom: 8,
      ),
      child: SizedBox(
        width: 300,
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

  void _showEditCableDialog(
    BuildContext context,
    GridProvider provider,
    DistributionBoard parent,
    DistributionBoard child,
  ) {
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

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Kabel: ${parent.name} → ${child.name}'),
              content: Column(
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
                    decoration: const InputDecoration(labelText: 'Materiał'),
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
                    decoration: const InputDecoration(labelText: 'Liczba żył'),
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
  }

  double? _parsePositiveNumber(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
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

  Widget _buildTile(
    BuildContext context,
    GridNode node,
    double ib,
    double loadRatio,
    Color progressColor, {
    bool isHighlighted = false,
    bool isDragging = false,
  }) {
    final protectionSummary =
        node is DistributionBoard ? _getProtectionDotsSummary(node) : null;
    final additionalEquipment = node is DistributionBoard
        ? node.additionalEquipment
        : const <BoardAdditionalEquipment>[];

    return SizedBox(
      width: 300,
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
                          Text(
                            'Ib ${ib.toStringAsFixed(1)}A · ${node.cableCores} żył',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
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

  double _calculateIb(GridNode node, double powerKw) {
    if (node.isThreePhase) {
      return (powerKw * 1000) / (sqrt(3) * 400);
    }

    return (powerKw * 1000) / 230;
  }

  void _showAddNodeDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dodaj nowy element'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Nazwa (np. Gniazdko 400V)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final provider =
                      Provider.of<GridProvider>(context, listen: false);
                  final newNode = DistributionBoard(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    powerKw: 10,
                    lengthM: 50,
                    crossSectionMm2: 2.5,
                    ratedCurrentA: 16,
                    material: ConductorMaterial.cu,
                  );
                  provider.addNode(newNode);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dodano: ${newNode.name}')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  void _handleNodeAction(BuildContext context, GridNode node, String action) {
    switch (action) {
      case 'add':
        _showAddTypeDialog(context, node);
        break;
      case 'edit':
        _showEditNodeDialog(context, node);
        break;
      case 'replace':
        _showReplaceNodeDialog(context, node);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, node);
        break;
    }
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
        penSplitAlreadyExists: penExists,
        forceFiveCoreForThreePhase: downstreamOfPen,
        onSave: (newNode) {
          if (newNode is DistributionBoard) {
            if (newNode.isPenSplitPoint && penExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Punkt podziału PEN jest już oznaczony w topologii. Sugerowane jest pozostawienie jednego punktu.',
                  ),
                ),
              );
              return;
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
            return;
          }

          provider.addNode(newNode, parent: parentNode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dodano: ${newNode.name}')),
          );
        },
      ),
    );
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
              title: Text('Edytuj: ${node.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(_protectionSlotTitle(slot)),
                              subtitle: Text(
                                _protectionSlotSubtitle(slot, provider.nodes),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
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
                          child: Text('Kieszeń wkładki bezpiecznikowej'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                          if (selectedType == ProtectionDeviceType.fuseHolder) {
                            selectedPoleCount = 1;
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
                    if (selectedType != ProtectionDeviceType.fuseHolder) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: selectedPoleCount,
                        decoration: const InputDecoration(
                          labelText: 'Liczba biegunów',
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1P')),
                          DropdownMenuItem(value: 2, child: Text('2P')),
                          DropdownMenuItem(value: 3, child: Text('3P')),
                          DropdownMenuItem(value: 4, child: Text('4P')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            selectedPoleCount = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (selectedType != ProtectionDeviceType.fuseHolder)
                      TextField(
                        controller: ratedCurrentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prąd znamionowy [A]',
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

                    if (selectedType != ProtectionDeviceType.fuseHolder &&
                        ratedCurrent == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wprowadzone dane nie zostały zapisane (brak wartości prądu znamionowego).',
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
                      poleCount: selectedType == ProtectionDeviceType.fuseHolder
                          ? 1
                          : selectedPoleCount,
                      ratedCurrentA:
                          selectedType == ProtectionDeviceType.fuseHolder
                              ? null
                              : ratedCurrent,
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
              title: Text('Wyposażenie: ${board.name}'),
              content: SizedBox(
                width: 380,
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
    final poles = slot.type == ProtectionDeviceType.fuseHolder
        ? ''
        : ' ${slot.poleCount}P';

    switch (slot.type) {
      case ProtectionDeviceType.overcurrentBreaker:
        return 'Wyłącznik nadprądowy$poles ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A';
      case ProtectionDeviceType.residualCurrentDevice:
        return 'Wyłącznik różnicowoprądowy$poles ${slot.ratedCurrentA?.toStringAsFixed(0) ?? '-'}A/${slot.residualCurrentmA?.toStringAsFixed(0) ?? '-'}mA';
      case ProtectionDeviceType.fuseHolder:
        return 'Kieszeń wkładki bezpiecznikowej ${slot.fuseLinkSize ?? '-'}';
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

  void _showDeleteConfirmDialog(BuildContext context, GridNode node) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
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

enum _ObservationLevel { info, warning }

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
  final bool penSplitAlreadyExists;
  final bool forceFiveCoreForThreePhase;
  final Function(GridNode) onSave;

  const _AddTypeDialog({
    required this.parentNode,
    required this.penSplitAlreadyExists,
    required this.forceFiveCoreForThreePhase,
    required this.onSave,
  });

  @override
  State<_AddTypeDialog> createState() => _AddTypeDialogState();
}

class _AddTypeDialogState extends State<_AddTypeDialog> {
  String _selectedType = 'odbiornik'; // odbiornik, rozdzielnica, zkp, linia
  String _selectedBoardKind = 'rb'; // rg, rb, ro
  String _selectedDevicePresetId = 'custom';
  bool _isDeviceThreePhase = false;
  late TextEditingController _nameController;
  late TextEditingController _powerController;
  late TextEditingController _lengthController;
  late TextEditingController _crossSectionController;
  late TextEditingController _ratedCurrentController;
  int _selectedCableCores = 3;
  bool _isPenSplitPoint = false;

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
    _powerController = TextEditingController(text: '5');
    _lengthController = TextEditingController(text: '25');
    _crossSectionController = TextEditingController(text: '1.5');
    _ratedCurrentController = TextEditingController(text: '10');
    _applyDevicePreset(null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _powerController.dispose();
    _lengthController.dispose();
    _crossSectionController.dispose();
    _ratedCurrentController.dispose();
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
                    _typeButton('ZKP', 'zkp'),
                    _typeButton('Linia/obwód', 'linia'),
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

                // Line-specific fields
                if (_selectedType == 'linia') ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Typ zabezpieczenia',
                      hintText: 'A, B, C, D',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 16),

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
                      onPressed: () {
                        if (_selectedType != 'rozdzielnica' &&
                            _nameController.text.trim().isEmpty) {
                          return;
                        }

                        GridNode newNode;
                        final id =
                            DateTime.now().millisecondsSinceEpoch.toString();

                        if (_selectedType == 'odbiornik' ||
                            _selectedType == 'zkp') {
                          newNode = PowerReceiver(
                            id: id,
                            name: _nameController.text.trim(),
                            powerKw:
                                double.tryParse(_powerController.text) ?? 5,
                            lengthM:
                                double.tryParse(_lengthController.text) ?? 25,
                            crossSectionMm2:
                                double.tryParse(_crossSectionController.text) ??
                                    1.5,
                            cableCores: _selectedCableCores,
                            ratedCurrentA:
                                double.tryParse(_ratedCurrentController.text) ??
                                    10,
                            material: ConductorMaterial.cu,
                            isThreePhaseReceiver: _selectedType == 'odbiornik'
                                ? _isDeviceThreePhase
                                : false,
                          );
                        } else {
                          final defaultName = _defaultBoardName;
                          final boardName = _nameController.text.trim().isEmpty
                              ? defaultName
                              : _nameController.text.trim();
                          newNode = DistributionBoard(
                            id: id,
                            name: boardName,
                            powerKw:
                                double.tryParse(_powerController.text) ?? 5,
                            lengthM:
                                double.tryParse(_lengthController.text) ?? 25,
                            crossSectionMm2:
                                double.tryParse(_crossSectionController.text) ??
                                    1.5,
                            cableCores: _selectedCableCores,
                            ratedCurrentA:
                                double.tryParse(_ratedCurrentController.text) ??
                                    10,
                            material: ConductorMaterial.cu,
                            isPenSplitPoint: _isPenSplitPoint,
                          );
                        }

                        widget.onSave(newNode);
                        Navigator.pop(context);
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
    if (_selectedType == 'linia') {
      return [3, 4, 5];
    }
    if (_selectedType == 'odbiornik') {
      if (_isDeviceThreePhase) {
        return widget.forceFiveCoreForThreePhase ? [5] : [4, 5];
      }
      return [3];
    }
    return [3, 4, 5];
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
      case 'zkp':
        return 'np. ZKP-1';
      case 'linia':
        return 'np. Linia L1';
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
