import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final vehicle = provider.currentVehicle;
        if (vehicle == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalSpent = vehicle.totalSpent;
        final fuelTotal = vehicle.fuelEntries
            .fold(0.0, (s, f) => s + f.totalPrice);
        final maintTotal = vehicle.maintenanceEntries
            .fold(0.0, (s, m) => s + m.cost);
        final totalKm = vehicle.totalKm;
        final avgCons = vehicle.avgConsumption;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                      label: 'Dépenses totales',
                      value: '${totalSpent.toStringAsFixed(0)} MAD',
                      color: AppTheme.red),
                  _StatCard(
                      label: 'Carburant total',
                      value: '${fuelTotal.toStringAsFixed(0)} MAD',
                      color: AppTheme.accentBlue),
                  _StatCard(
                      label: 'Km parcourus',
                      value: totalKm.toStringAsFixed(0),
                      color: AppTheme.green),
                  _StatCard(
                      label: 'Conso. moyenne',
                      value: avgCons != null
                          ? '${avgCons.toStringAsFixed(1)} L'
                          : '--',
                      color: AppTheme.purple),
                ],
              ),
              const SizedBox(height: 16),

              // Monthly bar chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📊 Dépenses mensuelles (6 mois)',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _MonthlyBarChart(vehicle: vehicle),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pie + consumption
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🌈 Répartition',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 150,
                              child: _PieChartWidget(vehicle: vehicle),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⛽ Consommation',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 150,
                              child: _ConsLineChart(vehicle: vehicle),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final vehicle;
  const _MonthlyBarChart({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return m;
    });
    final data = months.map((m) => vehicle.monthlyTotal(m)).toList();
    final labels =
        months.map((m) => DateFormat('MM/yy').format(m)).toList();

    return BarChart(
      BarChartData(
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
              reservedSize: 45,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= 0 && i < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(labels[i],
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: AppTheme.accentBlue,
                width: 22,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  final vehicle;
  const _PieChartWidget({required this.vehicle});

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

    final data = [carburant, entretien, reparation, assurance, autre];
    final colors = [
      AppTheme.accentBlue, AppTheme.green, AppTheme.amber,
      AppTheme.purple, AppTheme.gray
    ];
    final total = data.fold(0.0, (s, v) => s + v);
    if (total == 0) {
      return const Center(
          child: Text('Aucune donnée', style: TextStyle(color: Colors.grey, fontSize: 12)));
    }

    return PieChart(
      PieChartData(
        sections: data.asMap().entries.where((e) => e.value > 0).map((e) {
          return PieChartSectionData(
            value: e.value,
            color: colors[e.key],
            title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }
}

class _ConsLineChart extends StatelessWidget {
  final vehicle;
  const _ConsLineChart({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final sorted = [...vehicle.fuelEntries]
      ..sort((a, b) => a.km.compareTo(b.km));
    final spots = <FlSpot>[];
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].km - sorted[i - 1].km;
      if (diff > 0) {
        spots.add(FlSpot(i.toDouble(), (sorted[i].liters / diff) * 100));
      }
    }
    if (spots.isEmpty) {
      return const Center(
          child: Text('Pas assez de données',
              style: TextStyle(color: Colors.grey, fontSize: 12)));
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.green,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.green.withOpacity(0.08),
            ),
            dotData: FlDotData(show: spots.length < 10),
          ),
        ],
      ),
    );
  }
}
