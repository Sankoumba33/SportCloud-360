@IsTest
private class SC360ProspectCompareControllerTest {
    @IsTest
    static void testCompare_twoProspects() {
        Prospect__c p1 = new Prospect__c(Name = 'Prospect Alpha', Position__c = 'Ailier');
        Prospect__c p2 = new Prospect__c(Name = 'Prospect Beta', Position__c = 'Milieu');
        insert new List<Prospect__c>{ p1, p2 };

        p1.ScoutingScore__c = 72;
        p1.PotentialScore__c = 80;
        p1.RiskScore__c = 30;
        p2.ScoutingScore__c = 65;
        p2.PotentialScore__c = 75;
        p2.RiskScore__c = 45;
        update new List<Prospect__c>{ p1, p2 };

        Test.startTest();
        List<SC360ProspectCompareController.ProspectCompareDto> rows = SC360ProspectCompareController.getProspectsCompare(
            new List<Id>{ p1.Id, p2.Id }
        );
        Test.stopTest();

        System.assertEquals(2, rows.size());
        System.assertEquals('Prospect Alpha', rows[0].name);
        System.assertEquals('Prospect Beta', rows[1].name);
        System.assertEquals(72, rows[0].scoutingScore);
    }

    @IsTest
    static void testCompare_tooFew() {
        Prospect__c p1 = new Prospect__c(Name = 'Solo');
        insert p1;
        Boolean threw = false;
        try {
            SC360ProspectCompareController.getProspectsCompare(new List<Id>{ p1.Id });
        } catch (Exception e) {
            threw = true;
        }
        System.assert(threw, 'Attendu: au moins deux prospects.');
    }
}
