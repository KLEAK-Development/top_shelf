import 'package:test/test.dart';
import 'package:top_shelf/src/internal/pbkdf2.dart';

void main() {
  String getTestPepper() => 'test_pepper';

  test('Hashing and verification with pepper', () {
    final password = 'testpassword123';

    final pbkdf2 = Pbkdf2(pepperFactory: getTestPepper);
    final hashedPassword = pbkdf2.hash(password);

    expect(pbkdf2.verify(password, hashedPassword), isTrue);
    expect(pbkdf2.verify('wrongpassword', hashedPassword), isFalse);
  });

  test('Salt uniqueness', () async {
    final password = 'testpassword';

    final pbkdf2 = Pbkdf2(pepperFactory: getTestPepper);

    final hash1 = pbkdf2.hash(password);
    final hash2 = pbkdf2.hash(password);

    // Extract salt from the hashes and compare
    final salt1 = hash1.split(',')[1];
    final salt2 = hash2.split(',')[1];
    expect(salt1, isNot(equals(salt2)));
  });
}
