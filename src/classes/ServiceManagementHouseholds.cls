public with sharing class ServiceManagementHouseholds implements Database.Batchable<SObject>, Schedulable {

	@TestVisible
	private static integer MAX_NAMES_IN_HH_NAME = 2;

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(
			[select Id, Name, Full_Address__c, Client_Names__c, Adults__c, Seniors__c, Children__c, Infants__c,
				(select Id, FirstName, LastName, Name, Age__c, Age_Entry_Date__c, Birthdate, AccountId, Gender__c, Id_Number__c from Contacts
					 order by createdDate, Age__c desc)
				from Account]);
	}

	public void execute(Database.BatchableContext BC, List<Account> batch) {
		list<Account> updatedHH = new list<Account>();
		for (Account hh : batch) {

			//String hhName = calculateHHName( hh, hh.Contacts );
			if (hh.Client_Names__c != hh.Name) {
				hh.Client_Names__c = hh.Name;

				updatedHH.add(hh);
			}
		}
		update updatedHH;
	}
	
	// Batch finish
	public void finish(Database.BatchableContext BC) {
	   // Nothing to do here.
	}

	public static void runBatchManually() {
		ServiceManagementHouseholds fbh = new ServiceManagementHouseholds();
		Database.executeBatch(fbh); 
	}
	
	public static void scheduleProcess(String schedule) {
		if (schedule == null) schedule = '0 0 1 * * ?';
		ServiceManagementHouseholds scheduler = new ServiceManagementHouseholds();
		System.schedule('ServiceManagementHouseholds', schedule, scheduler);
	}
	
	public void execute(SchedulableContext sc) {
		ServiceManagementHouseholds fbh = new ServiceManagementHouseholds();
		Database.executeBatch(fbh); 
	}

	public static String calculateHHName( Account hh, list<Contact> members ) {
		if ( members == null ) return hh.full_address__c;
		
		list<Contact> adultMembers = new list<Contact>();
		for ( Contact cl : members )
			if ( (cl.Age__c == null || cl.Age__c >= 18) && (MAX_NAMES_IN_HH_NAME == null || adultMembers.size() < MAX_NAMES_IN_HH_NAME) )
				adultMembers.add( cl );

		// if there are no adults, name the household as if the children were adults
		if ( adultMembers.size() == 0 ) {
			adultMembers = members;
		}

		if ( adultMembers.size() == 1 ) {
			return adultMembers[0].Name;
		} else {
			list<String> lastNames = new list<String>();
			map<String, list<String>> lastToFirstNames = new map<String, list<String>>();
			for ( Contact cl : adultMembers ) {
				if (!lastToFirstNames.containsKey(cl.LastName)) {
					lastNames.add(cl.LastName);
					lastToFirstNames.put(cl.LastName, new list<String>());
				}
				if (cl.FirstName != null)
					lastToFirstNames.get(cl.LastName).add(cl.FirstName);
			}

			String hhName = '';
			for ( String lname : lastNames ) {
				String fnames = String.join(lastToFirstNames.get( lname ), ' and ');
				hhName += ((hhName.length() > 0) ? ' and ' : '') + fnames + ' ' + lname;
			}
			return hhName;
		}
	}
}