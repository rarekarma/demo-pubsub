public class OrderEventPublisher {
  // default implementation
  public static IOrderEventPublisher impl = new RealOrderEventPublisher();

  public static void publish(List<OrderActivated__e> events) {
    impl.publish(events);
  }
}
