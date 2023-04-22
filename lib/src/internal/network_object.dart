abstract class NetworkObject {}

abstract class JsonNetworkObject extends NetworkObject {
  String toJsonString();
}

abstract class XmlNetworkObject extends NetworkObject {
  String toXmlString();
}
