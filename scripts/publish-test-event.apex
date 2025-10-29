// IMPORTANT: This script is executed from Execute Anonymous (not in a test context)
// to publish platform events to the REAL event bus that external subscribers can receive.
//
// WHY NOT Test.startTest()/Test.stopTest()?
// According to Salesforce Platform Events documentation, platform events published inside
// test methods are delivered to a separate TEST event bus that only in-org subscribers
// (triggers, flows, processes) can receive. External subscribers (like the Pub/Sub API
// middleware) DO NOT receive events from the test event bus.
//
// By executing this script outside of test context via Execute Anonymous, we publish
// events to the real production event bus that external subscribers can receive.
//
// This script uses the real Order activation flow (OrderTrigger -> OrderEventPublisher)
// to ensure events are published through the normal business logic, not artificially.

// Create Account
Account a = new Account(Name = 'IntegrationTestAcct');
insert a;

// Create Product
Product2 p = new Product2(Name = 'IntegrationProduct', IsActive = true);
insert p;

// Get Standard Pricebook (Test.getStandardPricebookId() only works in test context)
Pricebook2 standardPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];

// Create PricebookEntry
PricebookEntry pbe = new PricebookEntry(
  Product2Id = p.Id,
  Pricebook2Id = standardPb.Id,
  UnitPrice = 10,
  IsActive = true
);
insert pbe;

// Create Orders (Draft status)
Order o1 = new Order(AccountId = a.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = standardPb.Id);
Order o2 = new Order(AccountId = a.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = standardPb.Id);
Order o3 = new Order(AccountId = a.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = standardPb.Id);
insert o1;
insert o2;
insert o3;

// Add OrderItems (required for activation)
OrderItem oi1 = new OrderItem(OrderId = o1.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 10);
OrderItem oi2 = new OrderItem(OrderId = o2.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 10);
OrderItem oi3 = new OrderItem(OrderId = o3.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 10);
insert oi1;
insert oi2;
insert oi3;

// Activate Orders - this triggers OrderTrigger which publishes OrderActivated__e events
// The events are published to the REAL event bus via OrderEventPublisher.publish() -> RealOrderEventPublisher
o1.Status = 'Activated';
o2.Status = 'Activated';
o3.Status = 'Activated';
update o1;
update o2;
update o3;

System.debug('Published 3 events through OrderTrigger flow to real event bus');
