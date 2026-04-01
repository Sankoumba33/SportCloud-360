trigger ProspectFeatureUpdateTrigger on ProspectFeatureUpdate__e (after insert) {
    ProspectFeatureEventHandler.handleAfterInsert(Trigger.new);
}
