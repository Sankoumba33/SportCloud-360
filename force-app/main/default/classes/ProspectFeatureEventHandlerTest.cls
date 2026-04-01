@IsTest
private class ProspectFeatureEventHandlerTest {
    @IsTest
    static void updatesProspectFromPlatformEvent() {
        Prospect__c prospect = new Prospect__c(
            Name = 'Prospect Event Test',
            ExternalId__c = 'PRO-PE-001',
            Status__c = 'Identified'
        );
        insert prospect;

        Test.startTest();
        EventBus.publish(new ProspectFeatureUpdate__e(
            ProspectExternalId__c = 'PRO-PE-001',
            ScoutingScore__c = 72.40,
            PotentialScore__c = 81.15,
            FitScore__c = 69.80,
            RiskScore__c = 24.35,
            DataConfidence__c = 87.55,
            ScoutingSummary__c = 'Strong profile for short-term integration.',
            TopStrengths__c = 'acceleration; first touch',
            TopRisks__c = 'league gap',
            ScoutingFeaturesJson__c = '{"source":"test"}',
            EventTimestamp__c = System.now()
        ));
        Test.stopTest();

        Prospect__c updated = [
            SELECT
                ScoutingScore__c,
                PotentialScore__c,
                FitScore__c,
                RiskScore__c,
                DataConfidence__c,
                ScoutingSummary__c,
                TopStrengths__c,
                TopRisks__c,
                ScoutingFeaturesJson__c,
                LastDataCloudSync__c
            FROM Prospect__c
            WHERE Id = :prospect.Id
            LIMIT 1
        ];

        System.assertEquals(72.40, updated.ScoutingScore__c);
        System.assertEquals(81.15, updated.PotentialScore__c);
        System.assertEquals(69.80, updated.FitScore__c);
        System.assertEquals(24.35, updated.RiskScore__c);
        System.assertEquals(87.55, updated.DataConfidence__c);
        System.assertEquals('Strong profile for short-term integration.', updated.ScoutingSummary__c);
        System.assertEquals('acceleration; first touch', updated.TopStrengths__c);
        System.assertEquals('league gap', updated.TopRisks__c);
        System.assertEquals('{"source":"test"}', updated.ScoutingFeaturesJson__c);
        System.assertNotEquals(null, updated.LastDataCloudSync__c);
    }

    @IsTest
    static void ignoresUnknownExternalId() {
        Test.startTest();
        EventBus.publish(new ProspectFeatureUpdate__e(
            ProspectExternalId__c = 'PRO-NOT-FOUND',
            ScoutingScore__c = 60
        ));
        Test.stopTest();

        Integer countProspects = [
            SELECT COUNT()
            FROM Prospect__c
            WHERE ExternalId__c = 'PRO-NOT-FOUND'
        ];
        System.assertEquals(0, countProspects);
    }
}
