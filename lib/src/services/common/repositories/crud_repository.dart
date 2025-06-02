import 'dart:async';

/// Base interface for entities that can be stored in a repository
abstract class Entity {
  /// Unique identifier for the entity
  dynamic get id;
}

/// Query parameters for filtering and pagination
class QueryParams {
  final Map<String, dynamic> filters;
  final List<String> orderBy;
  final int? limit;
  final int? offset;
  final bool ascending;

  const QueryParams({
    this.filters = const {},
    this.orderBy = const [],
    this.limit,
    this.offset,
    this.ascending = true,
  });

  QueryParams copyWith({
    Map<String, dynamic>? filters,
    List<String>? orderBy,
    int? limit,
    int? offset,
    bool? ascending,
  }) {
    return QueryParams(
      filters: filters ?? this.filters,
      orderBy: orderBy ?? this.orderBy,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Result wrapper for paginated queries
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int? limit;
  final int? offset;
  final bool hasNext;
  final bool hasPrevious;

  const PagedResult({
    required this.items,
    required this.totalCount,
    this.limit,
    this.offset,
    required this.hasNext,
    required this.hasPrevious,
  });
}

/// Exception thrown when an entity is not found
class EntityNotFoundException implements Exception {
  final String message;
  final dynamic id;

  const EntityNotFoundException(this.message, this.id);

  @override
  String toString() => 'EntityNotFoundException: $message (ID: $id)';
}

/// Exception thrown when a create operation fails due to constraint violation
class EntityConstraintException implements Exception {
  final String message;
  final String constraint;

  const EntityConstraintException(this.message, this.constraint);

  @override
  String toString() => 'EntityConstraintException: $message ($constraint)';
}

/// Exception thrown when repository operations fail
class RepositoryException implements Exception {
  final String message;
  final Exception? cause;

  const RepositoryException(this.message, [this.cause]);

  @override
  String toString() =>
      'RepositoryException: $message${cause != null ? ' (Caused by: $cause)' : ''}';
}

/// Abstract base repository providing CRUD operations for entities
abstract class CrudRepository<T extends Entity, ID> {
  /// Creates a new entity in the repository
  /// Returns the created entity with populated ID and metadata
  FutureOr<T> create(T entity);

  /// Creates multiple entities in a single transaction
  /// Returns the list of created entities with populated IDs
  FutureOr<List<T>> createAll(List<T> entities);

  /// Finds an entity by its unique identifier
  /// Returns null if not found
  FutureOr<T?> findById(ID id);

  /// Finds an entity by its unique identifier
  /// Throws EntityNotFoundException if not found
  FutureOr<T> getById(ID id);

  /// Finds all entities matching the given query parameters
  FutureOr<List<T>> findAll([QueryParams? params]);

  /// Finds entities with pagination support
  FutureOr<PagedResult<T>> findPage(QueryParams params);

  /// Finds the first entity matching the query parameters
  /// Returns null if not found
  FutureOr<T?> findFirst(QueryParams params);

  /// Finds a single entity matching the query parameters
  /// Throws EntityNotFoundException if not found or multiple entities found
  FutureOr<T> findOne(QueryParams params);

  /// Checks if an entity with the given ID exists
  FutureOr<bool> existsById(ID id);

  /// Counts entities matching the query parameters
  FutureOr<int> count([QueryParams? params]);

  /// Updates an existing entity
  /// Returns the updated entity
  /// Throws EntityNotFoundException if entity doesn't exist
  FutureOr<T> update(T entity);

  /// Updates multiple entities in a single transaction
  /// Returns the list of updated entities
  FutureOr<List<T>> updateAll(List<T> entities);

  /// Partially updates an entity with the given fields
  /// Returns the updated entity
  /// Throws EntityNotFoundException if entity doesn't exist
  FutureOr<T> updatePartial(ID id, Map<String, dynamic> fields);

  /// Deletes an entity by its ID
  /// Returns true if entity was deleted, false if it didn't exist
  FutureOr<bool> deleteById(ID id);

  /// Deletes an entity
  /// Returns true if entity was deleted, false if it didn't exist
  FutureOr<bool> delete(T entity);

  /// Deletes multiple entities by their IDs
  /// Returns the number of entities actually deleted
  FutureOr<int> deleteAllById(List<ID> ids);

  /// Deletes entities matching the query parameters
  /// Returns the number of entities deleted
  FutureOr<int> deleteWhere(QueryParams params);

  /// Deletes all entities in the repository
  /// Returns the number of entities deleted
  FutureOr<int> deleteAll();

  /// Saves an entity (create if new, update if exists)
  /// Determines operation based on entity ID
  FutureOr<T> save(T entity);

  /// Saves multiple entities (create new ones, update existing)
  FutureOr<List<T>> saveAll(List<T> entities);
}

/// Extended repository interface with advanced querying capabilities
abstract class AdvancedCrudRepository<T extends Entity, ID>
    extends CrudRepository<T, ID> {
  /// Executes a custom query and returns raw results
  FutureOr<List<Map<String, dynamic>>> executeQuery(String query,
      [List<dynamic>? parameters]);

  /// Executes a custom update/delete command
  /// Returns the number of affected rows
  FutureOr<int> executeCommand(String command, [List<dynamic>? parameters]);

  /// Finds entities using a custom where clause
  FutureOr<List<T>> findWhere(String whereClause, [List<dynamic>? parameters]);

  /// Performs a batch operation within a transaction
  FutureOr<R> transaction<R>(FutureOr<R> Function() operation);

  /// Refreshes/reloads an entity from the data source
  FutureOr<T> refresh(T entity);
}
