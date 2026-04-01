# Data Cloud Scouting Blueprint (Data Cloud-First)

## Objectif
Centraliser les statistiques scouting détaillées dans Data Cloud, construire un Golden Record exploitable, puis activer un snapshot opérationnel vers Salesforce Core (`Prospect__c`).

## Principes
- **Data Cloud** = source de vérité data (détail volumineux).
- **Core** = cockpit opérationnel (snapshots, workflow, conversion).
- **Identity first** : clé externe unique sur prospect et athlete.

## Data Streams recommandés
- `scouting_match_stream` : stats match team + player (provider API).
- `scouting_event_stream` : événements détaillés (passes, tirs, duels).
- `scouting_training_stream` : charge et GPS (sessions).
- `scouting_profile_stream` : métadonnées joueur/prospect.

## DMO cibles (logiques)
- `ProspectProfileDMO`
- `PlayerMatchStatsDMO`
- `TeamMatchStatsDMO`
- `PlayerEventStatsDMO`
- `TrainingLoadDMO`
- `ProviderMetadataDMO`

## Clés d'identité
- `prospect_external_id` (exact)
- `athlete_external_id` (exact)
- `provider_player_id` (exact, avec priorité source)
- fallback : nom + date de naissance + nationalité (pondéré)

## Features scouting calculées (Data Cloud)
- `scouting_score`
- `potential_score`
- `fit_score`
- `risk_score`
- `data_confidence`
- `xg_per_90`
- `xa_per_90`
- `progressive_passes_per_90`
- `duel_win_pct`
- `pressing_actions_per_90`
- `hid_gt20_trend_28d`

## Activation vers Core (`Prospect__c`)
Champs cibles:
- `ScoutingScore__c`
- `PotentialScore__c`
- `FitScore__c`
- `RiskScore__c`
- `DataConfidence__c`
- `LastDataCloudSync__c`
- `ScoutingSummary__c`
- `TopStrengths__c`
- `TopRisks__c`
- `ScoutingFeaturesJson__c`

## Historisation Core
Objet:
- `ScoutingSnapshot__c` (1 ligne par activation majeure)

## Gouvernance
- refresh snapshots : quotidien
- refresh alertes : intraday si nécessaire
- conserver payload brut dans Data Cloud / Data Lake, pas dans Core

## Agent IA (AthleteAgent / ScoutingAgent)
Entrées:
- snapshot prospect + features JSON + contexte poste/âge/ligue
Sorties:
- résumé scouting actionnable
- alertes risques
- recommandations (court/moyen terme)
