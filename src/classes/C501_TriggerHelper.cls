public with sharing class C501_TriggerHelper {

	// only need one instance of this class per transaction
	private static C501_TriggerHelper instance;
	public static C501_TriggerHelper get() {
		if (instance == null) instance = new C501_TriggerHelper();
		return instance;
	}

	public void onChangeContact( list<Contact> cList, map<id, Contact> oldMap, Boolean isDelete ) {
		
		if ( cList == null || cList.isEmpty()) {
			return;
		}

		// TBD - for now ignore deletes
		if (isDelete) {
			return;
		}

		List<Contact> contacts = new List<Contact>();
		Set<Id> accountIds = new Set<Id>();
		for (Contact contact :cList) {
			if (contact.C501_Trigger_Ignore_Change__c) {
				contact.C501_Trigger_Ignore_Change__c = false;
			}
			else {
			   contacts.add(contact);
			   accountIds.add(contact.AccountId);
			}
		}

		Map<Id, Account> accounts = new Map<Id, Account>();
		for ( Account hh : 
			[select Id, Name, 
				BillingStreet, BillingCity, BillingState, BillingPostalCode,
				ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
				Phone, npo02__HouseholdPhone__c
				from Account where id in :accountIds] ) {
					accounts.put(hh.Id, hh);
				}

		// Create Service Households
		List<C501_Service_Household__c> insertServiceHouseholds = new List<C501_Service_Household__c>();
		for (Contact contact :contacts) {

			C501_Service_Household__c serviceHousehold = new C501_Service_Household__c (
				Name = 'Change Request by ' + UserInfo.getName(),
				C501_Service_Id__c = 'TEMP:' + contact.AccountId,
				C501_Household__c = contact.AccountId,
				C501_Start_Date__c = date.today(),
				C501_End_Date__c = date.today(),
				C501_Trigger_Ignore_Change__c = true
			);

			if (accounts.containsKey(contact.AccountId)) {
				// Check to make sure monitored contact field changed
				if (copyFieldsContact2ServiceContact(contact, oldMap.get(contact.Id), new C501_Service_Contact__c())) {
					insertServiceHouseholds.add(serviceHousehold);
				}
			}
		}

		if (!insertServiceHouseholds.isEmpty()) {
			insert insertServiceHouseholds;
		}

		List<C501_Service_Household__c> updateServiceHouseholds = new List<C501_Service_Household__c>();
		Map<Id, C501_Service_Household__c> serviceHouseholds = new Map<Id, C501_Service_Household__c>();
		for (C501_Service_Household__c serviceHousehold :insertServiceHouseholds) {

			serviceHousehold.C501_Service_Id__c = serviceHousehold.Id;
			serviceHousehold.C501_Trigger_Ignore_Change__c = true;
			serviceHouseholds.put(serviceHousehold.C501_Household__c, serviceHousehold);
			updateServiceHouseholds.add(serviceHousehold);
		}

		if (!updateServiceHouseholds.isEmpty()) {
			update updateServiceHouseholds;
		}

		// Create Service Contacts
		List<C501_Service_Contact__c> insertServiceContacts = new List<C501_Service_Contact__c>();
		for (contact contact :contacts) {

			if (serviceHouseholds.containsKey(contact.AccountId)) {

				C501_Service_Household__c serviceHousehold = serviceHouseholds.get(contact.AccountId);

				C501_Service_Contact__c serviceContact = new C501_Service_Contact__c (
					Name = 'Change Request by ' + UserInfo.getName(),
					C501_Service_Id__c = serviceHousehold.C501_Service_Id__c,
					C501_Contact__c = contact.Id,
					C501_Contact_Id__c = 'TEMP: ' + contact.Id,
					C501_Service_Household_Id__c = serviceHousehold.Id,
					C501_Trigger_Ignore_Change__c = true
				);

				if (copyFieldsContact2ServiceContact(contact, oldMap.get(contact.Id), serviceContact)) {
					insertServiceContacts.add(serviceContact);
				}
			}
		}

		if (!insertServiceContacts.isEmpty()) {
			insert insertServiceContacts;
		}

		List<C501_Service_Contact__c> updateServiceContacts = new List<C501_Service_Contact__c>();
		for (C501_Service_Contact__c serviceContact :insertServiceContacts) {

			serviceContact.C501_Contact_Id__c = serviceContact.Id;
			serviceContact.C501_Trigger_Ignore_Change__c = true;
			updateServiceContacts.add(serviceContact);
		}

		if (!updateServiceContacts.isEmpty()) {
			update updateServiceContacts;
		}
	}

	public void onChangeAccount( list<Account> aList, map<id, Account> oldMap, Boolean isDelete ) {

		if ( aList == null || aList.isEmpty()) {
			return;
		}

		// TBD - for now ignore deletes
		if (isDelete) {
			return;
		}

		// Output Info

		for (Account account :aList) {
			system.debug('***** C501_TriggerHelper::onChangeAccount aList: ' + String.valueOf(account));
		}
		for (Account account :oldMap.values()) {
			system.debug('***** C501_TriggerHelper::onChangeAccount oldMap: ' + String.valueOf(account));
		}


		List<Account> accounts = new List<Account>();
		for (Account account :aList) {
			if (account.C501_Trigger_Ignore_Change__c) {
				account.C501_Trigger_Ignore_Change__c = false;
			}
			else {
			   accounts.add(account);
			}
		}

		// Create Service Households
		List<C501_Service_Household__c> insertServiceHouseholds = new List<C501_Service_Household__c>();
		for (Account account :accounts) {

			C501_Service_Household__c serviceHousehold = new C501_Service_Household__c (
				Name = 'Change Request by ' + UserInfo.getName(),
				C501_Service_Id__c = 'TEMP:' + account.Id,
				C501_Household__c = account.Id,
				C501_Start_Date__c = date.today(),
				C501_End_Date__c = date.today(),
				C501_Trigger_Ignore_Change__c = true
			);

			if (copyFieldsAccount2ServiceAccount(account, oldMap.get(account.Id), serviceHousehold)) {
				insertServiceHouseholds.add(serviceHousehold);
			}
		}

		if (!insertServiceHouseholds.isEmpty()) {
			insert insertServiceHouseholds;
		}

		List<C501_Service_Household__c> updateServiceHouseholds = new List<C501_Service_Household__c>();
		for (C501_Service_Household__c serviceHousehold :insertServiceHouseholds) {

			serviceHousehold.C501_Service_Id__c = serviceHousehold.Id;
			serviceHousehold.C501_Trigger_Ignore_Change__c = true;
			updateServiceHouseholds.add(serviceHousehold);
		}

		if (!updateServiceHouseholds.isEmpty()) {
			update updateServiceHouseholds;
		}
	}

	public void updateAggregateContact( list<C501_Service_Contact__c> scList, map<id, C501_Service_Contact__c> oldMap, Boolean isDelete ) {

		if ( scList == null || scList.isEmpty()) {
			return;
		}

		map<String, C501_Service_Contact__c> triggerSCMap = new map<String, C501_Service_Contact__c>();
		
		for ( C501_Service_Contact__c sc :scList ) {

			if (sc.C501_Trigger_Ignore_Change__c) {
				sc.C501_Trigger_Ignore_Change__c = false;
			}
			else {
				// Save most recent Service Contact as the master for updating contact
				if (!triggerSCMap.containsKey(sc.C501_Contact__c)) {
					triggerSCMap.put(sc.C501_Contact__c, sc);
				} else {
					if (sc.CreatedDate > triggerSCMap.get(sc.C501_Contact__c).CreatedDate) {
						triggerSCMap.remove(sc.C501_Contact__c);
						triggerSCMap.put(sc.C501_Contact__c, sc);
					}
				}
			}
		}

		list<Contact> cToUpdate = new list<Contact>();
		map<Id, C501_Service_Contact__c> scToUpdate = new map<Id, C501_Service_Contact__c>();
		Map<Id, List<String>> cOtherNames = new Map<Id, List<String>>();
		map<Id, Account> aToUpdate = new map<Id, Account>();

		// Get all related Other Names
		for ( C501_Other_Name__c cOtherName : 
				[select 
					C501_Contact__c, C501_Other_Name__c
				from C501_Other_Name__c
				where C501_Contact__c in : triggerSCMap.keyset()] ) {

			List<String> listOtherNames = new List<String>();
			if (cOtherNames.containsKey(cOtherName.C501_Contact__c)) {
				listOtherNames = cOtherNames.remove(cOtherName.C501_Contact__c);
			}

			listOtherNames.add(cOtherName.C501_Other_Name__c);
			cOtherNames.put(cOtherName.C501_Contact__c, listOtherNames);
		}

		List<C501_Other_Name__c> cOtherNamesInsert = new List<C501_Other_Name__c>();
		for ( Contact c : 
				[select 
					Account.Id, Account.npe01__One2OneContact__c,
					AccountId, Id, Name,
					FirstName, LastName, MiddleName, C501_FirstName_Initial__c,
					Birthdate, C501_IS_Birthdate_Searchable__c, C501_IS_Other_Names_Searchable__c,
					C501_Partial_Social_Security_Id__c, C501_Order__c,
					C501_Age__c, C501_Military_Status__c, C501_Disabling_Condition_Special_Needs__c,
					C501_Developmental_Disability__c, C501_Medicaid__c, C501_Medicare__c,
					C501_Education_Level__c, C501_Health_Insurance__c, C501_Race__c, C501_Ethnicity__c, Gender__c,
					C501_Preferred_Language__c, C501_Additional_Languages__c,
					C501_Work_Status__c, C501_Case_Worker__c, C501_Is_In_Household__c
				from Contact
				where Id in : triggerSCMap.keyset()] ) {

			C501_Service_Contact__c sc = triggerSCMap.get( c.Id );

			if (isDelete) {
				// ToDo - Add Delete Support - maybe just a no action since probably delete is just triggered by automation
				//		purging the system so data already rollup and just wait for next import.
			}

			// Copy Fields and add to update if successful 
			if (copyFieldsContact( c, sc,
				cOtherNames.containsKey(c.Id) ? cOtherNames.get(c.Id) : new List<String>(),
				cOtherNamesInsert)) {

				// Set flag so contact trigger does not process the change
				c.C501_Trigger_Ignore_Change__c = true;

				cToUpdate.add( c );
				scToUpdate.put(c.Id, sc);
			}

			// Check to update Account Primary Contact
			if (sc.C501_Primary_Contact__c && c.Account.npe01__One2OneContact__c != c.Id) {
				c.Account.npe01__One2OneContact__c = c.Id;
				if (!aToUpdate.containsKey(c.Account.Id)) {
					aToUpdate.put( c.Account.Id, c.Account );
				}
				else {
					// ToDo - Merge Logic for Contact
					//handleMergeContact();
				}
			}
		}

		if (!cToUpdate.isEmpty())
			update cToUpdate;

		if (!aToUpdate.values().isEmpty())
			update aToUpdate.values();

		if (!cOtherNamesInsert.isEmpty()) {
			insert cOtherNamesInsert;
		}

		for (C501_Service_Contact__c sc :scList) {
			if (scToUpdate.containsKey(sc.C501_Contact__c)) {
				C501_Service_Contact__c scUpdate = scToUpdate.get(sc.C501_Contact__c);
				sc.C501_FirstName_Initial__c = scUpdate.C501_FirstName_Initial__c;
			}
		}
	}

	public void updateAggregateHousehold( list<C501_Service_Household__c> shList, map<id, C501_Service_Household__c> oldMap, Boolean isDelete ) {

		if ( shList == null || shList.isEmpty()) {
			return;
		}

		map<id, C501_Service_Household__c> triggerSHMap = new map<id, C501_Service_Household__c>();
		
		for ( C501_Service_Household__c sh :shList ) {
			if (sh.C501_Trigger_Ignore_Change__c) {
				sh.C501_Trigger_Ignore_Change__c = false;
			}
			else {
				// Save most recent Service Contact as the master for updating contact
				if (!triggerSHMap.containsKey(sh.C501_Household__c)) {
					triggerSHMap.put(sh.C501_Household__c, sh);
				} else {
					if (sh.CreatedDate > triggerSHMap.get(sh.C501_Household__c).CreatedDate) {
						triggerSHMap.remove(sh.C501_Household__c);
						triggerSHMap.put(sh.C501_Household__c, sh);
					}

					// ToDo - Handle Merge Logic Household
					// handleMergeAccount();
				}
			}
		}

		list<Account> hhToUpdate = new list<Account>();

		for ( Account hh : 
				[select Id, Name, 
					BillingStreet, BillingCity, BillingState, BillingPostalCode,
					ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
					C501_SNAP__c, C501_Other_Income__c, C501_Earned_Income__c, C501_Self_Employed__c, C501_Unemployment_Insurance__c, C501_Child_Support__c,
					C501_Pension__c, C501_Retirement_Income_Social_Security__c, C501_Supplemental_Security_Income__c, C501_Social_Security_Disability_Income__c,
					C501_TANF__c, C501_WIC__c, C501_Household_Income_Sources__c, C501_Annual_Income__c, C501_Housing__c,
					C501_VA_Service_Connected_Disability__c, C501_Worker_s_Compensation__c,
					C501_Household_Size__c, C501_Household_Type__c, Phone, npo02__HouseholdPhone__c,
					C501_Years_At_Current_Address__c, C501_Current_Address_Move_In_Year__c, C501_Case_Worker__c
					from Account where id in : triggerSHMap.keyset()] ) {

			C501_Service_Household__c sh = triggerSHMap.get( hh.Id );

			if (isDelete) {
				// ToDo - Add Delete Support - maybe just a no action since probably delete is just triggered by automation
				//		purging the system so data already rollup and just wait for next import.
			}

			// Copy Fields and add to update if successful 
			if (copyFieldsAccount( hh, sh ))
				hhToUpdate.add( hh );
		}

		if (!hhToUpdate.isEmpty())
			update hhToUpdate;
	}

	private Boolean copyFieldsAccount( Account hh, C501_Service_Household__c sh) {

		Boolean updateRecord = false;

		// NPSP feature set Name = REPLACE will trigger NPSP Household rename logic
		hh.Name = 'REPLACE';

		if (hh.BillingStreet != sh.C501_BillingStreet__c && !String.isBlank(sh.C501_BillingStreet__c)) {
			updateRecord = true;
			hh.BillingStreet = sh.C501_BillingStreet__c;
		}
		if (hh.BillingCity != sh.C501_BillingCity__c && !String.isBlank(sh.C501_BillingCity__c)) {
			updateRecord = true;
			hh.BillingCity = sh.C501_BillingCity__c;
		}
		if (hh.BillingState != sh.C501_BillingState__c && !String.isBlank(sh.C501_BillingState__c)) {
			updateRecord = true;
			hh.BillingState = sh.C501_BillingState__c;
		}
		if (hh.BillingPostalCode != sh.C501_BillingPostalCode__c && !String.isBlank(sh.C501_BillingPostalCode__c)) {
			updateRecord = true;
			hh.BillingPostalCode = sh.C501_BillingPostalCode__c;
		}
		if (hh.ShippingStreet != sh.C501_ShippingStreet__c && !String.isBlank(sh.C501_ShippingStreet__c)) {
			updateRecord = true;
			hh.ShippingStreet = sh.C501_ShippingStreet__c;
		}
		if (hh.ShippingCity != sh.C501_ShippingCity__c && !String.isBlank(sh.C501_ShippingCity__c)) {
			updateRecord = true;
			hh.ShippingCity = sh.C501_ShippingCity__c;
		}
		if (hh.ShippingState != sh.C501_ShippingState__c && !String.isBlank(sh.C501_ShippingState__c)) {
			updateRecord = true;
			hh.ShippingState = sh.C501_ShippingState__c;
		}
		if (hh.ShippingPostalCode != sh.C501_ShippingPostalCode__c && !String.isBlank(sh.C501_ShippingPostalCode__c)) {
			updateRecord = true;
			hh.ShippingPostalCode = sh.C501_ShippingPostalCode__c;
		}
		if (hh.Phone != sh.C501_Phone__c && !String.isBlank(sh.C501_Phone__c)) {
			updateRecord = true;
			hh.Phone = sh.C501_Phone__c;
		}
		if (hh.npo02__HouseholdPhone__c != sh.C501_Other_Phone__c && !String.isBlank(sh.C501_Other_Phone__c)) {
			updateRecord = true;
			hh.npo02__HouseholdPhone__c = sh.C501_Other_Phone__c;
		}

		// Service speicific fields not handled in I&R
		if (sh.C501_Program__c != 'Information & Referral') {

			if (hh.C501_SNAP__c != sh.C501_SNAP__c) {
				updateRecord = true;
				hh.C501_SNAP__c = sh.C501_SNAP__c;
			}
			if (hh.C501_Other_Income__c != sh.C501_Other_Income__c) {
				updateRecord = true;
				hh.C501_Other_Income__c = sh.C501_Other_Income__c;
			}
			if (hh.C501_Earned_Income__c != sh.C501_Earned_Income__c) {
				updateRecord = true;
				hh.C501_Earned_Income__c = sh.C501_Earned_Income__c;
			}
			if (hh.C501_Self_Employed__c != sh.C501_Self_Employed__c) {
				updateRecord = true;
				hh.C501_Self_Employed__c = sh.C501_Self_Employed__c;
			}
			if (hh.C501_Unemployment_Insurance__c != sh.C501_Unemployment_Insurance__c) {
				updateRecord = true;
				hh.C501_Unemployment_Insurance__c = sh.C501_Unemployment_Insurance__c;
			}
			if (hh.C501_Child_Support__c != sh.C501_Child_Support__c) {
				updateRecord = true;
				hh.C501_Child_Support__c = sh.C501_Child_Support__c;
			}
			if (hh.C501_Pension__c != sh.C501_Pension__c) {
				updateRecord = true;
				hh.C501_Pension__c = sh.C501_Pension__c;
			}
			if (hh.C501_Retirement_Income_Social_Security__c != sh.C501_Retirement_Income_Social_Security__c) {
				updateRecord = true;
				hh.C501_Retirement_Income_Social_Security__c = sh.C501_Retirement_Income_Social_Security__c;
			}
			if (hh.C501_Social_Security_Disability_Income__c != sh.C501_Social_Security_Disability_Income__c) {
				updateRecord = true;
				hh.C501_Social_Security_Disability_Income__c = sh.C501_Social_Security_Disability_Income__c;
			}
			if (hh.C501_Supplemental_Security_Income__c != sh.C501_Supplemental_Security_Income__c) {
				updateRecord = true;
				hh.C501_Supplemental_Security_Income__c = sh.C501_Supplemental_Security_Income__c;
			}
			if (hh.C501_TANF__c != sh.C501_TANF__c) {
				updateRecord = true;
				hh.C501_TANF__c = sh.C501_TANF__c;
			}
			if (hh.C501_WIC__c != sh.C501_WIC__c) {
				updateRecord = true;
				hh.C501_WIC__c = sh.C501_WIC__c;
			}
			if (hh.C501_Worker_s_Compensation__c != sh.C501_Worker_s_Compensation__c) {
				updateRecord = true;
				hh.C501_Worker_s_Compensation__c = sh.C501_Worker_s_Compensation__c;
			}
			if (hh.C501_VA_Service_Connected_Disability__c != sh.C501_VA_Service_Connected_Disability__c) {
				updateRecord = true;
				hh.C501_VA_Service_Connected_Disability__c = sh.C501_VA_Service_Connected_Disability__c;
			}
			if (hh.C501_Household_Income_Sources__c != sh.C501_Household_Income_Sources__c) {
				updateRecord = true;
				hh.C501_Household_Income_Sources__c = sh.C501_Household_Income_Sources__c;
			}
			if (hh.C501_Annual_Income__c != sh.C501_Annual_Income__c) {
				updateRecord = true;
				hh.C501_Annual_Income__c = sh.C501_Annual_Income__c;
			}
			if (hh.C501_Housing__c != sh.C501_Housing__c) {
				updateRecord = true;
				hh.C501_Housing__c = sh.C501_Housing__c;
			}
			if (hh.C501_Household_Size__c != sh.C501_Household_Size__c) {
				updateRecord = true;
				hh.C501_Household_Size__c = sh.C501_Household_Size__c;
			}
			if (hh.C501_Household_Type__c != sh.C501_Household_Type__c) {
				updateRecord = true;
				hh.C501_Household_Type__c = sh.C501_Household_Type__c;
			}
			if (hh.C501_Years_At_Current_Address__c != sh.C501_Years_At_Current_Address__c) {
				updateRecord = true;
				hh.C501_Years_At_Current_Address__c = sh.C501_Years_At_Current_Address__c;
			}
			if (hh.C501_Current_Address_Move_In_Year__c != sh.C501_Current_Address_Move_In_Year__c) {
				updateRecord = true;
				hh.C501_Current_Address_Move_In_Year__c = sh.C501_Current_Address_Move_In_Year__c;
			}
			if (hh.C501_Case_Worker__c != sh.C501_Case_Worker__c) {
				updateRecord = true;
				hh.C501_Case_Worker__c = sh.C501_Case_Worker__c;
			}
		}

		return updateRecord;
	}

	private Boolean copyFieldsContact( Contact c, C501_Service_Contact__c sc, List<String> otherNames, List<C501_Other_Name__c> cOtherNamesInsert) {

		Boolean updateRecord = false;

		if (!String.IsEmpty(sc.C501_Nickname__c)) {

			if (c.FirstName != sc.C501_Nickname__c) {
				updateRecord = true;
				c.FirstName = sc.C501_Nickname__c;
			}

			// Check to create other name records
			if (otherNames.isEmpty() || !otherNames.contains(sc.C501_First_Name__c)) {
				cOtherNamesInsert.add(
					new C501_Other_Name__c (
						C501_Contact__c = c.Id,
						C501_Other_Name__c = sc.C501_First_Name__c,
						C501_IsPreferred__c = false,
						C501_Start_Date__c = date.today()
				));
			}

			if (otherNames.isEmpty() || !otherNames.contains(sc.C501_Nickname__c)) {
				cOtherNamesInsert.add(
					new C501_Other_Name__c (
						C501_Contact__c = c.Id,
						C501_Other_Name__c = sc.C501_Nickname__c,
						C501_IsPreferred__c = true,
						C501_Start_Date__c = date.today()
				));
			}
		}
		else {
			if (c.FirstName != sc.C501_First_Name__c) {
				updateRecord = true;
				c.FirstName = sc.C501_First_Name__c;
			}
		}
		if (!String.isEmpty(sc.C501_First_Name__c) &&
			(String.isEmpty(sc.C501_FirstName_Initial__c) || sc.C501_First_Name__c.left(1) != sc.C501_FirstName_Initial__c)) { 
			updateRecord = true;
			sc.C501_FirstName_Initial__c = sc.C501_First_Name__c.left(1);
		}
		if (!String.isEmpty(c.FirstName) &&
			(String.isEmpty(c.C501_FirstName_Initial__c) ||  c.FirstName.left(1) != c.C501_FirstName_Initial__c)) { 
			updateRecord = true;
			c.C501_FirstName_Initial__c = c.FirstName.left(1);
		}
		if (!String.IsEmpty(sc.C501_Last_Name_Other__c)) {
			if (c.LastName != sc.C501_Last_Name_Other__c) {
				updateRecord = true;
				c.LastName = sc.C501_Last_Name_Other__c;
			}

			// Check to create other name records
			if (otherNames.isEmpty() || !otherNames.contains(sc.C501_Last_Name__c)) {
				cOtherNamesInsert.add(
					new C501_Other_Name__c (
						C501_Contact__c = c.Id,
						C501_Other_Name__c = sc.C501_Last_Name__c,
						C501_IsPreferred__c = false,
						C501_Start_Date__c = date.today()
				));
			}
			if (otherNames.isEmpty() || !otherNames.contains(sc.C501_Last_Name_Other__c)) {
				cOtherNamesInsert.add(
					new C501_Other_Name__c (
						C501_Contact__c = c.Id,
						C501_Other_Name__c = sc.C501_Last_Name_Other__c,
						C501_IsPreferred__c = true,
						C501_Start_Date__c = date.today()
				));
			}
        }
		else {
			if (c.LastName != sc.C501_Last_Name__c) {
				updateRecord = true;
				c.LastName = sc.C501_Last_Name__c;
			}
		}

		String searchableOtherNames = '';
		for (String otherName :otherNames) {
			searchableOtherNames += OtherName + ' ';
		}
		for (C501_Other_Name__c otherName :cOtherNamesInsert) {
			searchableOtherNames += OtherName.C501_Other_Name__c + ' ';
		}
		if (c.C501_IS_Other_Names_Searchable__c != searchableOtherNames) {
			updateRecord = true;
			c.C501_IS_Other_Names_Searchable__c = searchableOtherNames.left(128);
		}

		if (c.MiddleName != sc.C501_Middle_Name__c) {
			updateRecord = true;
			c.MiddleName = sc.C501_Middle_Name__c;
		}
		if (c.Birthdate != sc.C501_Birthdate__c) {
			updateRecord = true;
			c.Birthdate = sc.C501_Birthdate__c;
		}
		if (c.Birthdate != null && c.Birthdate.format() != c.C501_IS_Birthdate_Searchable__c) {
			updateRecord = true;
			c.C501_IS_Birthdate_Searchable__c = c.Birthdate.format();
		}
		if (c.C501_Is_In_Household__c != sc.C501_Is_In_Household__c) {
			updateRecord = true;
			c.C501_Is_In_Household__c = sc.C501_Is_In_Household__c;
		}
		if (c.C501_Partial_Social_Security_Id__c != sc.C501_Partial_Social_Security_Id__c) {
			updateRecord = true;
			c.C501_Partial_Social_Security_Id__c = sc.C501_Partial_Social_Security_Id__c;
		}
		if (c.C501_Order__c != sc.C501_Order__c) {
			updateRecord = true;
			c.C501_Order__c = sc.C501_Order__c;
		}
		if (c.C501_Age__c != sc.C501_Age__c) {
			updateRecord = true;
			c.C501_Age__c = sc.C501_Age__c;
		}
		if (c.C501_Military_Status__c != sc.C501_Military_Status__c) {
			updateRecord = true;
			c.C501_Military_Status__c = sc.C501_Military_Status__c;
		}
		if (c.C501_Disabling_Condition_Special_Needs__c != sc.C501_Disabling_Condition_Special_Needs__c) {
			updateRecord = true;
			c.C501_Disabling_Condition_Special_Needs__c = sc.C501_Disabling_Condition_Special_Needs__c;
		}
		if (c.C501_Education_Level__c != sc.C501_Education_Level__c) {
			updateRecord = true;
			c.C501_Education_Level__c = sc.C501_Education_Level__c;
		}
		if (c.C501_Developmental_Disability__c != sc.C501_Developmental_Disability__c) {
			updateRecord = true;
			c.C501_Developmental_Disability__c = sc.C501_Developmental_Disability__c;
		}
		if (c.C501_Medicare__c != sc.C501_Medicare__c) {
			updateRecord = true;
			c.C501_Medicare__c = sc.C501_Medicare__c;
		}
		if (c.C501_Medicaid__c != sc.C501_Medicaid__c) {
			updateRecord = true;
			c.C501_Medicaid__c = sc.C501_Medicaid__c;
		}
		if (c.C501_Health_Insurance__c != sc.C501_Health_Insurance__c) {
			updateRecord = true;
			c.C501_Health_Insurance__c = sc.C501_Health_Insurance__c;
		}
		if (c.C501_Race__c != sc.C501_Race__c) {
			updateRecord = true;
			c.C501_Race__c = sc.C501_Race__c;
		}
		if (c.C501_Ethnicity__c != sc.C501_Ethnicity__c) {
			updateRecord = true;
			c.C501_Ethnicity__c = sc.C501_Ethnicity__c;
		}
		if (c.Gender__c != sc.C501_Gender__c) {
			updateRecord = true;
			c.Gender__c = sc.C501_Gender__c;
		}
		if (c.C501_Preferred_Language__c != sc.C501_Preferred_Language__c) {
			updateRecord = true;
			c.C501_Preferred_Language__c = sc.C501_Preferred_Language__c;
		}
		if (c.C501_Additional_Languages__c != sc.C501_Additional_Languages__c) {
			updateRecord = true;
			c.C501_Additional_Languages__c = sc.C501_Additional_Languages__c;
		}
		if (c.C501_Work_Status__c != sc.C501_Work_Status__c) {
			updateRecord = true;
			c.C501_Work_Status__c = sc.C501_Work_Status__c;
		}
		if (c.C501_Case_Worker__c != sc.C501_Case_Worker__c) {
			updateRecord = true;
			c.C501_Case_Worker__c = sc.C501_Case_Worker__c;
		}
		
		return updateRecord;
	}

	private Boolean copyFieldsContact2ServiceContact( Contact c, Contact cOld, C501_Service_Contact__c sc) {

		// Check for Change Request monitored field
		if (c.FirstName != cOld.FirstName
			|| c.C501_FirstName_Initial__c != c.C501_FirstName_Initial__c
			|| c.LastName != c.LastName
			|| c.MiddleName != c.MiddleName
			|| c.Birthdate != c.Birthdate
			|| c.C501_Is_In_Household__c != c.C501_Is_In_Household__c
			|| c.C501_Partial_Social_Security_Id__c != c.C501_Partial_Social_Security_Id__c
			|| c.C501_Order__c != c.C501_Order__c
			|| c.C501_Age__c != c.C501_Age__c
			|| c.C501_Military_Status__c != c.C501_Military_Status__c
			|| c.C501_Disabling_Condition_Special_Needs__c != c.C501_Disabling_Condition_Special_Needs__c
			|| c.C501_Education_Level__c != c.C501_Education_Level__c
			|| c.C501_Developmental_Disability__c != c.C501_Developmental_Disability__c
			|| c.C501_Medicare__c != c.C501_Medicare__c
			|| c.C501_Medicaid__c != c.C501_Medicaid__c
			|| c.C501_Health_Insurance__c != c.C501_Health_Insurance__c
			|| c.C501_Race__c != c.C501_Race__c
			|| c.C501_Ethnicity__c != c.C501_Ethnicity__c
			|| c.Gender__c != c.Gender__c
			|| c.C501_Preferred_Language__c != c.C501_Preferred_Language__c
			|| c.C501_Additional_Languages__c != c.C501_Additional_Languages__c
			|| c.C501_Work_Status__c != c.C501_Work_Status__c
			|| c.C501_Case_Worker__c != c.C501_Case_Worker__c) {

			sc.C501_First_Name__c = c.FirstName;
			sc.C501_FirstName_Initial__c = c.C501_FirstName_Initial__c;
			sc.C501_Last_Name__c = c.LastName;
			sc.C501_Middle_Name__c = c.MiddleName;
			sc.C501_Birthdate__c = c.Birthdate;
			sc.C501_Is_In_Household__c = c.C501_Is_In_Household__c;
			sc.C501_Partial_Social_Security_Id__c = c.C501_Partial_Social_Security_Id__c;
			sc.C501_Order__c = c.C501_Order__c;
			sc.C501_Age__c = c.C501_Age__c;
			sc.C501_Military_Status__c = c.C501_Military_Status__c;
			sc.C501_Disabling_Condition_Special_Needs__c = c.C501_Disabling_Condition_Special_Needs__c;
			sc.C501_Education_Level__c = c.C501_Education_Level__c;
			sc.C501_Developmental_Disability__c = c.C501_Developmental_Disability__c;
			sc.C501_Medicare__c = c.C501_Medicare__c;
			sc.C501_Medicaid__c = c.C501_Medicaid__c;
			sc.C501_Health_Insurance__c = c.C501_Health_Insurance__c;
			sc.C501_Race__c = c.C501_Race__c;
			sc.C501_Ethnicity__c = c.C501_Ethnicity__c;
			sc.C501_Gender__c = c.Gender__c;
			sc.C501_Preferred_Language__c = c.C501_Preferred_Language__c;
			sc.C501_Additional_Languages__c = c.C501_Additional_Languages__c;
			sc.C501_Work_Status__c = c.C501_Work_Status__c;
			sc.C501_Case_Worker__c = c.C501_Case_Worker__c;

			return true;
		}

		return false;
	}

	private Boolean copyFieldsAccount2ServiceAccount( Account hh, Account hhOld, C501_Service_Household__c sh) {

		// Check for Change Request monitored field
		if (hh.BillingStreet != hhOld.BillingStreet
			|| hh.BillingCity != hhOld.BillingCity
			|| hh.BillingState != hhOld.BillingState
			|| hh.BillingPostalCode != hhOld.BillingPostalCode
			|| hh.ShippingStreet != hhOld.ShippingStreet
			|| hh.ShippingCity != hhOld.ShippingCity
			|| hh.ShippingState != hhOld.ShippingState
			|| hh.ShippingPostalCode != hhOld.ShippingPostalCode
			|| hh.Phone != hhOld.Phone
			|| hh.npo02__HouseholdPhone__c != hhOld.npo02__HouseholdPhone__c) {

			sh.C501_BillingStreet__c = hh.BillingStreet;
			sh.C501_BillingCity__c = hh.BillingCity;
			sh.C501_BillingState__c = hh.BillingState;
			sh.C501_BillingPostalCode__c = hh.BillingPostalCode;
			sh.C501_ShippingStreet__c = hh.ShippingStreet;
			sh.C501_ShippingCity__c = hh.ShippingCity;
			sh.C501_ShippingState__c = hh.ShippingState;
			sh.C501_ShippingPostalCode__c = hh.ShippingPostalCode;
			sh.C501_Phone__c = hh.Phone;
			sh.C501_Other_Phone__c = hh.npo02__HouseholdPhone__c;

			return true;
		}

		return false;
	}
}