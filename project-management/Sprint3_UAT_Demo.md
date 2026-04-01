# Sprint 3 - UAT Demo Script

## Objectif
Montrer un cycle complet: Data Cloud alimente Core, des alertes se declenchent, et les prompts IA produisent des recommandations actionnables.

## Preconditions
- Sprint 2 stable (activation athlete + prospect OK)
- `ExternalId__c` aligne avec `athlete_external_id` et `prospect_external_id`
- Data Actions Athlete et Prospect actives
- Permission set `SportCloud_Admin` assigne

## Etapes demo

1. Verifier la donnee source dans Data Cloud (`AthleteFeaturesDLO__dlm`).
   - Resultat attendu: enregistrements avec `athlete_external_id` presents.

2. Declencher un run d activation Athlete.
   - Resultat attendu: event activity publiee sans erreur.

3. Ouvrir un athlete en Core.
   - Resultat attendu: `Load7d__c`, `Acwr__c`, `ReadinessScore__c`, `InjuryRiskScore__c` mis a jour.

4. Simuler un cas risque (injury score eleve ou ACWR hors plage).
   - Resultat attendu: Flow d alerte declenche + notification visible.

5. Ouvrir un prospect en Core apres activation Prospect.
   - Resultat attendu: `ScoutingScore__c`, `PotentialScore__c`, `FitScore__c`, `RiskScore__c` mis a jour.

6. Executer prompt `Athlete Summary`.
   - Resultat attendu: resume clair + 2 actions recommandees.

7. Executer prompt `Risk Alert` ou `Scouting Recommendation`.
   - Resultat attendu: decision exploitable (go / monitor / no-go).

8. Verifier monitoring.
   - Resultat attendu: KPI sync visibles (`LastDataCloudSync__c`, erreurs, latence).

## Go / No-Go
- 8/8 etapes passent
- Aucune erreur de matching external ID
- Aucune alerte faussement repetitive
