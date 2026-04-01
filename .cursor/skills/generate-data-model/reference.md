# Référence Data Model – Athlete Core 360

## Champs types par objet (à adapter selon besoin)

- **Athlete__c** : Name (auto), FirstName__c, LastName__c, DateOfBirth__c, Email__c, Phone__c, Sport__c, Status__c, ExternalId__c (pour Data Cloud / Golden Record).
- **TrainingSession__c** : Athlete__c (Lookup/M-D), SessionDate__c, DurationMinutes__c, Type__c, Notes__c.
- **TrainingPerformance__c** : TrainingSession__c (M-D), MetricName__c, Value__c, Unit__c.
- **MedicalEvent__c** : Athlete__c (Lookup), EventDate__c, Type__c (picklist), Description__c, Severity__c, ResolvedDate__c.
- **RecoveryPlan__c** : Athlete__c (Lookup), MedicalEvent__c (Lookup optionnel), StartDate__c, EndDate__c, Status__c, Notes__c.
- **AdministrativeDoc__c** : Athlete__c (Lookup), DocumentType__c, IssueDate__c, ExpiryDate__c, DocumentUrl__c ou ContentVersion link.
- **ComplianceItem__c** : Athlete__c (Lookup) ou objet parent selon modèle, ItemType__c, Status__c, DueDate__c, CompletedDate__c.
- **SensorSource__c** : Athlete__c (Lookup), SourceType__c, Name/Identifier__c, LastSync__c.
- **SensorReading__c** : SensorSource__c (M-D), Timestamp__c, MetricType__c, Value__c, Unit__c.

## Patterns de relations

- **Master-Detail** : TrainingSession → TrainingPerformance ; SensorSource → SensorReading (cascade delete logique).
- **Lookup** : Athlete → TrainingSession, MedicalEvent, RecoveryPlan, AdministrativeDoc, ComplianceItem, SensorSource (pas de cascade delete par défaut).
- **Optionnel** : RecoveryPlan → MedicalEvent (Lookup) pour lier un plan à un événement médical.

## Mermaid – conventions

- Noms d’entités : `NomObjet__c` (ex. `Athlete__c`).
- Relation : `Athlete__c ||--o{ TrainingSession__c : "sessions"`.
- Éviter espaces et caractères spéciaux dans les noms d’entités.
