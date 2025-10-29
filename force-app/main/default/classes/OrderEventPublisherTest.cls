@isTest
private class OrderEventPublisherTest {
  @isTest
  static void testPublisherCalledOnInsert() {
    // Swap in mock
    OrderEventPublisher.impl = new MockOrderEventPublisher();

    Account a = new Account(Name = 'PubTestAcct');
    insert a;

    // create supporting product and order item so activation is permitted
    Product2 p = new Product2(Name = 'PubProduct', IsActive = true);
    insert p;
    Id standardPbId = Test.getStandardPricebookId();
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = p.Id,
      Pricebook2Id = standardPbId,
      UnitPrice = 5,
      IsActive = true
    );
    insert pbe;

    Order o = new Order(
      AccountId = a.Id,
      Status = 'Draft',
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPbId
    );
    insert o;
    OrderItem oi = new OrderItem(
      OrderId = o.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 1,
      UnitPrice = 5
    );
    insert oi;

    Test.startTest();
    o.Status = 'Activated';
    update o;
    Test.stopTest();

    // Verify the mock recorded the published event
    System.assertEquals(
      1,
      MockOrderEventPublisher.lastPublished.size(),
      'One event should have been published'
    );
    System.assertEquals(
      o.Id,
      MockOrderEventPublisher.lastPublished[0].OrderId__c
    );
  }

  @isTest
  static void testSubscriberCreatesEventLog() {
    // Use real publisher; subscriber writes EventLog__c
    Account a = new Account(Name = 'SubTestAcct');
    insert a;

    Product2 p = new Product2(Name = 'SubProduct', IsActive = true);
    insert p;
    Id standardPbId = Test.getStandardPricebookId();
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = p.Id,
      Pricebook2Id = standardPbId,
      UnitPrice = 6,
      IsActive = true
    );
    insert pbe;

    Order o = new Order(
      AccountId = a.Id,
      Status = 'Draft',
      EffectiveDate = Date.today(),
      Pricebook2Id = standardPbId
    );
    insert o;
    OrderItem oi = new OrderItem(
      OrderId = o.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 1,
      UnitPrice = 6
    );
    insert oi;

    Test.startTest();
    o.Status = 'Activated';
    update o;
    Test.stopTest();

    // subscriber should have written an EventLog__c
    List<EventLog__c> logs = [
      SELECT Id, OrderId__c
      FROM EventLog__c
      WHERE OrderId__c = :o.Id
    ];
    System.assertEquals(
      1,
      logs.size(),
      'Subscriber should create one EventLog record'
    );
  }
}
