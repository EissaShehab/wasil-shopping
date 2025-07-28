part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartInitialize extends CartEvent {}

class CartAddItem extends CartEvent {
  final Product product;
  final int quantity;

  const CartAddItem(this.product, this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}

class CartUpdateQuantity extends CartEvent {
  final CartItem cartItem;
  final int newQuantity;

  const CartUpdateQuantity(this.cartItem, this.newQuantity);

  @override
  List<Object?> get props => [cartItem, newQuantity];
}

class CartRemoveItem extends CartEvent {
  final CartItem cartItem;

  const CartRemoveItem(this.cartItem);

  @override
  List<Object?> get props => [cartItem];
}

class CartClear extends CartEvent {}

class CartMergeGuestCart extends CartEvent {}