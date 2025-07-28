import 'package:wasil_shopping/features/products/models/product.dart';

abstract class WishlistEvent {}

class WishlistFetch extends WishlistEvent {}

class WishlistAddItem extends WishlistEvent {
  final Product product;
  WishlistAddItem(this.product);
}

class WishlistRemoveItem extends WishlistEvent {
  final Product product;
  WishlistRemoveItem(this.product);
}
