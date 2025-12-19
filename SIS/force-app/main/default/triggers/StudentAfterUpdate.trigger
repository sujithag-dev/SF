trigger StudentAfterUpdate on Student__c (after update) {
  StudentChangeHandler.processStudentChanges(Trigger.new, Trigger.oldMap);
}