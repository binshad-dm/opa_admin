import 'dart:convert';
import 'package:dio/dio.dart';
import 'app_exception.dart';
import 'failure.dart';

class ErrorMapper {
  static Failure from(Object e) {
    if (e is DioException) {
      final s = e.response?.statusCode ?? 0;
      final path = e.requestOptions.path;

      if (s >= 400 && s < 500) {
        // ── Try to parse the response body ──────────────────────────────────
        dynamic data = e.response?.data;
        Map<String, dynamic>? errorMap;

        if (data is Map) {
          errorMap = data.cast<String, dynamic>();
        } else if (data is String && data.isNotEmpty) {
          try {
            errorMap = jsonDecode(data) as Map<String, dynamic>;
          } catch (_) {}
        }

        if (errorMap != null) {
          final detail = errorMap['detail']?.toString();
          final title = errorMap['title']?.toString();
          final error = errorMap['error']?.toString();
          final errorCode =
              errorMap['properties']?['errorCode']?.toString() ?? title;

          // Return the most specific message available
          if (detail != null && detail.isNotEmpty) {
            return NetworkFailure(detail, errorCode: errorCode);
          }
          if (title != null && title.isNotEmpty) {
            return NetworkFailure(title, errorCode: errorCode);
          }
          if (error != null && error.isNotEmpty) {
            return NetworkFailure(error, errorCode: errorCode);
          }
          if (errorCode != null && errorCode.isNotEmpty) {
            return NetworkFailure(errorCode, errorCode: errorCode);
          }
        }

        // ── Auth errors ─────────────────────────────────────────────────────
        if (s == 401) {
          if (path.contains('/login')) {
            return const AuthFailure(
              'Invalid email/username or password. Please try again.',
            );
          }
          return const AuthFailure('Your session expired.');
        }

        // ── Supervisor-only close endpoint fallback ──────────────────────────
        if (path.contains('/close')) {
          return const NetworkFailure(
            'Only a Supervisor can complete this case sheet.',
          );
        }

        // ── Fallback: never show raw Dio message for client errors ──────────
        return const NetworkFailure('Something went wrong. Please try again.');
      }

      if (s == 401) {
        if (path.contains('/login')) {
          return const AuthFailure(
            'Invalid email/username or password. Please try again.',
          );
        }
        return const AuthFailure('Your session expired.');
      }
      if (s >= 500) {
        return const NetworkFailure(
          'Something went wrong. Please try again later.',
        );
      }

      // No status code (connection error, timeout, etc.)
      return const NetworkFailure(
        'Unable to connect. Please check your network.',
      );
    }
    if (e is Failure) return e;
    if (e is AppException) return UnknownFailure(e.message);
    return UnknownFailure(e.toString());
  }
}
