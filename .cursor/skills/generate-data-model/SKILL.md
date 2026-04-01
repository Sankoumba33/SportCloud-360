---
name: generate-data-model
description: Génère ou met à jour le data model complet (ERD mermaid, objets custom Salesforce, metadata XML) pour Sports Intelligence Cloud – Athlete Core 360. Use when the user types "/model" or asks to generate/update the data model, ERD, custom objects, or sObject schema for the project.
---

# Generate Data Model (Athlete Core 360)

## Trigger

- Commande : `/model` ou `/model + instructions spécifiques`
- Demande explicite : "génère l'ERD", "mets à jour le data model", "objets et champs pour Athlete Core 360"

## Objets MVP (base obligatoire)

Toujours inclure ces objets dans le modèle :

| Objet | Rôle |
|-------|------|
| `Athlete__c` | Objet pivot (entité centrale) |
| `TrainingSession__c` | Séance d'entraînement |
| `TrainingPerformance__c` | Performance / métrique par séance |
| `MedicalEvent__c` | Événement médical / blessure |
| `RecoveryPlan__c` | Plan de récupération |
| `AdministrativeDoc__c` | Document administratif |
| `ComplianceItem__c` | Élément conformité / checklist |
| `SensorSource__c` | Source de capteurs (appareil / flux) |
| `SensorReading__c` | Lecture / donnée capteur |

## Workflow

1. **Lire le contexte** : instructions après `/model` ou demande utilisateur.
2. **Déterminer le périmètre** : full model vs ajout/évolution (nouveau module, nouveaux objets).
3. **Produire dans l’ordre** :
   - ERD Mermaid (schéma clair et valide)
   - Liste des objets et champs (sObject + champs custom)
   - Relations (Lookup vs Master-Detail avec justification courte)
   - Description technique (1 paragraphe par objet ou bloc logique)
   - Si demandé : fichiers metadata XML (CustomObject + CustomField).
4. **Vérifier la cohérence** : Athlete__c reste le pivot ; pas d’orphelins ; cardinalités logiques.
5. **Proposer des améliorations** : nouveaux champs, index, relations manquantes, évolution Data Cloud / Golden Record.

## Format de sortie

Utiliser ce canevas (adapter selon "full" vs "delta") :

```markdown
## ERD (Mermaid)
[Diagramme erDiagram avec entités et relations]

## Objets et champs
- **Objet** : champs (API Name, Type, relation le cas échéant)

## Relations
- Parent → Enfant : type (Lookup / Master-Detail), raison courte

## Description technique
[Par objet ou bloc]

## Suggestions
- [Améliorations optionnelles]
```

## Règles strictes

- Toujours se baser sur la liste des 9 objets MVP ci-dessus. Ajouter d’autres objets seulement si l’utilisateur le demande ou si les instructions l’indiquent.
- ERD Mermaid : syntaxe valide (`erDiagram`, `ENTITY {}`, `ENTITY ||--o{ ENTITY : label`). Pas de caractères spéciaux dans les noms d’entités (utiliser `__c` pour les custom objects).
- Relations : privilégier Master-Detail quand la suppression du parent doit supprimer les enfants ; Lookup sinon. Toujours lier les enfants à `Athlete__c` (ou via une chaîne logique jusqu’à Athlete).
- Metadata XML : générer uniquement si l’utilisateur demande explicitement des "fichiers metadata", "XML", ou "deploy".

## Référence détaillée

Pour champs types et patterns de relations (Lookup vs M-D), voir [reference.md](reference.md).

## Évolutions / modules

Si l’utilisateur mentionne un nouveau module (ex. "ajoute le module Nutrition", "module Staff") :
- Conserver les 9 objets MVP.
- Ajouter les nouveaux objets et les relier au modèle existant (idéalement à `Athlete__c` ou à un objet déjà lié).
- Mettre à jour l’ERD et la section Relations en conséquence.
- Indiquer clairement ce qui a été ajouté dans la description technique et les suggestions.
