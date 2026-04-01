@IsTest
private class SC360BayonneSquadSyncServiceTest {
    @IsTest
    static void syncSquad_mock_ok() {
        Test.setMock(HttpCalloutMock.class, new SquadsMock());
        Test.startTest();
        SC360BayonneSquadSyncService.SyncResult r = SC360BayonneSquadSyncService.syncSquad();
        Test.stopTest();
        System.assertEquals(true, r.success, r.message);
        System.assertEquals(2, r.upsertCount);
        List<Athlete__c> athletes = [
            SELECT ExternalId__c, Name, Sport__c, Status__c, CurrentSquad__c, FeaturesJson__c
            FROM Athlete__c
            WHERE ExternalId__c LIKE 'APISPORTS-%'
        ];
        System.assertEquals(2, athletes.size());
    }

    @IsTest
    static void syncSquad_http_error() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        SC360BayonneSquadSyncService.SyncResult r = SC360BayonneSquadSyncService.syncSquad();
        System.assertEquals(false, r.success);
    }

    private class SquadsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{"get":"players/squads","errors":[],"response":[{"team":{"id":10166,"name":"Bayonne","logo":"x"},' +
                    '"players":[' +
                    '{"id":111,"name":"Test Un","age":22,"number":1,"position":"Goalkeeper","photo":"http://p"},' +
                    '{"id":222,"name":"Test Deux","age":24,"number":9,"position":"Attacker","photo":"http://q"}' +
                    ']}]}'
            );
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{}');
            return res;
        }
    }
}
