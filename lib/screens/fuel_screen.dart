import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/fuel_entry.dart';
import '../utils/app_theme.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _pplCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double? _calcLiters;
  double? _calcCons;
  double? _calcCostKm;

  @override
  void dispose() {
    _kmCtrl.dispose();
    _pplCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _updateCalc() {
    final ppl = double.tryParse(_pplCtrl.text);
    final price = double.tryParse(_priceCtrl.text);
    final km = double.tryParse(_kmCtrl.text);
    if (ppl != null && ppl > 0 && price != null && price > 0) {
      final liters = price / ppl;
      setState(() {
        _calcLiters = liters;
        if (km != null) {
          final provider = context.read<AppProvider>();
          final vehicle = provider.currentVehicle;
          if (vehicle != null) {
            final sorted = [...vehicle.fuelEntries]
              ..sort((a, b) => a.km.compareTo(b.km));
            final prev = sorted.where((f) => f.km < km).toList();
            if (prev.isNotEmpty) {
              final diff = km - prev.last.km;
              if (diff > 0) {
                _calcCons = (liters / diff) * 100;
                _calcCostKm = price / diff;
                return;
              }
            }
          }
        }
        _calcCons = null;
        _calcCostKm = null;
      });
    } else {
      setState(() {
        _calcLiters = null;
        _calcCons = null;
        _calcCostKm = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveFuel() {
    if (!_formKey.currentState!.validate()) return;
    final ppl = double.parse(_pplCtrl.text);
    final price = double.parse(_priceCtrl.text);
    final km = double.parse(_kmCtrl.text);
    final liters = price / ppl;
    final entry = FuelEntry.withLiters(
      date: _selectedDate,
      km: km,
      pricePerLiter: ppl,
      totalPrice: price,
      liters: liters,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );
    context.read<AppProvider>().addFuelEntry(entry);
    _kmCtrl.clear();
    _pplCtrl.clear();
    _priceCtrl.clear();
    _noteCtrl.clear();
    setState(() {
      _calcLiters = null;
      _calcCons = null;
      _calcCostKm = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plein enregistré ✓'),
        backgroundColor: AppTheme.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final vehicle = provider.currentVehicle;
        final fuelList = vehicle?.fuelEntries ?? [];
        final sorted = [...fuelList]
          ..sort((a, b) => b.date.compareTo(a.date));
        final sortedByKm = [...fuelList]
          ..sort((a, b) => a.km.compareTo(b.km));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Add form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⛽ Ajouter un plein',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                        // Date picker
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(_selectedDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _kmCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Kilométrage (km)',
                                    hintText: 'ex: 45000'),
                                onChanged: (_) => _updateCalc(),
                                validator: (v) => (v == null ||
                                        double.tryParse(v) == null)
                                    ? 'Requis'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _pplCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    labelText: 'Prix/litre (MAD)',
                                    hintText: 'ex: 13.50'),
                                onChanged: (_) => _updateCalc(),
                                validator: (v) => (v == null ||
                                        double.tryParse(v) == null)
                                    ? 'Requis'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    labelText: 'Prix total (MAD)',
                                    hintText: 'ex: 550'),
                                onChanged: (_) => _updateCalc(),
                                validator: (v) => (v == null ||
                                        double.tryParse(v) == null)
                                    ? 'Requis'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _noteCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Note (optionnel)',
                                    hintText: 'Station...'),
                              ),
                            ),
                          ],
                        ),
                        // Calculated preview
                        if (_calcLiters != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '⛽ Litres : ${_calcLiters!.toStringAsFixed(1)} L',
                                    style: const TextStyle(
                                        color: Color(0xFF1E40AF),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                if (_calcCons != null) ...[
                                  Text(
                                      '📈 Conso : ${_calcCons!.toStringAsFixed(1)} L/100km',
                                      style: const TextStyle(
                                          color: Color(0xFF1E40AF),
                                          fontSize: 13)),
                                  Text(
                                      '💰 Coût/km : ${_calcCostKm!.toStringAsFixed(2)} MAD',
                                      style: const TextStyle(
                                          color: Color(0xFF1E40AF),
                                          fontSize: 13)),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveFuel,
                            child: const Text('✓ Enregistrer le plein'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // History
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📋 Historique des pleins',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (sorted.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                                'Aucun plein enregistré\nSaisissez le prix/litre et le prix total',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ...sorted.map((f) {
                          final idx = sortedByKm.indexWhere((e) => e.id == f.id);
                          double? cons;
                          if (idx > 0) {
                            final diff = sortedByKm[idx].km - sortedByKm[idx - 1].km;
                            if (diff > 0) {
                              cons = (f.liters / diff) * 100;
                            }
                          }
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                  child: Text('⛽',
                                      style: TextStyle(fontSize: 18))),
                            ),
                            title: Text(
                                '${f.liters.toStringAsFixed(1)}L — ${f.km.toStringAsFixed(0)} km',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${f.pricePerLiter.toStringAsFixed(2)} MAD/L'
                                '${cons != null ? '  ·  ${cons.toStringAsFixed(1)} L/100' : ''}',
                                style: const TextStyle(fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '${f.totalPrice.toStringAsFixed(0)} MAD',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        DateFormat('dd/MM/yy').format(f.date),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _confirmDelete(context,
                                      provider, f.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14,
                                        color: AppTheme.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous supprimer ce plein ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              provider.deleteFuelEntry(id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}
