# Sprint 2 - Execution Checklist

## 1) Data Cloud Inputs (T1)
- [ ] Data source `football-data.org` parametree (token + quota)
- [ ] Mock files generes (`athlete_features.csv`, `prospect_features.csv`)
- [ ] External IDs alignes avec `Athlete__c.ExternalId__c` et `Prospect__c.ExternalId__c`
- [ ] Plan de refresh documente (intraday training, daily scouting)

## 2) Feature Engineering (T2)
- [ ] Features athlete calculees (`readiness_score`, `injury_risk_score`, `acwr`, trends)
- [ ] Features scouting calculees (`scouting_score`, `potential_score`, `fit_score`, `risk_score`)
- [ ] `data_confidence` calcule avec regles qualite data
- [ ] Export JSON snapshot present pour audit (`*_features_json`)

## 3) Activation Core (T3)
- [ ] Mapping athlete valide avec `DataCloud_Activation_Mapping_Athlete.csv`
- [ ] Mapping scouting valide avec `DataCloud_Activation_Mapping_Scouting.csv`
- [ ] Upsert cible `Athlete__c` OK (pas de doublons)
- [ ] Upsert cible `Prospect__c` OK (pas de doublons)
- [ ] Timestamps sync remplis (`LastTrainingSync__c`, `LastMatchSync__c`, `LastDataCloudSync__c`)

## 4) IA and Automation (T4-T5)
- [ ] Prompt `AthleteAgent` summary pret
- [ ] Prompt `AthleteAgent` risk alert pret
- [ ] Prompt `ScoutingAgent` recommendation pret
- [ ] Flow alerte risque (high injury risk) cree
- [ ] Flow alerte charge (ACWR out-of-range) cree

## 5) QA and UAT (T6)
- [ ] 5 athletes verifies (coherence features -> record Core)
- [ ] 5 prospects verifies (coherence scores -> record Core)
- [ ] Alerts testees (positive + negative cases)
- [ ] UAT Sprint 2 passe sans blocker

## 6) Demo Ready
- [ ] Script demo Sprint 2 execute en moins de 10 min
- [ ] Aucun echec de sync sur 24h
- [ ] KPI pilotage Data Cloud presentes (latence + couverture + qualite)
