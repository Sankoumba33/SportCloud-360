// Exécute une fois après déploiement de PhotoUrl__c : copie photo depuis FeaturesJson (sync API).
// Les prochains sync Bayonne N2 remplissent PhotoUrl__c directement.

List<Athlete__c> rows = [
    SELECT Id, FeaturesJson__c, PhotoUrl__c
    FROM Athlete__c
    WHERE ExternalId__c LIKE 'APISPORTS-%'
];
List<Athlete__c> upd = new List<Athlete__c>();
for (Athlete__c a : rows) {
    if (String.isNotBlank(a.PhotoUrl__c) || String.isBlank(a.FeaturesJson__c)) {
        continue;
    }
    try {
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(a.FeaturesJson__c);
        Object p = m.get('photo');
        if (p == null) {
            continue;
        }
        String url = String.valueOf(p).trim();
        if (String.isBlank(url)) {
            continue;
        }
        a.PhotoUrl__c = url;
        upd.add(a);
    } catch (Exception e) {
    }
}
if (!upd.isEmpty()) {
    update upd;
}
System.debug('PhotoUrl__c backfill: ' + upd.size());
