import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryImageUpload {
  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'bcdcj5dc',
  );
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'ql_sanpham',
  );
  static const isConfigured = cloudName != '' && uploadPreset != '';

  static Future<String> upload(XFile image) async {
    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw StateError('Cloudinary upload failed (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;
    if (url == null || !url.startsWith('https://')) {
      throw StateError('Cloudinary did not return an HTTPS image URL');
    }
    return url;
  }
}
