public interface IOrderEventPublisher {
  void publish(List<OrderActivated__e> events);
}
