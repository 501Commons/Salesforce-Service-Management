trigger C501ServiceContactTrigger on C501_Service_Contact__c (after update, after delete) {

    C501_TriggerHelper.get().updateAggregateContact( Trigger.New, Trigger.oldMap, Trigger.isDelete );
}