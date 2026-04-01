trigger PlanningEventTrigger on PlanningEvent__c (
    after insert,
    after update,
    after delete,
    after undelete
) {
    PlanningEventCalendarSync.handleAfter(
        Trigger.new,
        Trigger.newMap,
        Trigger.oldMap,
        Trigger.isInsert,
        Trigger.isUpdate,
        Trigger.isDelete,
        Trigger.isUndelete
    );
}
