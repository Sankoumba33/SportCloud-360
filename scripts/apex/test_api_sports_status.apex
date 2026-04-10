// Test Named Credential APISports_Football -> GET /status
// sf apex run --file scripts/apex/test_api_sports_status.apex -o SPC360

HttpRequest r = new HttpRequest();
r.setMethod('GET');
r.setEndpoint('callout:APISports_Football/status');
r.setTimeout(120000);
HttpResponse res = new Http().send(r);
System.debug(LoggingLevel.INFO, 'HTTP ' + res.getStatusCode());
String body = res.getBody();
System.debug(LoggingLevel.INFO, body.length() > 800 ? body.substring(0, 800) + '...' : body);
