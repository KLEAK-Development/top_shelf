import 'package:test/test.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_memory_repository.dart';

import 'shared_account_repository_tests.dart';

void main() {
  group('Memory Account Repository Unit Tests', () {
    // Run all shared repository tests
    runAccountRepositoryTests(
      () async {
        return AccountMemoryRepository();
      },
    );
  });
}
