import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'auth_api.dart';
import 'token_manager.dart';
import 'user_context.dart';
import '../../app/navigation/routes.dart';
import '../service_locator.dart';

class _QueuedRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  final DioException originalError;

  _QueuedRequest({
    required this.requestOptions,
    required this.handler,
    required this.originalError,
  });
}

class AuthInterceptor extends Interceptor {
  final TokenManager tokenManager;
  final AuthApi authApi;
  final UserContext? userContext;
  Dio? dio;

  final List<_QueuedRequest> _retryQueue = [];
  Completer<void>? _refreshCompleter;
  bool _isProcessingQueue = false;

  AuthInterceptor({
    required this.tokenManager,
    required this.authApi,
    this.userContext,
    this.dio,
  });

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    final a = await tokenManager.getAccess();
    if (a != null && a.isNotEmpty) {
      o.headers['Authorization'] = 'Bearer $a';
    }
    final studentId = userContext?.studentId;
    if (userContext?.isStudent == true &&
        studentId != null &&
        studentId.isNotEmpty) {
      o.headers['x-user'] = studentId;
    }
    h.next(o);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler h) async {
    final skipRefresh = err.requestOptions.extra['skipAuthRefresh'] == true;
    final path = err.requestOptions.path;

    if (skipRefresh ||
        path.contains('/auth/login') ||
        path.contains('/auth/refresh')) {
      return h.next(err);
    }

    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      _retryQueue.add(
        _QueuedRequest(
          requestOptions: err.requestOptions,
          handler: h,
          originalError: err,
        ),
      );

      if (_refreshCompleter == null) {
        _refreshCompleter = Completer<void>();
        try {
          final refreshToken = await tokenManager.getRefresh();
          if (refreshToken == null || refreshToken.isEmpty) {
            throw Exception('No refresh token available');
          }
          final newTokens = await authApi.refresh(refreshToken);
          await tokenManager.save(newTokens);
          _refreshCompleter?.complete();
        } catch (e) {
          _refreshCompleter?.completeError(e);
          _rejectAllQueuedRequests(err);
          _retryQueue.clear();
          return;
        } finally {
          _refreshCompleter = null;
        }
      } else {
        try {
          await _refreshCompleter!.future;
        } catch (e) {
          return;
        }
      }

      if (!_isProcessingQueue) {
        _processQueuedRequests();
      }
      return;
    }

    h.next(err);
  }

  void _processQueuedRequests() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    final requestsToProcess = List<_QueuedRequest>.from(_retryQueue);
    _retryQueue.clear();

    final newAccessToken = await tokenManager.getAccess();

    for (final queuedRequest in requestsToProcess) {
      try {
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          queuedRequest.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';
        }

        final client =
            dio ?? (queuedRequest.requestOptions.extra['dio'] as Dio?);
        if (client == null) {
          queuedRequest.handler.reject(queuedRequest.originalError);
          continue;
        }

        final responseFuture = client.fetch(queuedRequest.requestOptions);
        responseFuture.then(
          (response) => queuedRequest.handler.resolve(response),
          onError: (error) {
            if (error is DioException) {
              queuedRequest.handler.reject(error);
            } else {
              queuedRequest.handler.reject(queuedRequest.originalError);
            }
          },
        );
      } catch (e) {
        queuedRequest.handler.reject(queuedRequest.originalError);
      }
    }

    _isProcessingQueue = false;
  }

  void _rejectAllQueuedRequests(DioException error) {
    for (final queuedRequest in _retryQueue) {
      queuedRequest.handler.reject(error);
    }
  }
}
