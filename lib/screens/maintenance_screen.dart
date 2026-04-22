import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/maintenance_entry.dart';
import '../utils/app_theme.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _nextKmCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _nextDate;
  MaintenanceType _selectedType = MaintenanceType.vidange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kmCtrl.dispose();
    _costCtrl.dispose();
    _nextKmCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isNext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext ? (DateTime.now()) : _selectedDate,
      firstDate: isNext ? DateTime.now() : DateTime(2000),
      lastDate: isNext
          ? DateTime.now().add(const Duration(days: 365 * 5))
          : DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isNext) _nextDate = picked;
        else _selectedDate = picked;
      });
    }
  }

  void _saveMaintenance() {
    if (!_formKey.currentState!.validate()) return;
    final entry = MaintenanceEntry(
      type: _selectedType,
      date: _selectedDate,
      km: double.parse(_kmCtrl.text),
      cost: double.tryParse(_costCtrl.text) ?? 0,
      nextKm: double.tryParse(_nextKmCtrl.text),
      nextDate: _nextDate,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );
    context.read<AppProvider>().addMaintenance(entry);
    _kmCtrl.clear();
    _costCtrl.clear();
    _nextKmCtrl.clear();
    _noteCtrl.clear();
    setState(() => _nextDate = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Entretien enregistré ✓'),
          backgroundColor: AppTheme.green),
    );
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final vehicle = provider.currentVehicle;
        final entries = vehicle?.maintenanceEntries ?? [];
        final sorted = [...entries]
          ..sort((a, b) => b.date.compareTo(a.date));
        final currentKm = vehicle?.fuelEntries.isEmpty == true
            ? 0.0
            : (vehicle?.fuelEntries
                    .reduce((a, b) => a.km > b.km ? a : b)
                    .km ?? 0.0);

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.accentBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.accentBlue,
              tabs: const [
                Tab(text: '📋 Historique'),
                Tab(text: '➕ Ajouter'),
                Tab(text: '🔔 Alertes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // History tab
                  _buildHistoryTab(sorted, currentKm, provider),
                  // Add tab
                  _buildAddTab(),
                  // Alerts tab
                  _buildAlertsTab(entries, currentKm),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab(List<MaintenanceEntry> sorted, double currentKm,
      AppProvider provider) {
    if (sorted.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucun entretien enregistré\nAppuyez sur "Ajouter" pour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final m = sorted[index];
        double? progress;
        Color progressColor = AppTheme.green;
        if (m.nextKm != null && m.km > 0 && m.nextKm! > m.km) {
          final total = m.nextKm! - m.km;
          final done = (currentKm - m.km).clamp(0.0, total);
          progress = done / total;
          if (progress > 0.8) progressColor = AppTheme.red;
          else if (progress > 0.6) progressColor = AppTheme.amber;
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(m.type.emoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          m.type.label +
                              (m.note != null ? ' — ${m.note}' : ''),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                          '${m.km.toStringAsFixed(0)} km'
                          '${m.nextKm != null ? '  ·  Prochain: ${m.nextKm!.toStringAsFixed(0)} km' : ''}'
                          '${m.nextDate != null ? '  ·  avant ${DateFormat('dd/MM/yy').format(m.nextDate!)}' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      if (progress != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor:
                                      AlwaysStoppedAnimation(progressColor),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontSize: 10, color: progressColor)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        m.cost > 0
                            ? '${m.cost.toStringAsFixed(0)} MAD'
                            : '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(DateFormat('dd/MM/yy').format(m.date),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _confirmDelete(context,
                          context.read<AppProvider>(), m.id),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Icon(Icons.close,
                            size: 13, color: AppTheme.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('➕ Enregistrer un entretien',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                DropdownButtonFormField<MaintenanceType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: "Type d'entretien"),
                  items: MaintenanceType.values.map((t) {
                    return DropdownMenuItem(
                        value: t,
                        child: Text('${t.emoji} ${t.label}'));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(false),
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
                                  size: 15, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(_selectedDate),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _kmCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Kilométrage (km)'),
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
                        controller: _costCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Coût (MAD)',
                            hintText: 'ex: 350'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _nextKmCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Prochain à (km)',
                            hintText: 'ex: 50000'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, size: 15, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _nextDate != null
                              ? 'Prochain avant : ${DateFormat('dd/MM/yyyy').format(_nextDate!)}'
                              : 'Prochain avant (date optionnel)',
                          style: TextStyle(
                              fontSize: 13,
                              color: _nextDate != null
                                  ? null
                                  : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Note / Garage (optionnel)'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveMaintenance,
                    child: const Text('✓ Enregistrer l\'entretien'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsTab(
      List<MaintenanceEntry> entries, double currentKm) {
    final now = DateTime.now();
    final byType = <MaintenanceType, MaintenanceEntry>{};
    for (final m in [...entries]
        ..sort((a, b) => b.date.compareTo(a.date))) {
      byType.putIfAbsent(m.type, () => m);
    }
    final alertItems = byType.values
        .where((m) => m.nextKm != null || m.nextDate != null)
        .toList();

    if (alertItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucune alerte.\nEnregistrez des entretiens avec le km ou la date du prochain pour activer les alertes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: alertItems.map((m) {
        String msg = '';
        Color bgColor;
        Color borderColor;
        String icon;

        bool isUrgent = false;
        bool isWarning = false;

        if (m.nextDate != null) {
          final diff = m.nextDate!.difference(now).inDays;
          if (diff < 0) {
            isUrgent = true;
            msg = 'En retard de ${diff.abs()} jours';
          } else if (diff < 30) {
            isWarning = true;
            msg = 'Dans $diff jours (${DateFormat('dd/MM/yy').format(m.nextDate!)})';
          } else {
            msg = 'Prévu le ${DateFormat('dd/MM/yy').format(m.nextDate!)}';
          }
        }
        if (m.nextKm != null && currentKm > 0) {
          final rem = m.nextKm! - currentKm;
          if (rem <= 0) {
            isUrgent = true;
            msg += (msg.isNotEmpty ? '  ·  ' : '') +
                'Dépassé de ${rem.abs().toStringAsFixed(0)} km';
          } else if (rem < 1000) {
            isWarning = true;
            msg += (msg.isNotEmpty ? '  ·  ' : '') +
                'Encore ${rem.toStringAsFixed(0)} km';
          } else if (msg.isEmpty) {
            msg = 'Encore ${rem.toStringAsFixed(0)} km';
          }
        }

        if (isUrgent) {
          bgColor = const Color(0xFFFEF2F2);
          borderColor = const Color(0xFFFCA5A5);
          icon = '🚨';
        } else if (isWarning) {
          bgColor = const Color(0xFFFFFBEB);
          borderColor = const Color(0xFFFDE68A);
          icon = '⚠️';
        } else {
          bgColor = const Color(0xFFF0FDF4);
          borderColor = const Color(0xFFBBF7D0);
          icon = '✅';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${m.type.emoji} ${m.type.label}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(msg,
                        style: const TextStyle(fontSize: 12)),
                    Text(
                        'Dernier entretien : ${DateFormat('dd/MM/yy').format(m.date)} à ${m.km.toStringAsFixed(0)} km',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Supprimer cet entretien ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              provider.deleteMaintenance(id);
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
