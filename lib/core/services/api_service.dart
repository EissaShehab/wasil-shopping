import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wasil_shopping/core/constants/api_constants.dart';
import 'package:wasil_shopping/features/products/models/product.dart';

class ApiService {
  Future<Map<String, dynamic>> fetchProducts(int limit, int skip) async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}?limit=$limit&skip=$skip'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsJson = data['products'] as List;
        final int total = data['total'] as int;
        return {
          'products': productsJson.map((json) => Product.fromJson(json)).toList(),
          'total': total,
        };
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Product> fetchProductById(int productId) async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.productsEndpoint}/$productId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product by ID: $e');
    }
  }
}