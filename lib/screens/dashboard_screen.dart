import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/maintenance_entry.dart';
import '../utils/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final vehicle = provider.currentVehicle;
        if (vehicle == null) return const Center(child: CircularProgressIndicator());

        final cons = vehicle.avgConsumption;
        final now = DateTime.now();
        final monthTotal = vehicle.monthlyTotal(now);
        final costPerKm = vehicle.costPerKm;
        final lastFuel = vehicle.lastFuelEntry;
        final alerts = vehicle.maintenanceEntries
            .where((m) => m.alertLevel != AlertLevel.ok)
            .toList();

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert banner
                  if (alerts.isNotEmpty) _buildAlertBanner(context, alerts),

                  // Metric cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _MetricCard(
                        icon: '⛽',
                        label: 'Consommation moy.',
                        value: cons != null
                            ? '${cons.toStringAsFixed(1)} L'
                            : '--',
                        sub: 'pour 100 km',
                        color: AppTheme.accentBlue,
                      ),
                      _MetricCard(
                        icon: '💳',
                        label: 'Coût ce mois',
                        value: '${monthTotal.toStringAsFixed(0)} MAD',
                        sub: DateFormat('MMM yyyy', 'fr').format(now),
                        color: AppTheme.green,
                      ),
                      _MetricCard(
                        icon: '📊',
                        label: 'Coût par km',
                        value: costPerKm != null
                            ? '${costPerKm.toStringAsFixed(2)} MAD'
                            : '--',
                        sub: 'total cumulé',
                        color: AppTheme.purple,
                      ),
                      _MetricCard(
                        icon: '🔧',
                        label: 'Alertes entretien',
                        value: '${vehicle.pendingAlerts}',
                        sub: vehicle.pendingAlerts > 0
                            ? 'À traiter'
                            : 'Tout OK ✓',
                        color: vehicle.pendingAlerts > 0
                            ? AppTheme.amber
                            : AppTheme.green,
                        highlight: vehicle.pendingAlerts > 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Consumption chart
                  if (vehicle.fuelEntries.length >= 2) ...[
                    _SectionCard(
                      title: '📈 Consommation (L/100km)',
                      child: SizedBox(
                        height: 180,
                        child: _ConsumptionChart(vehicle: vehicle),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Category chart
                  _SectionCard(
                    title: '🌈 Dépenses par catégorie',
                    child: SizedBox(
                      height: 180,
                      child: _CategoryChart(vehicle: vehicle),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recent operations
                  _SectionCard(
                    title: '🕐 Dernières opérations',
                    child: _RecentList(vehicle: vehicle, provider: provider),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertBanner(
      BuildContext context, List<MaintenanceEntry> alerts) {
    final urgent = alerts.where((a) => a.alertLevel == AlertLevel.danger).toList();
    final warning = alerts.where((a) => a.alertLevel == AlertLevel.warning).toList();
    return Column(
      children: [
        if (urgent.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Text('🚨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${urgent.length} entretien(s) en retard !',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                      Text(
                        urgent.map((a) => a.type.label).join(', '),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (warning.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${warning.length} entretien(s) à prévoir bientôt',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E)),
                      ),
                      Text(
                        warning.map((a) => a.type.label).join(', '),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final bool highlight;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlight
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE2E8F0),
        ),
      ),
      color: highlight ? const Color(0xFFFFFBEB) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6))),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: highlight ? AppTheme.amber : color)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ConsumptionChart extends StatelessWidget {
  final vehicle;
  const _ConsumptionChart({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final sorted = [...vehicle.fuelEntries]
      ..sort((a, b) => a.km.compareTo(b.km));
    final spots = <FlSpot>[];
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].km - sorted[i - 1].km;
      if (diff > 0) {
        spots.add(FlSpot(
            i.toDouble(), (sorted[i].liters / diff) * 100));
      }
    }
    if (spots.isEmpty) {
      return const Center(
          child: Text('Ajoutez au moins 2 pleins',
              style: TextStyle(color: Colors.grey)));
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(1),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.accentBlue,
            barWidth: 2.5,
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accentBlue.withOpacity(0.08),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.accentBlue,
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final vehicle;
  const _CategoryChart({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    double carburant = 0, entretien = 0, reparation = 0, assurance = 0, autre = 0;
    for (final f in vehicle.fuelEntries) carburant += f.totalPrice;
    for (final e in vehicle.expenses) {
      switch (e.type.name) {
        case 'carburant': carburant += e.amount; break;
        case 'entretien': entretien += e.amount; break;
        case 'reparation': reparation += e.amount; break;
        case 'assurance': assurance += e.amount; break;
        default: autre += e.amount;
      }
    }
    for (final m in vehicle.maintenanceEntries) entretien += m.cost;

    final data = {
      'Carburant': carburant,
      'Entretien': entretien,
      'Réparation': reparation,
      'Assurance': assurance,
      'Autre': autre,
    };
    final filtered = data.entries.where((e) => e.value > 0).toList();
    if (filtered.isEmpty) {
      return const Center(
          child: Text('Aucune dépense enregistrée',
              style: TextStyle(color: Colors.grey)));
    }
    final colors = [
      AppTheme.accentBlue,
      AppTheme.green,
      AppTheme.amber,
      AppTheme.purple,
      AppTheme.gray,
    ];
    final total = filtered.fold(0.0, (s, e) => s + e.value);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: filtered.asMap().entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value.value,
                  color: colors[entry.key % colors.length],
                  title: '${((entry.value.value / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: filtered.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[entry.key % colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(entry.value.key,
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  final vehicle;
  final AppProvider provider;
  const _RecentList({required this.vehicle, required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[];
    for (final f in vehicle.fuelEntries) {
      items.add({
        'date': f.date,
        'title': 'Plein ${f.liters.toStringAsFixed(1)}L',
        'sub': '${f.km.toStringAsFixed(0)} km · ${f.pricePerLiter.toStringAsFixed(2)} MAD/L',
        'amount': f.totalPrice,
        'icon': '⛽',
        'color': AppTheme.accentBlue,
      });
    }
    for (final e in vehicle.expenses) {
      items.add({
        'date': e.date,
        'title': e.note ?? e.type.label,
        'sub': e.type.label,
        'amount': e.amount,
        'icon': e.type.emoji,
        'color': AppTheme.expenseTypeColor(e.type.name),
      });
    }
    for (final m in vehicle.maintenanceEntries) {
      items.add({
        'date': m.date,
        'title': m.type.label + (m.note != null ? ' — ${m.note}' : ''),
        'sub': '${m.km.toStringAsFixed(0)} km',
        'amount': m.cost,
        'icon': m.type.emoji,
        'color': AppTheme.green,
      });
    }
    items.sort((a, b) =>
        (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final recent = items.take(6).toList();

    if (recent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Aucune opération\nCommencez par ajouter un plein ⛽',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: recent.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(item['icon'] as String,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          title: Text(item['title'] as String,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(item['sub'] as String,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(item['amount'] as double).toStringAsFixed(0)} MAD',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                DateFormat('dd/MM/yy').format(item['date'] as DateTime),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
