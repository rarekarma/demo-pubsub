public class RealOrderEventPublisher implements IOrderEventPublisher {
  public void publish(List<OrderActivated__e> events) {
    if (events == null || events.isEmpty())
      return;
    EventBus.publish(events);
  }
}
