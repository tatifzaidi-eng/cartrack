import 'package:uuid/uuid.dart';

class FuelEntry {
  final String id;
  final DateTime date;
  final double km;
  final double pricePerLiter;
  final double totalPrice;
  final double liters;
  String? note;

  FuelEntry({
    String? id,
    required this.date,
    required this.km,
    required this.pricePerLiter,
    required this.totalPrice,
    String? note,
  })  : id = id ?? const Uuid().v4(),
        liters = totalPrice / pricePerLiter,
        note = note;

  FuelEntry.withLiters({
    String? id,
    required this.date,
    required this.km,
    required this.pricePerLiter,
    required this.totalPrice,
    required this.liters,
    this.note,
  }) : id = id ?? const Uuid().v4();

  double? get consumption => null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'km': km,
        'pricePerLiter': pricePerLiter,
        'totalPrice': totalPrice,
        'liters': liters,
        'note': note,
      };

  factory FuelEntry.fromJson(Map<String, dynamic> json) =>
      FuelEntry.withLiters(
        id: json['id'],
        date: DateTime.parse(json['date']),
        km: (json['km'] as num).toDouble(),
        pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
        totalPrice: (json['totalPrice'] as num).toDouble(),
        liters: (json['liters'] as num).toDouble(),
        note: json['note'],
      );
}
