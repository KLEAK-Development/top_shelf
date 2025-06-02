import 'dart:async';
import 'package:sqlite3/sqlite3.dart';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';

/// SQLite implementation of the CRUD repository using secure hardcoded SQL patterns
abstract class SqliteCrudRepository<T extends Entity, ID>
    implements AdvancedCrudRepository<T, ID> {
  final Database database;

  SqliteCrudRepository(this.database);

  /// Converts a Map from SQLite to an entity instance
  T fromMap(Map<String, dynamic> map);

  /// Converts an entity to a Map for SQLite operations
  Map<String, dynamic> toMap(T entity);

  /// Returns hardcoded SQL for creating an entity
  String get createSql;

  /// Returns hardcoded SQL for finding by ID
  String get findByIdSql;

  /// Returns hardcoded SQL for finding all entities
  String get findAllSql;

  /// Returns hardcoded SQL for counting entities
  String get countSql;

  /// Returns hardcoded SQL for updating an entity by ID
  String get updateByIdSql;

  /// Returns hardcoded SQL for deleting by ID
  String get deleteByIdSql;

  /// Returns the list of column values for insert operations
  List<dynamic> getInsertValues(T entity);

  /// Returns the list of column values for update operations
  List<dynamic> getUpdateValues(T entity);

  @override
  Future<T> create(T entity) async {
    try {
      final values = getInsertValues(entity);
      final results = database.select(createSql, values);
      if (results.isEmpty) {
        throw RepositoryException('Failed to create entity');
      }
      return fromMap(results.first);
    } catch (e) {
      if (e is SqliteException) {
        if (e.extendedResultCode == 2067) {
          throw EntityConstraintException(
              'Unique constraint violation', e.message);
        }
      }
      throw RepositoryException('Error creating entity',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<List<T>> createAll(List<T> entities) async {
    return await transaction(() async {
      final results = <T>[];
      for (final entity in entities) {
        results.add(await create(entity));
      }
      return results;
    });
  }

  @override
  Future<T?> findById(ID id) async {
    try {
      final results = database.select(findByIdSql, [id]);
      return results.isEmpty ? null : fromMap(results.first);
    } catch (e) {
      throw RepositoryException('Error finding entity by ID',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<T> getById(ID id) async {
    final result = await findById(id);
    if (result == null) {
      throw EntityNotFoundException('Entity not found', id);
    }
    return result;
  }

  @override
  Future<List<T>> findAll([QueryParams? params]) async {
    try {
      // For simple findAll without complex filtering, use the basic SQL
      if (params == null ||
          (params.filters.isEmpty &&
              params.orderBy.isEmpty &&
              params.limit == null)) {
        final results = database.select(findAllSql);
        return results.map((row) => fromMap(row)).toList();
      }

      // For complex queries, delegate to subclass implementation
      return await findWithParams(params);
    } catch (e) {
      throw RepositoryException('Error finding entities',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Subclasses must implement this method for complex filtering
  /// This ensures all SQL remains hardcoded in specific repositories
  Future<List<T>> findWithParams(QueryParams params);

  @override
  Future<PagedResult<T>> findPage(QueryParams params) async {
    try {
      // Get total count first
      final totalCount = await count(QueryParams(filters: params.filters));

      // Get paginated results
      final items = await findWithParams(params);

      final hasNext = params.offset != null && params.limit != null
          ? (params.offset! + params.limit!) < totalCount
          : false;

      final hasPrevious = params.offset != null ? params.offset! > 0 : false;

      return PagedResult(
        items: items,
        totalCount: totalCount,
        limit: params.limit,
        offset: params.offset,
        hasNext: hasNext,
        hasPrevious: hasPrevious,
      );
    } catch (e) {
      throw RepositoryException('Error finding paginated entities',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<T?> findFirst(QueryParams params) async {
    final modifiedParams = params.copyWith(limit: 1);
    final results = await findWithParams(modifiedParams);
    return results.isEmpty ? null : results.first;
  }

  @override
  Future<T> findOne(QueryParams params) async {
    final results = await findWithParams(params.copyWith(limit: 2));
    if (results.isEmpty) {
      throw EntityNotFoundException(
          'No entity found matching criteria', params.filters);
    }
    if (results.length > 1) {
      throw RepositoryException('Multiple entities found when expecting one');
    }
    return results.first;
  }

  @override
  Future<bool> existsById(ID id) async {
    final result = await findById(id);
    return result != null;
  }

  @override
  Future<int> count([QueryParams? params]) async {
    try {
      if (params == null || params.filters.isEmpty) {
        final results = database.select(countSql);
        return results.first['count'] as int;
      }

      // For filtered counts, delegate to subclass
      return await countWithParams(params);
    } catch (e) {
      throw RepositoryException('Error counting entities',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Subclasses must implement this method for filtered counting
  Future<int> countWithParams(QueryParams params);

  @override
  Future<T> update(T entity) async {
    try {
      final values = getUpdateValues(entity);
      final results = database.select(updateByIdSql, values);
      if (results.isEmpty) {
        throw EntityNotFoundException('Entity not found for update', entity.id);
      }
      return fromMap(results.first);
    } catch (e) {
      if (e is EntityNotFoundException) rethrow;
      throw RepositoryException('Error updating entity',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<List<T>> updateAll(List<T> entities) async {
    return await transaction(() async {
      final results = <T>[];
      for (final entity in entities) {
        results.add(await update(entity));
      }
      return results;
    });
  }

  @override
  Future<T> updatePartial(ID id, Map<String, dynamic> fields) async {
    // Subclasses must implement specific update methods for different field combinations
    throw UnimplementedError(
        'Subclasses must implement updatePartial with specific SQL for each field combination');
  }

  @override
  Future<bool> deleteById(ID id) async {
    try {
      database.execute(deleteByIdSql, [id]);
      return database.updatedRows > 0;
    } catch (e) {
      throw RepositoryException('Error deleting entity by ID',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<bool> delete(T entity) async {
    return await deleteById(entity.id);
  }

  @override
  Future<int> deleteAllById(List<ID> ids) async {
    if (ids.isEmpty) return 0;

    // Subclasses must implement this with hardcoded SQL for batch deletes
    throw UnimplementedError(
        'Subclasses must implement deleteAllById with specific SQL');
  }

  @override
  Future<int> deleteWhere(QueryParams params) async {
    // Subclasses must implement this with hardcoded SQL for conditional deletes
    throw UnimplementedError(
        'Subclasses must implement deleteWhere with specific SQL');
  }

  @override
  Future<int> deleteAll() async {
    // Subclasses must implement this with hardcoded SQL
    throw UnimplementedError(
        'Subclasses must implement deleteAll with specific SQL');
  }

  @override
  Future<T> save(T entity) async {
    if (entity.id == null) {
      return await create(entity);
    } else {
      final exists = await existsById(entity.id);
      return exists ? await update(entity) : await create(entity);
    }
  }

  @override
  Future<List<T>> saveAll(List<T> entities) async {
    return await transaction(() async {
      final results = <T>[];
      for (final entity in entities) {
        results.add(await save(entity));
      }
      return results;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> executeQuery(String query,
      [List<dynamic>? parameters]) async {
    try {
      return database.select(query, parameters ?? []);
    } catch (e) {
      throw RepositoryException('Error executing custom query',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<int> executeCommand(String command,
      [List<dynamic>? parameters]) async {
    try {
      database.execute(command, parameters ?? []);
      return database.updatedRows;
    } catch (e) {
      throw RepositoryException('Error executing custom command',
          e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<List<T>> findWhere(String whereClause,
      [List<dynamic>? parameters]) async {
    // This method should only be used by subclasses with hardcoded WHERE clauses
    throw UnimplementedError(
        'Subclasses must implement findWhere with specific hardcoded SQL');
  }

  @override
  Future<R> transaction<R>(FutureOr<R> Function() operation) async {
    database.execute('BEGIN TRANSACTION');
    try {
      final result = await operation();
      database.execute('COMMIT');
      return result;
    } catch (e) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<T> refresh(T entity) async {
    return await getById(entity.id);
  }
}
