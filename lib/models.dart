import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:shortid/shortid.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weightechapp/utils.dart';
import 'package:string_validator/string_validator.dart' show isURL;




class ProductManager {
  static ProductCategory? all;
  static DateTime? timestamp;
  static bool isBackup = false;

  ProductManager._();

  static Future<void> create() async {
    Map<String, dynamic> catalogJson;

    try {
      catalogJson = await getCatalogFromFirestore();
      all = ProductCategory.fromJson(catalogJson);
      if (await _thisBackupExists(refId: FirebaseUtils.catalogReferenceId!)) {
        Log.logger.t("Backup already exists for catalog with reference ${FirebaseUtils.catalogReferenceId}");
      }
      else {
        Log.logger.t("Creating backup for catalog with reference ${FirebaseUtils.catalogReferenceId}...");
        await backupCatalog();
        Log.logger.t("Backup created successfully.");
      }
    } catch (e) {
      if (FirebaseUtils.connectionMade) {
        Log.logger.t("Error fetching Firebase catalog.");
        rethrow;
      }
      else {
        Log.logger.t("Error with Firebase connection. Checking for backups...");
        if (await _anyBackupExists()) {
          Log.logger.t("Backup found.");
          catalogJson = await _getBackupCatalog();
        }
        else {
          Log.logger.w("No backups found.");
          throw("No backups found.");
        }
      }
    }

    all = ProductCategory.fromJson(catalogJson);
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

  static Future<void> postCatalogToFirestore() async {
    Log.logger.t("Posting catalog to Firestore");
    Map<String,dynamic> catalogJson = all!.toJson();
    catalogJson['timestamp'] = DateTime.now();
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

  static Future<Map<String,dynamic>> _getBackupCatalog() async {
    Directory defaultBackupDirectory = (await getExternalStorageDirectory())!;
    Directory backupDirectory = Directory('${defaultBackupDirectory.path}/backups');

    final List<FileSystemEntity> entities = await backupDirectory.list().toList();
    final Iterable<File> files = entities.whereType<File>();

    File backupFile = files.where((element) => extension(element.path) == '.txt',).first;

    try {
      String backupString = backupFile.readAsStringSync();
      Map<String,dynamic> catalog = jsonDecode(backupString);
      Log.logger.i("Backup retrieve with reference ${basenameWithoutExtension(backupFile.path)}.");
      return catalog;
    } catch (e) {
      throw();
    }
  }

  static Future<bool> _thisBackupExists({required String refId}) async {
    Directory defaultBackupDirectory = (await getExternalStorageDirectory())!;
    return await File('${defaultBackupDirectory.path}/backups/$refId.txt').exists();
  }

  static Future<bool> _anyBackupExists() async {
    Directory defaultBackupDirectory = (await getExternalStorageDirectory())!;
    return Directory('${defaultBackupDirectory.path}/backups').existsSync();
  }

  static Future<void> backupCatalog({Directory? directory}) async {
    directory ??= (await getExternalStorageDirectory())!;
    File backupFile = await File('${directory.path}/backups/${FirebaseUtils.catalogReferenceId}.txt').create(recursive: true);
    
    ProductCategory copyOfAll = ProductCategory.fromJson(all!.toJson());
    
    try {
      await _storeBackupImages(catalog: copyOfAll, directory: directory).then((_) {
        backupFile.writeAsString(jsonEncode(copyOfAll), mode: FileMode.write);
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _storeBackupImages({required ProductCategory catalog, required Directory directory}) async {
    Directory imageDirectory = await Directory('${directory.path}/backups/images').create(recursive: true);
    final List<FileSystemEntity> entities = await imageDirectory.list().toList();

    for (var entity in entities) {
      entity.deleteSync();
    }

    Future<void> traverseCatalog(CatalogItem item) async {
      switch (item) {
        case ProductCategory _ : {
          if (item.imageUrl != null) {
            FirebaseUtils.downloadFromFirebaseStorage(url: item.imageUrl!, directory: imageDirectory).then((value) {
              item.imageUrl = value;
            });
          }
          for (var subItem in item.catalogItems) {
            await traverseCatalog(subItem);
          }
        }
        case Product _ : {
          if (item.productMediaUrls?.isNotEmpty ?? false) {
            for (int i = 0; i < item.productMediaUrls!.length; i++) {
              FirebaseUtils.downloadFromFirebaseStorage(url: item.productMediaUrls![i], directory: imageDirectory).then((value) {
                item.productMediaUrls![i] = value!;
                if (i==0) {
                  item.imageUrl = value;
                }
              });
            }
          }
        }
      }
    }

    await traverseCatalog(catalog);
  }

  static Future<void> precacheImages() async {

    Future<void> traverseCatalog(CatalogItem item) async {
      item.precachePrimaryImage();
      // switch (item) {
      //   case ProductCategory _ : {
      //     item.precacheImages(context);
      //     for (var subItem in item.catalogItems) {
      //       traverseCatalog(subItem);
      //     }
      //   }
      //   case Product _ : {
      //     item.precacheImages(context);
      //   }
      // }
    }

    await traverseCatalog(all!);
  }
}

sealed class CatalogItem {
  final String id;
  late String name;
  late String? parentId;
  String? imageUrl;
  ImageProvider? imageProvider;

  CatalogItem({required this.name, this.parentId, String? id, this.imageUrl}) 
  : id = id ?? shortid.generate()
  {
    if (imageUrl != null) {
      try {
        if (isURL(imageUrl)) {
          imageProvider = CachedNetworkImageProvider(imageUrl!);
        }
        else {
          imageProvider = FileImage(File(imageUrl!));
        }
      } catch (e) {
        Log.logger.e("Failed to retrieve image at $imageUrl. Error: $e");
        imageUrl = null;
        imageProvider = Image.asset('assets/weightech_logo.png').image;
      }
    }
    else {
      imageProvider = Image.asset('assets/weightech_logo.png').image;
    }
  }

  Future<void> precachePrimaryImage() async {
    if (imageUrl != null) await DefaultCacheManager().downloadFile(imageUrl!);
  }

  Widget buildCard(VoidCallback onTapCallback) {
    return Card(
      surfaceTintColor: Colors.white,
      shadowColor: const Color(0xAA000000),
      margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 30.0, top: 30.0),
      child: Stack( 
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: 
                  Container (
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 30, bottom: 14),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(image: ResizeImage(imageProvider!, policy: ResizeImagePolicy.fit, height: 400, width: 400), fit: BoxFit.fitWidth,),
                    ),
                  )
              ),
              Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: Colors.black)), // Handle if name is null
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

  void precacheImages(BuildContext context) async {
    if (imageProvider != null) {
      await precacheImage(imageProvider!, context, onError: (error, stackTrace) {debugPrint('Image for $name failed to load: $error');});
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
      catalogItems: (json['catalogItems'] as List<dynamic>).map((itemJson) => CatalogItem.fromJson(itemJson)).toList(),
    );
  }

}

class Product extends CatalogItem {
  String? modelNumber;
  List<String>? productMediaUrls;
  String? description;
  List<Map<String, dynamic>>? brochure;
  static const String buttonRoute = '/product';

  Product({
    required super.name,
    super.parentId,
    super.id,
    String? imageUrl,
    this.productMediaUrls,
    this.modelNumber,
    this.description,
    this.brochure,
    BuildContext? context,
  }) : super(imageUrl: imageUrl ?? productMediaUrls?[0])
  {
    productMediaUrls ??= [];
  }

  //
  // Maps the list of brochure items to the brochure json structure. 
  //
  static List<Map<String, dynamic>> mapListToBrochure(List<BrochureItem> brochure) {
    Log.logger.t("Mapping BrochureItem list...");
    List<String> entries = [];
    List<dynamic> subheaders = [];
    final List<Map<String, dynamic>> brochureMap = [];

    for (var item in brochure.reversed) {
      switch (item) {
        case BrochureEntry _: {
          entries.insert(0, item.entry);
        }
        case BrochureSubheader _: {
          subheaders.insert(0, {item.subheader : List.from(entries)});
          entries.clear();
        }
        case BrochureHeader _: {
          if (entries.isNotEmpty && subheaders.isNotEmpty){
            brochureMap.insert(0, {item.header : [{"Entries" : List.from(entries)}, ...List.from(subheaders)]});
          }
          else if (entries.isNotEmpty) {
            brochureMap.insert(0, {item.header : [{"Entries" : List.from(entries)}]});
          }
          else if (subheaders.isNotEmpty) {
            brochureMap.insert(0, {item.header : List.from(subheaders)});
          }
          else {
            brochureMap.insert(0, {item.header : []});
          }
          subheaders.clear();
          entries.clear();
        }
      }
    }
    Log.logger.t("-> done.");

    return brochureMap;
  }

  List<BrochureItem> retrieveBrochureList() {
    Log.logger.t("Retrieving brochure list...");

    List<BrochureItem> brochureList = [];

    if (brochure == null) {
      return brochureList;
    }
    else {
      for (var mapItem in brochure!) {
        String key = mapItem.keys.first;
        brochureList.add(BrochureHeader(header: key));
        if (mapItem[key] is List) {
          for (var item in mapItem[key]) {
            item.forEach((key, value) {
              if (key == "Entries") {
                for (var entry in value) {
                  brochureList.add(BrochureEntry(entry: entry));
                }
              }
              else {
                String subKey = key;
                brochureList.add(BrochureSubheader(subheader: subKey));
                for (var entry in item[subKey]) {
                  brochureList.add(BrochureEntry(entry: entry));
                }
              }
            });
          }
        }
        else if (mapItem[key] is Map) {
          mapItem[key].forEach((key, value) {
            if (key == "Entries") {
              for (var entry in value) {
                brochureList.add(BrochureEntry(entry: entry));
              }
            }
            else {
              String subKey = key;
              brochureList.add(BrochureSubheader(subheader: subKey));
              for (var entry in mapItem[key][subKey]) {
                brochureList.add(BrochureEntry(entry: entry));
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
    json['imageUrls'] = productMediaUrls;
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
      productMediaUrls: List<String>.from(json['imageUrls'] ?? [])
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

  // @override
  // void precacheImages(BuildContext context) async {
  //   if (imageProvider != null) {
  //     await precacheImage(imageProvider!, context);
  //   }
  //   if (productMedia.isNotEmpty) {
  //     for (var provider in productImageProviders) {
  //       if (context.mounted) await precacheImage(provider, context);
  //     }
  //   }
  // }
}

sealed class BrochureItem {
  Widget buildItem(BuildContext context);
}

class BrochureHeader implements BrochureItem {
  String header;
  List<BrochureItem> items;
  final TextEditingController controller;

  BrochureHeader({required this.header}) : controller = TextEditingController(text: header), items = [];
  BrochureHeader.basic() : header="New Header", controller = TextEditingController(), items = [];

  @override
  Widget buildItem(BuildContext context) {
    return ListTile(
      leading: const Padding(
        padding: EdgeInsets.only(top: 15),
        child: Icon(Icons.drag_handle, size: 30), 
      ),
      title: TextFormField(
        controller: controller, 
        maxLines: null,
        onChanged: (value) {
          header = value;
        },
        decoration: 
          const InputDecoration(
            label: Text("Header")
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
  List<BrochureEntry> entries;
  final TextEditingController controller;

  BrochureSubheader({required this.subheader}) : controller = TextEditingController(text: subheader), entries = [];
  BrochureSubheader.basic() : subheader="New Subheader", controller = TextEditingController(), entries = [];

  @override
  Widget buildItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20), 
      child: ListTile(
        leading: const Padding(
          padding: EdgeInsets.only(top: 15),
          child: Icon(Icons.drag_handle, size: 30), 
        ),
        title: TextFormField(
          controller: controller, 
          maxLines: null,
          onChanged: (value) {
            subheader = value;
          },
          decoration: 
            const InputDecoration(
              label: Text("Subheader")
            ),
          validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          textCapitalization: TextCapitalization.words, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,)
        ),
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
      padding: const EdgeInsets.only(left: 40), 
      child: 
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.only(top: 15),
            child: Icon(Icons.drag_handle, size: 30), 
          ),
          title: TextFormField(
            controller: controller,
            maxLines: null,
            onChanged: (value) {
              entry = value;
            },
            decoration: 
              const InputDecoration(
                label: Text("Entry")
              ),
            validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          )
        )
    );
  }
}