import 'package:uuid/uuid.dart';
import 'fuel_entry.dart';
import 'expense.dart';
import 'maintenance_entry.dart';

class Vehicle {
  final String id;
  String name;
  String? brand;
  String? model;
  int? year;
  List<FuelEntry> fuelEntries;
  List<Expense> expenses;
  List<MaintenanceEntry> maintenanceEntries;

  Vehicle({
    String? id,
    required this.name,
    this.brand,
    this.model,
    this.year,
    List<FuelEntry>? fuelEntries,
    List<Expense>? expenses,
    List<MaintenanceEntry>? maintenanceEntries,
  })  : id = id ?? const Uuid().v4(),
        fuelEntries = fuelEntries ?? [],
        expenses = expenses ?? [],
        maintenanceEntries = maintenanceEntries ?? [];

  double? get avgConsumption {
    if (fuelEntries.length < 2) return null;
    final sorted = [...fuelEntries]..sort((a, b) => a.km.compareTo(b.km));
    double total = 0;
    int count = 0;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].km - sorted[i - 1].km;
      if (diff > 0) {
        total += (sorted[i].liters / diff) * 100;
        count++;
      }
    }
    return count > 0 ? total / count : null;
  }

  double get totalKm {
    if (fuelEntries.isEmpty) return 0;
    final sorted = [...fuelEntries]..sort((a, b) => a.km.compareTo(b.km));
    return sorted.last.km - sorted.first.km;
  }

  double get totalSpent {
    double total = 0;
    for (final f in fuelEntries) total += f.totalPrice;
    for (final e in expenses) total += e.amount;
    for (final m in maintenanceEntries) total += m.cost;
    return total;
  }

  double? get costPerKm {
    final km = totalKm;
    if (km == 0) return null;
    return totalSpent / km;
  }

  FuelEntry? get lastFuelEntry {
    if (fuelEntries.isEmpty) return null;
    return [...fuelEntries]
        .reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  double monthlyTotal(DateTime month) {
    double total = 0;
    for (final f in fuelEntries) {
      if (f.date.year == month.year && f.date.month == month.month) {
        total += f.totalPrice;
      }
    }
    for (final e in expenses) {
      if (e.date.year == month.year && e.date.month == month.month) {
        total += e.amount;
      }
    }
    for (final m in maintenanceEntries) {
      if (m.date.year == month.year && m.date.month == month.month) {
        total += m.cost;
      }
    }
    return total;
  }

  int get pendingAlerts {
    return maintenanceEntries
        .where((m) => m.alertLevel != AlertLevel.ok)
        .length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'model': model,
        'year': year,
        'fuelEntries': fuelEntries.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'maintenanceEntries':
            maintenanceEntries.map((e) => e.toJson()).toList(),
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        name: json['name'],
        brand: json['brand'],
        model: json['model'],
        year: json['year'],
        fuelEntries: (json['fuelEntries'] as List? ?? [])
            .map((e) => FuelEntry.fromJson(e))
            .toList(),
        expenses: (json['expenses'] as List? ?? [])
            .map((e) => Expense.fromJson(e))
            .toList(),
        maintenanceEntries: (json['maintenanceEntries'] as List? ?? [])
            .map((e) => MaintenanceEntry.fromJson(e))
            .toList(),
      );
}
