# Sprint 2 - Data Cloud Runbook

## Scope
Ce runbook couvre:
- T1 ingestion mock
- T2 feature generation
- T3 activation cible `Athlete__c` et `Prospect__c`

## 1) Generer les fichiers mock

```bash
python scripts/generate_sprint2_datacloud_mock.py
```

Output attendu:
- `data/sprint2/athlete_features.csv`
- `data/sprint2/prospect_features.csv`

## 2) Charger les fichiers dans Data Cloud (ou simulation locale)

- Stream 1: athlete features
  - identity key: `athlete_external_id`
- Stream 2: prospect features
  - identity key: `prospect_external_id`

## 3) Mapper vers Core

Utiliser les mappings existants:
- `project-management/DataCloud_Activation_Mapping_Athlete.csv`
- `project-management/DataCloud_Activation_Mapping_Scouting.csv`

Regles critiques:
- Upsert uniquement sur `ExternalId__c`
- Ne pas ecraser `Sport__c` si deja renseigne en Core
- Conserver timestamps source dans les champs sync

## 4) Verification post-activation

### Athlete
- `Load7d__c`, `Load28d__c`, `Acwr__c`
- `ReadinessScore__c`, `InjuryRiskScore__c`
- `LastTrainingSync__c`, `LastMatchSync__c`, `LastDataCloudSync__c`

### Prospect
- `ScoutingScore__c`, `PotentialScore__c`, `FitScore__c`, `RiskScore__c`
- `DataConfidence__c`, `ScoutingSummary__c`, `ScoutingFeaturesJson__c`
- `LastDataCloudSync__c`

## 5) Queries de controle

### Data Cloud (éditeur SQL Data Cloud)

```sql
SELECT *
FROM AthleteFeaturesDLO__dlm
LIMIT 20
```

(Colonnes selon le schéma du DLO : ex. `athlete_external_id`, `load_7d`, `acwr`, `readiness_score`, etc.)

### Core CRM (SOQL – après activation)

```sql
SELECT Id, Name, ExternalId__c, Load7d__c, Acwr__c, ReadinessScore__c, InjuryRiskScore__c, LastDataCloudSync__c
FROM Athlete__c
WHERE ExternalId__c != null
ORDER BY LastModifiedDate DESC
LIMIT 20
```

```sql
SELECT Id, Name, ExternalId__c, ScoutingScore__c, PotentialScore__c, FitScore__c, RiskScore__c, DataConfidence__c, LastDataCloudSync__c
FROM Prospect__c
WHERE ExternalId__c != null
ORDER BY LastModifiedDate DESC
LIMIT 20
```

## 6) Error handling

- Duplicate external ID:
  - nettoyer source puis rejouer upsert
- Missing mapping target field:
  - verifier metadonnees champs Core
- Null spikes:
  - controler quality du stream et schema input

## 7) Next step

Une fois stable:
- brancher la vraie extraction API football-data.org
- brancher les alertes Flow (T5)
- brancher prompts IA (T4)
