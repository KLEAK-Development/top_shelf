import 'package:top_shelf/top_shelf.dart';

class Account implements NetworkObjectToJson {
  final int id;
  final String email;
  final String password;
  final DateTime creationDate;
  final List<String> roles;

  Account(this.id, this.email, this.password, this.creationDate, this.roles);

  factory Account.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'id': final int id,
          'email': final String email,
          'password': final String password,
          'creationDate': final String creationDate,
          'roles': final List<String> roles,
        }) {
      return Account(
        id,
        email,
        password,
        DateTime.parse(creationDate),
        roles,
      );
    } else if (json
        case {
          'id': final int id,
          'email': final String email,
          'password': final String password,
          'creationDate': final String creationDate,
          'roles': final String roles,
        }) {
      return Account(
        id,
        email,
        password,
        DateTime.parse(creationDate),
        roles.split(','),
      );
    } else {
      throw FormatException('Unexpected JSON');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'creationDate': creationDate.toIso8601String(),
      'roles': roles,
    };
  }
}
