import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shortid/shortid.dart';
import 'dart:io';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/brochure.dart';

class ProductManager {
  static ProductCategory? all;
  static String? name;
  static DateTime? timestamp;

  ProductManager._();

  static Future<void> create() async {
    try {
      Map<String, dynamic> catalogJson = await getCatalogFromFirestore();
      all = ProductCategory.fromJson(catalogJson);
      // _restructureDatabase();
      // timestamp = DateTime.fromMillisecondsSinceEpoch(catalogJson["timestamp"].millisecondsSinceEpoch);
      name = catalogJson["catalogName"];
    } catch (e) {
      rethrow;
    }
  }


  static Future<void> createFromMap(Map<String, dynamic> catalogJson) async {
    try {
      all = ProductCategory.fromJson(catalogJson);
      name = catalogJson["catalogName"];
    } catch (e) {
      rethrow;
    }
  }


  static void _restructureDatabase() {
    final ProductCategory root = all!;

    void traverseCategories(ProductCategory category) {
      // Traverse subcategories recursively
      for (var item in category.catalogItems) {
        if (item is Product) {
          item.productMedia = [];
          String baseRefName = item.id;
          int i = 0;

          for (var url in item.productMedia?.map((x) => x['downloadUrl']).toList() ?? []) {
            String name = '${baseRefName}_$i';
            String extension = '';

            if (url.contains('.mp4?')) {
              extension = 'mp4';
            }
            else if (url.contains('.png?')){
              extension = 'png';
            }
            else if (url.contains('.jpeg') || (url.contains('.jpg'))) {
              extension = 'jpeg';
            }

            item.productMedia!.add({
              'name': name,
              'contentType': (extension == 'mp4' ? 'video' : 'image'),
              'fileType': extension,
              'downloadUrl': url,
            });
            i++;
          }
        }
        else {
          traverseCategories(item as ProductCategory);
        }
      }
    }

    traverseCategories(root);
    postCatalogToFirestore();
  }

  List<ProductCategory> getAllCategories(ProductCategory? category) {
    final ProductCategory root = category ?? all!;

    List<ProductCategory> allCategories = [];

    void traverseCategories(ProductCategory category) {
      allCategories.add(category); // Add the current category to the list

      // Traverse subcategories recursively
      for (var item in category.catalogItems) {
        if (item.runtimeType == ProductCategory) {
          traverseCategories(item as ProductCategory);
        }
      }
    }

    traverseCategories(root);

    return allCategories;
  }

  static CatalogItem? getItemById(String id, {ProductCategory? category}) {
    final ProductCategory root = category ?? all!;

    CatalogItem? result;

    void traverseItems(ProductCategory category) {
      if (category.id == id) {
        result = category;
        return;
      }
      for (var item in category.catalogItems) {
        switch (item) {
          case ProductCategory _: {
            traverseItems(item);
            if (result != null) {
              return;
            }
          }
          case Product _: {
            if (item.id == id) {
              result = item;
            }
          }
        }
      }
    }

    traverseItems(root);

    return result;
  }

  static Future<void> postCatalogToFirestore({String? name}) async {
    Log.logger.t("Posting catalog to Firestore");
    Map<String,dynamic> catalogJson = all!.toJson();
    catalogJson['timestamp'] = DateTime.now();
    catalogJson['catalogName'] = name;
    try {
      await FirebaseUtils.postCatalogToFirestore(catalogJson);
    } catch (e) {
      rethrow;
    }
    Log.logger.t(" -> done.");
  }

  static Future<Map<String,dynamic>> getCatalogFromFirestore() async {
    Log.logger.t("Retrieving catalog from Firestore");
    return await FirebaseUtils.getCatalogFromFirestore();
  }
}

sealed class CatalogItem {
  final String id;
  late String name;
  late String? parentId;
  String? imageUrl;
  ImageProvider? imageProvider;

  CatalogItem({required this.name, this.parentId, String? id, this.imageUrl, BuildContext? context}) 
  : id = id ?? shortid.generate()
  {
    if (imageUrl != null) {
      try {
        imageProvider = CachedNetworkImageProvider(imageUrl!);
      } on HttpExceptionWithStatus catch (e) {
        Log.logger.e("Failed to retrieve image at $imageUrl. Error: $e");
        imageUrl = null;
        imageProvider = Image.asset('assets/weightech_logo.png').image;
      }
    }
    else {
      imageProvider = Image.asset('assets/weightech_logo.png').image;
    }
  }

  Widget buildCard(VoidCallback onTapCallback) {
    return Card(
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 30.0, top: 30.0),
      child: Stack( 
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                            // Expanded(
              //   child: 
              //     Container (
              //       alignment: Alignment.center,
              //       padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 30, bottom: 14),
              //       child: ClipRRect(
              //           borderRadius: BorderRadius.circular(10),
              //           child: Image(image: ResizeImage(imageProvider!, policy: ResizeImagePolicy.fit, height: 400, width: 400), fit: BoxFit.fitWidth,),
              //       ),
              //     )
              // ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10,15,10,15),
                  child: Container (
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20, bottom: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: ResizeImage(
                          imageProvider!,
                          policy: ResizeImagePolicy.fit,
                          height: 400,
                        )
                      )
                    ),
                  )
                )
              ),
              Container(
                height: 25,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name, 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontSize: 16.0, color: Colors.black)
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          Positioned.fill(
            child: 
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Log.logger.t('Item tapped: $name');
                    onTapCallback();
                  }
                )
              )
          )
        ]
      )
    );
  }

  Widget buildListTile({int? index}) {
    return ListTile(title: Text(name));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'imageUrl': imageUrl,
    };
  }

  static CatalogItem fromJson(Map<String, dynamic> json) {
    if (json['catalogItems'] != null) {
      return ProductCategory.fromJson(json);
    }
    else {
      return Product.fromJson(json);
    }
  }

  ProductCategory? getParentById() {
    if (parentId != null) {
      return ProductManager.getItemById(parentId!) as ProductCategory;
    }
    Log.logger.t("Parent doesn't exist");
    return null;
  }

  void storeImage(File imageFile) {
    final storageRef = FirebaseUtils.storage.ref("devImages");
    final categoryImageRef = storageRef.child("${id}_0");
    try {
      categoryImageRef.putFile(imageFile);
    } on FirebaseException catch (e) {
      Log.logger.t("Failed to add ${id}_0 to Firebase. Error code: ${e.code}");
    }
  }
}

class ProductCategory extends CatalogItem {
  late List<CatalogItem> catalogItems;
  static const String buttonRoute = '/listing';

  ProductCategory({
    required super.name,
    super.id,
    super.parentId,
    super.imageUrl,
    List<CatalogItem>? catalogItems,
  }) : catalogItems = catalogItems ?? [];

  ProductCategory.temp() : this(name: '');

  ProductCategory.all() : catalogItems = [], super(name: 'All');

  // Function to add a product to the list1
  void addProduct(Product product) {
    product.parentId = id;
    catalogItems.add(product);
  }

  void addCategory(ProductCategory category){
    category.parentId = id;
    catalogItems.add(category);
  }

  // Function to remove a product from the list
  void removeProduct(Product product) {
    catalogItems.remove(product);
  }

  void removeCategory(ProductCategory category){
    catalogItems.remove(category);
  }

  // Function to get all products
  List<Product> getAllProducts() {
    return catalogItems.where((item) => item.runtimeType == Product).toList() as List<Product>;
  }

  List<dynamic> getAllCatalogItems() {
    return catalogItems;
  }

  dynamic getItemByName(String? name) {
    if (name == null || name.isEmpty) {
      // Handle null argument
      return null;
    }

    // Check if the item exists in subcategories
    for (var item in catalogItems) {
      if (item.name == name) {
        return item;
      }
    }

    // If the item is not found in subcategories or products, return null
    return null;
  }

  void addProductByParentId(Product newProduct) {
    if (id == newProduct.parentId) {
      addProduct(newProduct);
      Log.logger.t('${newProduct.name} (id: ${newProduct.id}) added to $name (id: $id)');
      return;
    }
    for (var item in catalogItems) {
      if (item is ProductCategory && item.id == newProduct.parentId) {
        item.addProduct(newProduct);
        Log.logger.t('${newProduct.name} (id: ${newProduct.id}) added to ${item.name} (id: ${item.id})');
        return;
      }
    }
    // If not found in the current category, recursively search in subcategories
    for (var item in catalogItems) {
      if (item is ProductCategory) {
        item.addProductByParentId(newProduct); // Recursively search in subcategories
      }
    }
    Log.logger.t('Parent category with ID ${newProduct.parentId} not found in category $name (id: $id).');
  }

  
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['catalogItems'] = catalogItems.map((item) => item.toJson()).toList();
    return json;
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    // Log.logger.t("Converting the following JSON to a ProductCategory. Here's the JSON:");
    // Log.logger.t("------");
    // Log.logger.t((const JsonEncoder.withIndent('   ')).convert(json));
    // Log.logger.t("------");
    return ProductCategory(
      name: json['name'],
      id: json['id'],
      parentId: json['parentId'],
      imageUrl: json['imageUrl'],
      catalogItems: (json['catalogItems'] as List<dynamic>).map((itemJson) => CatalogItem.fromJson(itemJson)).toList()
    );
  }

}

class Product extends CatalogItem {
  String? modelNumber;
  List<Map<String, dynamic>>? productMedia;
  String? description;
  List<Map<String, dynamic>>? brochure;
  static const String buttonRoute = '/product';

  Product({
    required super.name,
    super.parentId,
    super.id,
    String? imageUrl,
    this.productMedia,
    this.modelNumber,
    this.description,
    this.brochure,
    BuildContext? context,
  }) : super(imageUrl: imageUrl ?? ((productMedia?.isNotEmpty ?? false) ? productMedia![0]['downloadUrl'] : null))
  {
    productMedia ??= [];
  }

  Product.temp() : this(name: '');
  

  List<BrochureItem> retrieveBrochureList() {
    Log.logger.t("Retrieving brochure list...");

    List<BrochureItem> brochureList = [];

    if (brochure == null) {
      return brochureList;
    }
    else {
      for (var mapItem in brochure!) {
        String key = mapItem.keys.first;
        brochureList.add(BrochureHeader(text: key));
        if (mapItem[key] is List) {
          for (var item in mapItem[key]) {
            item.forEach((key, value) {
              if (key == "Entries") {
                for (var entry in value) {
                  brochureList.add(BrochureEntry(text: entry));
                }
              }
              else {
                String subKey = key;
                brochureList.add(BrochureSubheader(text: subKey));
                for (var entry in item[subKey]) {
                  brochureList.add(BrochureEntry(text: entry));
                }
              }
            });
          }
        }
        else if (mapItem[key] is Map) {
          mapItem[key].forEach((key, value) {
            if (key == "Entries") {
              for (var entry in value) {
                brochureList.add(BrochureEntry(text: entry));
              }
            }
            else {
              String subKey = key;
              brochureList.add(BrochureSubheader(text: subKey));
              for (var entry in mapItem[key][subKey]) {
                brochureList.add(BrochureEntry(text: entry));
              }
            }
          });
        }
      }
    }

    Log.logger.t(" -> done.");
    return brochureList;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['modelNumber'] = modelNumber;
    json['description'] = description;
    json['brochure'] = brochure;
    json['parentId'] = parentId;
    json['media'] = productMedia;
    return json;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      id: json['id'],
      modelNumber: json['modelNumber'],
      description: json['description'],
      brochure: List<Map<String,dynamic>>.from(json['brochure']),
      parentId: json['parentId'],
      productMedia: List<Map<String, dynamic>>.from(json['media'] ?? []),
    );
  }

  void storeListOfImages(List<File> imageFiles){
    final storageRef = FirebaseUtils.storage.ref("devImages");
    for ( int i=0 ; i < imageFiles.length ; i++ ) {
      final imageRef = storageRef.child("${id}_$i");
      try {
        imageRef.putFile(imageFiles[i]);
      } on FirebaseException catch (e) {
        Log.logger.t("Failed to add ${id}_$i to Firebase. Error code: ${e.code}");
      }
    }
  }
}