import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconly/iconly.dart';
import 'package:wasil_shopping/core/constants/constants.dart';
import 'package:wasil_shopping/core/utils/toast_utils.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_event.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_state.dart';
import 'package:wasil_shopping/features/cart/bloc/cart_bloc.dart';
import 'package:wasil_shopping/features/products/bloc/product_bloc.dart';
import 'package:wasil_shopping/features/products/bloc/product_event.dart';
import 'package:wasil_shopping/features/products/bloc/product_state.dart';
import 'package:wasil_shopping/features/products/models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    context.read<ProductBloc>().add(ProductFetch());
    _searchController.addListener(() {
      context.read<ProductBloc>().add(ProductSearch(_searchController.text));
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
  if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7 && // 70% of the way down
      context.read<ProductBloc>().state is ProductLoaded &&
      !context.read<ProductBloc>().isFetching) { // استخدام getter بدلاً من _isFetching
    context.read<ProductBloc>().add(ProductLoadMore());
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: MediaQuery.of(context).size.width * 0.55,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(IconlyLight.search, color: Theme.of(context).colorScheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(IconlyLight.close_square, color: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductBloc>().add(ProductSearch(''));
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthUnauthenticated) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    label: const Text('Guest'),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return IconButton(
                icon: Icon(IconlyLight.logout, color: Theme.of(context).colorScheme.error, size: 24),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogout());
                  ToastUtils.showToast('Logged out successfully');
                },
                tooltip: 'Logout',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(IconlyLight.filter, color: Colors.amber, size: 24),
              onPressed: () => _showFilterSortDialog(context),
              tooltip: 'Filter & Sort',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoaded && state.isCached) {
                return Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.info_circle, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Offline: Cached products',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 120,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    SizedBox(height: 12, width: double.infinity),
                                    SizedBox(height: 4),
                                    SizedBox(height: 8, width: 80),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (state is ProductLoadingMore) {
                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length + 1, // +1 لمؤشر التحميل
                    itemBuilder: (context, index) {
                      if (index == state.products.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final product = state.products[index];
                      return AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.scale(
                              scale: 0.95 + (_fadeAnimation.value * 0.05),
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  onTap: () => context.push('/product_detail', extra: product),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.surface,
                                          Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surfaceVariant,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Hero(
                                          tag: 'product_${product.id}',
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: CachedNetworkImage(
                                              imageUrl: product.thumbnail,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor: Colors.grey[100]!,
                                                child: Container(
                                                  height: 120,
                                                  color: Theme.of(context).colorScheme.surface,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    product.title,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${product.price.toStringAsFixed(2)}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.secondary,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                                const Spacer(),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: FloatingActionButton(
                                                    onPressed: () => _showQuantityDialog(context, product),
                                                    mini: true,
                                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                                    child: Icon(
                                                      IconlyBold.buy,
                                                      color: Theme.of(context).colorScheme.onPrimary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
                if (state is ProductError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IconlyBold.danger, size: 60, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<ProductBloc>().add(ProductFetch()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyBold.search, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductBloc>().add(ProductSearch(''));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: Text(
                                  'Clear Search',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length + (state.total! > state.products.length ? 1 : 0), // +1 لمؤشر التحميل إذا كان هناك المزيد
                    itemBuilder: (context, index) {
                      if (index == state.products.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final product = state.products[index];
                      return AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.scale(
                              scale: 0.95 + (_fadeAnimation.value * 0.05),
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  onTap: () => context.push('/product_detail', extra: product),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.surface,
                                          Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surfaceVariant,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Hero(
                                          tag: 'product_${product.id}',
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: CachedNetworkImage(
                                              imageUrl: product.thumbnail,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor: Colors.grey[100]!,
                                                child: Container(
                                                  height: 120,
                                                  color: Theme.of(context).colorScheme.surface,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    product.title,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${product.price.toStringAsFixed(2)}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.secondary,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                                const Spacer(),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: FloatingActionButton(
                                                    onPressed: () => _showQuantityDialog(context, product),
                                                    mini: true,
                                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                                    child: Icon(
                                                      IconlyBold.buy,
                                                      color: Theme.of(context).colorScheme.onPrimary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
                return const Center(child: Text('Unexpected state'));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSortDialog(BuildContext context) {
    String? filterCategory;
    double? minPrice;
    double? maxPrice;
    String? errorMessage;
    String? sortBy;
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: Text('Filter & Sort', style: Theme.of(context).textTheme.titleLarge),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Sort'),
                    Tab(text: 'Filter'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
                Container(
                  height: 200,
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.secondary),
                              title: const Text('Price (Low to High)'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () => setState(() => sortBy = 'price'),
                              trailing: Radio<String>(
                                value: 'price',
                                groupValue: sortBy,
                                onChanged: (value) => setState(() => sortBy = value),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.category, color: Theme.of(context).colorScheme.secondary),
                              title: const Text('Category (A-Z)'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () => setState(() => sortBy = 'category'),
                              trailing: Radio<String>(
                                value: 'category',
                                groupValue: sortBy,
                                onChanged: (value) => setState(() => sortBy = value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      BlocBuilder<ProductBloc, ProductState>(
                        builder: (context, state) {
                          final categories = state is ProductLoaded ? state.categories : <String>[];
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Category',
                                        prefixIcon: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      hint: const Text('Select Category'),
                                      value: filterCategory,
                                      items: categories.map((category) => DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category),
                                      )).toList(),
                                      onChanged: (value) => setState(() => filterCategory = value),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Min Price',
                                        prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        errorText: errorMessage,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          minPrice = double.tryParse(value);
                                          if (minPrice != null && maxPrice != null && minPrice! > maxPrice!) {
                                            errorMessage = 'Min price cannot be greater than max price';
                                          } else {
                                            errorMessage = null;
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Max Price',
                                        prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        errorText: errorMessage,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          maxPrice = double.tryParse(value);
                                          if (minPrice != null && maxPrice != null && minPrice! > maxPrice!) {
                                            errorMessage = 'Min price cannot be greater than max price';
                                          } else {
                                            errorMessage = null;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _searchController.clear();
                context.read<ProductBloc>().add(ProductSearch(''));
                context.read<ProductBloc>().add(ProductFilter());
                Navigator.pop(context);
                ToastUtils.showToast('Filters and search reset');
              },
              child: Text('Reset', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            TextButton(
              onPressed: errorMessage == null
                  ? () {
                      if (sortBy != null) {
                        context.read<ProductBloc>().add(ProductSort(sortBy!));
                      }
                      context.read<ProductBloc>().add(
                        ProductFilter(
                          category: filterCategory,
                          minPrice: minPrice,
                          maxPrice: maxPrice,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Product product) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${product.title} to Cart', style: Theme.of(context).textTheme.titleLarge),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quantity: $quantity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: Theme.of(context).colorScheme.primary),
                      onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                    ),
                    Text(
                      '$quantity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: Icon(IconlyLight.plus, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          TextButton(
            onPressed: () {
              context.read<CartBloc>().add(CartAddItem(product, quantity));
              ToastUtils.showToast('${product.title} added to cart!');
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}