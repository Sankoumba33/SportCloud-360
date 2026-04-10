@IsTest
private class SC360InsidersMatchStatsServiceTest {
    @IsTest
    static void merge_inserts_match_stats_by_shirt() {
        insert new Athlete__c(
            Name = 'Test GPS',
            ExternalId__c = 'APISPORTS-900001',
            Sport__c = 'Football',
            Status__c = 'Active',
            FeaturesJson__c = '{"number":4,"apiSource":"api-football"}'
        );

        String payload =
            '{"bundles":[{"matchKey":"J18-test-2026-03-18","matchLabel":"J18 vs X","matchDate":"2026-03-18","sourceFile":"x.pdf","reportType":"FullPlayerStats","players":[{"shirtNumber":4,"distanceM":9999.0,"maxSpeedKmh":30.1}]}]}';

        Test.startTest();
        SC360InsidersMatchStatsService.MergeResult r = SC360InsidersMatchStatsService.mergeFromPayloadJson(payload);
        Test.stopTest();

        System.assertEquals(1, r.updated);
        Athlete__c a = [SELECT FeaturesJson__c FROM Athlete__c WHERE ExternalId__c = 'APISPORTS-900001'];
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(a.FeaturesJson__c);
        Map<String, Object> il = (Map<String, Object>) root.get('insidersLive');
        Map<String, Object> ms = (Map<String, Object>) il.get('matchStats');
        Map<String, Object> row = (Map<String, Object>) ms.get('J18-test-2026-03-18');
        System.assertEquals(9999.0, Decimal.valueOf(String.valueOf(row.get('distanceM'))));
    }
}
