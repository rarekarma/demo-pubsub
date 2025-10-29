trigger OrderTrigger on Order(after insert, after update) {
  List<OrderActivated__e> events = new List<OrderActivated__e>();
  if (Trigger.isInsert) {
    for (Order o : Trigger.new) {
      // If created with Activated status and EffectiveDate set
      if (o.Status == 'Activated' && o.EffectiveDate != null) {
        events.add(
          new OrderActivated__e(
            OrderId__c = o.Id,
            Status__c = o.Status,
            EffectiveDate__c = o.EffectiveDate,
            AccountId__c = o.AccountId
          )
        );
      }
    }
  }
  if (Trigger.isUpdate) {
    for (Order o : Trigger.new) {
      Order oldO = Trigger.oldMap.get(o.Id);
      // Consider cases where status or effective date became set
      Boolean statusBecameActivated =
        oldO != null &&
        oldO.Status != o.Status &&
        o.Status == 'Activated';
      Boolean effectiveDateBecameSet =
        oldO != null &&
        oldO.EffectiveDate == null &&
        o.EffectiveDate != null;
      Boolean nowHasBoth = o.Status == 'Activated' && o.EffectiveDate != null;
      if ((statusBecameActivated || effectiveDateBecameSet) && nowHasBoth) {
        events.add(
          new OrderActivated__e(
            OrderId__c = o.Id,
            Status__c = o.Status,
            EffectiveDate__c = o.EffectiveDate,
            AccountId__c = o.AccountId
          )
        );
      }
    }
  }
  if (!events.isEmpty()) {
    OrderEventPublisher.publish(events);
  }
}
