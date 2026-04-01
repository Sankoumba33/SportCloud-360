# Sprint 2 - Activation via Platform Event

## Pourquoi ce pattern
Dans cet org, les Data Action Targets disponibles sont:
- `Evenement Salesforce Platform`
- `Webhook`

La cible CRM directe n'etant pas disponible, on active via Platform Event puis on alimente `Athlete__c` en Apex.

## Composants deployes
- Platform Event: `AthleteFeatureUpdate__e`
- Trigger: `AthleteFeatureUpdateTrigger`
- Handler: `AthleteFeatureEventHandler`
- Test: `AthleteFeatureEventHandlerTest`
- Platform Event: `ProspectFeatureUpdate__e`
- Trigger: `ProspectFeatureUpdateTrigger`
- Handler: `ProspectFeatureEventHandler`
- Test: `ProspectFeatureEventHandlerTest`

## Mapping conseille dans Data Action
Source (`athlete_features_stream`) -> Event (`AthleteFeatureUpdate__e`):
- `athlete_external_id` -> `AthleteExternalId__c`
- `training_load_7d` -> `Load7d__c`
- `training_load_28d` -> `Load28d__c`
- `acwr` -> `Acwr__c`
- `readiness_score` -> `ReadinessScore__c`
- `injury_risk_score` -> `InjuryRiskScore__c`
- `load_trend` -> `LoadTrend__c`
- `performance_trend` -> `PerformanceTrend__c`
- `athlete_features_json` -> `FeaturesJson__c`
- `last_datacloud_sync_utc` -> `EventTimestamp__c`

Source (`prospect_features_stream`) -> Event (`ProspectFeatureUpdate__e`):
- `prospect_external_id` -> `ProspectExternalId__c`
- `scouting_score` -> `ScoutingScore__c`
- `potential_score` -> `PotentialScore__c`
- `fit_score` -> `FitScore__c`
- `risk_score` -> `RiskScore__c`
- `data_confidence` -> `DataConfidence__c`
- `scouting_summary` -> `ScoutingSummary__c`
- `top_strengths` -> `TopStrengths__c`
- `top_risks` -> `TopRisks__c`
- `features_json` -> `ScoutingFeaturesJson__c`
- `activation_timestamp` -> `EventTimestamp__c`

## Ce que fait le handler
- Match par `Athlete__c.ExternalId__c = AthleteExternalId__c`
- MAJ champs:
  - `Load7d__c`, `Load28d__c`, `Acwr__c`
  - `ReadinessScore__c`, `InjuryRiskScore__c`
  - `LoadTrend__c`, `PerformanceTrend__c` (normalises en `Up/Down/Stable`)
  - `FeaturesJson__c`
  - `LastDataCloudSync__c`

- Match par `Prospect__c.ExternalId__c = ProspectExternalId__c`
- MAJ champs:
  - `ScoutingScore__c`, `PotentialScore__c`, `FitScore__c`, `RiskScore__c`
  - `DataConfidence__c`
  - `ScoutingSummary__c`, `TopStrengths__c`, `TopRisks__c`
  - `ScoutingFeaturesJson__c`
  - `LastDataCloudSync__c`

## Deploiement cible
```bash
sf project deploy start --target-org "SPC360" --source-dir "force-app/main/default/objects/AthleteFeatureUpdate__e" --source-dir "force-app/main/default/classes/AthleteFeatureEventHandler.cls" --source-dir "force-app/main/default/classes/AthleteFeatureEventHandlerTest.cls" --source-dir "force-app/main/default/triggers/AthleteFeatureUpdateTrigger.trigger"
```

## Test
```bash
sf apex run test --tests AthleteFeatureEventHandlerTest --target-org "SPC360" --result-format human
```
