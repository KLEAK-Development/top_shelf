abstract class Body<T> {
  final dynamic data;

  const Body(this.data);

  T parse();
}
