public with sharing class PlanningEventCalendarSync {
    private static Boolean isRunning = false;
    private static final String DESC_PREFIX = '[SC_PLANNING_ID=';
    private static final String DESC_SUFFIX = ']';

    public static void handleAfter(
        List<PlanningEvent__c> newList,
        Map<Id, PlanningEvent__c> newMap,
        Map<Id, PlanningEvent__c> oldMap,
        Boolean isInsert,
        Boolean isUpdate,
        Boolean isDelete,
        Boolean isUndelete
    ) {
        if (isRunning) {
            return;
        }
        isRunning = true;
        try {
            if (isDelete) {
                deleteLinkedEvents(oldMap);
                return;
            }

            upsertLinkedEvents(newList);
        } finally {
            isRunning = false;
        }
    }

    private static void upsertLinkedEvents(List<PlanningEvent__c> planningEvents) {
        if (planningEvents == null || planningEvents.isEmpty()) {
            return;
        }

        Set<Id> planningIds = new Set<Id>();
        DateTime minStart;
        DateTime maxEnd;
        for (PlanningEvent__c pe : planningEvents) {
            planningIds.add(pe.Id);
            if (pe.StartDateTime__c != null && (minStart == null || pe.StartDateTime__c < minStart)) {
                minStart = pe.StartDateTime__c;
            }
            if (pe.EndDateTime__c != null && (maxEnd == null || pe.EndDateTime__c > maxEnd)) {
                maxEnd = pe.EndDateTime__c;
            }
        }

        Map<Id, Event> existingByPlanningId = new Map<Id, Event>();
        if (minStart == null) {
            minStart = DateTime.now().addYears(-1);
        }
        if (maxEnd == null) {
            maxEnd = DateTime.now().addYears(1);
        }
        DateTime minStartBuffer = minStart.addDays(-30);
        DateTime maxEndBuffer = maxEnd.addDays(30);
        for (Event evt : [
            SELECT Id, Description
            FROM Event
            WHERE StartDateTime >= :minStartBuffer
            AND StartDateTime <= :maxEndBuffer
        ]) {
            Id planningId = extractPlanningId(evt.Description);
            if (planningId != null && planningIds.contains(planningId)) {
                existingByPlanningId.put(planningId, evt);
            }
        }

        List<Event> toInsert = new List<Event>();
        List<Event> toUpdate = new List<Event>();

        for (PlanningEvent__c pe : planningEvents) {
            if (pe.StartDateTime__c == null || pe.EndDateTime__c == null) {
                continue;
            }

            Event evt = existingByPlanningId.containsKey(pe.Id)
                ? existingByPlanningId.get(pe.Id)
                : new Event();

            evt.Subject = String.isBlank(pe.Name) ? 'Planning Event' : pe.Name;
            evt.StartDateTime = pe.StartDateTime__c;
            evt.EndDateTime = pe.EndDateTime__c;
            evt.Location = pe.Location__c;
            evt.Description = buildDescription(pe);

            if (evt.Id == null) {
                toInsert.add(evt);
            } else {
                toUpdate.add(evt);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void deleteLinkedEvents(Map<Id, PlanningEvent__c> oldMap) {
        if (oldMap == null || oldMap.isEmpty()) {
            return;
        }

        Set<Id> planningIds = oldMap.keySet();
        DateTime minStart;
        DateTime maxEnd;
        for (PlanningEvent__c pe : oldMap.values()) {
            if (pe.StartDateTime__c != null && (minStart == null || pe.StartDateTime__c < minStart)) {
                minStart = pe.StartDateTime__c;
            }
            if (pe.EndDateTime__c != null && (maxEnd == null || pe.EndDateTime__c > maxEnd)) {
                maxEnd = pe.EndDateTime__c;
            }
        }
        if (minStart == null) {
            minStart = DateTime.now().addYears(-1);
        }
        if (maxEnd == null) {
            maxEnd = DateTime.now().addYears(1);
        }
        DateTime minStartBuffer = minStart.addDays(-30);
        DateTime maxEndBuffer = maxEnd.addDays(30);
        List<Event> eventsToDelete = [
            SELECT Id, Description
            FROM Event
            WHERE StartDateTime >= :minStartBuffer
            AND StartDateTime <= :maxEndBuffer
        ];
        if (!eventsToDelete.isEmpty()) {
            List<Event> filteredToDelete = new List<Event>();
            for (Event evt : eventsToDelete) {
                Id planningId = extractPlanningId(evt.Description);
                if (planningId != null && planningIds.contains(planningId)) {
                    filteredToDelete.add(evt);
                }
            }
            if (!filteredToDelete.isEmpty()) {
                delete filteredToDelete;
            }
        }
    }

    private static String buildDescription(PlanningEvent__c pe) {
        List<String> lines = new List<String>();
        lines.add(DESC_PREFIX + pe.Id + DESC_SUFFIX);
        lines.add('Generated from PlanningEvent__c');
        if (pe.EventType__c != null) {
            lines.add('Type: ' + pe.EventType__c);
        }
        if (pe.Status__c != null) {
            lines.add('Status: ' + pe.Status__c);
        }
        return String.join(lines, '\n');
    }

    private static Id extractPlanningId(String descriptionValue) {
        if (String.isBlank(descriptionValue) || !descriptionValue.startsWith(DESC_PREFIX)) {
            return null;
        }
        Integer endIdx = descriptionValue.indexOf(DESC_SUFFIX);
        if (endIdx <= DESC_PREFIX.length()) {
            return null;
        }
        String idValue = descriptionValue.substring(DESC_PREFIX.length(), endIdx);
        if (String.isBlank(idValue)) {
            return null;
        }
        try {
            return (Id) idValue;
        } catch (Exception e) {
            return null;
        }
    }
}
