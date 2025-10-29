@IsTest
public class MockOrderEventPublisher implements IOrderEventPublisher {
  public static List<OrderActivated__e> lastPublished = new List<OrderActivated__e>();

  public void publish(List<OrderActivated__e> events) {
    lastPublished.clear();
    if (events != null)
      lastPublished.addAll(events);
  }
}
