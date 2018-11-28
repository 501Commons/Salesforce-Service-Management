trigger C501ServiceHouseholdTrigger on C501_Service_Household__c (before update, before delete) {

    C501_TriggerHelper.get().updateAggregateHousehold( Trigger.New, Trigger.oldMap, Trigger.isDelete );
}