@IsTest
private class SC360ScoutingProspectSyncServiceTest {
    @IsTest
    static void enrichOneProspect_mock_ok() {
        Test.setMock(HttpCalloutMock.class, new PlayerByIdMock());
        Prospect__c p = new Prospect__c(
            Name = 'Temp',
            ExternalId__c = 'APISPORTS-111',
            Status__c = 'New'
        );
        insert p;

        Test.startTest();
        SC360ScoutingOperationResult r = SC360ScoutingProspectSyncService.enrichOneProspect(p.Id, 2024);
        Test.stopTest();

        System.assertEquals(true, r.success, r.message);
        Prospect__c updated = [
            SELECT
                ScoutingSummary__c,
                CurrentClub__c,
                Championship__c,
                DataConfidence__c,
                ApiStatsSeason__c,
                ApiAppearances__c,
                ApiLineups__c,
                ApiMinutes__c,
                ApiGoals__c,
                ApiAssists__c,
                ApiShotsOnTarget__c,
                ApiPassesAccuracyPct__c
            FROM Prospect__c
            WHERE Id = :p.Id
        ];
        System.assertEquals('Bayonne', updated.CurrentClub__c);
        System.assert(updated.ScoutingSummary__c.contains('2024'));
        System.assertEquals(2024, updated.ApiStatsSeason__c.intValue());
        System.assertEquals(5, updated.ApiAppearances__c.intValue());
        System.assertEquals(4, updated.ApiLineups__c.intValue());
        System.assertEquals(420, updated.ApiMinutes__c.intValue());
        System.assertEquals(2, updated.ApiGoals__c.intValue());
        System.assertEquals(1, updated.ApiAssists__c.intValue());
        System.assertEquals(5, updated.ApiShotsOnTarget__c.intValue());
        System.assertEquals(82.5, updated.ApiPassesAccuracyPct__c);
    }

    @IsTest
    static void enrichBatch_runs() {
        Test.setMock(HttpCalloutMock.class, new PlayerByIdMock());
        insert new Prospect__c(
            Name = 'Batch',
            ExternalId__c = 'APISPORTS-111',
            Status__c = 'New'
        );

        Test.startTest();
        Id jobId = Database.executeBatch(new SC360ScoutingProspectEnrichBatch(2024), 1);
        Test.stopTest();

        AsyncApexJob j = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', j.Status);
    }

    @IsTest
    static void leagueImportQueueable_mock_ok() {
        Test.setMock(HttpCalloutMock.class, new LeaguePlayersMock());
        Test.startTest();
        System.enqueueJob(
            new SC360ScoutingLeagueImportQueueable(new List<Integer>{ 999001 }, 0, 1, 2024, 1)
        );
        Test.stopTest();

        Prospect__c imported = [
            SELECT Id, ApiMinutes__c, ApiLineups__c
            FROM Prospect__c
            WHERE ExternalId__c = 'APISPORTS-999'
            LIMIT 1
        ];
        System.assertEquals(90, imported.ApiMinutes__c.intValue());
        System.assertEquals(1, imported.ApiLineups__c.intValue());
    }

    private class PlayerByIdMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"get":"players","errors":[],"response":[{"player":{"id":111,"name":"Test Player","nationality":"France","position":"Midfielder"},' +
                    '"statistics":[{"team":{"name":"Bayonne"},"league":{"name":"National 2 - Group A"},' +
                    '"games":{"appearences":5,"lineups":4,"minutes":420,"position":"Midfielder"},' +
                    '"goals":{"total":2,"assists":1},"cards":{"yellow":1,"red":0},' +
                    '"shots":{"total":10,"on":5},"passes":{"total":100,"key":3,"accuracy":82.5},' +
                    '"tackles":{"total":12},"duels":{"won":8}}]}]}'
            );
            return res;
        }
    }

    private class LeaguePlayersMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"get":"players","errors":[],"paging":{"current":1,"total":1},"response":[{"player":{"id":999,"name":"Import Test","nationality":"France"},' +
                    '"statistics":[{"team":{"name":"Club X"},"league":{"name":"National 2 - Group A"},' +
                    '"games":{"appearences":2,"lineups":1,"minutes":90}}]}]}'
            );
            return res;
        }
    }
}
