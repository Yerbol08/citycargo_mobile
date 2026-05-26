import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:citycargo_mobile/features/auth/data/auth_repository.dart';
import 'package:citycargo_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:citycargo_mobile/core/storage/token_storage.dart';
import 'package:citycargo_mobile/features/auth/domain/models/auth_response_model.dart';
import 'package:citycargo_mobile/features/auth/domain/models/user_model.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockTokenStorage mockStorage;
  late AuthRepository repository;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockStorage = MockTokenStorage();
    repository = AuthRepository(mockRemote, mockStorage);
  });

  group('AuthRepository', () {
    final testUser = const UserModel(
      id: '1',
      phone: '+77001234567',
      fullName: 'Test',
      roles: [],
    );
    final authResponse = AuthResponseModel(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      user: testUser,
    );

    test('login saves tokens and user', () async {
      when(() => mockRemote.login('phone', 'pass')).thenAnswer((_) async => authResponse);
      when(() => mockStorage.saveTokens(accessToken: 'access_token', refreshToken: 'refresh_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.saveUser(any())).thenAnswer((_) async {});

      final result = await repository.login('phone', 'pass');

      expect(result, equals(authResponse));
      verify(() => mockRemote.login('phone', 'pass')).called(1);
      verify(() => mockStorage.saveTokens(accessToken: 'access_token', refreshToken: 'refresh_token')).called(1);
      verify(() => mockStorage.saveUser(testUser.toJson())).called(1);
    });

    test('logout calls remote and clears storage', () async {
      when(() => mockRemote.logout()).thenAnswer((_) async {});
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockRemote.logout()).called(1);
      verify(() => mockStorage.clearAll()).called(1);
    });

    test('logout clears storage even if remote fails', () async {
      when(() => mockRemote.logout()).thenThrow(Exception('Network error'));
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockRemote.logout()).called(1);
      verify(() => mockStorage.clearAll()).called(1);
    });

    test('getMe returns from remote and caches', () async {
      when(() => mockRemote.getMe()).thenAnswer((_) async => testUser);
      when(() => mockStorage.saveUser(any())).thenAnswer((_) async {});

      final result = await repository.getMe();

      expect(result, testUser);
      verify(() => mockRemote.getMe()).called(1);
      verify(() => mockStorage.saveUser(testUser.toJson())).called(1);
    });

    test('getMe returns from cache if remote fails', () async {
      when(() => mockRemote.getMe()).thenThrow(Exception('Network error'));
      when(() => mockStorage.getUser()).thenAnswer((_) async => testUser.toJson());

      final result = await repository.getMe();

      expect(result.id, testUser.id);
      verify(() => mockRemote.getMe()).called(1);
      verify(() => mockStorage.getUser()).called(1);
    });
  });
}
