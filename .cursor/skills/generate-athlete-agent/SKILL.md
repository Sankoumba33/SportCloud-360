---
name: generate-athlete-agent
description: Crée l'IA AthleteAgent pour analyser automatiquement les données d'un athlète (performance, charge, blessures, tendances). Génère prompts structurés, JSON schemas, logique d'analyse et intégration Agentforce. Use when the user types "/agent ia" or "/agent ia + besoin" or asks to create/configure the AthleteAgent, agent IA athlète, or Agentforce prompts.
---

# Generate AthleteAgent (IA)

## Trigger

- Commande : `/agent ia` ou `/agent ia` + besoin spécifique
- Demande explicite : "créer l'agent IA athlète", "prompts AthleteAgent", "schémas pour Agentforce", "logique d'analyse athlète"

## Règles obligatoires

- **Toujours inclure** dans les livrables : performance, charge (training load), blessures, tendances.
- **Toujours optimiser** pour un usage Salesforce Agentforce (prompts, actions, schémas compatibles).

## Workflow

1. **Lire le contexte** : instruction après `/agent ia` ou demande utilisateur (use case précis ou full agent).
2. **Déterminer le périmètre** : agent complet vs besoin ciblé (ex. "seulement readiness", "seulement risque blessure").
3. **Produire dans l’ordre** :
   - Prompt complet agent (rôle, comportement, contraintes)
   - JSON Schema input (données attendues en entrée)
   - JSON Schema output (structure de réponse)
   - Liste des actions IA disponibles (tools/capabilities)
   - Exemples d’appels (request/response)
   - Suggestions d’amélioration continue
4. **Vérifier** : les 4 piliers (performance, charge, blessures, tendances) sont couverts ; formulation Agentforce-friendly.

## Livrables à fournir

| Livrable | Contenu |
|----------|--------|
| **Prompt agent** | System prompt + instructions de comportement (ton, format, limites). |
| **JSON Schema input** | Champs attendus : identifiant athlète, période, sources (sessions, medical, sensors), options (granularité, métriques). |
| **JSON Schema output** | Résumé, indicateurs (readiness, charge, risque), tendances, recommandations, alertes. |
| **Actions IA** | Liste nommée (ex. `analyze_athlete`, `get_readiness`, `get_injury_risk`, `get_trends`) avec description et paramètres. |
| **Exemples** | 1–2 exemples d’appel (input JSON) et réponse type (output JSON). |
| **Suggestions** | Améliorations (nouvelles métriques, raffinage prompts, évolution Data Cloud / Einstein). |

## Logique d’analyse à couvrir

- **Charge** : agrégation training load (volume, intensité), comparaison à des seuils ou baselines.
- **Readiness** : indicateur de disponibilité / fraîcheur (scores, facteurs : sommeil, fatigue, charge récente).
- **Risque** : risque blessure ou surentraînement (signaux : charge aiguë/chronique, historique medical, tendances).
- **Tendances** : évolution dans le temps (performance, charge, récupération) ; détection de dérive ou d’amélioration.

Formules ou seuils : les indiquer de façon paramétrable (constantes nommées) pour faciliter la maintenance. Détails et exemples complets en [reference.md](reference.md).

## Format de sortie

Utiliser ce canevas (adapter selon "full" vs "besoin ciblé") :

```markdown
## Prompt agent
[System prompt + comportement]

## JSON Schema – Input
[JSON Schema des entrées]

## JSON Schema – Output
[JSON Schema des sorties]

## Actions IA disponibles
- Action 1 : description, paramètres
- Action 2 : ...

## Exemples d’appels
[Input exemple → Output exemple]

## Suggestions
- [Améliorations]
```

## Intégration Agentforce

- Prompts : formulation claire, étapes explicites, pas de placeholders vagues.
- Actions : nommage cohérent avec les invocable actions Agentforce ; paramètres typés (string, number, date).
- Schémas : compatibles avec ce qu’Agentforce peut consommer (JSON standard, pas de types exotiques).
- Réponses : structurées pour affichage dans une conversation ou un résumé (titres, listes, alertes).

Pour détails Agentforce (config, best practices), voir [reference.md](reference.md).

## Référence détaillée

Schemas JSON complets, exemples de prompts par use case, et bonnes pratiques Agentforce : [reference.md](reference.md).
