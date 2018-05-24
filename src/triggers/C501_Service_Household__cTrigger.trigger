trigger C501ServiceHouseholdTrigger on C501_Service_Household__c (after update, after delete) {

    C501_TriggerHelper.get().updateAggregateHousehold( Trigger.New, Trigger.oldMap, Trigger.isDelete );
}