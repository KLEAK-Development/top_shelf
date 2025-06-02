import 'package:test/test.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_factory.dart';

import 'shared_account_repository_tests.dart';

void main() {
  group('Memory Account Repository Unit Tests', () {
    // Run all shared repository tests
    runAccountRepositoryTests(
      () async {
        return AccountRepositoryFactory.createMemoryRepository();
      },
    );
  });
}
