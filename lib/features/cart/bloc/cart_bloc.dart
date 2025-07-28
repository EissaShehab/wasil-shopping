import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wasil_shopping/core/services/api_service.dart';
import 'package:wasil_shopping/core/utils/toast_utils.dart';
import 'package:wasil_shopping/features/cart/models/cart_item.dart';
import 'package:wasil_shopping/features/products/models/product.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  final List<CartItem> _cartItems = [];
  String? _guestId;
  Stream<DocumentSnapshot>? _cartStream;

  CartBloc() : super(CartInitial()) {
    on<CartInitialize>(_onInitialize);
    on<CartAddItem>(_onAddItem);
    on<CartUpdateQuantity>(_onUpdateQuantity);
    on<CartRemoveItem>(_onRemoveItem);
    on<CartClear>(_onClear);
    on<CartMergeGuestCart>(_onMergeGuestCart);
    add(CartInitialize());
  }

  Future<String> _getUserId() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    }
    if (_guestId == null) {
      final prefs = await SharedPreferences.getInstance();
      _guestId = prefs.getString('guest_id');
      if (_guestId == null) {
        _guestId = const Uuid().v4();
        await prefs.setString('guest_id', _guestId!);
      }
    }
    return _guestId!;
  }

  Future<void> _saveCartToFirestore() async {
    try {
      final userId = await _getUserId();
      await _firestore.collection('carts').doc(userId).set({
        'items': _cartItems.map((item) => item.toJson()).toList(),
        'totalPrice': _calculateTotal(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      ToastUtils.showToast('Error saving cart: $e', isError: true);
    }
  }

  Stream<List<CartItem>> _loadCartFromFirestore() async* {
    final userId = await _getUserId();
    _cartStream = _firestore.collection('carts').doc(userId).snapshots();
    await for (final snapshot in _cartStream!) {
      _cartItems.clear();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final itemsData = data['items'] as List<dynamic>? ?? [];
        for (var itemData in itemsData) {
          final productId = itemData['productId'] as int;
          try {
            final product = await _apiService.fetchProductById(productId);
            _cartItems.add(CartItem(
              product: product,
              quantity: itemData['quantity'] as int,
            ));
          } catch (e) {
            ToastUtils.showToast('Error loading product $productId: $e', isError: true);
          }
        }
      }
      yield List.from(_cartItems);
    }
  }

  double _calculateTotal() {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  Future<void> _onInitialize(CartInitialize event, Emitter<CartState> emit) async {
    emit(CartLoading());
    await for (final cartItems in _loadCartFromFirestore()) {
      emit(CartLoaded(List.from(cartItems), _calculateTotal()));
    }
  }

  Future<void> _onAddItem(CartAddItem event, Emitter<CartState> emit) async {
    if (event.quantity <= 0) {
      ToastUtils.showToast('Quantity must be greater than 0', isError: true);
      return;
    }
    final existingItem = _cartItems.firstWhere(
      (item) => item.product.id == event.product.id,
      orElse: () => CartItem(product: event.product, quantity: 0),
    );
    if (existingItem.quantity == 0) {
      _cartItems.add(CartItem(product: event.product, quantity: event.quantity));
    } else {
      existingItem.quantity += event.quantity;
    }
    await _saveCartToFirestore();
    // No need to emit here since Stream will handle updates
    ToastUtils.showToast('${event.product.title} added to cart!');
  }

  Future<void> _onUpdateQuantity(CartUpdateQuantity event, Emitter<CartState> emit) async {
    final index = _cartItems.indexWhere((item) => item.product.id == event.cartItem.product.id);
    if (index == -1) {
      ToastUtils.showToast('Item not found in cart', isError: true);
      return;
    }
    if (event.newQuantity <= 0) {
      _cartItems.removeAt(index);
      ToastUtils.showToast('${event.cartItem.product.title} removed from cart');
    } else {
      _cartItems[index].quantity = event.newQuantity;
      ToastUtils.showToast('Quantity updated for ${event.cartItem.product.title}');
    }
    await _saveCartToFirestore();
    // No need to emit here since Stream will handle updates
  }

  Future<void> _onRemoveItem(CartRemoveItem event, Emitter<CartState> emit) async {
    final removed = _cartItems.remove(event.cartItem);
    if (removed) {
      await _saveCartToFirestore();
      ToastUtils.showToast('${event.cartItem.product.title} removed from cart');
    } else {
      ToastUtils.showToast('Item not found in cart', isError: true);
    }
    // No need to emit here since Stream will handle updates
  }

  Future<void> _onClear(CartClear event, Emitter<CartState> emit) async {
    _cartItems.clear();
    await _saveCartToFirestore();
    ToastUtils.showToast('Cart cleared');
    // No need to emit here since Stream will handle updates
  }

  Future<void> _onMergeGuestCart(CartMergeGuestCart event, Emitter<CartState> emit) async {
    if (_auth.currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final guestId = prefs.getString('guest_id');
    if (guestId == null) return;
    try {
      final doc = await _firestore.collection('carts').doc(guestId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final itemsData = data['items'] as List<dynamic>? ?? [];
        for (var itemData in itemsData) {
          final productId = itemData['productId'] as int;
          final product = await _apiService.fetchProductById(productId);
          final existingItem = _cartItems.firstWhere(
            (item) => item.product.id == productId,
            orElse: () => CartItem(product: product, quantity: 0),
          );
          if (existingItem.quantity == 0) {
            _cartItems.add(CartItem(product: product, quantity: itemData['quantity'] as int));
          } else {
            existingItem.quantity += itemData['quantity'] as int;
          }
        }
        await _saveCartToFirestore();
        await _firestore.collection('carts').doc(guestId).delete();
        await prefs.remove('guest_id');
        _guestId = null;
        ToastUtils.showToast('Guest cart merged successfully');
      }
    } catch (e) {
      ToastUtils.showToast('Error merging guest cart: $e', isError: true);
      emit(CartError('Error merging guest cart'));
    }
    // No need to emit CartLoaded since Stream will handle updates
  }
}