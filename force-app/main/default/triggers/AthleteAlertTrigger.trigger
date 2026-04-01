trigger AthleteAlertTrigger on Athlete__c (after insert, after update) {
    AthleteAlertAutomation.handleAfter(Trigger.new);
}
