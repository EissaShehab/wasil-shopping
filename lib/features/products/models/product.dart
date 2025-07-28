import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String title;
  final String description;
  final double price;
  final String thumbnail;
  final String category;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0, // افتراض قيمة افتراضية إذا كانت null
      title: json['title'] as String? ?? 'No Title', // افتراض قيمة افتراضية
      description: json['description'] as String? ?? 'No Description', // افتراض قيمة افتراضية
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // تحويل مع التحقق من null
      thumbnail: json['thumbnail'] as String? ?? '', // افتراض قيمة فارغة إذا كانت null
      category: json['category'] as String? ?? 'Uncategorized', // افتراض قيمة افتراضية
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'thumbnail': thumbnail,
      'category': category,
    };
  }

  @override
  List<Object> get props => [id, title, description, price, thumbnail, category];
}