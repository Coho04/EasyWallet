# Statistics Redesign — Sub-Projekt 2

**Datum:** 2026-07-07  
**Status:** Approved  
**Scope:** StatisticView + ChartDetailPage

---

## Ziel

Statistik-Seite auf gleiches visuelles Niveau wie Subscription-Liste heben:
- Selber Dark-Gradient-Header (Monat + Jahr) via bestehenden `SubscriptionHeader`
- 5 fokussierte Karten statt 3 überlappenden
- Neue Karten: „Verbleibend" + „Top 3 Abos"
- Charts bleiben, nur neue Card-Hülle
- ChartDetailPage: Gradient statt flat CupertinoNavigationBar

---

## Design-Entscheidungen

| Bereich | Entscheidung |
|---|---|
| Header | Reuse `SubscriptionHeader` (Monat + Jahr, budgetLimit aus monthlyLimit) |
| Karte 1 | **Verbleibend**: Bis Monatsende + Bis Jahresende |
| Karte 2 | **Top 3 Abos**: 3 teuerste aktive Abos nach monatlichem Äquivalent |
| Karte 3 | **Kostenverteilung**: Bestehender PieChart in neuer StatCard |
| Karte 4 | **Monatlicher Verlauf**: Bestehender SfCartesianChart in neuer StatCard |
| Karte 5 | **App Gesamt**: Seit Installation + Aktiv/Pausiert Anzahl |
| Card-Style | Weiß/dunkel, borderRadius 14, subtiler Schatten, Cupertino-Farben |
| Detail-Seite | Gradient-Header (kein CupertinoNavigationBar), Rest unverändert |

---

## Architektur

### Neue / geänderte Dateien

```
lib/views/main/
  statistic.dart              ← komplett überarbeitet
lib/views/statistics/
  show.dart                   ← Header ersetzt
lib/views/components/
  stat_card.dart              ← NEU: reusable Karten-Wrapper
```

### Bestehende Komponenten bleiben

- `CardSection`, `CardDetailRow`, `CardActionButton` — unverändert (andere Screens nutzen sie)
- `SubscriptionHeader` — wiederverwendet
- Alle Chart-Widgets (PieChart, SfCartesianChart) — unverändert

---

## Komponenten-Spec

### StatCard (neu)

```dart
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
}
```

- Hintergrund: `CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context)`
- Border-Radius: 14
- Padding: 14
- Schatten: `BoxShadow(color: black 0.06, blurRadius: 8, offset: Offset(0,2))`
- Header-Zeile: Icon (16px, grau) + Titel (13px, w600, grau)
- Divider + Children darunter

### Karte 1: Verbleibend

Zwei Zeilen:
- „Bis Monatsende" → `calculateExpensesToEndOfMonth()` (bereits async, wird in `initState` geladen)
- „Bis Jahresende" → `calculateExpensesToEndOfYear()`
- Icon: `CupertinoIcons.calendar_badge_minus`

### Karte 2: Top 3 Abos

Berechnung: `monthlyEquivalent = repeatPattern == 'yearly' ? amount/12 : amount`
Sortierung: descending by monthlyEquivalent, take first 3, only !isPaused

Jede Zeile: favicon (28px) + Name + „X €/Monat" rechts
Tippbar → `SubscriptionShowView`

### Karte 3: Kostenverteilung

Bestehender `buildPieChart()` call + „Alle →" Button → `ChartDetailPage`
Icon: `CupertinoIcons.chart_pie`

### Karte 4: Monatlicher Verlauf

Bestehender `_buildChart(_makeYearlyToMonthlyData(...))` + „Alle →" → `ChartDetailPage`
Icon: `CupertinoIcons.chart_bar`

### Karte 5: App Gesamt

Drei Zeilen:
- „Gesamtausgaben": `calculateExpensesSinceInstallation()`
- „Aktive Abos": `subscriptions.where((s) => !s.isPaused).length`
- „Pausiert": `subscriptions.where((s) => s.isPaused).length`
- Icon: `CupertinoIcons.info_circle`

### StatisticView Layout

```
CustomScrollView
  SliverToBoxAdapter → SubscriptionHeader
  SliverPadding(16)
    SliverList
      StatCard (Verbleibend)
      SizedBox(12)
      StatCard (Top 3)
      SizedBox(12)
      StatCard (Kostenverteilung)
      SizedBox(12)
      StatCard (Verlauf)
      SizedBox(12)
      StatCard (Gesamt)
      SizedBox(85) — Tab-Bar Abstand
```

### ChartDetailPage

- `CupertinoNavigationBar` ersetzen durch: Gradient-Container mit safe-area-padding + Titel + Back-Button
- Gleiche Gradient-Farben wie SubscriptionHeader
- Rest des Screens unverändert

---

## Performance

- `calculateExpensesToEndOfMonth/Year` (async) einmalig in `_init()` laden, Ergebnis in State speichern
- `monthlyLimit` aus SharedPreferences einmalig in `_init()`
- Charts lazy — keine Änderung nötig

---

## Was NICHT geändert wird

- Chart-Berechnungsmethoden
- `ChartDetailPage` Chart-Inhalt
- `CardSection` / `CardDetailRow` / `CardActionButton` (andere Screens)
- Navigation-Struktur

---

## Akzeptanzkriterien

- [ ] Header zeigt korrekte monatliche + jährliche Summen
- [ ] 5 Karten sichtbar, korrekte Daten
- [ ] Top 3 zeigt teuerste aktive Abos, sortiert nach monatlichem Äquivalent
- [ ] Charts öffnen ChartDetailPage via „Alle →"
- [ ] ChartDetailPage hat Gradient-Header mit Back-Button
- [ ] Dark Mode funktioniert
- [ ] Keine Regression in anderen Screens
