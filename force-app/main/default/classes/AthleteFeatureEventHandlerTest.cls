@IsTest
private class AthleteFeatureEventHandlerTest {
    @IsTest
    static void updatesAthleteFromPlatformEvent() {
        Athlete__c athlete = new Athlete__c(
            Name = 'Athlete Event Test',
            ExternalId__c = 'ATH-PE-001',
            Status__c = 'Active',
            Sport__c = 'Football'
        );
        insert athlete;

        Test.startTest();
        EventBus.publish(new AthleteFeatureUpdate__e(
            AthleteExternalId__c = 'ATH-PE-001',
            Load7d__c = 455.50,
            Load28d__c = 1550.75,
            Acwr__c = 1.176,
            ReadinessScore__c = 78.25,
            InjuryRiskScore__c = 22.90,
            LoadTrend__c = 'up',
            PerformanceTrend__c = 'stable',
            FeaturesJson__c = '{"source":"test"}',
            EventTimestamp__c = System.now()
        ));
        Test.stopTest();

        Athlete__c updated = [
            SELECT
                Load7d__c,
                Load28d__c,
                Acwr__c,
                ReadinessScore__c,
                InjuryRiskScore__c,
                LoadTrend__c,
                PerformanceTrend__c,
                FeaturesJson__c,
                LastDataCloudSync__c
            FROM Athlete__c
            WHERE Id = :athlete.Id
            LIMIT 1
        ];

        System.assertEquals(455.50, updated.Load7d__c);
        System.assertEquals(1550.75, updated.Load28d__c);
        System.assertEquals(1.176, updated.Acwr__c);
        System.assertEquals(78.25, updated.ReadinessScore__c);
        System.assertEquals(22.90, updated.InjuryRiskScore__c);
        System.assertEquals('Up', updated.LoadTrend__c);
        System.assertEquals('Stable', updated.PerformanceTrend__c);
        System.assertEquals('{"source":"test"}', updated.FeaturesJson__c);
        System.assertNotEquals(null, updated.LastDataCloudSync__c);
    }

    @IsTest
    static void ignoresUnknownExternalId() {
        Test.startTest();
        EventBus.publish(new AthleteFeatureUpdate__e(
            AthleteExternalId__c = 'ATH-NOT-FOUND',
            Load7d__c = 100
        ));
        Test.stopTest();

        Integer updated = [
            SELECT COUNT()
            FROM Athlete__c
            WHERE ExternalId__c = 'ATH-NOT-FOUND'
        ];
        System.assertEquals(0, updated);
    }
}
