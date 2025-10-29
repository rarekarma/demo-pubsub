@isTest
private class OrderEventIntegrationTest {
  @isTest
  static void testRealEventPublishing() {
    // DON'T inject mock - use real publisher for integration testing
    // This ensures actual platform events are published to EventBus

    Account a = new Account(Name = 'IntegrationTestAcct');
    insert a;

    Product2 p = new Product2(Name = 'IntegrationProduct', IsActive = true);
    insert p;

    Id standardPbId = Test.getStandardPricebookId();
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = p.Id,
      Pricebook2Id = standardPbId,
      UnitPrice = 10,
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
      UnitPrice = 10
    );
    insert oi;

    Test.startTest();
    o.Status = 'Activated';
    update o;
    Test.stopTest();

    // Verify that the EventLog was created by the subscriber trigger
    // This proves the platform event was published and received
    List<EventLog__c> logs = [
      SELECT Id, OrderId__c, Name, EventPayload__c
      FROM EventLog__c
      WHERE OrderId__c = :o.Id
    ];

    System.assertEquals(
      1,
      logs.size(),
      'Integration test should create one EventLog record via real platform event publishing'
    );

    System.assertEquals(
      o.Id,
      logs[0].OrderId__c,
      'EventLog should reference the correct Order'
    );

    // Verify the event payload contains the expected data
    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
      logs[0].EventPayload__c
    );
    System.assertEquals(
      o.Id,
      payload.get('OrderId__c'),
      'Event payload should contain the Order ID'
    );
  }

  @isTest
  static void testMultipleOrdersCreateMultipleEvents() {
    // Test that multiple order activations create multiple events

    List<Account> accounts = new List<Account>();
    List<Product2> products = new List<Product2>();

    for (Integer i = 0; i < 3; i++) {
      accounts.add(new Account(Name = 'IntegrationTestAcct' + i));
      products.add(
        new Product2(Name = 'IntegrationProduct' + i, IsActive = true)
      );
    }
    insert accounts;
    insert products;

    Id standardPbId = Test.getStandardPricebookId();
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    List<Order> orders = new List<Order>();

    for (Integer i = 0; i < 3; i++) {
      pbes.add(
        new PricebookEntry(
          Product2Id = products[i].Id,
          Pricebook2Id = standardPbId,
          UnitPrice = 10 + i,
          IsActive = true
        )
      );

      orders.add(
        new Order(
          AccountId = accounts[i].Id,
          Status = 'Draft',
          EffectiveDate = Date.today(),
          Pricebook2Id = standardPbId
        )
      );
    }
    insert pbes;
    insert orders;

    List<OrderItem> orderItems = new List<OrderItem>();
    for (Integer i = 0; i < 3; i++) {
      orderItems.add(
        new OrderItem(
          OrderId = orders[i].Id,
          PricebookEntryId = pbes[i].Id,
          Quantity = 1,
          UnitPrice = 10 + i
        )
      );
    }
    insert orderItems;

    Test.startTest();
    for (Order o : orders) {
      o.Status = 'Activated';
    }
    update orders;
    Test.stopTest();

    // Extract Order IDs for the SOQL query
    List<Id> orderIds = new List<Id>();
    for (Order o : orders) {
      orderIds.add(o.Id);
    }

    // Verify that 3 EventLog records were created
    List<EventLog__c> logs = [
      SELECT Id, OrderId__c, Name
      FROM EventLog__c
      WHERE OrderId__c IN :orderIds
      ORDER BY Name
    ];

    System.assertEquals(
      3,
      logs.size(),
      'Integration test should create 3 EventLog records for 3 activated orders'
    );
  }
}
