import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fuel_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/stats_screen.dart';
import 'models/vehicle.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const CarTrackApp(),
    ),
  );
}

class CarTrackApp extends StatelessWidget {
  const CarTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'CarTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    FuelScreen(),
    MaintenanceScreen(),
    ExpensesScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final vehicle = provider.currentVehicle;
        final pendingAlerts = vehicle?.pendingAlerts ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('🚗 ', style: TextStyle(fontSize: 20)),
                const Text('CarTrack',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                if (provider.vehicles.length > 1)
                  Expanded(
                    child: DropdownButton<int>(
                      value: provider.currentVehicleIndex,
                      dropdownColor: const Color(0xFF1E40AF),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white70),
                      items: provider.vehicles
                          .asMap()
                          .entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (i) {
                        if (i != null) provider.switchVehicle(i);
                      },
                    ),
                  )
                else
                  Text(
                    vehicle?.name ?? '',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  provider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: provider.toggleDarkMode,
                tooltip: 'Mode sombre',
              ),
              IconButton(
                icon: const Icon(Icons.directions_car, color: Colors.white),
                onPressed: () => _showVehicleManager(context, provider),
                tooltip: 'Gérer les véhicules',
              ),
            ],
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.local_gas_station_outlined),
                activeIcon: Icon(Icons.local_gas_station),
                label: 'Carburant',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: pendingAlerts > 0,
                  label: Text('$pendingAlerts'),
                  child: const Icon(Icons.build_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: pendingAlerts > 0,
                  label: Text('$pendingAlerts'),
                  child: const Icon(Icons.build),
                ),
                label: 'Entretiens',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.credit_card_outlined),
                activeIcon: Icon(Icons.credit_card),
                label: 'Dépenses',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVehicleManager(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _VehicleManagerSheet(provider: provider),
    );
  }
}

class _VehicleManagerSheet extends StatefulWidget {
  final AppProvider provider;
  const _VehicleManagerSheet({required this.provider});

  @override
  State<_VehicleManagerSheet> createState() => _VehicleManagerSheetState();
}

class _VehicleManagerSheetState extends State<_VehicleManagerSheet> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚗 Gérer les véhicules',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          // Vehicle list
          ...widget.provider.vehicles.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: i == widget.provider.currentVehicleIndex
                    ? AppTheme.accentBlue
                    : Colors.grey.shade200,
                child: Text(v.name[0].toUpperCase(),
                    style: TextStyle(
                        color: i == widget.provider.currentVehicleIndex
                            ? Colors.white
                            : Colors.grey)),
              ),
              title: Text(v.name),
              subtitle: Text(
                  '${v.fuelEntries.length} pleins · ${v.expenses.length} dépenses'),
              trailing: widget.provider.vehicles.length > 1
                  ? IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: AppTheme.red),
                      onPressed: () {
                        widget.provider.deleteVehicle(i);
                        Navigator.pop(context);
                      },
                    )
                  : null,
              onTap: () {
                widget.provider.switchVehicle(i);
                Navigator.pop(context);
              },
            );
          }),
          const Divider(),
          // Add vehicle
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Nom du nouveau véhicule',
                      isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.trim().isNotEmpty) {
                    widget.provider.addVehicle(_nameCtrl.text.trim());
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
