import 'package:test/test.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_factory.dart';

import 'shared_account_service_tests.dart';

void main() {
  group('Memory Account Service Tests', () {
    // Run all shared integration tests
    runAccountIntegrationTests(
      () async {
        return AccountRepositoryFactory.createMemoryRepository();
      },
    );
  });
}
