@isTest(SeeAllData=false)
public with sharing class ServiceManagementTest {

    @isTest
    private static void testCheckOutIn() {
        // New Household insert then update
        Account cHh = new Account(
            Name = 'Test Account'
        );
        insert(cHh);

        // New contact nsert then update
        Contact cContact = new Contact(
            Lastname = 'Test Lastname'
        );
        insert(cContact);

        // Test CheckIn & CheckOut
        ServiceManagement.checkIn(cHh.Id, cContact.Id);
        //system.assert(Service_Management_Checkin__c.getInstance(cHh.Id) != null);

        // Attempt to CheckIn again should throw error
        try {
            ServiceManagement.checkIn(cHh.Id, cContact.Id);
            //system.assert(false, 'Error should have occured');
        } catch (Exception ex) {
            // Nothing to see here
            // TODO: check to see if correct error is thrown
        }

        ServiceManagement.cancelCheckIn(cHh.Id);
        //system.assert(Service_Management_Checkin__c.getInstance(cHh.Id) == null);
    }

    @isTest
    private static void testSaveHouseHold() {
        Account cHh = new Account(
            Name = 'Test Account',
            Inactive__c = false
        );
        
        // Check insert of Household
        Account cHh0 = new Account(Name = 'Test Account');
        cHh0 = ServiceManagement.saveHousehold(cHh);
        //system.assert(cHh0.Id != null, 'Id should not be null');

        // Check update of Household
        cHh.Address__c = '101 1st St';
        cHh0 = ServiceManagement.saveHousehold(cHh);
        //system.assert(cHh0.Address__c == cHh.Address__c, 'Method did not update Household: ' + cHh0.Children__c);

        // Insert Client
        Contact c1 = new Contact( AccountId = null, LastName = 'Test1', Birthdate = System.today().addyears(-50) );
        cHh0 = ServiceManagement.saveHouseholdMembers(cHh.Id, new List<Contact> { c1 });
        //system.assert(cHh0.Client_Names__c != null, 'Method did not update Household: ' + cHh0.Client_Names__c);

        // Update Client
        c1.FirstName = 'Test2';
        cHh0 = ServiceManagement.saveHouseholdMembers(cHh.Id, new List<Contact> { c1 });
        //system.assert(cHh0.Client_Names__c != null, 'Method did not update Household: ' + cHh0.Client_Names__c);
        System.debug('***** Client Name: ' + cHh0.Client_Names__c);
        System.debug('***** Inactive: ' + cHh0.Inactive__c);

        List<ServiceManagement.ClientHousehold> cHs = ServiceManagement.queryHouseholds(cHh0.Client_Names__c);
// TODO     // //system.assertEquals(1, cHs.size(), 'Could not find: ' + cHh0.Client_Names__c);   

        // Save new Household and Client
        Account cHh1 = new Account(
            Name = 'Test Account'
        );
        Contact c2 = new Contact( AccountId = null, LastName = 'Test1', Birthdate = System.today().addyears(-50) );
        Account cHh2 = ServiceManagement.saveHouseholdAndMembers(cHh1, new List<Contact> { c2 });       
        //system.assert(cHh2.Id != null, 'Id should not be null');
        
        ServiceManagement.AppSettings appSettings = ServiceManagement.getAppSettings();
        //system.assert(appSettings.general != null);
    }


	@isTest
	private static void testCheckInsVisits() {
		Account household1 = new Account(
            Name = 'Test Account',
			Inactive__c = false
		);
		
		// insert a contact
        Contact contact = new Contact(
			Lastname = 'Test Lastname'
			);
        
		// Check insert of Household
		household1 = ServiceManagement.saveHousehold(household1);

		Service_Management_Checkin__c checkin1 = new Service_Management_Checkin__c(
			Name = household1.Id,
            Client_Name__c = 'Household 1',
            Points_Remaining__c = 15,
            Box_Size__c = 'small',
            Check_In_Time__c = Datetime.now()
        );

		insert checkin1;

		Account household2 = new Account(
            Name = 'Test Account',
			Inactive__c = false
		);
		
		// Check insert of Household
		household2 = ServiceManagement.saveHousehold(household2);

		Service_Management_Checkin__c checkin2 = new Service_Management_Checkin__c(
			Name = household2.Id,
            Client_Name__c = 'Household 2',
            Points_Remaining__c = 15,
            Box_Size__c = 'small',
            Check_In_Time__c = Datetime.now()
        );
		insert checkin2;

		List<ServiceManagement.ClientCheckin> cc = ServiceManagement.getCheckedInList();
		//system.assertEquals(2, cc.size(), 'Two households are currently checked in');

		Map<String, Integer> commU = new Map<String, Integer>();
		commU.put('Meat', 2);
		commU.put('Bread', 1);
		Id cVId = ServiceManagement.logVisit(household1.Id, contact.Id, 'small', 1.1, 5, commU, 'These are notes');
		//system.assert(cVId != null);

		List<Client_Visit__c> cV = ServiceManagement.getVisitHistory(household1.Id);
		//system.assert(cV.size() == 1);	
	}	

    @isTest
    private static void testHHBatch() {
        // New Household insert then update
        Account cHh = new Account(
            Name = 'Test Account'
        );
        insert(cHh);
        ServiceManagementHouseholds.runBatchManually();
     }
}