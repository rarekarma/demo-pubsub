@isTest
private class OrderTriggerTest {
  @isTest
  static void testInsertWithActivatedAndEffectiveDate() {
    Account a = new Account(Name = 'TestAcct');
    insert a;

    // Create a product and pricebook entry so the Order can be activated
    Product2 p = new Product2(Name = 'TestProduct1', IsActive = true);
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
    // add an OrderItem so activation will succeed
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

    Order inserted = [
      SELECT Id, Status, EffectiveDate
      FROM Order
      WHERE Id = :o.Id
    ];
    System.assertEquals(
      'Activated',
      inserted.Status,
      'Order should have Activated status'
    );
    System.assertNotEquals(
      null,
      inserted.EffectiveDate,
      'EffectiveDate should be set'
    );
  }

  @isTest
  static void testUpdateStatusToActivatedWhenEffectiveDatePresent() {
    Account a = new Account(Name = 'TestAcct2');
    insert a;

    // Create product and order item before activating
    Product2 p = new Product2(Name = 'TestProduct2', IsActive = true);
    insert p;
    Id standardPbId = Test.getStandardPricebookId();
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = p.Id,
      Pricebook2Id = standardPbId,
      UnitPrice = 20,
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
      UnitPrice = 20
    );
    insert oi;

    Test.startTest();
    o.Status = 'Activated';
    update o;
    Test.stopTest();

    Order updated = [
      SELECT Id, Status, EffectiveDate
      FROM Order
      WHERE Id = :o.Id
    ];
    System.assertEquals(
      'Activated',
      updated.Status,
      'Order status should be Activated after update'
    );
    System.assertNotEquals(
      null,
      updated.EffectiveDate,
      'EffectiveDate should remain set'
    );
  }

  @isTest
  static void testUpdateEffectiveDateWhenStatusActivated() {
    Account a = new Account(Name = 'TestAcct3');
    insert a;

    // Create product and order item then activate; then update EffectiveDate
    Product2 p = new Product2(Name = 'TestProduct3', IsActive = true);
    insert p;
    Id standardPbId = Test.getStandardPricebookId();
    PricebookEntry pbe = new PricebookEntry(
      Product2Id = p.Id,
      Pricebook2Id = standardPbId,
      UnitPrice = 30,
      IsActive = true
    );
    insert pbe;

    Order o = new Order(
      AccountId = a.Id,
      Status = 'Draft',
      EffectiveDate = Date.today().addDays(-1),
      Pricebook2Id = standardPbId
    );
    insert o;
    OrderItem oi = new OrderItem(
      OrderId = o.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 1,
      UnitPrice = 30
    );
    insert oi;

    // activate and set EffectiveDate in the same DML (setting EffectiveDate after activation is blocked)
    Test.startTest();
    o.Status = 'Activated';
    o.EffectiveDate = Date.today();
    update o;
    Test.stopTest();

    Order updated = [
      SELECT Id, Status, EffectiveDate
      FROM Order
      WHERE Id = :o.Id
    ];
    System.assertEquals(
      'Activated',
      updated.Status,
      'Order status should still be Activated'
    );
    System.assertNotEquals(
      null,
      updated.EffectiveDate,
      'EffectiveDate should now be set'
    );
  }
}
