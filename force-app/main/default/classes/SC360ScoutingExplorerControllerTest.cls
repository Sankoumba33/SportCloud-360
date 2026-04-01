@IsTest
private class SC360ScoutingExplorerControllerTest {
    @IsTest
    static void testFiltersAndSearchAndPromote() {
        Prospect__c p = new Prospect__c(
            Name = 'Test Explorer',
            Position__c = 'Ailier',
            Status__c = 'New',
            Country__c = 'France',
            Nationality__c = 'FR',
            Championship__c = 'Ligue 1',
            CurrentClub__c = 'FC Test',
            DataConfidence__c = 80,
            GeoLatitude__c = 48.8566,
            GeoLongitude__c = 2.3522
        );
        insert p;

        Test.startTest();
        SC360ScoutingExplorerController.FilterOptionsDto opts = SC360ScoutingExplorerController.getFilterOptions();
        System.assertNotEquals(null, opts);

        SC360ScoutingExplorerController.SearchResultDto res = SC360ScoutingExplorerController.searchProspects(
            'Test',
            'Ailier',
            null,
            'France',
            null,
            null,
            'high',
            25
        );
        System.assertEquals(1, res.totalCount);
        System.assertEquals(1, res.rows.size());

        SC360ScoutingExplorerController.promoteToPriority(p.Id);
        Test.stopTest();

        Prospect__c after = [SELECT Status__c FROM Prospect__c WHERE Id = :p.Id];
        System.assertEquals('Priority', after.Status__c);
    }

    @IsTest
    static void testAddProspectToPipeline() {
        SC360ScoutingExplorerController.ProspectDraftDto d = new SC360ScoutingExplorerController.ProspectDraftDto();
        d.name = 'Draft Prospect';
        d.position = 'Gardien';
        d.status = 'Under Review';

        Test.startTest();
        Id pid = SC360ScoutingExplorerController.addProspectToPipeline(d);
        Test.stopTest();

        Prospect__c p = [SELECT Name, Status__c FROM Prospect__c WHERE Id = :pid];
        System.assertEquals('Draft Prospect', p.Name);
        System.assertEquals('Under Review', p.Status__c);
    }
}
