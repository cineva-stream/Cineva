import 'package:dio/dio.dart';

/// Shares concurrent in-flight GET requests with the same URI, preventing duplicate requests.
class SingleFlightInterceptor extends Interceptor {
  final Dio dio;
  final _pending = <String, Future<Response<dynamic>>>{};

  SingleFlightInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.method.toUpperCase() != 'GET' || options.extra['singleFlightOwner'] == true) {
      handler.next(options);
      return;
    }

    final key = '${options.uri.toString()}:${options.responseType.name}';
    final operation = _pending.putIfAbsent(
      key,
      () => dio.fetch<dynamic>(
        options.copyWith(
          extra: {...options.extra, 'singleFlightOwner': true},
          cancelToken: CancelToken(),
        ),
      ),
    );

    try {
      final response = await operation;
      handler.resolve(
        Response<dynamic>(
          data: response.data,
          headers: response.headers,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          requestOptions: options,
          extra: {...response.extra},
        ),
      );
    } on DioException catch (error) {
      handler.reject(error.copyWith(requestOptions: options));
    } catch (error, stack) {
      handler.reject(
        DioException(requestOptions: options, error: error, stackTrace: stack),
      );
    } finally {
      if (identical(_pending[key], operation)) {
        _pending.remove(key);
      }
    }
  }
}

