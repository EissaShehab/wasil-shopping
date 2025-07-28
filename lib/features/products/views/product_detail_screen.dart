// lib/features/products/views/product_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wasil_shopping/core/utils/toast_utils.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_state.dart';
import 'package:wasil_shopping/features/cart/bloc/cart_bloc.dart';
import 'package:wasil_shopping/features/products/models/product.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_event.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_state.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.go('/main?index=0'),
        ),
        title: Text(
          widget.product.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          BlocBuilder<WishlistBloc, WishlistState>(
            builder: (context, state) {
              final isInWishlist =
                  state is WishlistLoaded &&
                  state.wishlistItems.any(
                    (item) => item.id == widget.product.id,
                  );
              return IconButton(
                icon: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  if (context.read<AuthBloc>().state is! AuthAuthenticated) {
                    ToastUtils.showToast(
                      'Please log in to manage your wishlist',
                      isError: true,
                    );
                    context.go('/auth');
                    return;
                  }
                  if (isInWishlist) {
                    context.read<WishlistBloc>().add(
                      WishlistRemoveItem(widget.product),
                    );
                    ToastUtils.showToast(
                      '${widget.product.title} removed from wishlist',
                    );
                  } else {
                    context.read<WishlistBloc>().add(
                      WishlistAddItem(widget.product),
                    );
                    ToastUtils.showToast(
                      '${widget.product.title} added to wishlist',
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product_${widget.product.id}',
              child: CachedNetworkImage(
                imageUrl: widget.product.thumbnail,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 300,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                        color: quantity > 1
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      Text(
                        '$quantity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => quantity++),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (context.read<AuthBloc>().state
                          is! AuthAuthenticated) {
                        ToastUtils.showToast(
                          'Please log in to add to cart',
                          isError: true,
                        );
                        context.go('/auth');
                        return;
                      }
                      context.read<CartBloc>().add(
                        CartAddItem(widget.product, quantity),
                      );
                      ToastUtils.showToast(
                        '${widget.product.title} added to cart',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        height: 56,
                        child: Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
