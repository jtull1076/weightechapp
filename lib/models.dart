import 'package:flutter/material.dart';


class ProductCategory {
  late String name;
  ProductCategory? parent;
  late List<ProductCategory> subcategories;
  late List<Product> products;
  static const String buttonRoute = '/listing';

  ProductCategory({
    required this.name,
    this.parent,
    List<ProductCategory>? subcategories,
    List<Product>? products
  }) : subcategories = subcategories ?? [], products = products ?? [];

  ProductCategory.all() : name='All';

  // Function to add a product to the list
  void addProduct(Product product) {
    products.add(product);
  }

  void addCategory(ProductCategory category){
    subcategories.add(category);
  }

  // Function to remove a product from the list
  void removeProduct(Product product) {
    products.remove(product);
  }

  void removeCategory(ProductCategory category){
    subcategories.remove(category);
  }

  // Function to get all products
  List<Product> getAllProducts() {
    return products;
  }

  // Function to get products by category
  List<Product> getProductsByCategory(String category) {
    return products.where((product) => product.category == category).toList();
  }
}


class Product {
  String? name;
  String? modelNumber;
  double? price;
  String? category;
  String? imagePath;
  String? description;
  Map<String, dynamic>? brochure;
  static const String buttonRoute = '/product';

  Product({
    this.name,
    this.modelNumber,
    this.price,
    this.category,
    this.imagePath,
    this.description,
    this.brochure,
  });
}


class CatalogItemTile extends StatelessWidget {
  final Product product;

  const CatalogItemTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.white,
      shadowColor: const Color(0xFF224190),
      margin: const EdgeInsets.all(10.0),
      child: Stack( 
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                  Image.asset(
                    product.imagePath ?? '', // Handle if imagePath is null
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
              ),
              Expanded(child: Text(product.name ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: Color(0xFF000000)))), // Handle if name is null
              // You can add more widgets to display additional information
            ],
          ),
          Positioned.fill(
            child: 
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {debugPrint('Product tapped: ${product.name}');}
                  )
              )
          )
        ]
      )
    );
  }
}