public with sharing class AthleteAlertAutomation {
    private static Boolean isRunning = false;

    private static final Decimal INJURY_THRESHOLD = 75;
    private static final Decimal ACWR_HIGH_THRESHOLD = 1.5;
    private static final Decimal ACWR_LOW_THRESHOLD = 0.8;
    private static final Integer COOLDOWN_HOURS = 24;

    public static void handleAfter(List<Athlete__c> newList) {
        if (isRunning || newList == null || newList.isEmpty()) {
            return;
        }

        isRunning = true;
        try {
            DateTime nowTs = System.now();
            DateTime cooldownCutoff = nowTs.addHours(-COOLDOWN_HOURS);
            List<Task> tasksToInsert = new List<Task>();
            List<Athlete__c> athletesToUpdate = new List<Athlete__c>();

            for (Athlete__c athlete : newList) {
                Boolean injuryTriggered = shouldTriggerInjuryAlert(athlete, cooldownCutoff);
                Boolean acwrTriggered = shouldTriggerAcwrAlert(athlete, cooldownCutoff);

                if (injuryTriggered) {
                    tasksToInsert.add(
                        buildTask(
                            athlete,
                            'Injury Risk Alert',
                            'Injury risk score = ' + String.valueOf(athlete.InjuryRiskScore__c) + ' (threshold >= 75).'
                        )
                    );
                }

                if (acwrTriggered) {
                    tasksToInsert.add(
                        buildTask(
                            athlete,
                            'ACWR Alert',
                            'ACWR = ' + String.valueOf(athlete.Acwr__c) + ' (outside safe range 0.8 - 1.5).'
                        )
                    );
                }

                if (injuryTriggered || acwrTriggered) {
                    Athlete__c patch = new Athlete__c(Id = athlete.Id);
                    if (injuryTriggered) {
                        patch.LastInjuryAlertAt__c = nowTs;
                    }
                    if (acwrTriggered) {
                        patch.LastAcwrAlertAt__c = nowTs;
                    }
                    athletesToUpdate.add(patch);
                }
            }

            if (!tasksToInsert.isEmpty()) {
                insert tasksToInsert;
            }
            if (!athletesToUpdate.isEmpty()) {
                update athletesToUpdate;
            }
        } finally {
            isRunning = false;
        }
    }

    private static Boolean shouldTriggerInjuryAlert(Athlete__c athlete, DateTime cooldownCutoff) {
        if (athlete.InjuryRiskScore__c == null || athlete.InjuryRiskScore__c < INJURY_THRESHOLD) {
            return false;
        }
        return athlete.LastInjuryAlertAt__c == null || athlete.LastInjuryAlertAt__c <= cooldownCutoff;
    }

    private static Boolean shouldTriggerAcwrAlert(Athlete__c athlete, DateTime cooldownCutoff) {
        if (athlete.Acwr__c == null) {
            return false;
        }
        Boolean outOfRange = athlete.Acwr__c > ACWR_HIGH_THRESHOLD || athlete.Acwr__c < ACWR_LOW_THRESHOLD;
        if (!outOfRange) {
            return false;
        }
        return athlete.LastAcwrAlertAt__c == null || athlete.LastAcwrAlertAt__c <= cooldownCutoff;
    }

    private static Task buildTask(Athlete__c athlete, String alertType, String signal) {
        String externalIdValue = String.isBlank(athlete.ExternalId__c) ? 'N/A' : athlete.ExternalId__c;
        String descriptionText = 'Athlete: ' + athlete.Name + '\n'
            + 'External ID: ' + externalIdValue + '\n'
            + 'Signal: ' + signal + '\n'
            + 'Source: Data Cloud alert automation';

        return new Task(
            WhatId = athlete.Id,
            Subject = alertType + ' - ' + athlete.Name,
            Status = 'Not Started',
            Priority = 'High',
            ActivityDate = Date.today(),
            Description = descriptionText,
            OwnerId = athlete.OwnerId == null ? UserInfo.getUserId() : athlete.OwnerId
        );
    }
}
