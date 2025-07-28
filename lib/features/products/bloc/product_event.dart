abstract class ProductEvent {}

class ProductFetch extends ProductEvent {}

class ProductSort extends ProductEvent {
  final String sortBy;
  ProductSort(this.sortBy);
}

class ProductFilter extends ProductEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  ProductFilter({this.category, this.minPrice, this.maxPrice});
}

class ProductSearch extends ProductEvent {
  final String query;
  ProductSearch(this.query);
}

class ProductLoadMore extends ProductEvent {}