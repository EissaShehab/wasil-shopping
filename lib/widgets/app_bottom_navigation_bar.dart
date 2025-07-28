import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_state.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_event.dart';
import 'package:wasil_shopping/features/wishlist/bloc/wishlist_state.dart';

class AppBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNavigationBar> createState() => _AppBottomNavigationBarState();
}

class _AppBottomNavigationBarState extends State<AppBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.currentIndex >= 0) {
      _controller.forward();
    }
    // تحميل قائمة المفضلة فقط إذا كان المستخدم مسجل دخول
    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      context.read<WishlistBloc>().add(WishlistFetch());
    }
  }

  @override
  void didUpdateWidget(covariant AppBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      builder: (context, wishlistState) {
        final wishlistCount = wishlistState is WishlistLoaded
            ? wishlistState.wishlistItems.length
            : 0;

        return CrystalNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          height: 60,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.8),
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).colorScheme.primary,
          outlineBorderColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.3),
          borderWidth: 2,
          margin: const EdgeInsets.all(10),
          itemPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          items: [
            CrystalNavigationBarItem(
              icon: IconlyBold.home,
              unselectedIcon: IconlyLight.home,
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            CrystalNavigationBarItem(
              icon: IconlyBold.bag,
              unselectedIcon: IconlyLight.bag,
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            CrystalNavigationBarItem(
              icon: IconlyBold.heart,
              unselectedIcon: IconlyLight.heart,
              selectedColor: Theme.of(context).colorScheme.primary,
              badge: wishlistCount > 0
                  ? Badge(
                      label: Text(
                        "$wishlistCount",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            CrystalNavigationBarItem(
              icon: IconlyBold.user_2,
              unselectedIcon: IconlyLight.user,
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        );
      },
    );
  }
}
