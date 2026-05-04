import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dio_client.dart';

part 'upload_service.g.dart';

class UploadResult {
  final String url;
  final String filename;

  const UploadResult({required this.url, required this.filename});
}

class UploadService {
  final Dio _dio;

  UploadService(this._dio);

  Future<UploadResult?> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last.split('\\').last,
        ),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final body = response.data;
      if (body is! Map) return null;

      final status = body['status']?.toString();
      if (status != 'success') return null;

      final data = body['data'];
      if (data is! Map) return null;

      final url = data['url']?.toString();
      final filename = data['filename']?.toString();
      if (url == null || filename == null) return null;

      return UploadResult(url: url, filename: filename);
    } on DioException {
      return null;
    }
  }
}

@riverpod
UploadService uploadService(UploadServiceRef ref) {
  return UploadService(ref.watch(dioClientProvider));
}
