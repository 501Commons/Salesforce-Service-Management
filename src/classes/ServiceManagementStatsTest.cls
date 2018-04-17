@isTest
public with sharing class ServiceManagementStatsTest {

	@isTest
	private static void testServiceManagementStats() {

		// insert a household and a visit for today
        Account hh = new Account(
			Name = 'Test Account',
			Inactive__c = false
			);

		// insert a contact
        Contact contact = new Contact(
			Lastname = 'Test Lastname'
			);

        hh = ServiceManagement.saveHousehold(hh);

		Service_Management_Checkin__c checkin1 = new Service_Management_Checkin__c(
			Name = hh.Id,
            Client_Name__c = 'Household 1',
            Points_Remaining__c = 15,
            Box_Size__c = 'small',
            Check_In_Time__c = Datetime.now()
        );

		insert checkin1;
		
        Map<String, Integer> commU = new Map<String, Integer>();
        Id cVId = ServiceManagement.logVisit(hh.Id, contact.Id, 'small', 1.5, 5, commU, 'These are notes');

		ApexPages.CurrentPage().getParameters().put('tfcode','TODAY');
		ServiceManagementStats fbs = new ServiceManagementStats();
		fbs.loadStats();
		fbs.queryStats('TODAY');
	}

}