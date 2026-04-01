# Club 360 — Microcycle (MVP)

## Modèle

| Objet | Rôle |
|--------|------|
| `Microcycle__c` | Semaine de préparation ; `Squad__c` + `AnchorMatch__c` (MD) + fenêtre `WeekStart/End` + `Status__c`. |
| `MicrocycleDay__c` | MD en `Phase__c` ; jour `DayDate__c` ; charge cible `TargetIntensity__c` ; lien optionnel `PlanningEvent__c`. |
| `AthleteMicrocycleDay__c` | Par athlète / jour : `PlannedLoad__c`, `ActualLoad__c`, `LoadComment__c`. Lookup `Athlete__c` → relation API `AthleteMicrocycleDayLinks` (évite collision avec `MicrocycleDay__c.AthleteMicrocycleDays`). |

## UI

- Layouts **Club 360** : listes reliées Microcycle → jours → lignes athlète.
- App Lightning **Club 360** : Home, Microcycles, Squads, Matchs, Planning.
- Permission sets : **SportCloud Admin** (full), **Coach Read** (lecture), **Planning Editor** (CRUD microcycle + lecture Match/Squad).

## Suite possible

- Flow / Apex : génération des `MicrocycleDay__c` à partir de `AnchorMatch__c.MatchDate__c` (grille MD±n).
- LWC board semaine (lecture `MicrocycleDay__c` + AMD).
- Rapports : écart `PlannedLoad__c` vs `ActualLoad__c` par squad.
