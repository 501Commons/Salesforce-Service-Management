trigger C501ServiceContactTrigger on C501_Service_Contact__c (before update, before delete) {

    C501_TriggerHelper.get().updateAggregateContact( Trigger.New, Trigger.oldMap, Trigger.isDelete );
}