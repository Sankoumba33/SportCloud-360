@IsTest
private class AthleteAlertAutomationTest {
    @IsTest
    static void createsInjuryAlertAndSetsCooldown() {
        Athlete__c athlete = new Athlete__c(
            Name = 'Alert Injury Test',
            ExternalId__c = 'ATH-ALERT-001',
            Sport__c = 'Football',
            Status__c = 'Active',
            InjuryRiskScore__c = 80
        );

        Test.startTest();
        insert athlete;
        Test.stopTest();

        List<Task> tasks = [
            SELECT Subject, WhatId
            FROM Task
            WHERE WhatId = :athlete.Id
        ];
        System.assertEquals(1, tasks.size(), 'One injury alert task should be created');
        System.assert(tasks[0].Subject.startsWith('Injury Risk Alert'));

        Athlete__c refreshed = [
            SELECT LastInjuryAlertAt__c
            FROM Athlete__c
            WHERE Id = :athlete.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, refreshed.LastInjuryAlertAt__c, 'Injury cooldown timestamp must be set');
    }

    @IsTest
    static void createsAcwrAlertAndRespectsCooldown() {
        Athlete__c athlete = new Athlete__c(
            Name = 'Alert ACWR Test',
            ExternalId__c = 'ATH-ALERT-002',
            Sport__c = 'Football',
            Status__c = 'Active',
            Acwr__c = 1.8
        );
        insert athlete;

        Integer taskCountAfterInsert = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :athlete.Id
        ];
        System.assertEquals(1, taskCountAfterInsert, 'One ACWR task should be created on insert');

        Test.startTest();
        update new Athlete__c(
            Id = athlete.Id,
            Sport__c = 'Futsal',
            Acwr__c = 1.82
        );
        Test.stopTest();

        Integer taskCountAfterImmediateUpdate = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :athlete.Id
        ];
        System.assertEquals(1, taskCountAfterImmediateUpdate, 'Cooldown must prevent duplicate immediate alert');

        Athlete__c cooledAthlete = [
            SELECT Id, Acwr__c, LastAcwrAlertAt__c
            FROM Athlete__c
            WHERE Id = :athlete.Id
            LIMIT 1
        ];
        update new Athlete__c(
            Id = cooledAthlete.Id,
            LastAcwrAlertAt__c = System.now().addHours(-25)
        );

        update new Athlete__c(
            Id = athlete.Id,
            Acwr__c = 1.7,
            Status__c = 'Injured'
        );

        Integer taskCountAfterCooldown = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :athlete.Id
        ];
        System.assertEquals(2, taskCountAfterCooldown, 'A new alert should be emitted after cooldown');
    }

    @IsTest
    static void createsTwoAlertsWhenBothSignalsTriggered() {
        Athlete__c athlete = new Athlete__c(
            Name = 'Alert Dual Test',
            ExternalId__c = 'ATH-ALERT-003',
            Sport__c = 'Football',
            Status__c = 'Active',
            InjuryRiskScore__c = 90,
            Acwr__c = 1.9
        );

        Test.startTest();
        insert athlete;
        Test.stopTest();

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :athlete.Id
        ];
        System.assertEquals(2, taskCount, 'Both injury and ACWR alerts should be created');
    }
}
