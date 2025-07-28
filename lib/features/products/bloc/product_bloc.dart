import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasil_shopping/core/services/api_service.dart';
import 'package:wasil_shopping/features/products/models/product.dart';
import 'package:wasil_shopping/core/utils/toast_utils.dart';
import 'package:wasil_shopping/features/products/bloc/product_event.dart';
import 'package:wasil_shopping/features/products/bloc/product_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = [];
  static const String _productsCacheKey = 'cached_products';
  int _currentSkip = 0;
  static const int _limit = 50; // عدد المنتجات لكل صفحة
  bool _isFetching = false;

  ProductBloc() : super(ProductInitial()) {
    on<ProductFetch>(_onFetch);
    on<ProductLoadMore>(_onLoadMore); // حدث جديد للتحميل التدريجي
    on<ProductSort>(_onSort);
    on<ProductFilter>(_onFilter);
    on<ProductSearch>(_onSearch);
    add(ProductFetch());
  }

  // Getter عام للوصول إلى _isFetching
  bool get isFetching => _isFetching;

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _cacheProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_productsCacheKey, productsJson);
    } catch (e) {
      ToastUtils.showToast('Error caching products: $e', isError: true);
    }
  }

  Future<List<Product>> _getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getStringList(_productsCacheKey);
      if (productsJson != null) {
        return productsJson.map((json) => Product.fromJson(jsonDecode(json))).toList();
      }
      return [];
    } catch (e) {
      ToastUtils.showToast('Error loading cached products: $e', isError: true);
      return [];
    }
  }

  Future<void> _onFetch(ProductFetch event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final isConnected = await _checkInternetConnection();
      if (!isConnected) {
        _products = await _getCachedProducts();
        if (_products.isNotEmpty) {
          _filteredProducts = List.from(_products);
          _categories = _products.map((p) => p.category).toSet().toList();
          emit(ProductLoaded(_filteredProducts, _categories, isCached: true));
          ToastUtils.showToast('Loaded cached products (offline mode)');
          return;
        } else {
          emit(ProductError('No internet connection and no cached products available'));
          ToastUtils.showToast('No internet connection and no cached products', isError: true);
          return;
        }
      }

      _currentSkip = 0;
      final result = await _apiService.fetchProducts(_limit, _currentSkip);
      _products = result['products'];
      final total = result['total'];
      await _cacheProducts(_products);
      _filteredProducts = List.from(_products);
      _categories = _products.map((p) => p.category).toSet().toList();
      emit(ProductLoaded(_filteredProducts, _categories, total: total));
    } catch (e) {
      _products = await _getCachedProducts();
      if (_products.isNotEmpty) {
        _filteredProducts = List.from(_products);
        _categories = _products.map((p) => p.category).toSet().toList();
        emit(ProductLoaded(_filteredProducts, _categories, isCached: true));
        ToastUtils.showToast('Failed to load products, using cached data: $e', isError: true);
      } else {
        emit(ProductError('Failed to load products: $e'));
        ToastUtils.showToast('Failed to load products', isError: true);
      }
    }
  }

  Future<void> _onLoadMore(ProductLoadMore event, Emitter<ProductState> emit) async {
    if (isFetching || state is! ProductLoaded) return; // استخدام الgetter هنا
    final currentState = state as ProductLoaded;
    if (_products.length >= currentState.total!) return;

    emit(ProductLoadingMore(currentState.products, currentState.categories, currentState.total, currentState.isCached));
    try {
      _isFetching = true;
      _currentSkip += _limit;
      final result = await _apiService.fetchProducts(_limit, _currentSkip);
      final newProducts = result['products'];
      _products.addAll(newProducts);
      _filteredProducts = List.from(_products);
      emit(ProductLoaded(_filteredProducts, currentState.categories, total: currentState.total, isCached: currentState.isCached));
    } catch (e) {
      emit(ProductLoaded(currentState.products, currentState.categories, total: currentState.total, isCached: currentState.isCached));
      ToastUtils.showToast('Failed to load more products: $e', isError: true);
    } finally {
      _isFetching = false;
    }
  }

  void _onSort(ProductSort event, Emitter<ProductState> emit) {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;
    final sortedProducts = List<Product>.from(_filteredProducts);
    if (event.sortBy == 'price') {
      sortedProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (event.sortBy == 'category') {
      sortedProducts.sort((a, b) => a.category.compareTo(b.category));
    }
    emit(ProductLoaded(sortedProducts, currentState.categories, total: currentState.total, isCached: currentState.isCached));
  }

  void _onFilter(ProductFilter event, Emitter<ProductState> emit) {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;
    _filteredProducts = _products.where((product) {
      bool matchesCategory = event.category == null || event.category!.isEmpty || product.category == event.category;
      bool matchesPrice = (event.minPrice == null || product.price >= event.minPrice!) &&
          (event.maxPrice == null || product.price <= event.maxPrice!);
      return matchesCategory && matchesPrice;
    }).toList();
    emit(ProductLoaded(_filteredProducts, currentState.categories, total: currentState.total, isCached: currentState.isCached));
  }

  void _onSearch(ProductSearch event, Emitter<ProductState> emit) {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;
    if (event.query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((product) {
        return product.title.toLowerCase().contains(event.query.toLowerCase()) ||
               product.description.toLowerCase().contains(event.query.toLowerCase());
      }).toList();
    }
    emit(ProductLoaded(_filteredProducts, currentState.categories, total: currentState.total, isCached: currentState.isCached));
  }
}