trigger C501ContactTrigger on Contact (before update, before delete) {

    C501_TriggerHelper.get().onChangeContact( Trigger.New, Trigger.oldMap, Trigger.isDelete );
}