// lib/features/wishlist/bloc/wishlist_bloc.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_state.dart';
import 'package:wasil_shopping/features/products/models/product.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_event.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_state.dart';



class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final AuthBloc authBloc;
  final FirebaseFirestore firestore;

  WishlistBloc(this.authBloc, this.firestore) : super(WishlistInitial()) {
    on<WishlistFetch>(_onFetch);
    on<WishlistAddItem>(_onAddItem);
    on<WishlistRemoveItem>(_onRemoveItem);
  }

  Future<void> _onFetch(
    WishlistFetch event,
    Emitter<WishlistState> emit,
  ) async {
    emit(WishlistLoading());
    try {
      if (authBloc.state is AuthAuthenticated) {
        final userId = (authBloc.state as AuthAuthenticated).user.uid;
        final docRef = firestore.collection('wishlists').doc(userId);
        final snapshot = await docRef.get();

        debugPrint('Fetching wishlist for user: $userId');
        debugPrint(
          'Snapshot exists: ${snapshot.exists}, Data: ${snapshot.data()}',
        );

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final List<Product> wishlistItems = data['items'] != null
              ? (data['items'] as List)
                    .map(
                      (item) => Product.fromJson(item as Map<String, dynamic>),
                    )
                    .toList()
              : [];
          debugPrint('Wishlist items loaded: ${wishlistItems.length}');
          emit(WishlistLoaded(wishlistItems));
        } else {
          debugPrint('Creating empty wishlist for user: $userId');
          await docRef.set({'items': []});
          emit(WishlistLoaded([])); 
        }
      } else {
        debugPrint('User not authenticated');
        emit(WishlistError('Please log in to view your wishlist'));
      }
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
      emit(WishlistError('Failed to load wishlist: $e'));
    }
  }

  Future<void> _onAddItem(
    WishlistAddItem event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      if (authBloc.state is AuthAuthenticated) {
        final userId = (authBloc.state as AuthAuthenticated).user.uid;
        final docRef = firestore.collection('wishlists').doc(userId);
        final snapshot = await docRef.get();
        List<Product> wishlistItems = [];

        debugPrint('Adding item: ${event.product.title} for user: $userId');

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          wishlistItems = data['items'] != null
              ? (data['items'] as List)
                    .map(
                      (item) => Product.fromJson(item as Map<String, dynamic>),
                    )
                    .toList()
              : [];
        }

        if (!wishlistItems.any((item) => item.id == event.product.id)) {
          wishlistItems.add(event.product);
          await docRef.set({
            'items': wishlistItems.map((item) => item.toJson()).toList(),
          }, SetOptions(merge: true));
          debugPrint('Item added, new wishlist size: ${wishlistItems.length}');
          emit(WishlistLoaded(List.from(wishlistItems)));
        } else {
          debugPrint('Item already in wishlist');
          emit(WishlistLoaded(List.from(wishlistItems)));
        }
      } else {
        debugPrint('User not authenticated for add item');
        emit(WishlistError('Please log in to add to wishlist'));
      }
    } catch (e) {
      debugPrint('Error adding item: $e');
      emit(WishlistError('Failed to add item: $e'));
    }
  }

  Future<void> _onRemoveItem(
    WishlistRemoveItem event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      if (authBloc.state is AuthAuthenticated) {
        final userId = (authBloc.state as AuthAuthenticated).user.uid;
        final docRef = firestore.collection('wishlists').doc(userId);
        final snapshot = await docRef.get();
        List<Product> wishlistItems = [];

        debugPrint('Removing item: ${event.product.title} for user: $userId');

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          wishlistItems = data['items'] != null
              ? (data['items'] as List)
                    .map(
                      (item) => Product.fromJson(item as Map<String, dynamic>),
                    )
                    .toList()
              : [];
        }

        wishlistItems.removeWhere((item) => item.id == event.product.id);
        await docRef.set({
          'items': wishlistItems.map((item) => item.toJson()).toList(),
        }, SetOptions(merge: true));
        debugPrint('Item removed, new wishlist size: ${wishlistItems.length}');
        emit(WishlistLoaded(List.from(wishlistItems)));
      } else {
        debugPrint('User not authenticated for remove item');
        emit(WishlistError('Please log in to remove from wishlist'));
      }
    } catch (e) {
      debugPrint('Error removing item: $e');
      emit(WishlistError('Failed to remove item: $e'));
    }
  }
}
