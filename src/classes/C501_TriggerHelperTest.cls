@isTest
public with sharing class C501_TriggerHelperTest {

	@isTest
	private static void testTriggers() {

		Account hh = new Account (
			Name = 'Account.Name',
			C501_Service_Id__c = 'sh1'
		);
		insert hh;

		Contact c = new Contact(
			LastName = 'Contact.LastName',
			C501_Contact_Id__c = 'sc1',
			C501_Service_Id__c = hh.C501_Service_Id__c,
			AccountId = hh.Id
		);
		insert c;

		C501_Service_Household__c sh = new C501_Service_Household__c(
            Name = 'C501_Service_Household__c.Name',
			C501_Household__c = hh.Id,
			C501_Service_Id__c = hh.C501_Service_Id__c
		);
		insert sh;

		// Call update to execute trigger
		sh.C501_BillingStreet__c = 'C501_BillingStreet__c';
		sh.C501_BillingCity__c = 'C501_BillingCity__c';
		sh.C501_BillingState__c = 'C501_BillingState__c';
		sh.C501_BillingPostalCode__c = '54321';
		sh.C501_ShippingStreet__c = 'C501_ShippingStreet__c';
		sh.C501_ShippingCity__c = 'C501_ShippingCity__c';
		sh.C501_ShippingState__c = 'C501_ShippingState__c';
		sh.C501_ShippingPostalCode__c = '12345';
		sh.C501_SNAP__c = TRUE;
		sh.C501_Other_Income__c = TRUE;
		sh.C501_Earned_Income__c = TRUE;
		sh.C501_Self_Employed__c = TRUE;
		sh.C501_Unemployment_Insurance__c = TRUE;
		sh.C501_Child_Support__c = TRUE;
		sh.C501_Pension__c = TRUE;
		sh.C501_Retirement_Income_Social_Security__c = TRUE;
		sh.C501_Supplemental_Security_Income__c = TRUE;
		sh.C501_TANF__c = TRUE;
		sh.C501_Household_Income_Sources__c = 'Unknown/Not Reported';
		sh.C501_Annual_Income__c = 1000;
		sh.C501_Housing__c = 'Unknown/Not Reported';
		sh.C501_Household_Size__c = 2;
		sh.C501_Household_Type__c = 'Unknown/Not Reported';
		sh.C501_Phone__c = 'Phone';
		sh.C501_Other_Phone__c = 'OtherPhone';
		sh.C501_Years_At_Current_Address__c = 5;
		sh.C501_Current_Address_Move_In_Year__c = date.today();

		update sh;

		// Check trigger replication from C501_Service_Household__c to Account
		Account hh_update = [select ShippingStreet from Account where id =: hh.id];
		System.assertEquals(hh_update.ShippingStreet, sh.C501_ShippingStreet__c);

		C501_Service_Contact__c sc = new C501_Service_Contact__c(
			Name = 'C501_Service_Contact__c.Name',
			C501_Contact_Id__c = c.C501_Contact_Id__c,
			C501_Service_Id__c = hh.C501_Service_Id__c,
			C501_Service_Household_Id__c = sh.Id,
			C501_Contact__c = c.Id,
			C501_Last_Name__c = 'C501_Service_Contact__c.C501_Last_Name__c'
		);
		insert sc;

		// Call update to execute trigger
		sc.C501_Last_Name__c = 'C501_Service_Contact__c.C501_Last_Name__c';
		sc.C501_Nickname__c = 'C501_Service_Contact__c.C501_Nickname__c';
		sc.C501_First_Name__c = 'C501_Service_Contact__c.C501_First_Name__c';
		sc.C501_FirstName_Initial__c = 'C';
		sc.C501_Last_Name_Other__c = 'C501_Service_Contact__c.C501_Last_Name_Other__c';
		sc.C501_Last_Name__c = 'C501_Service_Contact__c.C501_Last_Name__c';
		sc.C501_Middle_Name__c = 'C501_Middle_Name__c';
		sc.C501_Birthdate__c = date.today();
		sc.C501_Partial_Social_Security_Id__c = 'xxx-xx-xxxx';
		sc.C501_Primary_Contact__c = true;
		sc.C501_Age__c = 10;
		sc.C501_Military_Status__c = 'Unknown/Not Reported';
		sc.C501_Disabling_Condition_Special_Needs__c = 'Unknown/Not Reported';
		sc.C501_Education_Level__c = 'Unknown/Not Reported';
		sc.C501_Health_Insurance__c = 'Unknown/Not Reported';
		sc.C501_Race__c = 'Unknown/Not Reported';
		sc.C501_Ethnicity__c = 'Unknown/Not Reported';
		sc.C501_Gender__c = 'Unknown/Not Reported';

		update sc;

		// Check trigger replication from C501_Service_Contact__c to Contact
		Contact c_update = [select LastName, FirstName from Contact where id =: c.id];
		System.assertEquals(c_update.LastName, sc.C501_Last_Name_Other__c);
		System.assertEquals(c_update.FirstName, sc.C501_Nickname__c);
	}
}