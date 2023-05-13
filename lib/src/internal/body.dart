/// [Body] containt the raw body as a json in [data]
/// it also provide interface to parse it to a real Dart object
abstract class Body<T> {
  final dynamic data;

  const Body(this.data);

  T parse();
}
