/**
 * Client HTTP vers API-Football (v3) via Named Credential.
 * Auth: header x-apisports-key sur l'identifiant externe lié au Named Credential.
 */
public with sharing class ApiSportsFootballClient {
    /** Nom du Named Credential (callout:APISports_Football/...) */
    public static final String NAMED_CREDENTIAL = 'APISports_Football';

    /**
     * GET sur un chemin relatif (ex. /status, /players/squads?team=10166).
     */
    public static HttpResponse get(String pathAndQuery) {
        if (String.isBlank(pathAndQuery)) {
            throw new CalloutException('pathAndQuery requis');
        }
        String path = pathAndQuery.startsWith('/') ? pathAndQuery : '/' + pathAndQuery;
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + path);
        req.setTimeout(120000);
        return new Http().send(req);
    }
}
