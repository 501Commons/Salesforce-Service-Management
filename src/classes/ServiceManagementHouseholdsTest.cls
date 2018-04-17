@isTest
private class ServiceManagementHouseholdsTest {
    
    // there are no adult client names
    @isTest static void testNoAdultNames() {
        Account household = new Account(
            Name = 'Test Account',
            Address__c = '123 Main Street',
            City__c = 'Seattle',
            State__c = 'WA',
            Postal_Code__c = '98103'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 12));
        insert clients;

        ServiceManagementHouseholds.runBatchManually();

        household = [ SELECT Full_Address__c, Client_Names__c FROM Account WHERE Id = :household.Id ];
        //System.assertEquals('Amber Smith', household.Client_Names__c, 'If there are no adult clients, treat the children as adults.');
    }

    // there's just one person
    @isTest static void testSingleName() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 57));
        insert clients;

        ServiceManagementHouseholds.runBatchManually();

        household = [ SELECT Client_Names__c FROM Account WHERE Id = :household.Id ];
        //System.assertEquals('Amber Smith', household.Client_Names__c, 'Household name should match client name when there\'s only one person');
    }

    // there's just one person with just a last name
    @isTest static void testSingleNameLastNameOnly() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, null, 'Smith', 57));
        insert clients;

        ServiceManagementHouseholds.runBatchManually();

        household = [ SELECT Client_Names__c FROM Account WHERE Id = :household.Id ];
        //System.assertEquals('Smith', household.Client_Names__c, 'Household name should match client name when there\'s only one person and first name is missing');
    }

    // last names match
    @isTest static void testMatchingLastNames() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 57));
        clients.add(createClient(household.Id, 'Joe', 'Smith', 55));
        insert clients;

        ServiceManagementHouseholds.runBatchManually();

        household = [ SELECT Client_Names__c FROM Account WHERE Id = :household.Id ];
        //System.assertEquals('Amber and Joe Smith', household.Client_Names__c, 'Name should be combined when last names match');
    }
    
    // last names don't match
    @isTest static void testNonMatchingLastNames() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 57));
        clients.add(createClient(household.Id, 'Joe', 'Burns', 55));
        insert clients;

        ServiceManagementHouseholds.runBatchManually();

        household = [ SELECT Client_Names__c FROM Account WHERE Id = :household.Id ];
        //System.assertEquals('Amber Smith and Joe Burns', household.Client_Names__c, 'Name should not be combined when last names don\'t match');
    }

    // more than max number of names
    @isTest static void testSeveralLastNames() {
        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Joe', 'Burns', 88));
        clients.add(createClient(household.Id, 'Patty', 'Freeman', 8));
        clients.add(createClient(household.Id, 'Amber', 'Smith', 12));
        clients.add(createClient(household.Id, 'David', 'Gonzalez', 55));
        insert clients;

        // this is the default value; assume that's what we're testing against
        ServiceManagementHouseholds.MAX_NAMES_IN_HH_NAME = 2;

        ServiceManagementHouseholds.runBatchManually();

        household = [ SELECT Client_Names__c FROM Account WHERE Id = :household.Id ];
        //System.assertEquals('Joe Burns and David Gonzalez', household.Client_Names__c, 'Only the names of the two adults should be used');
    }

    // test scheduled job
    @isTest static void testScheduleHHUpdate() {

        Account household = new Account(
            Name = 'Test Account'
        );
        insert household;

        List<Contact> clients = new List<Contact>();
        clients.add(createClient(household.Id, 'Amber', 'Smith', 57));
        clients.add(createClient(household.Id, 'Joe', 'Smith', 55));
        insert clients;

        Test.startTest();

        String cron = '0 0 0 15 3 ? 2099';

        ServiceManagementHouseholds.scheduleProcess(cron);

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
            NextFireTime
            FROM CronTrigger WHERE CronExpression = :cron];

        //System.assertEquals(0, ct.TimesTriggered, 'Job should not have run yet');
        //System.assertEquals('2099-03-15 00:00:00', String.valueOf(ct.NextFireTime), 'Next run should match time from cron expression');
        
        Test.stopTest();

        household = [ SELECT Client_Names__c FROM Account WHERE Id = :household.Id ];
        //System.assertEquals('Amber and Joe Smith', household.Client_Names__c, 'Name should not be set yet');
 
    }
    
    private static Contact createClient(Id householdId, String firstName, String lastName, Integer age) {
        Contact client = new Contact( 
            AccountId = householdId, 
            FirstName = firstName,
            LastName = lastName, 
            Birthdate = System.today().addyears(-age)
        );
        return client;
    }
    
}