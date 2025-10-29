trigger OrderActivatedEventTrigger on OrderActivated__e(after insert) {
  List<EventLog__c> logs = new List<EventLog__c>();
  for (OrderActivated__e ev : Trigger.new) {
    logs.add(
      new EventLog__c(
        Name = 'OrderActivated-' + (ev.OrderId__c == null ? '' : ev.OrderId__c),
        OrderId__c = ev.OrderId__c,
        EventPayload__c = JSON.serialize(ev)
      )
    );
  }
  if (!logs.isEmpty())
    insert logs;
}
