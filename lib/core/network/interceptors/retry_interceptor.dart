import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// Checks if an error is due to transport/socket failure or timeout.
bool isTransportFailure(DioException error) =>
    [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ].contains(error.type) ||
    error.error is SocketException ||
    error.error is TimeoutException;

/// Interceptor that automatically retries idempotent requests with exponential backoff.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final Future<void> Function(Duration) _delay;

  RetryInterceptor(
    this.dio, {
    this.retries = 2,
    Future<void> Function(Duration)? delay,
  }) : _delay = delay ?? Future<void>.delayed;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final attempt = request.extra['retryAttempt'] as int? ?? 0;
    final limit = (request.extra['retryLimit'] as int? ?? retries).clamp(0, retries);
    final status = err.response?.statusCode;
    final retryable = isTransportFailure(err) || (status != null && status >= 500);

    if (request.method.toUpperCase() != 'GET' ||
        attempt >= limit ||
        !retryable ||
        request.cancelToken?.isCancelled == true ||
        err.type == DioExceptionType.cancel) {
      handler.next(err);
      return;
    }

    try {
      await _delay(Duration(milliseconds: 300 * (1 << attempt)));
      if (request.cancelToken?.isCancelled == true) {
        handler.next(request.cancelToken!.cancelError!);
        return;
      }
      final response = await dio.fetch<dynamic>(
        request.copyWith(
          extra: {...request.extra, 'retryAttempt': attempt + 1},
        ),
      );
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    } catch (unexpectedErr, stack) {
      handler.next(
        DioException(requestOptions: request, error: unexpectedErr, stackTrace: stack),
      );
    }
  }
}

