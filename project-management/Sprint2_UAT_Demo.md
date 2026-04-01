# Sprint 2 - UAT Demo Script

## Objectif
Montrer que Data Cloud alimente Athlete 360 et Scouting 360 avec des insights actionnables.

## Preconditions
- Objets Sprint 1 deployes
- Mock CSV Sprint 2 generes
- Mapping activation athlete/scouting valide
- Permission set `SportCloud_Admin` assigne

## Etapes demo

1. Charger `athlete_features.csv` dans le flux Data Cloud (ou import simulation).
   - Resultat attendu: enregistrements athlete features visibles dans la couche data.

2. Charger `prospect_features.csv` dans le flux Data Cloud.
   - Resultat attendu: enregistrements prospect features visibles.

3. Lancer activation vers `Athlete__c`.
   - Resultat attendu: `Load7d__c`, `Acwr__c`, `ReadinessScore__c`, `InjuryRiskScore__c` mis a jour.

4. Lancer activation vers `Prospect__c`.
   - Resultat attendu: `ScoutingScore__c`, `PotentialScore__c`, `FitScore__c`, `RiskScore__c` mis a jour.

5. Ouvrir 1 athlete "high risk".
   - Resultat attendu: `InjuryRiskScore__c` eleve + `TopRisks__c` coherent.

6. Ouvrir 1 athlete "match fit".
   - Resultat attendu: `ReadinessScore__c` eleve + trend stable/up.

7. Ouvrir 1 prospect "priority target".
   - Resultat attendu: `ScoutingSummary__c` exploitable + `DataConfidence__c` > 70.

8. Verifier timestamps de sync.
   - Resultat attendu: `LastDataCloudSync__c` renseigne et recent.

## Go / No-Go
- 8/8 etapes passent
- Aucune incoherence entre dataset et champs Core
- Aucune erreur d'upsert sur external IDs
