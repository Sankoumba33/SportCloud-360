@IsTest
private class PlanningEventCalendarSyncTest {
    @IsTest
    static void createsUpdatesDeletesAndUndeletesCalendarEvent() {
        Squad__c squad = new Squad__c(Name = 'U19', Code__c = 'U19', IsActive__c = true);
        insert squad;

        PlanningEvent__c planning = new PlanningEvent__c(
            Name = 'Training Session #1',
            Squad__c = squad.Id,
            EventType__c = 'Training',
            StartDateTime__c = DateTime.now().addDays(1),
            EndDateTime__c = DateTime.now().addDays(1).addHours(2),
            Location__c = 'Main Pitch',
            Status__c = 'Planned'
        );

        Test.startTest();
        insert planning;
        Test.stopTest();

        Event evt = findLinkedEvent(planning.Id);
        System.assertNotEquals(null, evt, 'Linked Event should exist after insert.');
        System.assertEquals('Training Session #1', evt.Subject);
        System.assertEquals('Main Pitch', evt.Location);
        System.assert(evt.Description.contains('[SC_PLANNING_ID=' + String.valueOf(planning.Id) + ']'));
        System.assert(evt.Description.contains('Type: Training'));
        System.assert(evt.Description.contains('Status: Planned'));

        planning.Name = 'Training Session #1 Updated';
        planning.Status__c = 'Confirmed';
        planning.EventType__c = 'Meeting';
        planning.Location__c = 'Video Room';
        update planning;

        evt = findLinkedEvent(planning.Id);
        System.assertNotEquals(null, evt, 'Linked Event should exist after update.');
        System.assertEquals('Training Session #1 Updated', evt.Subject);
        System.assertEquals('Video Room', evt.Location);
        System.assert(evt.Description.contains('Type: Meeting'));
        System.assert(evt.Description.contains('Status: Confirmed'));

        delete planning;
        Integer remaining = countLinkedEvents(planning.Id);
        System.assertEquals(0, remaining);

        undelete planning;
        remaining = countLinkedEvents(planning.Id);
        System.assertEquals(1, remaining);
    }

    private static Event findLinkedEvent(Id planningId) {
        String marker = '[SC_PLANNING_ID=' + String.valueOf(planningId) + ']';
        for (Event evt : [
            SELECT Id, Subject, Location, Description, StartDateTime
            FROM Event
            WHERE StartDateTime >= :DateTime.now().addYears(-1)
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            if (evt.Description != null && evt.Description.contains(marker)) {
                return evt;
            }
        }
        return null;
    }

    private static Integer countLinkedEvents(Id planningId) {
        Integer countLinked = 0;
        String marker = '[SC_PLANNING_ID=' + String.valueOf(planningId) + ']';
        for (Event evt : [
            SELECT Id, Description, StartDateTime
            FROM Event
            WHERE StartDateTime >= :DateTime.now().addYears(-1)
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            if (evt.Description != null && evt.Description.contains(marker)) {
                countLinked++;
            }
        }
        return countLinked;
    }
}
