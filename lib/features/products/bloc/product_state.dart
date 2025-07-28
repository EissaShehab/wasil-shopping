import 'package:equatable/equatable.dart';
import 'package:wasil_shopping/features/products/models/product.dart';

abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoadingMore extends ProductState {
  final List<Product> products;
  final List<String> categories;
  final int? total;
  final bool isCached;

  ProductLoadingMore(this.products, this.categories, this.total, this.isCached);

  @override
  List<Object?> get props => [products, categories, total, isCached];
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<String> categories;
  final int? total;
  final bool isCached;

  ProductLoaded(this.products, this.categories, {this.total, this.isCached = false});

  @override
  List<Object?> get props => [products, categories, total, isCached];
}

class ProductError extends ProductState {
  final String message;

  ProductError(this.message);

  @override
  List<Object?> get props => [message];
}