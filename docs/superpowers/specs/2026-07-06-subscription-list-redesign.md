# Subscription List Redesign — Sub-Projekt 1

**Datum:** 2026-07-06  
**Status:** Approved  
**Scope:** Subscription-Liste (SubscriptionIndexView + SubscriptionListComponent)

---

## Ziel

Den Hauptscreen der App funktioneller, schöner und schneller machen:
- Dark-Gradient-Header mit Spending-Summary und Budget-Warnung
- Horizontal scrollbarer Upcoming-Payments-Strip
- Swipe-Aktionen (beide Seiten) auf Listenzeilen
- Neue Card-Optik mit Favicon-Farb-Akzentbalken
- Performance: SharedPreferences einmal laden statt pro Zeile

---

## Design-Entscheidungen

| Bereich | Entscheidung |
|---|---|
| Header | Dark Gradient (`#1a1a2e → #16213e → #0f3460`) |
| Spending-Cards | Zwei Glassmorphism-Cards: Monat + Jahr |
| Budget-Bar | Dünner Fortschrittsbalken unter Spending-Cards |
| Budget-Warnung | Banner direkt unter Header, nur wenn Budget gesetzt + überschritten |
| Search | Eigener Bereich unter Header (nicht mehr im NavBar) |
| Upcoming | Horizontaler Chip-Strip, 7-Tage-Fenster, „Alle →" Link |
| Swipe rechts (→) | Pin / Unpin (blau) |
| Swipe links (←) | Pause (orange) + Löschen (rot) |
| List-Cards | 3px Akzentbalken links (Favicon-Farbe), Datum + Zyklus, Dringlichkeits-Badge |
| Badge-Farben | Rot < 3 Tage, Orange < 14 Tage, Grün ≥ 14 Tage |
| Paused-State | Ausgegrauter Hintergrund (#f9f9f9), gedimmter Text |
| Tab-Bar | Unverändert (CupertinoIcons) |

---

## Architektur

### Neue / geänderte Dateien

```
lib/views/subscription/
  index.dart              ← komplett überarbeitet
lib/views/components/
  subscription_list_component.dart  ← überarbeitet
  subscription_header.dart          ← NEU: dark gradient header widget
  upcoming_strip.dart               ← NEU: horizontaler chip strip
  budget_warning_banner.dart        ← NEU: banner widget
```

### Datenfluss

```
SubscriptionIndexView
  ├── SubscriptionHeader (stateless)
  │     ├── monthlySpent, yearlySpent (von Provider)
  │     ├── budgetLimit (von SharedPreferences, einmalig geladen)
  │     └── BudgetWarningBanner (conditional)
  ├── Search TextField
  ├── UpcomingStrip (stateless)
  │     └── subscriptions der nächsten 7 Tage (gefiltert)
  └── ListView.builder
        └── SubscriptionListComponent (überarbeitet)
              ├── displayCategories (von Parent übergeben, nicht per Item geladen)
              └── accentColor (von Favicon via colorCache, gecacht im Parent)
```

---

## Komponenten-Spec

### 1. SubscriptionHeader

**Datei:** `lib/views/components/subscription_header.dart`

```dart
class SubscriptionHeader extends StatelessWidget {
  final double monthlySpent;
  final double yearlySpent;
  final double? budgetLimit;   // null = kein Budget gesetzt
  final Currency currency;
  final VoidCallback onSortTap;
  final VoidCallback onAddTap;
}
```

- Gradient: `LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)])`
- Zwei `spend-cards` mit `BackdropFilter` (Glassmorphism)
- Budget-Bar: `LinearProgressIndicator` mit Farbverlauf Grün→Orange→Rot
- Wenn `budgetLimit != null && monthlySpent > budgetLimit`: `BudgetWarningBanner` einblenden

### 2. BudgetWarningBanner

**Datei:** `lib/views/components/budget_warning_banner.dart`

```dart
class BudgetWarningBanner extends StatelessWidget {
  final double spent;
  final double limit;
  final Currency currency;
}
```

- Hintergrund: `Color(0x26FF3B30)` (rot mit 15% Opacity) auf dunklem Gradient-Hintergrund
- Border: `Color(0x59FF3B30)`
- Text: Betrag über Limit, zweite Zeile Limit-Wert
- Nur sichtbar wenn `spent > limit`

### 3. UpcomingStrip

**Datei:** `lib/views/components/upcoming_strip.dart`

```dart
class UpcomingStrip extends StatelessWidget {
  final List<Subscription> subscriptions;  // bereits gefiltert: nächste 7 Tage, nicht pausiert
  final Currency currency;
  final VoidCallback onShowAll;
}
```

- Horizontaler `ListView` (scrollDirection: Axis.horizontal)
- Jeder Chip: 72px breit, App-Icon (buildImage()), Name, Tage-Countdown
- Chip-Farbe Tage: `< 3` → rot, `< 7` → orange, sonst grau
- „Alle →" Button öffnet volle Timeline (Sub-Projekt 2, später)

### 4. SubscriptionListComponent (überarbeitet)

**Datei:** `lib/views/components/subscription_list_component.dart`

Änderungen:
- Entfernt: eigenes SharedPreferences-Laden (`displayCategories`)
- Neu: `displayCategories` als Parameter vom Parent
- Neu: `accentColor` als optionaler Parameter (Favicon-Dominant-Color)
- Neu: 3px Akzentbalken links (`Container` mit `BoxDecoration`)
- Neu: Datum + Zyklus statt nur „X Tage" im Subtitle
- Neu: Dringlichkeits-Badge (roter/oranger/grüner Container)
- Neu: Paused-State Styling (gedimmter Background + Text)

**Swipe-Aktionen via `flutter_slidable` Package:**
```yaml
# pubspec.yaml
flutter_slidable: ^3.1.1
```

```dart
Slidable(
  key: ValueKey(subscription.id),
  startActionPane: ActionPane(           // → rechts wischen = Pin
    motion: DrawerMotion(),
    children: [
      SlidableAction(icon: CupertinoIcons.pin_fill, backgroundColor: Colors.blue,
                     onPressed: (_) => onTogglePin()),
    ],
  ),
  endActionPane: ActionPane(             // ← links wischen = Pause + Löschen
    motion: DrawerMotion(),
    children: [
      SlidableAction(icon: CupertinoIcons.pause, backgroundColor: Colors.orange,
                     onPressed: (_) => onTogglePause()),
      SlidableAction(icon: CupertinoIcons.delete, backgroundColor: Colors.red,
                     onPressed: (_) => onDelete()),
    ],
  ),
  child: _buildCard(),
)
```

### 5. SubscriptionIndexView (überarbeitet)

Änderungen:
- Budget-Limit einmalig aus SharedPreferences laden (key: `budgetLimit`)
- `displayCategories` einmalig laden, als Parameter weitergeben
- `colorCache` für Favicon-Farben (bereits vorhanden in StatisticView, hierher migrieren)
- Search-TextField aus NavBar herauslösen → eigener Widget unter Header
- `calculateYearlySpent` bleibt, `calculateMonthlySpent` als eigene Methode extrahieren
- Upcoming-Filter: `subscriptions.where(s => !s.isPaused && s.remainingDays() <= 7)`

---

## Settings-Erweiterung

Budget-Limit konfigurierbar in Settings:
- Neues Feld: „Monatliches Budget" (optional, leer = deaktiviert)
- Key: `budgetLimit` (double) in SharedPreferences
- Nur Eingabe + Speichern, kein eigener Screen nötig

---

## Performance

| Problem | Fix |
|---|---|
| SharedPreferences pro Listeneintrag | Einmalig in `initState` von IndexView laden |
| Favicon-Farben per Item berechnet | `colorCache` Map im IndexView, lazy befüllt |
| `setState` bei jedem Search-Keystroke | Debounce 200ms mit `Timer` |

---

## Was NICHT geändert wird

- Navigation-Struktur (4 Tabs bleiben)
- Subscription Create/Edit Flows
- Categories View
- Statistics View (Sub-Projekt 3)
- Datenmodell / Provider / Persistence

---

## Abgrenzung zu Sub-Projekt 2 + 3

- **Sub-Projekt 2** — Upcoming Payments volle Timeline (der „Alle →" Link in diesem Spec)
- **Sub-Projekt 3** — Statistics Redesign mit Budget-Warnung in Charts

---

## Akzeptanzkriterien

- [ ] Header zeigt korrekte monatliche + jährliche Summen
- [ ] Budget-Warnung erscheint nur wenn Limit gesetzt UND überschritten
- [ ] Upcoming-Strip zeigt Abos der nächsten 7 Tage, sortiert nach Datum
- [ ] Swipe → pinnt/unpinnt, Swipe ← pausiert / löscht mit Bestätigung
- [ ] Akzentbalken hat korrekte Favicon-Dominant-Color
- [ ] Paused-Abos sind visuell deutlich gedimmt
- [ ] SharedPreferences wird einmalig pro Screen-Load geladen
- [ ] Dark Mode funktioniert (Gradient bleibt, Cards passen sich an)
- [ ] Keine Regression in bestehenden Flows
