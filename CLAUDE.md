# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Development
```bash
# Get dependencies
dart pub get

# Run tests
dart test

# Run specific test file
dart test test/path/to/test_file.dart

# Analyze code
dart analyze

# Format code
dart format .

# Format specific files
dart format lib/ test/
```

### Example Application
```bash
# Navigate to example directory
cd example/

# Create database tables
dart run tools/create_database.dart

# Start production server (port 8080)
dart run bin/server.dart

# Start development server with hot reload
dart run --enable-vm-service bin/dev.dart
```

## Architecture Overview

Top Shelf is a Dart package providing helpers, middleware, and architectural patterns for `shelf` HTTP servers. It implements clean architecture with distinct layers:

### Core Layers
- **Handlers/Routes**: HTTP endpoint implementations
- **Services**: Business logic layer with validation hooks (`BaseService<T, ID>`)
- **Repositories**: Data access layer (`CrudRepository<T, ID>`, SQLite implementations)
- **Middleware**: Cross-cutting concerns (auth, logging, CORS, validation, etc.)

### Key Services
- **Account Service**: User management with PBKDF2 password hashing and role-based access
- **Authentication Service**: JWT-based auth with login/refresh token flow
- **Repository Pattern**: Generic CRUD operations with SQLite3 backend

### Important Patterns
- **Dependency Injection**: Services provided via `provide<T>()` middleware
- **Module Organization**: Routes organized by feature and mounted to main router
- **Middleware Pipelines**: Layered middleware application using `Pipeline()`
- **Factory Pattern**: Repository and service factories for clean instantiation

## Key Dependencies

- **shelf/shelf_router**: Core HTTP framework
- **sqlite3**: Database persistence
- **pbkdf2**: Secure password hashing (custom fork)
- **logging**: Structured logging support
- **pointycastle**: Cryptographic operations

## Testing

Tests are organized in `/test/` with patterns for:
- Internal utilities (`/test/internal/`)
- Middleware components (`/test/middlewares/`)
- Service layer (`/test/services/`)

Use `dart test` for full suite or `dart test test/specific_file.dart` for individual test files.

## Security Features

- Password hashing with PBKDF2 + pepper
- JWT authentication with refresh tokens
- Request logging with sensitive data masking
- Input validation at service and middleware levels
- Role-based access control

## In-Memory Repository

For testing and development without database setup, use the in-memory account repository:

```dart
// Create in-memory repository
final repository = AccountRepositoryFactory.createMemoryRepository();
final accountService = AccountService(repository, pepperFactory: testPepperFactory);

// Full CRUD operations available
final account = await accountService.createAccount(
  email: 'test@example.com',
  password: 'password123',
);

// Test utilities
final memoryRepo = repository as AccountMemoryRepository;
print('Total accounts: ${memoryRepo.size}');
memoryRepo.clear(); // Reset for tests
```

**Features:**
- Complete AccountRepositoryInterface implementation
- Email uniqueness enforcement
- Role management (add/remove roles)
- Advanced querying with filters, pagination, sorting
- Account statistics and search functionality
- Test utilities (clear, size, accountIds)

## Development Notes

- Example application in `/example/` demonstrates proper usage patterns
- Database setup required via `dart run tools/create_database.dart` in example
- Hot reload available in development mode
- In-memory repository available for testing: `AccountRepositoryFactory.createMemoryRepository()`
- Wiki documentation at: https://github.com/sakemaer/top_shelf/wiki