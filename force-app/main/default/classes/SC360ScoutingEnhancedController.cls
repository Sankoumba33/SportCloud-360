public with sharing class SC360ScoutingEnhancedController {

    // 1. IA Super-Scout (Utilise les vraies données textuelles existantes sur le Prospect)
    @AuraEnabled
    public static String generateAIScoutingSummary(Id prospectId) {
        List<Prospect__c> prospects = [
            SELECT Name, ScoutingSummary__c, TopStrengths__c, TopRisks__c, ScoutingScore__c 
            FROM Prospect__c 
            WHERE Id = :prospectId LIMIT 1
        ];
        
        if (prospects.isEmpty()) {
            return 'Prospect introuvable.';
        }
        Prospect__c p = prospects[0];
        
        String payload = 'Génère une synthèse exécutive pour le joueur ' + p.Name + '.\n'
                       + 'Force: ' + p.TopStrengths__c + '\n'
                       + 'Faiblesses: ' + p.TopRisks__c + '\n'
                       + 'Score actuel: ' + p.ScoutingScore__c + '\n'
                       + 'Résumé Scout: ' + p.ScoutingSummary__c;
        
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ScoutingAI/v1/completions'); // Named Credential expected
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody('{"prompt": "' + payload.escapeJava() + '", "max_tokens": 150}');
            
            // Pour le moment en attendant la config, on retourne une réponse d'attente
            return 'Requête IA préparée pour le prospect ' + p.Name + '. En attente de l\'activation du endpoint OpenAI/ScoutingAI dans Salesforce.';
        } catch (Exception e) {
            return 'Erreur IA : ' + e.getMessage();
        }
    }

    // 2. Data Kanban (Récupère les vrais prospects par Status)
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPipelineKanban() {
        List<Map<String, Object>> kanbanLanes = new List<Map<String, Object>>();
        
        Schema.DescribeFieldResult statusResult = Prospect__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> statusValues = statusResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : statusValues) {
            String status = entry.getValue();
            
            List<Map<String, Object>> prospectsInLane = new List<Map<String, Object>>();
            for (Prospect__c p : [
                SELECT Id, Name, ScoutingScore__c, RiskScore__c, Position__c 
                FROM Prospect__c 
                WHERE Status__c = :status
                ORDER BY ScoutingScore__c DESC NULLS LAST
            ]) {
                Map<String, Object> pMap = new Map<String, Object>();
                pMap.put('id', p.Id);
                pMap.put('title', p.Name);
                pMap.put('score', p.ScoutingScore__c);
                pMap.put('risk', p.RiskScore__c);
                pMap.put('position', p.Position__c);
                prospectsInLane.add(pMap);
            }
            
            Map<String, Object> lane = new Map<String, Object>();
            lane.put('laneName', entry.getLabel());
            lane.put('status', status);
            lane.put('items', prospectsInLane);
            kanbanLanes.add(lane);
        }
        
        return kanbanLanes;
    }
    
    // 3. Comparaison Data (Drag & Drop)
    @AuraEnabled(cacheable=true)
    public static List<Prospect__c> searchProspectsForComparison(String searchTerm) {
        String likeTerm = '%' + searchTerm + '%';
        return [
            SELECT Id, Name, Position__c, ScoutingScore__c, PotentialScore__c, RiskScore__c, FitScore__c 
            FROM Prospect__c 
            WHERE Name LIKE :likeTerm OR Position__c LIKE :likeTerm
            LIMIT 5
        ];
    }
}
