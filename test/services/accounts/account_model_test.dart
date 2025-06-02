import 'package:test/test.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/top_shelf.dart';

void main() {
  group('Account Model', () {
    group('Constructor', () {
      test('should create account with all required fields', () {
        // Arrange
        const id = 1;
        const email = 'test@example.com';
        const password = 'hashedpassword';
        final creationDate = DateTime(2023, 12, 25, 10, 30);
        final roles = ['user', 'admin'];

        // Act
        final account = Account(id, email, password, creationDate, roles);

        // Assert
        expect(account.id, equals(id));
        expect(account.email, equals(email));
        expect(account.password, equals(password));
        expect(account.creationDate, equals(creationDate));
        expect(account.roles, equals(roles));
      });

      test('should create account with single role', () {
        // Arrange
        const id = 2;
        const email = 'user@example.com';
        const password = 'hashedpassword';
        final creationDate = DateTime.now();
        final roles = ['user'];

        // Act
        final account = Account(id, email, password, creationDate, roles);

        // Assert
        expect(account.roles, equals(['user']));
        expect(account.roles.length, equals(1));
      });

      test('should create account with empty roles list', () {
        // Arrange
        const id = 3;
        const email = 'empty@example.com';
        const password = 'hashedpassword';
        final creationDate = DateTime.now();
        final roles = <String>[];

        // Act
        final account = Account(id, email, password, creationDate, roles);

        // Assert
        expect(account.roles, isEmpty);
      });
    });

    group('fromJson', () {
      test('should parse JSON with roles as List<String>', () {
        // Arrange
        final json = {
          'id': 1,
          'email': 'test@example.com',
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T10:30:00.000Z',
          'roles': ['user', 'admin'],
        };

        // Act
        final account = Account.fromJson(json);

        // Assert
        expect(account.id, equals(1));
        expect(account.email, equals('test@example.com'));
        expect(account.password, equals('hashedpassword'));
        expect(account.creationDate,
            equals(DateTime.parse('2023-12-25T10:30:00.000Z')));
        expect(account.roles, equals(['user', 'admin']));
      });

      test('should parse JSON with roles as comma-separated string', () {
        // Arrange
        final json = {
          'id': 2,
          'email': 'user@example.com',
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T15:45:30.123Z',
          'roles': 'user,admin,moderator',
        };

        // Act
        final account = Account.fromJson(json);

        // Assert
        expect(account.id, equals(2));
        expect(account.email, equals('user@example.com'));
        expect(account.password, equals('hashedpassword'));
        expect(account.creationDate,
            equals(DateTime.parse('2023-12-25T15:45:30.123Z')));
        expect(account.roles, equals(['user', 'admin', 'moderator']));
      });

      test('should parse JSON with single role as string', () {
        // Arrange
        final json = {
          'id': 3,
          'email': 'single@example.com',
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T08:00:00.000Z',
          'roles': 'user',
        };

        // Act
        final account = Account.fromJson(json);

        // Assert
        expect(account.roles, equals(['user']));
      });

      test('should parse JSON with empty roles string', () {
        // Arrange
        final json = {
          'id': 4,
          'email': 'empty@example.com',
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T12:00:00.000Z',
          'roles': '',
        };

        // Act
        final account = Account.fromJson(json);

        // Assert
        expect(account.roles, equals(['']));
      });

      test('should parse JSON with roles containing spaces', () {
        // Arrange
        final json = {
          'id': 5,
          'email': 'spaces@example.com',
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T16:30:00.000Z',
          'roles': 'user, admin, moderator',
        };

        // Act
        final account = Account.fromJson(json);

        // Assert
        expect(account.roles, equals(['user', ' admin', ' moderator']));
      });

      test('should throw FormatException for missing required fields', () {
        // Arrange
        final json = {
          'id': 1,
          'email': 'test@example.com',
          // Missing password, creationDate, and roles
        };

        // Act & Assert
        expect(
          () => Account.fromJson(json),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Unexpected JSON',
          )),
        );
      });

      test('should throw FormatException for invalid field types', () {
        // Arrange
        final json = {
          'id': 'not_an_int', // Should be int
          'email': 'test@example.com',
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T10:30:00.000Z',
          'roles': ['user'],
        };

        // Act & Assert
        expect(
          () => Account.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for invalid date format', () {
        // Arrange
        final json = {
          'id': 1,
          'email': 'test@example.com',
          'password': 'hashedpassword',
          'creationDate': 'invalid-date-format',
          'roles': ['user'],
        };

        // Act & Assert
        expect(
          () => Account.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle null values gracefully', () {
        // Arrange
        final json = {
          'id': 1,
          'email': null,
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T10:30:00.000Z',
          'roles': ['user'],
        };

        // Act & Assert
        expect(
          () => Account.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('toJson', () {
      test('should convert account to JSON format', () {
        // Arrange
        final creationDate = DateTime.utc(2023, 12, 25, 10, 30, 45);
        final account = Account(
          1,
          'test@example.com',
          'hashedpassword',
          creationDate,
          ['user', 'admin'],
        );

        // Act
        final json = account.toJson();

        // Assert
        expect(json['id'], equals(1));
        expect(json['email'], equals('test@example.com'));
        expect(json['creationDate'], equals('2023-12-25T10:30:45.000Z'));
        expect(json['roles'], equals(['user', 'admin']));
        expect(json.containsKey('password'),
            isFalse); // Password should not be included
      });

      test('should convert UTC dates correctly', () {
        // Arrange
        final localDate = DateTime(2023, 12, 25, 15, 30); // Local time
        final account = Account(
          2,
          'utc@example.com',
          'hashedpassword',
          localDate,
          ['user'],
        );

        // Act
        final json = account.toJson();

        // Assert
        expect(json['creationDate'], contains('T'));
        expect(json['creationDate'], endsWith('Z'));

        // Verify it's a valid ISO8601 UTC string
        final parsedDate = DateTime.parse(json['creationDate']);
        expect(parsedDate.isUtc, isTrue);
      });

      test('should handle empty roles list', () {
        // Arrange
        final account = Account(
          3,
          'empty@example.com',
          'hashedpassword',
          DateTime.utc(2023, 12, 25),
          [],
        );

        // Act
        final json = account.toJson();

        // Assert
        expect(json['roles'], isEmpty);
        expect(json['roles'], isA<List<String>>());
      });

      test('should handle single role', () {
        // Arrange
        final account = Account(
          4,
          'single@example.com',
          'hashedpassword',
          DateTime.utc(2023, 12, 25),
          ['admin'],
        );

        // Act
        final json = account.toJson();

        // Assert
        expect(json['roles'], equals(['admin']));
      });

      test('should preserve role order', () {
        // Arrange
        final roles = ['admin', 'user', 'moderator', 'guest'];
        final account = Account(
          5,
          'order@example.com',
          'hashedpassword',
          DateTime.utc(2023, 12, 25),
          roles,
        );

        // Act
        final json = account.toJson();

        // Assert
        expect(json['roles'], equals(roles));
      });
    });

    group('Interface Implementation', () {
      test('should implement NetworkObjectToJson interface', () {
        // Arrange
        final account = Account(
          1,
          'interface@example.com',
          'hashedpassword',
          DateTime.now(),
          ['user'],
        );

        // Act & Assert
        expect(account, isA<NetworkObjectToJson>());
        expect(account.toJson(), isA<Map<String, dynamic>>());
      });

      test('should implement Entity interface', () {
        // Arrange
        final account = Account(
          1,
          'entity@example.com',
          'hashedpassword',
          DateTime.now(),
          ['user'],
        );

        // Act & Assert
        expect(account, isA<Entity>());
        expect(account.id, isA<int>());
      });
    });

    group('Equality and Comparison', () {
      test('should have proper field access', () {
        // Arrange
        const id = 1;
        const email = 'access@example.com';
        const password = 'hashedpassword';
        final creationDate = DateTime.now();
        final roles = ['user', 'admin'];

        final account = Account(id, email, password, creationDate, roles);

        // Act & Assert
        expect(account.id, equals(id));
        expect(account.email, equals(email));
        expect(account.password, equals(password));
        expect(account.creationDate, equals(creationDate));
        expect(account.roles, equals(roles));
      });

      test('should share reference to roles list', () {
        // Arrange
        final roles = ['user'];
        final account = Account(
          1,
          'reference@example.com',
          'hashedpassword',
          DateTime.now(),
          roles,
        );

        // Act - Modify the original roles list after account creation
        roles.add('admin');

        // Assert - Account's roles should reflect the change since it shares the reference
        expect(account.roles, equals(['user', 'admin']));
        expect(account.roles, contains('admin'));
        expect(identical(account.roles, roles), isTrue);
      });
    });

    group('Round-trip Serialization', () {
      test(
          'should maintain data integrity through JSON round-trip with List roles',
          () {
        // Arrange
        final originalAccount = Account(
          42,
          'roundtrip@example.com',
          'hashedpassword123',
          DateTime.utc(2023, 12, 25, 14, 30, 45),
          ['user', 'admin', 'moderator'],
        );

        // Act
        final json = originalAccount.toJson();
        json['password'] =
            originalAccount.password; // Add password back for round-trip
        final deserializedAccount = Account.fromJson(json);

        // Assert
        expect(deserializedAccount.id, equals(originalAccount.id));
        expect(deserializedAccount.email, equals(originalAccount.email));
        expect(deserializedAccount.password, equals(originalAccount.password));
        expect(deserializedAccount.creationDate.toUtc(),
            equals(originalAccount.creationDate.toUtc()));
        expect(deserializedAccount.roles, equals(originalAccount.roles));
      });

      test('should handle round-trip with string roles format', () {
        // Arrange
        final json = {
          'id': 99,
          'email': 'string-roles@example.com',
          'password': 'hashedpassword',
          'creationDate': '2023-12-25T10:30:00.000Z',
          'roles': 'user,admin,guest',
        };

        // Act
        final account = Account.fromJson(json);
        final backToJson = account.toJson();

        // Assert
        expect(account.roles, equals(['user', 'admin', 'guest']));
        expect(backToJson['roles'], equals(['user', 'admin', 'guest']));
        expect(backToJson['roles'], isA<List<String>>());
      });
    });
  });
}
