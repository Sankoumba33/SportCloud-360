/*
Sprint 1 - T1 seed data
Run with:
sf apex run --file scripts/apex/sprint1_t1_seed_data.apex
*/

List<Map<String, Object>> squadDefs = new List<Map<String, Object>>{
    new Map<String, Object>{'name' => 'Equipe premiere', 'code' => 'PRO', 'order' => 1, 'isYouth' => false},
    new Map<String, Object>{'name' => 'Equipe reserve', 'code' => 'RES', 'order' => 2, 'isYouth' => false},
    new Map<String, Object>{'name' => 'U19', 'code' => 'U19', 'order' => 3, 'isYouth' => true},
    new Map<String, Object>{'name' => 'U18', 'code' => 'U18', 'order' => 4, 'isYouth' => true},
    new Map<String, Object>{'name' => 'U17', 'code' => 'U17', 'order' => 5, 'isYouth' => true},
    new Map<String, Object>{'name' => 'U16', 'code' => 'U16', 'order' => 6, 'isYouth' => true}
};

Set<String> squadNames = new Set<String>();
Map<String, String> codeToName = new Map<String, String>();
for (Map<String, Object> def : squadDefs) {
    String name = (String) def.get('name');
    squadNames.add(name);
    codeToName.put((String) def.get('code'), name);
}

Map<String, Squad__c> squadsByName = new Map<String, Squad__c>();
for (Squad__c s : [SELECT Id, Name FROM Squad__c WHERE Name IN :squadNames]) {
    squadsByName.put(s.Name, s);
}

List<Squad__c> squadsToInsert = new List<Squad__c>();
for (Map<String, Object> def : squadDefs) {
    String name = (String) def.get('name');
    if (!squadsByName.containsKey(name)) {
        squadsToInsert.add(new Squad__c(Name = name));
    }
}
if (!squadsToInsert.isEmpty()) {
    insert squadsToInsert;
}

for (Squad__c s : [SELECT Id, Name FROM Squad__c WHERE Name IN :squadNames]) {
    squadsByName.put(s.Name, s);
}
Map<String, Squad__c> squadsByCode = new Map<String, Squad__c>();
for (String code : codeToName.keySet()) {
    Squad__c s = squadsByName.get(codeToName.get(code));
    if (s != null) squadsByCode.put(code, s);
}

List<Athlete__c> athletes = new List<Athlete__c>{
    new Athlete__c(Name='Marc Dubois', ExternalId__c='ATH-001', DateOfBirth__c=Date.newInstance(2001, 3, 14), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Lucas Martin', ExternalId__c='ATH-002', DateOfBirth__c=Date.newInstance(2000, 11, 4), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Nabil Benali', ExternalId__c='ATH-003', DateOfBirth__c=Date.newInstance(2004, 1, 22), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Ibrahima Sarr', ExternalId__c='ATH-004', DateOfBirth__c=Date.newInstance(2005, 8, 2), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Adam Lefevre', ExternalId__c='ATH-005', DateOfBirth__c=Date.newInstance(2006, 6, 30), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Mehdi Bensaid', ExternalId__c='ATH-006', DateOfBirth__c=Date.newInstance(2007, 12, 10), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Hugo Lambert', ExternalId__c='ATH-007', DateOfBirth__c=Date.newInstance(2003, 9, 18), Sport__c='Football', Status__c='Injured'),
    new Athlete__c(Name='Yanis Traore', ExternalId__c='ATH-008', DateOfBirth__c=Date.newInstance(2008, 2, 5), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Noah Richard', ExternalId__c='ATH-009', DateOfBirth__c=Date.newInstance(2009, 7, 12), Sport__c='Football', Status__c='Active'),
    new Athlete__c(Name='Rayan Moreau', ExternalId__c='ATH-010', DateOfBirth__c=Date.newInstance(2008, 10, 27), Sport__c='Football', Status__c='Unavailable')
};
upsert athletes ExternalId__c;

Map<String, Athlete__c> athletesByExternalId = new Map<String, Athlete__c>();
for (Athlete__c a : [
    SELECT Id, ExternalId__c
    FROM Athlete__c
    WHERE ExternalId__c IN ('ATH-001','ATH-002','ATH-003','ATH-004','ATH-005','ATH-006','ATH-007','ATH-008','ATH-009','ATH-010')
]) {
    athletesByExternalId.put(a.ExternalId__c, a);
}

List<Prospect__c> prospects = new List<Prospect__c>{
    new Prospect__c(Name='Jules Petit', ExternalId__c='PROS-001', Status__c='New', Position__c='ST', CurrentClub__c='FC Nantes Academy'),
    new Prospect__c(Name='Bilal Ait', ExternalId__c='PROS-002', Status__c='Under Review', Position__c='CM', CurrentClub__c='US Creteil'),
    new Prospect__c(Name='Lenny Caron', ExternalId__c='PROS-003', Status__c='Priority', Position__c='CB', CurrentClub__c='Stade Lavallois'),
    new Prospect__c(Name='Ismael Diop', ExternalId__c='PROS-004', Status__c='New', Position__c='RW', CurrentClub__c='Amiens SC'),
    new Prospect__c(Name='Tao Girard', ExternalId__c='PROS-005', Status__c='Under Review', Position__c='GK', CurrentClub__c='FC Metz'),
    new Prospect__c(Name='Amine Bouchra', ExternalId__c='PROS-006', Status__c='New', Position__c='LB', CurrentClub__c='Tours FC'),
    new Prospect__c(Name='Matis Elouafi', ExternalId__c='PROS-007', Status__c='Priority', Position__c='CAM', CurrentClub__c='Le Havre AC'),
    new Prospect__c(Name='Sofiane Kaidi', ExternalId__c='PROS-008', Status__c='New', Position__c='RB', CurrentClub__c='SM Caen'),
    new Prospect__c(Name='Nathan Colin', ExternalId__c='PROS-009', Status__c='Negotiation', Position__c='CF', CurrentClub__c='RC Lens Academy'),
    new Prospect__c(Name='Milo Araujo', ExternalId__c='PROS-010', Status__c='Dropped', Position__c='DM', CurrentClub__c='Stade Briochin')
};
upsert prospects ExternalId__c;

List<SquadAssignment__c> existingAssignments = [
    SELECT Id
    FROM SquadAssignment__c
    WHERE Athlete__c IN :athletesByExternalId.values()
];
if (!existingAssignments.isEmpty()) {
    delete existingAssignments;
}

Date seasonStart = Date.today().toStartOfMonth().addMonths(-8);
Date transitionDate = Date.today().toStartOfMonth().addMonths(-3);

List<SquadAssignment__c> assignments = new List<SquadAssignment__c>{
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-001').Id, Squad__c=squadsByCode.get('PRO').Id, StartDate__c=seasonStart, EndDate__c=null, Reason__c='Coach Decision'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-002').Id, Squad__c=squadsByCode.get('PRO').Id, StartDate__c=seasonStart, EndDate__c=null, Reason__c='Coach Decision'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-003').Id, Squad__c=squadsByCode.get('U19').Id, StartDate__c=seasonStart, EndDate__c=transitionDate.addDays(-1), Reason__c='Other'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-003').Id, Squad__c=squadsByCode.get('RES').Id, StartDate__c=transitionDate, EndDate__c=null, Reason__c='Promotion'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-004').Id, Squad__c=squadsByCode.get('U19').Id, StartDate__c=seasonStart, EndDate__c=null, Reason__c='Other'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-005').Id, Squad__c=squadsByCode.get('U18').Id, StartDate__c=seasonStart, EndDate__c=null, Reason__c='Other'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-006').Id, Squad__c=squadsByCode.get('U18').Id, StartDate__c=seasonStart, EndDate__c=transitionDate.addDays(-1), Reason__c='Other'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-006').Id, Squad__c=squadsByCode.get('U19').Id, StartDate__c=transitionDate, EndDate__c=null, Reason__c='Promotion'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-007').Id, Squad__c=squadsByCode.get('RES').Id, StartDate__c=seasonStart, EndDate__c=null, Reason__c='Coach Decision'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-008').Id, Squad__c=squadsByCode.get('U17').Id, StartDate__c=seasonStart, EndDate__c=null, Reason__c='Other'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-009').Id, Squad__c=squadsByCode.get('U16').Id, StartDate__c=seasonStart, EndDate__c=transitionDate.addDays(-1), Reason__c='Other'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-009').Id, Squad__c=squadsByCode.get('U17').Id, StartDate__c=transitionDate, EndDate__c=null, Reason__c='Promotion'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-010').Id, Squad__c=squadsByCode.get('U16').Id, StartDate__c=seasonStart, EndDate__c=null, Reason__c='Other'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-004').Id, Squad__c=squadsByCode.get('U18').Id, StartDate__c=seasonStart.addYears(-1), EndDate__c=seasonStart.addDays(-1), Reason__c='Promotion'),
    new SquadAssignment__c(Athlete__c=athletesByExternalId.get('ATH-005').Id, Squad__c=squadsByCode.get('U17').Id, StartDate__c=seasonStart.addYears(-1), EndDate__c=seasonStart.addDays(-1), Reason__c='Promotion')
};
insert assignments;

Map<Id, Id> currentSquadByAthlete = new Map<Id, Id>();
for (SquadAssignment__c sa : assignments) {
    if (sa.EndDate__c == null) {
        currentSquadByAthlete.put(sa.Athlete__c, sa.Squad__c);
    }
}

List<Athlete__c> athletesToUpdate = new List<Athlete__c>();
for (Id athleteId : currentSquadByAthlete.keySet()) {
    athletesToUpdate.add(new Athlete__c(
        Id = athleteId,
        CurrentSquad__c = currentSquadByAthlete.get(athleteId)
    ));
}
if (!athletesToUpdate.isEmpty()) {
    update athletesToUpdate;
}

System.debug('T1 seed completed: squads=' + squadsByCode.size() + ', athletes=' + athletesByExternalId.size() + ', prospects=10, assignments=' + assignments.size());
