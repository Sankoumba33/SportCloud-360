# Data Cloud – Référence (DataCloudArchitect)

## Conventions de nommage

- **Data Streams** : `PascalCase` ou `snake_case` selon l’org ; rester cohérent (ex. `Athlete_CRM_Stream`, `athlete_api_stream`).
- **DMO / champs harmonisés** : alignés sur les API names Core quand c’est une activation (ex. `FirstName`, `Email__c`).
- **ID externe** : un seul champ par entité pour la clé externe (ex. `ExternalId__c`, `athlete_external_id`).

## Types courants (mapping source → Data Cloud)

| Type source   | Type Data Cloud / Core | Note                    |
|---------------|------------------------|-------------------------|
| string        | Text                   | Longueur max à respecter |
| integer/long  | Number                 | Précision, éventuellement Int |
| float/double  | Number                 | Échelle fixe si besoin  |
| date          | Date                   | Sans timezone si date seule |
| datetime      | DateTime               | Préférer UTC            |
| boolean       | Boolean                | -                       |
| id (Salesforce) | Text (18 chars)      | Id Core conservé tel quel |

## Identity Resolution – Bonnes pratiques

- Au moins une règle par entité (ex. Athlete).
- Match sur ID externe en priorité ; ensuite Email ou combinaison de champs stables.
- Éviter les matchs sur champs volatils (nom seul, téléphone non normalisé).
- Documenter l’ordre des sources pour la fusion (priorité).

## Performance

- Limiter les champs mappés au strict nécessaire (activation et analytique).
- Préférer des streams batch pour gros volumes ; streaming pour temps réel.
- Index / clés : s’assurer que les champs utilisés en match et en filtres sont indexables.

## Limites à garder en tête (Salesforce Data Cloud)

- Taille des champs texte, nombre de champs par objet, nombre de streams : consulter la doc officielle selon l’édition.
- Activation : respecter les limites d’objets et de champs mappés vers Core.

## Lien avec Athlete Core 360

- Objet pivot : **Athlete__c**.
- Champs souvent nécessaires pour Golden Record + IA : identifiant, nom, email, dates (naissance, dernière mise à jour), statut, lien vers séances/performances/blessures (via relations ou champs dénormalisés selon besoin).
