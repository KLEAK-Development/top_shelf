import 'dart:async';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';

/// Base service interface providing common business logic operations
abstract class BaseService<T extends Entity, ID> {
  /// Gets the underlying repository
  CrudRepository<T, ID> get repository;

  /// Creates a new entity with validation
  FutureOr<T> create(T entity);

  /// Creates multiple entities with validation
  FutureOr<List<T>> createAll(List<T> entities);

  /// Finds an entity by ID
  FutureOr<T?> findById(ID id);

  /// Gets an entity by ID or throws exception
  FutureOr<T> getById(ID id);

  /// Finds all entities with optional filtering
  FutureOr<List<T>> findAll([QueryParams? params]);

  /// Finds entities with pagination
  FutureOr<PagedResult<T>> findPage(QueryParams params);

  /// Updates an entity with validation
  FutureOr<T> update(T entity);

  /// Partially updates an entity
  FutureOr<T> updatePartial(ID id, Map<String, dynamic> fields);

  /// Deletes an entity by ID
  FutureOr<bool> deleteById(ID id);

  /// Checks if entity exists
  FutureOr<bool> exists(ID id);

  /// Counts entities
  FutureOr<int> count([QueryParams? params]);

  /// Validates entity before operations
  FutureOr<ValidationResult> validate(T entity);

  /// Validates partial update fields
  FutureOr<ValidationResult> validatePartialUpdate(Map<String, dynamic> fields);
}

/// Default implementation of BaseService
abstract class AbstractBaseService<T extends Entity, ID>
    implements BaseService<T, ID> {
  @override
  final CrudRepository<T, ID> repository;

  AbstractBaseService(this.repository);

  @override
  Future<T> create(T entity) async {
    final validation = await validate(entity);
    if (!validation.isValid) {
      throw ServiceValidationException(validation.errors);
    }

    await beforeCreate(entity);
    final result = await repository.create(entity);
    await afterCreate(result);
    return result;
  }

  @override
  Future<List<T>> createAll(List<T> entities) async {
    for (final entity in entities) {
      final validation = await validate(entity);
      if (!validation.isValid) {
        throw ServiceValidationException(validation.errors);
      }
    }

    await beforeCreateAll(entities);
    final results = await repository.createAll(entities);
    await afterCreateAll(results);
    return results;
  }

  @override
  Future<T?> findById(ID id) async {
    return await repository.findById(id);
  }

  @override
  Future<T> getById(ID id) async {
    final result = await repository.findById(id);
    if (result == null) {
      throw ServiceNotFoundException('Entity not found', id);
    }
    return result;
  }

  @override
  Future<List<T>> findAll([QueryParams? params]) async {
    return await repository.findAll(params);
  }

  @override
  Future<PagedResult<T>> findPage(QueryParams params) async {
    return await repository.findPage(params);
  }

  @override
  Future<T> update(T entity) async {
    final validation = await validate(entity);
    if (!validation.isValid) {
      throw ServiceValidationException(validation.errors);
    }

    await beforeUpdate(entity);
    final result = await repository.update(entity);
    await afterUpdate(result);
    return result;
  }

  @override
  Future<T> updatePartial(ID id, Map<String, dynamic> fields) async {
    final validation = await validatePartialUpdate(fields);
    if (!validation.isValid) {
      throw ServiceValidationException(validation.errors);
    }

    await beforePartialUpdate(id, fields);
    final result = await repository.updatePartial(id, fields);
    await afterPartialUpdate(result);
    return result;
  }

  @override
  Future<bool> deleteById(ID id) async {
    final entity = await findById(id);
    if (entity == null) {
      return false;
    }

    await beforeDelete(entity);
    final result = await repository.deleteById(id);
    if (result) {
      await afterDelete(entity);
    }
    return result;
  }

  @override
  Future<bool> exists(ID id) async {
    return await repository.existsById(id);
  }

  @override
  Future<int> count([QueryParams? params]) async {
    return await repository.count(params);
  }

  @override
  Future<ValidationResult> validate(T entity) async {
    // Default implementation - override in concrete services
    return ValidationResult.success();
  }

  @override
  Future<ValidationResult> validatePartialUpdate(
      Map<String, dynamic> fields) async {
    // Default implementation - override in concrete services
    return ValidationResult.success();
  }

  // Lifecycle hooks - override in concrete services
  Future<void> beforeCreate(T entity) async {}
  Future<void> afterCreate(T entity) async {}
  Future<void> beforeCreateAll(List<T> entities) async {}
  Future<void> afterCreateAll(List<T> entities) async {}
  Future<void> beforeUpdate(T entity) async {}
  Future<void> afterUpdate(T entity) async {}
  Future<void> beforePartialUpdate(ID id, Map<String, dynamic> fields) async {}
  Future<void> afterPartialUpdate(T entity) async {}
  Future<void> beforeDelete(T entity) async {}
  Future<void> afterDelete(T entity) async {}
}

/// Validation result for service operations
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult.success()
      : isValid = true,
        errors = [];
  ValidationResult.failure(this.errors) : isValid = false;
}

/// Exception thrown when service validation fails
class ServiceValidationException implements Exception {
  final List<String> errors;

  const ServiceValidationException(this.errors);

  @override
  String toString() => 'ServiceValidationException: ${errors.join(', ')}';
}

/// Exception thrown when service entity is not found
class ServiceNotFoundException implements Exception {
  final String message;
  final dynamic id;

  const ServiceNotFoundException(this.message, this.id);

  @override
  String toString() => 'ServiceNotFoundException: $message (ID: $id)';
}

/// Exception thrown when service operations fail
class ServiceException implements Exception {
  final String message;
  final Exception? cause;

  const ServiceException(this.message, [this.cause]);

  @override
  String toString() =>
      'ServiceException: $message${cause != null ? ' (Caused by: $cause)' : ''}';
}
