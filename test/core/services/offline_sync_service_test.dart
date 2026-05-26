import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:citycargo_mobile/core/services/offline_sync_service.dart';
import 'package:citycargo_mobile/core/storage/offline_queue.dart';

class MockOfflineQueue extends Mock implements OfflineQueue {}
class MockDio extends Mock implements Dio {}

void main() {
  late MockOfflineQueue mockQueue;
  late MockDio mockDio;
  late OfflineSyncService syncService;

  setUp(() {
    mockQueue = MockOfflineQueue();
    mockDio = MockDio();
    syncService = OfflineSyncService(offlineQueue: mockQueue, dio: mockDio);
  });

  group('OfflineSyncService', () {
    test('does nothing if queue is empty on startListening', () async {
      when(() => mockQueue.getPendingRequests()).thenReturn([]);
      
      syncService.startListening();

      verify(() => mockQueue.getPendingRequests()).called(1);
      verifyNever(() => mockDio.post(any(), data: any(named: 'data')));
      
      syncService.stopListening();
    });

    test('syncs pending POST requests and removes from queue on success', () async {
      final req1 = OfflineRequest(method: 'POST', path: '/api/v1/test', data: {'a': 1}, timestamp: 1);
      when(() => mockQueue.getPendingRequests()).thenReturn([
        MapEntry(0, req1),
      ]);
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/api/v1/test')));
      when(() => mockQueue.remove(any())).thenAnswer((_) async {});

      // Simulate a sync trigger
      syncService.startListening();
      
      // We need to wait for the microtask to finish since _syncOfflineRequests is async
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockQueue.getPendingRequests()).called(1);
      verify(() => mockDio.post('/api/v1/test', data: {'a': 1})).called(1);
      verify(() => mockQueue.remove(0)).called(1);

      syncService.stopListening();
    });

    test('retains request in queue if network error occurs', () async {
      final req1 = OfflineRequest(method: 'POST', path: '/api/v1/test', data: {'a': 1}, timestamp: 1);
      when(() => mockQueue.getPendingRequests()).thenReturn([
        MapEntry(0, req1),
      ]);
      
      final dioError = DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      );
      
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(dioError);

      syncService.startListening();
      
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockDio.post('/api/v1/test', data: {'a': 1})).called(1);
      verifyNever(() => mockQueue.remove(0)); // Should not remove on network error

      syncService.stopListening();
    });
  });
}
