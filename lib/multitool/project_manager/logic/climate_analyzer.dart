/// Analizator warunków klimatycznych Polski dla planowania prac elektrycznych
/// 
/// Uwzględnia:
/// - Temperatury sezonowe
/// - Prace na zewnątrz (montaż słupów, linii)
/// - Bezpieczeństwo w skrajnych temperaturach
/// - Pomiary rezystancji uziemienia (wymagają sprzyjających warunków)

class PolishClimateAnalyzer {
  /// Miesiące sezonów w Polsce
  static const winterMonths = [12, 1, 2];
  static const springMonths = [3, 4, 5];
  static const summerMonths = [6, 7, 8];
  static const autumnMonths = [9, 10, 11];
  
  /// Średnie temperatury dla prac na zewnątrz
  static const Map<String, Map<String, dynamic>> seasonalConditions = {
    'winter': {
      'months': [12, 1, 2],
      'avgTemp': -2,
      'minTemp': -15,
      'maxTemp': 5,
      'outdoorWorkSafetyFactor': 1.5, // 50% więcej czasu
      'groundingMeasurementMultiplier': 2.0, // 2x wyższy opór (suchy grunt)
      'safeForOutdoorWork': false,
      'description': 'Łatwe mrozy, niskie temperatury, krótkie dni',
    },
    'spring': {
      'months': [3, 4, 5],
      'avgTemp': 10,
      'minTemp': 0,
      'maxTemp': 20,
      'outdoorWorkSafetyFactor': 1.1, // 10% więcej czasu
      'groundingMeasurementMultiplier': 1.3, // Złe warunki (wiosenne roztopy)
      'safeForOutdoorWork': true,
      'description': 'Dobre warunki do robót naziemnych, wilgotny grunt',
    },
    'summer': {
      'months': [6, 7, 8],
      'avgTemp': 18,
      'minTemp': 10,
      'maxTemp': 28,
      'outdoorWorkSafetyFactor': 1.0, // Optymalne warunki
      'groundingMeasurementMultiplier': 1.5, // Suchy grunt (gorąco)
      'safeForOutdoorWork': true,
      'description': 'Najlepsze warunki do prac budowlanych',
    },
    'autumn': {
      'months': [9, 10, 11],
      'avgTemp': 9,
      'minTemp': -2,
      'maxTemp': 18,
      'outdoorWorkSafetyFactor': 1.2, // 20% więcej czasu
      'groundingMeasurementMultiplier': 1.2, // Umierkownie dobre
      'safeForOutdoorWork': true,
      'description': 'Dobre warunki, ale krótsze dni i tygodnie deszczowe',
    },
  };
  
  /// Analizuje warunki dla konkretnego miesiąca
  static Map<String, dynamic> analyzeMonth(int month) {
    String season = _getSeasonForMonth(month);
    return seasonalConditions[season]!;
  }
  
  /// Oblicz mnoży dla harmonogramu prac na podstawie zaplanowanych dat
  /// Jeśli projekt trwa przez kilka sezonów, oblicza średni mnożnik
  static double calculateScheduleMultiplier(DateTime startDate, DateTime endDate) {
    double totalMultiplier = 0;
    int monthCount = 0;
    
    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      final conditions = analyzeMonth(current.month);
      totalMultiplier += (conditions['outdoorWorkSafetyFactor'] as num).toDouble();
      monthCount++;
      current = DateTime(current.year, current.month + 1);
    }
    
    return monthCount > 0 ? totalMultiplier / monthCount : 1.0;
  }
  
  /// Oblicz mnożnik dla pomiarów rezystancji uziemienia
  /// Zależy od warunków glebowych i wilgotności
  static double calculateGroundingMeasurementMultiplier(DateTime startDate, DateTime endDate) {
    double totalMultiplier = 0;
    int monthCount = 0;
    
    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      final conditions = analyzeMonth(current.month);
      totalMultiplier += (conditions['groundingMeasurementMultiplier'] as num).toDouble();
      monthCount++;
      current = DateTime(current.year, current.month + 1);
    }
    
    return monthCount > 0 ? totalMultiplier / monthCount : 1.0;
  }
  
  /// Czy jest bezpieczny okres do prac na zewnątrz?
  static bool isSafeForOutdoorWork(DateTime date) {
    final conditions = analyzeMonth(date.month);
    return conditions['safeForOutdoorWork'] as bool;
  }
  
  /// Opisz zalecenia dla danego okresu
  static String getSeasonalRecommendations(DateTime startDate, DateTime endDate) {
    final season = _getSeasonForMonth(startDate.month);
    final conditions = seasonalConditions[season]!;
    
    return '''
Rekomendacje na okres ${formatDateRange(startDate, endDate)}:

${conditions['description']}

Temperatura: ${conditions['minTemp']}°C do ${conditions['maxTemp']}C (avg: ${conditions['avgTemp']}°C)
Prace na zewnątrz: ${conditions['safeForOutdoorWork'] ? '✓ BEZPIECZNE' : '✗ NIE ZALECANE'}
Mnożnik czasu: ${(conditions['outdoorWorkSafetyFactor'] as num).toStringAsFixed(1)}x

${_getDetailedRecommendations(season)}
''';
  }
  
  static String _getSeasonForMonth(int month) {
    if (winterMonths.contains(month)) return 'winter';
    if (springMonths.contains(month)) return 'spring';
    if (summerMonths.contains(month)) return 'summer';
    return 'autumn';
  }
  
  static String _getDetailedRecommendations(String season) {
    switch (season) {
      case 'winter':
        return '⚠️ Unikaj prac na zewnątrz.\n'
            '• Prace będą trwać dłużej (niskie temp, słabe światło)\n'
            '• Rezystancja gruntu może być 2x wyższa\n'
            '• Sporządź warunki bezpieczeństwa dla pracowników';
      case 'spring':
        return '✓ Dobre warunki, ale:\n'
            '• Grunt jest mokry (roztopy) - pomiary uziemienia mogą być niskie\n'
            '• Planuj prace zaraz po przesychaniu gruntu\n'
            '• Lepsze warunki niż zima';
      case 'summer':
        return '✓ OPTYMALNE WARUNKI\n'
            '• Najlepszy czas do prac budowlanych\n'
            '• Warunki glebowe dobre dla pomiarów\n'
            '• Maksymalne światło dzienne';
      case 'autumn':
        return '✓ Dobre warunki:\n'
            '• Wilgotny grunt (dobre do pomiarów)\n'
            '• Uniknij końca listopada (mrozy)\n'
            '• Krótsze dni - planuj więcej czasu';
      default:
        return '';
    }
  }
  
  static String formatDateRange(DateTime start, DateTime end) {
    final months = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }
}
