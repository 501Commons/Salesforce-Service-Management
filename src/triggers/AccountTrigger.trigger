trigger AccountTrigger on Account (before update, before insert) {

	if (Trigger.isBefore) {
		ServiceManagementTrigger.get().updateProofDates( Trigger.New, Trigger.oldMap );
	}

}