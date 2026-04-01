# T1 - Data Seed Runbook

## Objectif
Initialiser les données Sprint 1 :
- 6 `Squad__c`
- 10 `Athlete__c`
- 10 `Prospect__c`
- 15 `SquadAssignment__c` (historique inclus)

## Script
`scripts/apex/sprint1_t1_seed_data.apex`

## Exécution
```bash
sf apex run --file scripts/apex/sprint1_t1_seed_data.apex --target-org <alias>
```

## Vérifications rapides
```bash
sf data query --query "SELECT COUNT() FROM Squad__c" --target-org <alias>
sf data query --query "SELECT COUNT() FROM Athlete__c" --target-org <alias>
sf data query --query "SELECT COUNT() FROM Prospect__c" --target-org <alias>
sf data query --query "SELECT COUNT() FROM SquadAssignment__c" --target-org <alias>
```

## Notes
- Le script est idempotent pour `Athlete__c` et `Prospect__c` via `ExternalId__c`.
- Les affectations (`SquadAssignment__c`) des 10 athletes seed sont recréées pour garantir un historique cohérent.
