import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';
import '../models/expense.dart';
import '../models/maintenance_entry.dart';

class AppProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  int _currentVehicleIndex = 0;
  bool _isDarkMode = false;

  List<Vehicle> get vehicles => _vehicles;
  int get currentVehicleIndex => _currentVehicleIndex;
  bool get isDarkMode => _isDarkMode;

  Vehicle? get currentVehicle =>
      _vehicles.isEmpty ? null : _vehicles[_currentVehicleIndex];

  AppProvider() {
    _loadData();
  }

  // ── Persistence ────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? vehiclesJson = prefs.getString('vehicles');
    final int savedIndex = prefs.getInt('currentVehicleIndex') ?? 0;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    if (vehiclesJson != null) {
      final List decoded = jsonDecode(vehiclesJson);
      _vehicles = decoded.map((v) => Vehicle.fromJson(v)).toList();
      _currentVehicleIndex =
          savedIndex < _vehicles.length ? savedIndex : 0;
    }

    if (_vehicles.isEmpty) {
      _vehicles.add(Vehicle(name: 'Mon véhicule'));
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_vehicles.map((v) => v.toJson()).toList());
    await prefs.setString('vehicles', encoded);
    await prefs.setInt('currentVehicleIndex', _currentVehicleIndex);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // ── Vehicles ───────────────────────────────────────────
  void addVehicle(String name, {String? brand, String? model, int? year}) {
    _vehicles.add(Vehicle(name: name, brand: brand, model: model, year: year));
    _currentVehicleIndex = _vehicles.length - 1;
    _saveData();
    notifyListeners();
  }

  void switchVehicle(int index) {
    if (index >= 0 && index < _vehicles.length) {
      _currentVehicleIndex = index;
      _saveData();
      notifyListeners();
    }
  }

  void deleteVehicle(int index) {
    if (_vehicles.length > 1) {
      _vehicles.removeAt(index);
      if (_currentVehicleIndex >= _vehicles.length) {
        _currentVehicleIndex = _vehicles.length - 1;
      }
      _saveData();
      notifyListeners();
    }
  }

  // ── Fuel ──────────────────────────────────────────────
  void addFuelEntry(FuelEntry entry) {
    currentVehicle?.fuelEntries.add(entry);
    _saveData();
    notifyListeners();
  }

  void deleteFuelEntry(String id) {
    currentVehicle?.fuelEntries.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  // ── Expenses ──────────────────────────────────────────
  void addExpense(Expense expense) {
    currentVehicle?.expenses.add(expense);
    _saveData();
    notifyListeners();
  }

  void deleteExpense(String id) {
    currentVehicle?.expenses.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  // ── Maintenance ───────────────────────────────────────
  void addMaintenance(MaintenanceEntry entry) {
    currentVehicle?.maintenanceEntries.add(entry);
    _saveData();
    notifyListeners();
  }

  void deleteMaintenance(String id) {
    currentVehicle?.maintenanceEntries.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  // ── Dark Mode ─────────────────────────────────────────
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveData();
    notifyListeners();
  }

  // ── Fuel consumption calculation ─────────────────────
  double? getConsumptionForEntry(FuelEntry entry) {
    final vehicle = currentVehicle;
    if (vehicle == null) return null;
    final sorted = [...vehicle.fuelEntries]
      ..sort((a, b) => a.km.compareTo(b.km));
    final idx = sorted.indexWhere((e) => e.id == entry.id);
    if (idx <= 0) return null;
    final diff = sorted[idx].km - sorted[idx - 1].km;
    if (diff <= 0) return null;
    return (sorted[idx].liters / diff) * 100;
  }
}
