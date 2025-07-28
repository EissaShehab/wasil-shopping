import 'package:wasil_shopping/features/products/models/product.dart';

class WishlistState {}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<Product> wishlistItems;
  WishlistLoaded(this.wishlistItems);
}

class WishlistError extends WishlistState {
  final String message;
  WishlistError(this.message);
}
