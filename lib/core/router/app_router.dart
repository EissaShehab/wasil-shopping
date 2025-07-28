import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_state.dart';
import 'package:wasil_shopping/features/auth/views/auth_screen.dart';
import 'package:wasil_shopping/features/cart/views/cart_screen.dart';
import 'package:wasil_shopping/features/cart/views/checkout_screen.dart';
import 'package:wasil_shopping/features/main/views/main_screen.dart';
import 'package:wasil_shopping/features/products/models/product.dart';
import 'package:wasil_shopping/features/products/views/product_detail_screen.dart';
import 'package:wasil_shopping/features/products/views/product_list_screen.dart';
import 'package:wasil_shopping/features/profile/views/profile_screen.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_event.dart';
import 'package:wasil_shopping/features/wishlist/views/wishlist_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/main?index=0',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => WishlistBloc(
              context.read<AuthBloc>(),
              FirebaseFirestore.instance,
            ),
          ),
        ],
        child: MainScreen(child: child),
      ),
      routes: [
        GoRoute(
          path: '/main',
          builder: (context, state) {
            final index = int.parse(state.uri.queryParameters['index'] ?? '0');
            return index == 0
                ? const ProductListScreen()
                : index == 1
                ? const CartScreen()
                : index == 2
                ? const WishlistScreen()
                : const ProfileScreen();
          },
        ),
      ],
    ),
    GoRoute(
      path: '/product_detail',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            WishlistBloc(context.read<AuthBloc>(), FirebaseFirestore.instance)
              ..add(WishlistFetch()),
        child: ProductDetailScreen(product: state.extra as Product),
      ),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
  ],
  redirect: (context, state) {
    final authBloc = context.read<AuthBloc>();
    final isAuthenticated = authBloc.state is AuthAuthenticated;
    if (!isAuthenticated && state.uri.toString().startsWith('/checkout')) {
      return '/auth';
    }
    return null;
  },
);
