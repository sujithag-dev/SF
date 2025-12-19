trigger AccountUpdate on Account (after update) {
    StudentChangeHandler.processAccountChanges(Trigger.new, Trigger.oldMap);
}