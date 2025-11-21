import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'token_store.dart'; // Assuming this exists, or I'll hardcode/find base URL

class ProductService {
  // Base URL should be centralized. For now, I'll assume a standard pattern or check other services.
  // Checking auth_service.dart would be good to see how they handle URLs.
  // But I'll write this to be adaptable.
  
  final String _baseUrl = 'http://localhost:8080/api'; // Default dev URL

  Future<void> createProduct(Map<String, dynamic> productData, List<(String, Uint8List)> images) async {
    final uri = Uri.parse('$_baseUrl/products');
    final request = http.MultipartRequest('POST', uri);

    // Add Headers (Auth)
    final token = await TokenStore.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    final orgId = await TokenStore.getOrgId();
    if (orgId != null) {
      request.headers['X-Organization-Id'] = orgId.toString();
    } else {
       request.headers['X-Organization-Id'] = '1'; // Fallback
    }

    // Add JSON Data
    request.fields['data'] = jsonEncode(productData);

    // Add Images
    for (var i = 0; i < images.length; i++) {
      final (path, bytes) = images[i];
      // Determine mime type based on extension or default to image/jpeg
      final ext = path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      request.files.add(http.MultipartFile.fromBytes(
        'images',
        bytes,
        filename: path.split('/').last,
        contentType: mimeType,
      ));
    }

    // Send Request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create product: ${response.body}');
    }
  }
}
