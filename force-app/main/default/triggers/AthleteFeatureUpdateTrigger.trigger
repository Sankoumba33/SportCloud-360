trigger AthleteFeatureUpdateTrigger on AthleteFeatureUpdate__e (after insert) {
    AthleteFeatureEventHandler.handleAfterInsert(Trigger.new);
}
