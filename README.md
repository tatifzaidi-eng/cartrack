# 🚗 CarTrack — Application Flutter

Application mobile de gestion et suivi de consommation et dépenses automobile.

## Fonctionnalités

- ⛽ **Carburant** — Saisie prix/litre + prix total, calcul automatique des litres et L/100km
- 🔧 **Entretiens** — Suivi avec alertes kilométrique et par date (vidange, pneus, freins...)
- 💳 **Dépenses** — Toutes les dépenses par catégorie
- 📊 **Dashboard** — Métriques clés + graphiques en temps réel
- 📈 **Statistiques** — Dépenses mensuelles, répartition, évolution consommation
- 🚗 **Multi-véhicules** — Gérez plusieurs voitures
- 🌙 **Mode sombre**
- 💾 **Stockage local** — Données sauvegardées sur l'appareil

## Obtenir l'APK via GitHub Actions

1. **Forkez** ce dépôt ou uploadez-le sur votre GitHub
2. Allez dans l'onglet **Actions**
3. Le build démarre automatiquement à chaque push sur `main`
4. Téléchargez l'APK depuis **Actions → Build Flutter APK → Artifacts**

> L'APK est aussi créé automatiquement dans **Releases** à chaque push sur main.

## Build local (optionnel)

```bash
# Installer Flutter 3.19.6
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

## Structure du projet

```
lib/
├── main.dart                  # Point d'entrée + navigation
├── models/
│   ├── vehicle.dart           # Modèle véhicule
│   ├── fuel_entry.dart        # Modèle plein carburant
│   ├── expense.dart           # Modèle dépense
│   └── maintenance_entry.dart # Modèle entretien
├── providers/
│   └── app_provider.dart      # State management (Provider)
├── screens/
│   ├── dashboard_screen.dart  # Dashboard
│   ├── fuel_screen.dart       # Carburant
│   ├── maintenance_screen.dart# Entretiens
│   ├── expenses_screen.dart   # Dépenses
│   └── stats_screen.dart      # Statistiques
└── utils/
    └── app_theme.dart         # Thème et couleurs
```
