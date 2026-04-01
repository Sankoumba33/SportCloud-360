# Generate AthleteAgent – Référence

## JSON Schema Input (exemple complet)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["athleteId", "period"],
  "properties": {
    "athleteId": { "type": "string", "description": "Id Salesforce ou externe de l'athlète" },
    "period": {
      "type": "object",
      "properties": {
        "start": { "type": "string", "format": "date" },
        "end": { "type": "string", "format": "date" }
      }
    },
    "sources": {
      "type": "object",
      "properties": {
        "trainingSessions": { "type": "boolean", "default": true },
        "medicalEvents": { "type": "boolean", "default": true },
        "sensorReadings": { "type": "boolean", "default": false }
      }
    },
    "options": {
      "type": "object",
      "properties": {
        "granularity": { "enum": ["day", "week", "month"] },
        "metrics": { "type": "array", "items": { "type": "string" } }
      }
    }
  }
}
```

## JSON Schema Output (exemple complet)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "readiness": {
      "type": "object",
      "properties": {
        "score": { "type": "number" },
        "factors": { "type": "array", "items": { "type": "string" } }
      }
    },
    "load": {
      "type": "object",
      "properties": {
        "acute": { "type": "number" },
        "chronic": { "type": "number" },
        "acwr": { "type": "number" }
      }
    },
    "injuryRisk": {
      "type": "object",
      "properties": {
        "level": { "enum": ["low", "medium", "high"] },
        "signals": { "type": "array", "items": { "type": "string" } }
      }
    },
    "trends": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "metric": { "type": "string" },
          "direction": { "enum": ["up", "down", "stable"] },
          "description": { "type": "string" }
        }
      }
    },
    "recommendations": { "type": "array", "items": { "type": "string" } },
    "alerts": { "type": "array", "items": { "type": "string" } }
  }
}
```

## Prompt agent (template)

```
Tu es AthleteAgent, un assistant IA expert en analyse des données d'athlètes.

Rôle : Analyser automatiquement les données d'un athlète (performance, charge d'entraînement, blessures, tendances) et fournir des résumés, indicateurs et recommandations actionnables.

Comportement :
- Répondre de façon structurée (résumé, indicateurs, tendances, recommandations, alertes).
- Toujours couvrir : performance, charge, blessures, tendances.
- Utiliser les données fournies ; si une donnée manque, le préciser sans inventer.
- Ton professionnel et concis.

Contraintes :
- Ne pas donner de diagnostic médical ; orienter vers un professionnel de santé si nécessaire.
- Les seuils (charge, readiness, risque) sont configurables ; les indiquer comme paramètres quand pertinent.
```

## Use cases IA (liste type)

| Use case | Description | Entrées clés | Sorties clés |
|----------|-------------|--------------|--------------|
| Analyse complète | Vue 360 sur une période | athleteId, period, sources | summary, readiness, load, injuryRisk, trends, recommendations, alerts |
| Readiness uniquement | Score de disponibilité | athleteId, date (ou période courte) | readiness.score, factors |
| Risque blessure | Niveau et signaux | athleteId, period, charge + medical | injuryRisk.level, signals |
| Tendances | Évolution métriques | athleteId, period, granularity | trends[] |
| Recommandations | Actions suggérées | Idem analyse complète | recommendations[], alerts[] |

## Exemple d’appel (request/response)

**Input :**
```json
{
  "athleteId": "a0X1234567890ABC",
  "period": { "start": "2025-02-01", "end": "2025-02-23" },
  "sources": { "trainingSessions": true, "medicalEvents": true, "sensorReadings": false },
  "options": { "granularity": "week" }
}
```

**Output (extrait) :**
```json
{
  "summary": "Sur les 3 dernières semaines, charge en hausse modérée, bonne récupération. Un événement médical mineur signalé.",
  "readiness": { "score": 72, "factors": ["charge récente modérée", "pas de blessure ouverte"] },
  "load": { "acute": 420, "chronic": 400, "acwr": 1.05 },
  "injuryRisk": { "level": "medium", "signals": ["ACWR légèrement > 1.0"] },
  "trends": [
    { "metric": "volume", "direction": "up", "description": "Volume hebdo +8 % vs période précédente" }
  ],
  "recommendations": ["Maintenir charge stable 1 semaine", "Surveiller ACWR"],
  "alerts": []
}
```

## Logique d’analyse (formules paramétrables)

- **ACWR** : Acute Chronic Workload Ratio = charge_aiguë / charge_chronique. Seuils typiques : <0.8 sous-charge, 0.8–1.3 zone sûre, >1.5 risque accru.
- **Readiness** : score composite (ex. 0–100) à partir de charge récente, sommeil/fatigue si dispo, historique blessures récent.
- **Risque** : combinaison ACWR, tendance charge, présence d’événements médicaux récents.

Constantes à nommer dans les prompts/specs : `ACWR_SAFE_MAX`, `ACWR_HIGH_RISK`, `READINESS_WEIGHTS`, etc.

## Agentforce – bonnes pratiques

- **Invocable actions** : une action par use case principal (analyze_athlete, get_readiness, get_injury_risk, get_trends) avec paramètres typés (String, Integer, Date).
- **Réponses** : garder une structure JSON ou markdown (titres, listes) pour affichage dans le chat Agentforce.
- **Prompts** : éviter les placeholders du type "…" ; utiliser des instructions explicites étape par étape.
- **Données** : s’appuyer sur les sObjects Athlete Core 360 (Athlete__c, TrainingSession__c, TrainingPerformance__c, MedicalEvent__c, etc.) et/ou Data Cloud pour le Golden Record.
