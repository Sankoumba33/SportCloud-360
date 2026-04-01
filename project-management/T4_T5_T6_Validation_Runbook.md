# T4-T5-T6 Runbook

## T4 - Planning sync (`PlanningEvent__c` -> `Event`)

### Deployment
```bash
sf project deploy start --metadata "ApexClass:PlanningEventCalendarSync,ApexClass:PlanningEventCalendarSyncTest,ApexTrigger:PlanningEventTrigger,CustomObject:Event" --target-org <alias>
```

### Test
```bash
sf apex run test --tests PlanningEventCalendarSyncTest --result-format human --target-org <alias>
```

Expected:
- create/update/delete/undelete synchronise correctement vers `Event`.

## T5 - Date validation rules coverage

### Test
```bash
sf project deploy start --metadata "ApexClass:DateValidationRulesTest" --target-org <alias>
sf apex run test --tests DateValidationRulesTest --result-format human --target-org <alias>
```

Expected:
- validations bloquent les dates invalides sur:
  - `SquadAssignment__c`
  - `PlanningEvent__c`
  - `Booking__c`
  - `SchoolAbsence__c`

## T6 - Permission sets MVP

Permission sets créés:
- `SportCloud_Admin`
- `Coach_Read`
- `Scout_Editor`
- `Recruiter_Editor`
- `Planning_Editor`

### Deployment
```bash
sf project deploy start --metadata "PermissionSet:SportCloud_Admin,PermissionSet:Coach_Read,PermissionSet:Scout_Editor,PermissionSet:Recruiter_Editor,PermissionSet:Planning_Editor" --target-org <alias>
```

### Assign examples
```bash
sf org assign permset --name SportCloud_Admin --target-org <alias>
sf org assign permset --name Coach_Read --on-behalf-of <user-username> --target-org <alias>
```
