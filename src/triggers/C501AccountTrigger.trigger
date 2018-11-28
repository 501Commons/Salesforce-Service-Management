trigger C501AccountTrigger on Account (after update, after delete) {

    C501_TriggerHelper.get().onChangeAccount( Trigger.New, Trigger.oldMap, Trigger.isDelete );
}