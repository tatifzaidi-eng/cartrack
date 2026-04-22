import 'package:uuid/uuid.dart';

enum MaintenanceType {
  vidange,
  pneus,
  freins,
  filtres,
  courroie,
  controle,
  batterie,
  autre,
}

extension MaintenanceTypeExtension on MaintenanceType {
  String get label {
    switch (this) {
      case MaintenanceType.vidange:
        return 'Vidange huile';
      case MaintenanceType.pneus:
        return 'Pneus';
      case MaintenanceType.freins:
        return 'Freins / Plaquettes';
      case MaintenanceType.filtres:
        return 'Filtres';
      case MaintenanceType.courroie:
        return 'Courroie distribution';
      case MaintenanceType.controle:
        return 'Contrôle technique';
      case MaintenanceType.batterie:
        return 'Batterie';
      case MaintenanceType.autre:
        return 'Autre';
    }
  }

  String get emoji {
    switch (this) {
      case MaintenanceType.vidange:
        return '🛢️';
      case MaintenanceType.pneus:
        return '🔄';
      case MaintenanceType.freins:
        return '🛑';
      case MaintenanceType.filtres:
        return '🌀';
      case MaintenanceType.courroie:
        return '⚙️';
      case MaintenanceType.controle:
        return '📋';
      case MaintenanceType.batterie:
        return '🔋';
      case MaintenanceType.autre:
        return '🔧';
    }
  }
}

class MaintenanceEntry {
  final String id;
  final MaintenanceType type;
  final DateTime date;
  final double km;
  final double cost;
  final double? nextKm;
  final DateTime? nextDate;
  final String? note;

  MaintenanceEntry({
    String? id,
    required this.type,
    required this.date,
    required this.km,
    required this.cost,
    this.nextKm,
    this.nextDate,
    this.note,
  }) : id = id ?? const Uuid().v4();

  AlertLevel get alertLevel {
    final now = DateTime.now();
    bool isUrgent = false;
    bool isWarning = false;

    if (nextDate != null) {
      final diff = nextDate!.difference(now).inDays;
      if (diff < 0) isUrgent = true;
      else if (diff < 30) isWarning = true;
    }

    if (isUrgent) return AlertLevel.danger;
    if (isWarning) return AlertLevel.warning;
    return AlertLevel.ok;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'date': date.toIso8601String(),
        'km': km,
        'cost': cost,
        'nextKm': nextKm,
        'nextDate': nextDate?.toIso8601String(),
        'note': note,
      };

  factory MaintenanceEntry.fromJson(Map<String, dynamic> json) =>
      MaintenanceEntry(
        id: json['id'],
        type: MaintenanceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MaintenanceType.autre,
        ),
        date: DateTime.parse(json['date']),
        km: (json['km'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        nextKm: json['nextKm'] != null
            ? (json['nextKm'] as num).toDouble()
            : null,
        nextDate: json['nextDate'] != null
            ? DateTime.parse(json['nextDate'])
            : null,
        note: json['note'],
      );
}

enum AlertLevel { ok, warning, danger }
