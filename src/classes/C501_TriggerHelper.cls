public with sharing class C501_TriggerHelper {

	// only need one instance of this class per transaction
	private static C501_TriggerHelper instance;
	public static C501_TriggerHelper get() {
		if (instance == null) instance = new C501_TriggerHelper();
		return instance;
	}

	public void updateAggregateContact( list<C501_Service_Contact__c> scList, map<id, C501_Service_Contact__c> oldMap, Boolean isDelete ) {

		map<String, list<C501_Service_Contact__c>> triggerSCMap = new map<String, list<C501_Service_Contact__c>>();
		
		if ( scList != null ) {
			// Avoid SOQL query limits by collecting all the required info in the trigger from a single SOQL call
			for ( C501_Service_Contact__c sc :scList ) {
				if (!triggerSCMap.containsKey(sc.C501_Contact__c)) {
					triggerSCMap.put(sc.C501_Contact__c, new list<C501_Service_Contact__c>{ sc });
				} else {
					triggerSCMap.get(sc.C501_Contact__c).add(sc);
				}
			}
		}

		list<Contact> cToUpdate = new list<Contact>();
		list<Account> aToUpdate = new list<Account>();

		for ( Contact c : 
				[select 
					Account.Id, Account.npe01__One2OneContact__c,
					AccountId, Id, Name, 
					FirstName, LastName, MiddleName,
					Birthdate, C501_Partial_Social_Security_Id__c,
					C501_Age__c, C501_Military_Status__c, C501_Disabling_Condition_Special_Needs__c,
					C501_Education_Level__c, C501_Health_Insurance__c, C501_Race__c, C501_Ethnicity__c, Gender__c
					from Contact where Id in : triggerSCMap.keyset()] ) {

			list<C501_Service_Contact__c> scGroup = triggerSCMap.get( c.Id );

			if (isDelete) {
				// ToDo - Add Delete Support - maybe just a no action since probably delete is just triggered by automation
				//		purging the system so data already rollup and just wait for next import.
			}

			// Copy Fields and add to update if successful 
			if (copyFieldsContact( c, scGroup[0] ))
				cToUpdate.add( c );

			// Check to update Account Primary Contact
			if (scGroup[0].C501_Primary_Contact__c && c.Account.npe01__One2OneContact__c != c.Id) {
				c.Account.npe01__One2OneContact__c = c.Id;
				aToUpdate.add( c.Account );
			}
		}

		if (!cToUpdate.isEmpty())
			update cToUpdate;

		if (!aToUpdate.isEmpty())
			update aToUpdate;
	}

	public void updateAggregateHousehold( list<C501_Service_Household__c> shList, map<id, C501_Service_Household__c> oldMap, Boolean isDelete ) {

		map<id, list<C501_Service_Household__c>> triggerSHMap = new map<id, list<C501_Service_Household__c>>();
		
		if ( shList != null ) {
			// Avoid SOQL query limits by collecting all the required info in the trigger from a single SOQL call
			for ( C501_Service_Household__c sh :shList ) {
				if (!triggerSHMap.containsKey(sh.C501_Household__c)) {
					triggerSHMap.put(sh.C501_Household__c, new list<C501_Service_Household__c>{ sh });
				} else {
					triggerSHMap.get(sh.C501_Household__c).add(sh);
				}
			}
		}

		list<Account> hhToUpdate = new list<Account>();

		for ( Account hh : 
				[select Id, Name, 
					BillingStreet, BillingCity, BillingState, BillingPostalCode,
					ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
					C501_SNAP__c, C501_Other_Income__c, C501_Earned_Income__c, C501_Self_Employed__c, C501_Unemployment_Insurance__c, C501_Child_Support__c,
					C501_Pension__c, C501_Retirement_Income_Social_Security__c, C501_Supplemental_Security_Income__c,
					C501_TANF__c, C501_Household_Income_Sources__c, C501_Annual_Income__c, C501_Housing__c,
					C501_Household_Size__c, C501_Household_Type__c, Phone, npo02__HouseholdPhone__c,
					C501_Years_At_Current_Address__c, C501_Current_Address_Move_In_Year__c,
					C501_Level__c, C501_Previous_Level__c
					from Account where id in : triggerSHMap.keyset()] ) {

			list<C501_Service_Household__c> shGroup = triggerSHMap.get( hh.Id );

			if (isDelete) {
				// ToDo - Add Delete Support - maybe just a no action since probably delete is just triggered by automation
				//		purging the system so data already rollup and just wait for next import.
			}

			// Copy Fields and add to update if successful 
			if (copyFieldsAccount( hh, shGroup[0] ))
				hhToUpdate.add( hh );
		}

		if (!hhToUpdate.isEmpty())
			update hhToUpdate;
	}

	private Boolean copyFieldsAccount( Account hh, C501_Service_Household__c sh ) {

		Boolean updateRecord = false;

		// NPSP feature set Name = REPLACE will trigger NPSP Household rename logic
		hh.Name = 'REPLACE';

		if (hh.BillingStreet != sh.C501_BillingStreet__c) {
			updateRecord = true;
			hh.BillingStreet = sh.C501_BillingStreet__c;
		}
		if (hh.BillingCity != sh.C501_BillingCity__c) {
			updateRecord = true;
			hh.BillingCity = sh.C501_BillingCity__c;
		}
		if (hh.BillingState != sh.C501_BillingState__c) {
			updateRecord = true;
			hh.BillingState = sh.C501_BillingState__c;
		}
		if (hh.BillingPostalCode != sh.C501_BillingPostalCode__c) {
			updateRecord = true;
			hh.BillingPostalCode = sh.C501_BillingPostalCode__c;
		}
		if (hh.ShippingStreet != sh.C501_ShippingStreet__c) {
			updateRecord = true;
			hh.ShippingStreet = sh.C501_ShippingStreet__c;
		}
		if (hh.ShippingCity != sh.C501_ShippingCity__c) {
			updateRecord = true;
			hh.ShippingCity = sh.C501_ShippingCity__c;
		}
		if (hh.ShippingState != sh.C501_ShippingState__c) {
			updateRecord = true;
			hh.ShippingState = sh.C501_ShippingState__c;
		}
		if (hh.ShippingPostalCode != sh.C501_ShippingPostalCode__c) {
			updateRecord = true;
			hh.ShippingPostalCode = sh.C501_ShippingPostalCode__c;
		}
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
		if (hh.C501_Supplemental_Security_Income__c != sh.C501_Supplemental_Security_Income__c) {
			updateRecord = true;
			hh.C501_Supplemental_Security_Income__c = sh.C501_Supplemental_Security_Income__c;
		}
		if (hh.C501_TANF__c != sh.C501_TANF__c) {
			updateRecord = true;
			hh.C501_TANF__c = sh.C501_TANF__c;
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
		if (hh.Phone != sh.C501_Phone__c) {
			updateRecord = true;
			hh.Phone = sh.C501_Phone__c;
		}
		if (hh.npo02__HouseholdPhone__c != sh.C501_Other_Phone__c) {
			updateRecord = true;
			hh.npo02__HouseholdPhone__c = sh.C501_Other_Phone__c;
		}
		if (hh.C501_Years_At_Current_Address__c != sh.C501_Years_At_Current_Address__c) {
			updateRecord = true;
			hh.C501_Years_At_Current_Address__c = sh.C501_Years_At_Current_Address__c;
		}
		if (hh.C501_Current_Address_Move_In_Year__c != sh.C501_Current_Address_Move_In_Year__c) {
			updateRecord = true;
			hh.C501_Current_Address_Move_In_Year__c = sh.C501_Current_Address_Move_In_Year__c;
		}

		// Nightly Batch process fields (i.e., Level, Previous Level)
		if (hh.C501_Level__c != sh.C501_Level__c) {
			updateRecord = true;
			hh.C501_Level__c = sh.C501_Level__c;
		}
		if (hh.C501_Previous_Level__c != sh.C501_Previous_Level__c) {
			updateRecord = true;
			hh.C501_Previous_Level__c = sh.C501_Previous_Level__c;
		}

		return updateRecord;
	}

	private Boolean copyFieldsContact( Contact c, C501_Service_Contact__c sc ) {

		Boolean updateRecord = false;

		if (!String.IsEmpty(sc.C501_Nickname__c)) {
			if (c.FirstName != sc.C501_Nickname__c) {
				updateRecord = true;
				c.FirstName = sc.C501_Nickname__c;
			}
		}
		else {
			if (c.FirstName != sc.C501_First_Name__c) {
				updateRecord = true;
				c.FirstName = sc.C501_First_Name__c;
			}
		}
		if (!String.IsEmpty(sc.C501_Last_Name_Other__c)) {
			if (c.LastName != sc.C501_Last_Name_Other__c) {
				updateRecord = true;
				c.LastName = sc.C501_Last_Name_Other__c;
			}
        }
		else {
			if (c.LastName != sc.C501_Last_Name__c) {
				updateRecord = true;
				c.LastName = sc.C501_Last_Name__c;
			}
		}
		if (c.MiddleName != sc.C501_Middle_Name__c) {
			updateRecord = true;
			c.MiddleName = sc.C501_Middle_Name__c;
		}
		if (c.Birthdate != sc.C501_Birthdate__c) {
			updateRecord = true;
			c.Birthdate = sc.C501_Birthdate__c;
		}
		if (c.C501_Partial_Social_Security_Id__c != sc.C501_Partial_Social_Security_Id__c) {
			updateRecord = true;
			c.C501_Partial_Social_Security_Id__c = sc.C501_Partial_Social_Security_Id__c;
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
		
		return updateRecord;
	}
}