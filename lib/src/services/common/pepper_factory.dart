import 'dart:io';

String defaultPepperFactory() {
  final pepper = Platform.environment['PEPPER'];
  if (pepper == null) {
    throw Exception("PEPPER environment variable is not set");
  }
  return pepper;
}
