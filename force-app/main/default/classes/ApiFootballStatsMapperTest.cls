@IsTest
private class ApiFootballStatsMapperTest {
    @IsTest
    static void applyToProspect_maps_blocks() {
        Prospect__c p = new Prospect__c();
        Map<String, Object> stat0 = (Map<String, Object>) JSON.deserializeUntyped(
            '{"games":{"appearences":3,"lineups":2,"minutes":180},' +
                '"goals":{"total":1,"assists":0},' +
                '"cards":{"yellow":2,"red":0},' +
                '"shots":{"total":4,"on":1},' +
                '"passes":{"total":50,"key":1,"accuracy":"71"},' +
                '"tackles":{"total":6},' +
                '"duels":{"won":4}}'
        );
        ApiFootballStatsMapper.applyToProspect(p, stat0, 2025);
        System.assertEquals(2025, p.ApiStatsSeason__c.intValue());
        System.assertEquals(3, p.ApiAppearances__c.intValue());
        System.assertEquals(2, p.ApiLineups__c.intValue());
        System.assertEquals(180, p.ApiMinutes__c.intValue());
        System.assertEquals(71, p.ApiPassesAccuracyPct__c);
        System.assert(p.ApiStatisticsJson__c.contains('"games"'));
    }

    @IsTest
    static void applyToProspect_null_clears() {
        Prospect__c p = new Prospect__c();
        p.ApiGoals__c = 9;
        ApiFootballStatsMapper.applyToProspect(p, null, 2024);
        System.assertEquals(null, p.ApiGoals__c);
        System.assertEquals(2024, p.ApiStatsSeason__c.intValue());
    }
}
