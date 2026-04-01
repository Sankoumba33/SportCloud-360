# Sprint 3 - AI Automation Runbook

## Scope
Ce runbook couvre:
- T1 alignement identite
- T2 flows alertes
- T3 prompts IA
- T4 monitoring et incident response

## 1) Verification identite (Core)

### Athlete
```bash
sf data query --query "SELECT COUNT() FROM Athlete__c WHERE ExternalId__c = null" --target-org <alias>
sf data query --query "SELECT ExternalId__c, COUNT(Id) c FROM Athlete__c WHERE ExternalId__c != null GROUP BY ExternalId__c HAVING COUNT(Id) > 1" --target-org <alias>
```

### Prospect
```bash
sf data query --query "SELECT COUNT() FROM Prospect__c WHERE ExternalId__c = null" --target-org <alias>
sf data query --query "SELECT ExternalId__c, COUNT(Id) c FROM Prospect__c WHERE ExternalId__c != null GROUP BY ExternalId__c HAVING COUNT(Id) > 1" --target-org <alias>
```

## 2) Verification donnees Data Cloud

SQL Data Cloud:
```sql
SELECT athlete_external_id, readiness_score, injury_risk_score, load_trend, last_datacloud_sync_utc
FROM AthleteFeaturesDLO__dlm
LIMIT 20
```

```sql
SELECT prospect_external_id, scouting_score, potential_score, fit_score, risk_score, data_confidence
FROM prospect_featuresDLO__dlm
LIMIT 20
```

## 3) Validation post-activation Core

```bash
sf data query --query "SELECT Name, ExternalId__c, Load7d__c, Acwr__c, ReadinessScore__c, InjuryRiskScore__c, LastDataCloudSync__c FROM Athlete__c WHERE ExternalId__c != null ORDER BY LastModifiedDate DESC LIMIT 20" --target-org <alias>
```

```bash
sf data query --query "SELECT Name, ExternalId__c, ScoutingScore__c, PotentialScore__c, FitScore__c, RiskScore__c, DataConfidence__c, LastDataCloudSync__c FROM Prospect__c WHERE ExternalId__c != null ORDER BY LastModifiedDate DESC LIMIT 20" --target-org <alias>
```

## 4) Flows alertes (T2)

Regles minimales recommandees:
- Injury alert: `InjuryRiskScore__c >= 75`
- ACWR alert: `Acwr__c > 1.5 OR Acwr__c < 0.8`
- Cooldown anti-spam: ne pas renvoyer la meme alerte dans les 24h pour le meme athlete

Verification:
- 1 cas positif injury
- 1 cas positif ACWR
- 1 cas negatif (aucune alerte)

## 5) Prompt pack IA (T3)

Prompts cibles:
- `Athlete Summary`
- `Risk Alert`
- `Scouting Recommendation`

Artefacts:
- `project-management/Sprint3_PromptPack.md`
- `project-management/Sprint3_PromptEval_Set.csv`

Critere qualite minimal:
- sortie actionnable en <= 6 lignes
- 2 recommandations max priorisees
- mention explicite des signaux data utilises

## 6) Incident response (T4)

Symptomes courants:
- Event publie mais pas de MAJ Core
- MAJ partielle (athlete oui / prospect non)
- timestamps sync non rafraichis

Check rapide:
1. verifier matching external id
2. verifier que l event contient les champs attendus
3. verifier logs Apex trigger/handler
4. rejouer ingestion puis activation

## 7) Definition of Done Sprint 3

- Identite alignee et stable (0 null, 0 doublon)
- Alertes automatises operationnelles
- Prompt pack IA valide par UAT
- Monitoring et runbook incident partages equipe
