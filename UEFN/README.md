# UEFN-Verse-Code für eine eigene Fortnite-Map

Zwei Verse-Geräte als Grundgerüst für eine selbstgebaute Insel:

| Datei | Was es macht |
|---|---|
| `Verse/arena_manager.verse` | Rundenmanager: Startknopf → Countdown → Runde → Sieger → nächste Runde. Zählt Eliminierungen, verteilt Start-Loadouts, beendet das Match. |
| `Verse/loot_zone.verse` | Loot-Zone pro POI: Spieler betritt den Trigger, bekommt eine zufällige Waffe nach Seltenheits-Gewichtung, danach Cooldown. |

Beide sind `creative_device`-Klassen — sie werden in UEFN wie normale Geräte
ins Level gezogen und im Details-Panel verkabelt.

## Einrichtung in UEFN

1. **Projekt anlegen:** UEFN öffnen → *New Project* → z. B. leeres Island-Template.
2. **Verse-Ordner öffnen:** Menü *Verse* → *Verse Explorer*. Rechtsklick auf den
   Projektnamen → *Add new Verse file to project*.
3. **Dateien einfügen:** Den Inhalt von `arena_manager.verse` und `loot_zone.verse`
   in je eine neue Datei kopieren. Der Dateiname muss **nicht** dem Klassennamen
   entsprechen, aber es hält alles übersichtlich.
4. **Kompilieren:** Menü *Verse* → *Build Verse Code* (oder `Strg + Umschalt + B`).
   Erst danach tauchen die Geräte im Content Browser auf.
5. **Ins Level ziehen:** Im Content Browser nach `arena_manager` bzw. `loot_zone`
   suchen und in die Map ziehen.
6. **Referenzen setzen:** Gerät anklicken → Details-Panel → jedes `@editable`-Feld
   auf ein echtes Gerät in der Map zeigen lassen.
7. **Testen:** *Launch Session*. Änderungen an Verse-Code brauchen jedes Mal ein
   neues *Build Verse Code*, danach *Push Changes*.

## Was du im Level platzieren musst

Für `arena_manager`:

- **Button Device** → `StartButton`
- **HUD Message Device** → `HUD`
- **Player Spawn Pads** → `PlayerSpawners` (Array, alle Spawner reinziehen)
- **Item Granter Devices** → `StartingGranters` (Start-Loadout, z. B. Waffe + Mats)
- **End Game Device** → `EndGame`

Einstellungen: `RoundDurationSeconds`, `CountdownSeconds`, `EliminationsToWin`,
`RoundsPerMatch` (0 = endlos).

Für jede `loot_zone` (ein Gerät pro POI):

- **Trigger Device** mit Volume über dem Gebiet → `Trigger`
- **Item Granter Devices** pro Seltenheit → `CommonGranters` … `LegendaryGranters`
  (jeweils Arrays, du kannst mehrere Waffen pro Stufe hinterlegen)
- optional **HUD Message Device** und **Audio Player Device**
- `ZoneName` auf den POI-Namen setzen, z. B. `Tilted Towers`

Die Gewichte `WeightCommon` … `WeightLegendary` steuern die Drop-Chancen:
40/30/18/9/3 bedeutet, dass Common rund 40 % der Ziehungen ausmacht. Eine
"heiße" Zone bekommt einfach höhere Epic-/Legendary-Gewichte als eine ruhige.

## Bekannte Stolperfallen

- **`@editable`-Felder erscheinen nicht:** Verse-Code wurde nicht neu gebaut, oder
  das Gerät im Level ist noch die alte Version — Gerät löschen und neu reinziehen.
- **`GrantItem` tut nichts:** Der Item Granter braucht ein zugewiesenes Item in
  seinem eigenen Details-Panel; das Skript wählt nur *welchen* Granter es auslöst.
- **Eliminierungen zählen nicht:** `PlayerSpawners` muss gefüllt sein — das Skript
  hängt sich über `SpawnedEvent` an jeden neuen Charakter, um an dessen
  `EliminatedEvent` zu kommen.
- **Verse-API ändert sich:** Epic benennt gelegentlich Events und Methoden um. Wenn
  der Compiler eine Zeile anmeckert, in der UEFN-Dokumentation die aktuelle
  Signatur des jeweiligen Devices nachschlagen und dort anpassen — die Struktur
  drumherum bleibt gleich.

Der Code ist hier nicht gegen den UEFN-Compiler getestet worden (das geht nur in
UEFN selbst); rechne beim ersten Build mit ein bis zwei Signatur-Anpassungen.
