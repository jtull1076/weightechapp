import 'package:flutter/material.dart';


class ProductManager extends ChangeNotifier {
  final ProductCategory all = ProductCategory.all();

  ProductManager() {
    all.addCategory(
      ProductCategory(
        name: "Microweigh Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        parent: all,
      ),
    );
    all.addProduct(
      Product(
        name: "Case Weigher",
        category: "In-Line Weighers",
        imagePath: "assets/product_images/case_weigher_front.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    all.addProduct(
      Product(
        name: "Sizer System",
        category: "Sizers",
        imagePath: "assets/product_images/sizer.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    all.addProduct(
      Product(
        name: "Trimline Station",
        category: "Trimlines",
        imagePath: "assets/product_images/trimline_station.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 2",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 3",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 4",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 5",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 6",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 7",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 8",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 9",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 10",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 11",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
  }


  List<ProductCategory> getAllCategories(ProductCategory? category) {
    final ProductCategory root = category ?? all;

    List<ProductCategory> allCategories = [];

    void traverseCategories(ProductCategory category) {
      allCategories.add(category); // Add the current category to the list

      // Traverse subcategories recursively
      for (var subcategory in category.subcategories) {
        traverseCategories(subcategory);
      }
    }

    traverseCategories(root);

    return allCategories;
  }

}


class ProductCategory {
  late String name;
  ProductCategory? parent;
  late List<ProductCategory> subcategories;
  late List<Product> products;
  String? imagePath;
  static const String buttonRoute = '/listing';

  ProductCategory({
    required this.name,
    required parent,
    List<ProductCategory>? subcategories,
    List<Product>? products,
    String? imagePath,
  }) : subcategories = subcategories ?? [], products = products ?? [], imagePath = imagePath ?? '';

  ProductCategory.all() : name='All', subcategories = [], products = [];

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

  List<dynamic> getAllCatalogItems() {
    List<dynamic> catalogItems = [];
    catalogItems.addAll(subcategories);
    catalogItems.addAll(products);
    return catalogItems;
  }

  dynamic getItemByName(String? name) {
    if (name == null || name.isEmpty) {
      // Handle null argument
      return null;
    }

    // Check if the item exists in subcategories
    for (var category in subcategories) {
      if (category.name == name) {
        return category;
      }
    }

    // Check if it exists in products
    for (var product in products) {
      if (product.name == name) {
        return product;
      }
    }

    // If the item is not found in subcategories or products, return null
    return null;
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
  final dynamic item;
  final VoidCallback onTapCallback;

  const CatalogItemTile({super.key, required this.item, required this.onTapCallback});

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.white,
      shadowColor: const Color(0xAA000000),
      margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0, top: 30.0),
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
                    item.imagePath?.isNotEmpty ?? false ? item.imagePath! : 'assets/weightech_logo.png', // Handle if imagePath is null
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
              ),
              Expanded(child: Text(item.name ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: Colors.black))), // Handle if name is null
              // You can add more widgets to display additional information
            ],
          ),
          Positioned.fill(
            child: 
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    debugPrint('Item tapped: ${item.name}');
                    onTapCallback();
                  }
                )
              )
          )
        ]
      )
    );
  }
}