@IsTest
private class DateValidationRulesTest {
    @IsTest
    static void squadAssignmentRejectsEndDateBeforeStartDate() {
        Squad__c squad = new Squad__c(Name = 'U18', Code__c = 'U18', IsActive__c = true);
        insert squad;

        Athlete__c athlete = new Athlete__c(Name = 'Validation Athlete', ExternalId__c = 'VAL-ATH-001', Sport__c = 'Football', Status__c = 'Active');
        insert athlete;

        SquadAssignment__c invalidAssignment = new SquadAssignment__c(
            Athlete__c = athlete.Id,
            Squad__c = squad.Id,
            StartDate__c = Date.today(),
            EndDate__c = Date.today().addDays(-1),
            Reason__c = 'Other'
        );

        try {
            insert invalidAssignment;
            System.assert(false, 'Expected validation error for SquadAssignment__c');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('End Date must be greater than or equal to Start Date.'));
        }
    }

    @IsTest
    static void planningEventRejectsEndDateTimeBeforeOrEqualStartDateTime() {
        PlanningEvent__c invalidPlanning = new PlanningEvent__c(
            Name = 'Invalid Planning',
            EventType__c = 'Training',
            StartDateTime__c = DateTime.now().addDays(1),
            EndDateTime__c = DateTime.now().addDays(1),
            Status__c = 'Planned'
        );

        try {
            insert invalidPlanning;
            System.assert(false, 'Expected validation error for PlanningEvent__c');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('End Date Time must be greater than Start Date Time.'));
        }
    }

    @IsTest
    static void bookingRejectsEndDateTimeBeforeOrEqualStartDateTime() {
        Resource__c resource = new Resource__c(Name = 'Pitch A', Type__c = 'Pitch', IsActive__c = true);
        insert resource;

        PlanningEvent__c planning = new PlanningEvent__c(
            Name = 'Planning For Booking',
            EventType__c = 'Training',
            StartDateTime__c = DateTime.now().addDays(1),
            EndDateTime__c = DateTime.now().addDays(1).addHours(2),
            Status__c = 'Planned'
        );
        insert planning;

        Booking__c invalidBooking = new Booking__c(
            Resource__c = resource.Id,
            PlanningEvent__c = planning.Id,
            StartDateTime__c = DateTime.now().addDays(2),
            EndDateTime__c = DateTime.now().addDays(2),
            Notes__c = 'Invalid booking'
        );

        try {
            insert invalidBooking;
            System.assert(false, 'Expected validation error for Booking__c');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('End Date Time must be greater than Start Date Time.'));
        }
    }

    @IsTest
    static void schoolAbsenceRejectsEndDateBeforeStartDate() {
        Athlete__c athlete = new Athlete__c(Name = 'School Athlete', ExternalId__c = 'VAL-ATH-002', Sport__c = 'Football', Status__c = 'Active');
        insert athlete;

        SchoolAbsence__c invalidAbsence = new SchoolAbsence__c(
            Athlete__c = athlete.Id,
            StartDate__c = Date.today(),
            EndDate__c = Date.today().addDays(-2),
            Type__c = 'Exam',
            Description__c = 'Invalid dates'
        );

        try {
            insert invalidAbsence;
            System.assert(false, 'Expected validation error for SchoolAbsence__c');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains('End Date must be greater than or equal to Start Date.'));
        }
    }
}
