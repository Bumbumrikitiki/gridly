import 'package:gridly/multitool/project_manager/models/project_models.dart';

class ProjectAreaChecklistTemplate {
  final String id;
  final String title;
  final String description;

  const ProjectAreaChecklistTemplate({
    required this.id,
    required this.title,
    required this.description,
  });
}

class ProjectAreaInfoItem {
  final String label;
  final String value;

  const ProjectAreaInfoItem({
    required this.label,
    required this.value,
  });
}

class ProjectAreaDefinition {
  final String id;
  final ProjectAreaType type;
  final String title;
  final String subtitle;
  final List<ProjectAreaInfoItem> infoItems;
  final List<ProjectAreaChecklistTemplate> checklist;

  const ProjectAreaDefinition({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.infoItems,
    required this.checklist,
  });
}

class ProjectAreaCatalog {
  static List<ProjectAreaDefinition> buildDefinitions(
    ConstructionProject project,
  ) {
    final definitions = <ProjectAreaDefinition>[];
    final config = project.config;

    for (final room in config.additionalRooms) {
      definitions.add(
        ProjectAreaDefinition(
          id: 'room:${room.id}',
          type: ProjectAreaType.room,
          title: room.name,
          subtitle: _formatRoomLocation(config, room),
          infoItems: [
            ProjectAreaInfoItem(
              label: 'Budynek',
              value: _buildingName(config, room.buildingIndex),
            ),
            ProjectAreaInfoItem(
              label: 'Poziom',
              value:
                  '${room.levelType == AdditionalRoomLevelType.nadziemna ? 'Nadziemny' : 'Podziemny'} ${room.floorNumber}',
            ),
            ProjectAreaInfoItem(
              label: 'Klatka',
              value: room.stairCaseName?.trim().isEmpty ?? true
                  ? 'Brak'
                  : room.stairCaseName!,
            ),
            ProjectAreaInfoItem(
              label: 'Numer pomieszczenia',
              value: room.roomNumber.trim().isEmpty ? 'Brak' : room.roomNumber,
            ),
            ProjectAreaInfoItem(
              label: 'Systemy',
              value: room.specificSystems.isEmpty
                  ? 'Brak systemów dedykowanych'
                  : room.specificSystems.map((item) => item.displayName).join(', '),
            ),
          ],
          checklist: _roomChecklist(room),
        ),
      );
    }

    for (var buildingIndex = 0; buildingIndex < config.buildings.length; buildingIndex++) {
      final building = config.buildings[buildingIndex];
      final buildingName = _buildingName(config, buildingIndex);

      for (final stairCase in building.stairCases) {
        final stairUnits = project.units
            .where((unit) => unit.stairCase == stairCase.stairCaseName)
            .toList();
        final floorsLabel = stairCase.numberOfLevels == 1
            ? '1 kondygnacja'
            : '${stairCase.numberOfLevels} kondygnacje';

        definitions.add(
          ProjectAreaDefinition(
            id: 'staircase:$buildingIndex:${stairCase.stairCaseName}',
            type: ProjectAreaType.stairCase,
            title: '$buildingName · Klatka ${stairCase.stairCaseName}',
            subtitle:
                'Lokale: ${stairUnits.length} · Dźwigi: ${stairCase.numberOfElevators}',
            infoItems: [
              ProjectAreaInfoItem(label: 'Budynek', value: buildingName),
              ProjectAreaInfoItem(
                label: 'Klatka',
                value: stairCase.stairCaseName,
              ),
              ProjectAreaInfoItem(label: 'Kondygnacje', value: floorsLabel),
              ProjectAreaInfoItem(
                label: 'Dźwigi',
                value: stairCase.numberOfElevators.toString(),
              ),
              ProjectAreaInfoItem(
                label: 'Zakres lokali',
                value: stairUnits.isEmpty
                    ? 'Brak lokali'
                    : stairUnits
                        .map((unit) => project.displayUnitId(unit))
                        .take(8)
                        .join(', '),
              ),
            ],
            checklist: _stairCaseChecklist(),
          ),
        );

        for (var elevatorIndex = 0;
            elevatorIndex < stairCase.numberOfElevators;
            elevatorIndex++) {
          definitions.add(
            ProjectAreaDefinition(
              id:
                  'elevator:$buildingIndex:${stairCase.stairCaseName}:$elevatorIndex',
              type: ProjectAreaType.elevator,
              title:
                  '$buildingName · Klatka ${stairCase.stairCaseName} · Winda ${elevatorIndex + 1}',
              subtitle:
                  'Obsługa klatki ${stairCase.stairCaseName} na ${stairCase.numberOfLevels} kondygnacjach',
              infoItems: [
                ProjectAreaInfoItem(label: 'Budynek', value: buildingName),
                ProjectAreaInfoItem(
                  label: 'Klatka',
                  value: stairCase.stairCaseName,
                ),
                ProjectAreaInfoItem(
                  label: 'Numer windy',
                  value: '${elevatorIndex + 1}',
                ),
                ProjectAreaInfoItem(
                  label: 'Obsługiwane kondygnacje',
                  value: stairCase.numberOfLevels.toString(),
                ),
              ],
              checklist: _elevatorChecklist(),
            ),
          );
        }
      }

      if (config.hasGarage || config.hasParking || building.basementLevels > 0) {
        definitions.add(
          ProjectAreaDefinition(
            id: 'garage:$buildingIndex',
            type: ProjectAreaType.garage,
            title: '$buildingName · Garaż',
            subtitle:
                'Poziomy podziemne: ${building.basementLevels} · Parking: ${config.hasParking ? 'tak' : 'nie'}',
            infoItems: [
              ProjectAreaInfoItem(label: 'Budynek', value: buildingName),
              ProjectAreaInfoItem(
                label: 'Poziomy podziemne',
                value: building.basementLevels.toString(),
              ),
              ProjectAreaInfoItem(
                label: 'Garaż',
                value: config.hasGarage ? 'Tak' : 'Nie',
              ),
              ProjectAreaInfoItem(
                label: 'Parking',
                value: config.hasParking ? 'Tak' : 'Nie',
              ),
              ProjectAreaInfoItem(
                label: 'Ładowarki EV',
                value: config.renewableEnergyConfig?.electricMobility.isEnabled ?? false
                    ? '${config.renewableEnergyConfig?.electricMobility.chargingStations.length ?? 0}'
                    : 'Brak',
              ),
            ],
            checklist: _garageChecklist(config),
          ),
        );
      }

      definitions.add(
        ProjectAreaDefinition(
          id: 'roof:$buildingIndex',
          type: ProjectAreaType.roof,
          title: '$buildingName · Dach',
          subtitle: _roofSubtitle(config),
          infoItems: [
            ProjectAreaInfoItem(label: 'Budynek', value: buildingName),
            ProjectAreaInfoItem(
              label: 'Instalacja odgromowa',
              value: config.selectedSystems.contains(ElectricalSystemType.odgromowa)
                  ? 'Tak'
                  : 'Nie',
            ),
            ProjectAreaInfoItem(
              label: 'Fotowoltaika',
              value: config.renewableEnergyConfig?.photovoltaic.isEnabled ?? false
                  ? '${config.renewableEnergyConfig?.photovoltaic.installedPowerKwp ?? 0} kWp'
                  : 'Brak',
            ),
            ProjectAreaInfoItem(
              label: 'Magazyn energii',
              value: config.renewableEnergyConfig?.batteryStorage.isEnabled ?? false
                  ? '${config.renewableEnergyConfig?.batteryStorage.storageSizeKwh ?? 0} kWh'
                  : 'Brak',
            ),
          ],
          checklist: _roofChecklist(config),
        ),
      );

      definitions.add(
        ProjectAreaDefinition(
          id: 'external:$buildingIndex',
          type: ProjectAreaType.externalArea,
          title: '$buildingName · Teren zewnętrzny',
          subtitle: _externalSubtitle(config),
          infoItems: [
            ProjectAreaInfoItem(label: 'Budynek', value: buildingName),
            ProjectAreaInfoItem(
              label: 'Parking zewnętrzny',
              value: config.hasParking ? 'Tak' : 'Nie',
            ),
            ProjectAreaInfoItem(
              label: 'Oświetlenie zewnętrzne',
              value: config.selectedSystems.contains(ElectricalSystemType.oswietlenie)
                  ? 'Tak'
                  : 'Nie',
            ),
            ProjectAreaInfoItem(
              label: 'Monitoring zewnętrzny',
              value: config.selectedSystems.contains(ElectricalSystemType.cctv)
                  ? 'Tak'
                  : 'Nie',
            ),
          ],
          checklist: _externalChecklist(config),
        ),
      );
    }

    return definitions;
  }

  static String _buildingName(BuildingConfiguration config, int buildingIndex) {
    if (buildingIndex >= 0 && buildingIndex < config.buildings.length) {
      return config.buildings[buildingIndex].buildingName;
    }
    return 'Budynek ${buildingIndex + 1}';
  }

  static String _formatRoomLocation(
    BuildingConfiguration config,
    AdditionalRoom room,
  ) {
    final buildingName = _buildingName(config, room.buildingIndex);
    final stair = room.stairCaseName == null ? '' : ' · Klatka ${room.stairCaseName}';
    final roomNumber = room.roomNumber.trim().isEmpty
        ? ''
        : ' · Pom. ${room.roomNumber.trim()}';
    final level = room.levelType == AdditionalRoomLevelType.nadziemna
        ? 'Nadziemna'
        : 'Podziemna';
    return '$buildingName$stair · $level ${room.floorNumber}$roomNumber';
  }

  static List<ProjectAreaChecklistTemplate> _roomChecklist(AdditionalRoom room) {
    final taskOrder = room.tasks.isEmpty
        ? AdditionalRoomTask.values
        : room.tasks.toList();
    return taskOrder.map((task) {
      switch (task) {
        case AdditionalRoomTask.projekt:
          return const ProjectAreaChecklistTemplate(
            id: 'projekt',
            title: 'Koordynacja i trasy',
            description: 'Zweryfikuj projekt, przebiegi tras i kolizje w pomieszczeniu.',
          );
        case AdditionalRoomTask.okablowanie:
          return const ProjectAreaChecklistTemplate(
            id: 'okablowanie',
            title: 'Okablowanie i przepusty',
            description: 'Wykonaj trasy, przepusty i okablowanie dla wszystkich systemów pomieszczenia.',
          );
        case AdditionalRoomTask.montazOsprzetu:
          return const ProjectAreaChecklistTemplate(
            id: 'montazOsprzetu',
            title: 'Montaż osprzętu',
            description: 'Zamontuj rozdzielnice, osprzęt i urządzenia przewidziane dla pomieszczenia.',
          );
        case AdditionalRoomTask.pomiary:
          return const ProjectAreaChecklistTemplate(
            id: 'pomiary',
            title: 'Pomiary',
            description: 'Wykonaj pomiary i sprawdzenia instalacji w pomieszczeniu.',
          );
        case AdditionalRoomTask.uruchomienie:
          return const ProjectAreaChecklistTemplate(
            id: 'uruchomienie',
            title: 'Uruchomienie',
            description: 'Uruchom układy i potwierdź poprawną pracę urządzeń.',
          );
        case AdditionalRoomTask.odbior:
          return const ProjectAreaChecklistTemplate(
            id: 'odbior',
            title: 'Odbiór',
            description: 'Przygotuj pomieszczenie do odbioru i zamknij checklistę.',
          );
      }
    }).toList();
  }

  static List<ProjectAreaChecklistTemplate> _stairCaseChecklist() {
    return const [
      ProjectAreaChecklistTemplate(
        id: 'trasy',
        title: 'Trasy i piony kablowe',
        description: 'Wykonaj piony, przepusty i trasy dla części wspólnych klatki.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'oswietlenie',
        title: 'Oświetlenie klatki',
        description: 'Wykonaj zasilanie i montaż opraw w częściach wspólnych.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'instalacje_bezpieczenstwa',
        title: 'SSP, oddymianie, teletechnika',
        description: 'Zamontuj i podłącz systemy bezpieczeństwa klatki schodowej.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'dokumentacja_foto',
        title: 'Wykonanie dokumentacji fotograficznej',
        description: 'Wykonaj zdjęcia tras kablowych i instalacji SSP/teletechniki przed zakryciem.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'osprzet',
        title: 'Osprzęt i oznaczenia',
        description: 'Zamontuj osprzęt, oznaczenia i przygotuj dokumentację powykonawczą.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'odbior',
        title: 'Sprawdzenie i odbiór',
        description: 'Zweryfikuj kompletność robót w klatce i zamknij zakres.',
      ),
    ];
  }

  static List<ProjectAreaChecklistTemplate> _elevatorChecklist() {
    return const [
      ProjectAreaChecklistTemplate(
        id: 'zasilanie',
        title: 'Zasilanie windy',
        description: 'Przygotuj dedykowane zasilanie i zabezpieczenia dla dźwigu.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'trasy',
        title: 'Trasy i przepusty',
        description: 'Wykonaj trasy, przepusty i przygotowanie szybu / maszynowni.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'sterowanie',
        title: 'Sterowanie i sygnały',
        description: 'Podłącz sterowanie, sygnały alarmowe i współpracę z SSP.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'dokumentacja_foto',
        title: 'Wykonanie dokumentacji fotograficznej',
        description: 'Wykonaj zdjęcia tras i podłączeń w szybie/maszynowni przed zamknięciem zabudów.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'koordynacja',
        title: 'Koordynacja z dostawcą',
        description: 'Potwierdź zakres i interfejsy z dostawcą windy.',
      ),
      ProjectAreaChecklistTemplate(
        id: 'odbior',
        title: 'Testy i odbiór',
        description: 'Przeprowadź testy funkcjonalne i odbiór zakresu elektrycznego windy.',
      ),
    ];
  }

  static List<ProjectAreaChecklistTemplate> _garageChecklist(
    BuildingConfiguration config,
  ) {
    return [
      const ProjectAreaChecklistTemplate(
        id: 'trasy',
        title: 'Trasy garażowe',
        description: 'Wykonaj główne trasy kablowe i przepusty w garażu.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'oswietlenie',
        title: 'Oświetlenie i zasilanie',
        description: 'Wykonaj obwody oświetlenia, gniazd oraz zasilania urządzeń garażowych.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'systemy',
        title: 'Systemy garażowe',
        description: 'Podłącz bramy, wentylację, SSP, CCTV i inne systemy wspólne.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'dokumentacja_foto',
        title: 'Wykonanie dokumentacji fotograficznej',
        description: 'Wykonaj zdjęcia tras i instalacji garażowych przed zakryciem lub zabudową.',
      ),
      if (config.renewableEnergyConfig?.electricMobility.isEnabled ?? false)
        const ProjectAreaChecklistTemplate(
          id: 'ev',
          title: 'Ładowarki EV',
          description: 'Wykonaj przygotowanie i podłączenie infrastruktury ładowania.',
        ),
      const ProjectAreaChecklistTemplate(
        id: 'odbior',
        title: 'Pomiary i odbiór',
        description: 'Wykonaj pomiary, testy i przygotuj garaż do odbioru.',
      ),
    ];
  }

  static List<ProjectAreaChecklistTemplate> _roofChecklist(
    BuildingConfiguration config,
  ) {
    return [
      const ProjectAreaChecklistTemplate(
        id: 'trasy',
        title: 'Trasy i przepusty dachowe',
        description: 'Wykonaj przejścia dachowe, trasy i zabezpieczenia tras kablowych.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'odgrom',
        title: 'Instalacja odgromowa',
        description: 'Wykonaj zwody, przewody odprowadzające i połączenia wyrównawcze.',
      ),
      if (config.renewableEnergyConfig?.photovoltaic.isEnabled ?? false)
        const ProjectAreaChecklistTemplate(
          id: 'pv',
          title: 'Fotowoltaika',
          description: 'Wykonaj montaż okablowania i przygotowanie pod instalację PV.',
        ),
      const ProjectAreaChecklistTemplate(
        id: 'urzadzenia',
        title: 'Urządzenia dachowe',
        description: 'Podłącz zasilanie urządzeń dachowych i wykonaj oznaczenia.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'odbior',
        title: 'Kontrola i odbiór',
        description: 'Zweryfikuj szczelność, kompletność i przygotuj odbiór prac dachowych.',
      ),
    ];
  }

  static List<ProjectAreaChecklistTemplate> _externalChecklist(
    BuildingConfiguration config,
  ) {
    return [
      const ProjectAreaChecklistTemplate(
        id: 'zasilanie',
        title: 'Zasilanie terenu',
        description: 'Przygotuj zasilanie urządzeń i punktów instalacyjnych na zewnątrz.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'oswietlenie',
        title: 'Oświetlenie zewnętrzne',
        description: 'Wykonaj słupy, oprawy i sterowanie oświetleniem zewnętrznym.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'niskopradowe',
        title: 'Systemy niskoprądowe',
        description: 'Podłącz CCTV, KD, domofony, bramy i inne systemy zewnętrzne.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'dokumentacja_foto',
        title: 'Wykonanie dokumentacji fotograficznej',
        description: 'Wykonaj zdjęcia tras i instalacji zewnętrznych przed zasypaniem lub zakryciem.',
      ),
      if (config.hasParking)
        const ProjectAreaChecklistTemplate(
          id: 'parking',
          title: 'Parking i infrastruktura',
          description: 'Wykonaj zasilanie parkingu, szlabanów i elementów towarzyszących.',
        ),
      const ProjectAreaChecklistTemplate(
        id: 'inwentaryzacja_geodezyjna',
        title: 'Wykonanie inwentaryzacji geodezyjnej',
        description: 'Zleć i odbierz inwentaryzację geodezyjną powykonawczą instalacji terenu zewnętrznego.',
      ),
      const ProjectAreaChecklistTemplate(
        id: 'odbior',
        title: 'Pomiary i odbiór',
        description: 'Wykonaj pomiary, regulacje i przygotuj teren do odbioru.',
      ),
    ];
  }

  static String _roofSubtitle(BuildingConfiguration config) {
    final tags = <String>[];
    if (config.selectedSystems.contains(ElectricalSystemType.odgromowa)) {
      tags.add('odgrom');
    }
    if (config.renewableEnergyConfig?.photovoltaic.isEnabled ?? false) {
      tags.add('PV');
    }
    if (config.renewableEnergyConfig?.batteryStorage.isEnabled ?? false) {
      tags.add('BESS');
    }
    return tags.isEmpty ? 'Prace dachowe i przygotowanie odbioru' : tags.join(' · ');
  }

  static String _externalSubtitle(BuildingConfiguration config) {
    final tags = <String>[];
    if (config.hasParking) {
      tags.add('parking');
    }
    if (config.selectedSystems.contains(ElectricalSystemType.oswietlenie)) {
      tags.add('oświetlenie');
    }
    if (config.selectedSystems.contains(ElectricalSystemType.cctv)) {
      tags.add('CCTV');
    }
    return tags.isEmpty ? 'Instalacje zewnętrzne' : tags.join(' · ');
  }
}
