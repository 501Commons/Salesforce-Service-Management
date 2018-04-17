trigger ContactTrigger on Contact (before insert, before update, after insert, after update, after delete) {

	if (Trigger.isBefore) {
		ServiceManagementTrigger.get().updateContactAge( Trigger.New, Trigger.oldMap );
	} else {
		if (Trigger.isDelete)
			ServiceManagementTrigger.get().fixHouseholdForContactChange( Trigger.Old, Trigger.oldMap, true );
		else
			ServiceManagementTrigger.get().fixHouseholdForContactChange( Trigger.New, Trigger.oldMap, false );
	}

}