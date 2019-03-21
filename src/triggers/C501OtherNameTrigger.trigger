trigger C501OtherNameTrigger on C501_Other_Name__C (after insert, after update, after delete) {

    C501_TriggerHelper.get().onChangeOtherName(Trigger.New);
}