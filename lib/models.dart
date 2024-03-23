import 'package:flutter/material.dart';


class ProductManager extends ChangeNotifier {
  static final ProductCategory all = ProductCategory.all();

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
        imagePath: "assets/product_images/case_weigher_front.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    all.addProduct(
      Product(
        name: "Sizer System",
        imagePath: "assets/product_images/sizer.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    all.addProduct(
      Product(
        name: "Trimline Station",
        imagePath: "assets/product_images/trimline_station.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 2",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 3",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 4",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 5",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 6",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 7",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 8",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 9",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 10",
        category: all.getItemByName("Indicators"),
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 11",
        category: all.getItemByName("Indicators"),
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
  ProductCategory? category;
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

  static Map<String, dynamic> mapListToBrochure(List<BrochureItem> brochure) {

    List<String> entries = [];
    List<dynamic> subheaders = [];
    final Map<String, dynamic> brochureMap = {};

    for (var item in brochure.reversed) {
      switch (item.runtimeType) {
        case BrochureEntry _ : {
          entries.add((item as BrochureEntry).entry);
        }
        case BrochureSubheader _ : {
          subheaders.add({(item as BrochureSubheader).subheader : entries});
          entries.clear();
        }
        case BrochureHeader _ : {
          brochureMap[(item as BrochureHeader).header] = [entries, subheaders];
          subheaders.clear();
          entries.clear();
        }
      }
    }

    return Map.fromEntries(brochureMap.entries);
  }

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
              Expanded(
                child: 
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                      Image.asset(
                        item.imagePath?.isNotEmpty ?? false ? item.imagePath! : 'assets/weightech_logo.png', // Handle if imagePath is null
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                  ),
              ),
              Text(item.name ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: Colors.black)), // Handle if name is null
              const SizedBox(height: 10),
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


abstract class BrochureItem {
  Widget buildItem(BuildContext context);
}

class BrochureHeader implements BrochureItem {
  String header;
  final TextEditingController controller;

  BrochureHeader({required this.header}) : controller = TextEditingController(text: header);
  BrochureHeader.basic() : header="New Header", controller = TextEditingController();

  @override
  Widget buildItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.menu, size: 30,), 
      title: TextFormField(
        controller: controller, 
        decoration: 
          InputDecoration(
            label: Text(header)
          ),
        validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      )
    );
  }


}

class BrochureSubheader implements BrochureItem {
  String subheader;
  final TextEditingController controller;

  BrochureSubheader({required this.subheader}) : controller = TextEditingController(text: subheader);
  BrochureSubheader.basic() : subheader="New Subheader", controller = TextEditingController();

  @override
  Widget buildItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50), 
      child: ListTile(
        leading: const Icon(Icons.menu, size: 30), 
        title: TextFormField(
          controller: controller, 
          decoration: 
            InputDecoration(
              label: Text(subheader)
            ),
          validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          textCapitalization: TextCapitalization.words, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,)
        )
      )
    );
  }
}

class BrochureEntry implements BrochureItem {
  String entry;
  final TextEditingController controller;

  BrochureEntry({required this.entry}) : controller = TextEditingController(text: entry);

  BrochureEntry.basic() : entry="New Entry", controller = TextEditingController();

  @override
  Widget buildItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 100), 
      child: 
        ListTile(
          leading: const Icon(Icons.menu, size: 30), 
          title: TextFormField(
            controller: controller,
            decoration: 
              InputDecoration(
                label: Text(entry)
              ),
            validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          )
        )
    );
  }
}