abstract class NetworkObject {}

abstract class NetworkObjectToJson extends NetworkObject {
  String toJsonString();
}

abstract class NetworkObjectToXml extends NetworkObject {
  String toXmlString();
}
