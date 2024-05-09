import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shortid/shortid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path/path.dart' as path_handler;
import 'dart:math' as math;
import 'package:string_validator/string_validator.dart';
import 'package:weightechapp/utils.dart';





class ProductManager {
  static ProductCategory? all;
  static DateTime? timestamp;

  ProductManager._();

  static Future<void> create() async {
    Map<String, dynamic> catalogJson = await getCatalogFromFirestore();
    all = ProductCategory.fromJson(catalogJson);
    //timestamp = catalogJson["timestamp"];
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
    Map<String,dynamic> catalogJson = all!.toJson();
    catalogJson['timestamp'] = DateTime.now();
    await FirebaseUtils.postCatalogToFirestore(catalogJson);
  }

  static Future<Map<String,dynamic>> getCatalogFromFirestore() async {
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
                    padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 30, bottom: 30),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(image: imageProvider!, fit: BoxFit.fitWidth),
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
                    Log.logger.i('Item tapped: $name');
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
    Log.logger.i("Parent doesn't exist");
    return null;
  }

  void storeImage(File imageFile) {
    final storageRef = FirebaseUtils.storage.ref("images");
    final categoryImageRef = storageRef.child("${id}_0");
    try {
      categoryImageRef.putFile(imageFile);
    } on FirebaseException catch (e) {
      Log.logger.i("Failed to add ${id}_0 to Firebase. Error code: ${e.code}");
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
      Log.logger.i('${newProduct.name} (id: ${newProduct.id}) added to $name (id: $id)');
      return;
    }
    for (var item in catalogItems) {
      if (item is ProductCategory && item.id == newProduct.parentId) {
        item.addProduct(newProduct);
        Log.logger.i('${newProduct.name} (id: ${newProduct.id}) added to ${item.name} (id: ${item.id})');
        return;
      }
    }
    // If not found in the current category, recursively search in subcategories
    for (var item in catalogItems) {
      if (item is ProductCategory) {
        item.addProductByParentId(newProduct); // Recursively search in subcategories
      }
    }
    Log.logger.i('Parent category with ID ${newProduct.parentId} not found in category $name (id: $id).');
  }

  
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['catalogItems'] = catalogItems.map((item) => item.toJson()).toList();
    return json;
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    // Log.logger.i("Converting the following JSON to a ProductCategory. Here's the JSON:");
    // Log.logger.i("------");
    // Log.logger.i((const JsonEncoder.withIndent('   ')).convert(json));
    // Log.logger.i("------");
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
  List<String>? productImageUrls;
  List<CachedNetworkImageProvider> productImageProviders;
  String? description;
  List<Map<String, dynamic>>? brochure;
  static const String buttonRoute = '/product';

  Product({
    required super.name,
    super.parentId,
    super.id,
    super.imageUrl,
    this.productImageUrls,
    this.modelNumber,
    this.description,
    this.brochure,
    BuildContext? context,
  }) 
  : productImageProviders = []
  {
    if (super.imageUrl == null && (productImageUrls?.isNotEmpty ?? false)) {
      super.imageUrl = productImageUrls![0];
      if (imageUrl != null) {
        try {
          super.imageProvider = CachedNetworkImageProvider(super.imageUrl!);
        } on HttpExceptionWithStatus catch (e) {
          Log.logger.i("Failed to retrieve image at $imageUrl. Error: $e");
          super.imageUrl = null;
          super.imageProvider = Image.asset('assets/weightech_logo.png').image;
        }
      }
      for (String url in productImageUrls!) {
        try {
          CachedNetworkImageProvider newImageProvider = CachedNetworkImageProvider(url);
          productImageProviders.add(newImageProvider);
        } on HttpExceptionWithStatus catch (e) {
          Log.logger.i("Failed to retrieve image at $imageUrl. Error: $e");
          productImageUrls!.remove(url);
        }
      }
    }
  }

  //
  // Maps the list of brochure items to the brochure json structure. 
  //
  static List<Map<String, dynamic>> mapListToBrochure(List<BrochureItem> brochure) {

    List<String> entries = [];
    List<dynamic> subheaders = [];
    final List<Map<String, dynamic>> brochureMap = [];

    for (var item in brochure.reversed) {
      switch (item) {
        case BrochureEntry _: {
          entries.insert(0, item.entry);
        }
        case BrochureSubheader _: {
          subheaders.insert(0, {item.subheader : List<String>.from(entries)}
          );
          entries.clear();
        }
        case BrochureHeader _: {
          if (entries.isNotEmpty && subheaders.isNotEmpty){
            brochureMap.insert(0, {item.header : [{"Entries" : List.from(entries)}, List.from(subheaders)]});
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

    return brochureMap;
  }

  List<BrochureItem> retrieveBrochureList() {
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

    return brochureList;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['modelNumber'] = modelNumber;
    json['description'] = description;
    json['brochure'] = brochure;
    json['parentId'] = parentId;
    json['imageUrls'] = productImageUrls;
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
      productImageUrls: List<String>.from(json['imageUrls'] ?? [])
    );
  }


  void storeListOfImages(List<File> imageFiles){
    final storageRef = FirebaseUtils.storage.ref("images");
    for ( int i=0 ; i < imageFiles.length ; i++ ) {
      final imageRef = storageRef.child("${id}_$i");
      try {
        imageRef.putFile(imageFiles[i]);
      } on FirebaseException catch (e) {
        Log.logger.i("Failed to add ${id}_$i to Firebase. Error code: ${e.code}");
      }
    }
  }
}


sealed class EItem {
  late int rank;
  final String id;
  String? parentId;
  EItem({required this.id, required this.rank, this.parentId});

  static late ECategory all;

  static ECategory createEditorCatalog(ProductCategory catalogCopy) {

    ECategory traverseCategory(category, rank) {
      List<EItem> editorItems = [];

      for (var item in category.catalogItems) {
        switch (item) {
          case ProductCategory _ : {
            ECategory newItem = traverseCategory(item, rank+1);
            editorItems.add(newItem);
          }
          case Product _ : {
            editorItems.add(EProduct(product: item, rank: rank));
          }
        }
      }

      return ECategory(category: category, editorItems: editorItems, rank: rank-1);
    }


    all = traverseCategory(catalogCopy, 0);
    return all;
  }

  static Future<void> updateProductCatalog(ECategory editorCatalog) async {
    await updateImages(editorCatalog);
    ProductManager.all = editorCatalog.category;
    await ProductManager.postCatalogToFirestore();
    Log.logger.i("Catalog update completed.");
  }

  static Future<void> updateImages(ECategory editorCatalog) async {
    final storageRef = FirebaseUtils.storage.ref().child("devImages");

    Future<void> traverseItems(ECategory category) async {
      if (category.imageFile != null) {
        final refName = "${category.id}_0${path_handler.extension(category.imageFile!.path)}";

        final SettableMetadata metadata = SettableMetadata(contentType: 'images/${path_handler.extension(category.imageFile!.path)}');

        await storageRef.child(refName).putFile(category.imageFile!, metadata).then((value) async {
          await storageRef.child(refName).getDownloadURL().then((value) {
            category.category.imageUrl = value;
            Log.logger.i("Category image url updated.");
          });
        });
      }
      for (var item in category.editorItems) {
        switch (item) {
          case ECategory _: {
            await traverseItems(item);
          }
          case EProduct _: {
            if (item.imagePaths != null) {

              // if (item.product.productImageUrls != null) {
              //   await Future.wait([
              //     for (var url in item.product.productImageUrls!)
              //       FirebaseUtils.storage.refFromURL(url).delete(),
              //   ]);
              // }

              item.product.productImageUrls = [];

              int nonPrimaryCount = 0;
              for (int i = 0; i < item.imageFiles!.length; i++) {
                File imageFile = item.imageFiles![i];
                String baseRefName = '';
                if (i == item.primaryImageIndex) {
                  baseRefName = "${item.id}_0";
                  String extension = path_handler.extension(imageFile.path).substring(1);

                  if (extension == 'jpg') {
                    extension = 'jpeg';
                  }
                  
                  await storageRef.child("$baseRefName.$extension").putFile(imageFile, SettableMetadata(contentType: 'images/$extension')).then((value) async {
                    final imageUrl = await storageRef.child("$baseRefName.$extension").getDownloadURL();
                    item.product.productImageUrls!.insert(0, imageUrl);
                  });
                }
                else {
                  baseRefName = "${item.id}_${nonPrimaryCount+1}";
                  String extension = path_handler.extension(imageFile.path).substring(1);

                  if (extension == 'jpg') {
                    extension = 'jpeg';
                  }

                  await storageRef.child("$baseRefName.$extension").putFile(imageFile, SettableMetadata(contentType: 'images/$extension')).then((value) async {
                    final imageUrl = await storageRef.child("$baseRefName.$extension").getDownloadURL();
                    item.product.productImageUrls!.add(imageUrl);
                  });
                  nonPrimaryCount++;
                }
                
              }
            }
          }
        }
      }
    }

    await traverseItems(editorCatalog);
    Log.logger.i("Images updated.");
  }

  static EItem? getItemById({required root, required id}) {
    EItem? result;

    void traverseItems(ECategory category) {
      if (category.id == id) {
        result = category;
        return;
      }
      for (var item in category.editorItems) {
        switch (item) {
          case ECategory _: {
            traverseItems(item);
            if (result != null) {
              return;
            }
          }
          case EProduct _: {
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

  static EItem? getItemByName({required root, required name}) {
    EItem? result;

    void traverseItems(ECategory category) {
      if (category.category.name == name) {
        result = category;
        return;
      }
      for (var item in category.editorItems) {
        switch (item) {
          case ECategory _: {
            traverseItems(item);
            if (result != null) {
              return;
            }
          }
          case EProduct _: {
            if (item.product.name == name) {
              result = item;
            }
          }
        }
      }
    }

    traverseItems(root);

    return result;
  }

  ECategory? getParent({required root});
}

class ECategory extends EItem {
  final ProductCategory category;
  List<EItem> editorItems;
  String? imagePath;
  File? imageFile;
  bool showChildren = false;
  ECategory({required this.category, required super.rank, required this.editorItems, this.imagePath}) : super(id: category.id, parentId: category.parentId);

  bool open = false;
  bool play = false;

  
  Widget buildListTile({int? index, VoidCallback? onArrowCallback, VoidCallback? onEditCallback, VoidCallback? onDragStarted, VoidCallback? onDragCompleted, VoidCallback? onDragCanceled, TickerProvider? ticker}) {
    Tween<double>? openTween;
    Tween<double>? closeTween;
    AnimationController? controller; 


    if (ticker != null) {
      openTween = Tween<double>(begin: 0.75, end: 1);
      closeTween = Tween<double>(begin: 1.0, end: 0.75);
      controller = AnimationController(vsync: ticker, duration: const Duration(milliseconds: 100));
      controller.forward();
    }

    return DragTarget<EItem>(
      onWillAcceptWithDetails: (details) {
        return (!editorItems.contains(details.data) && details.data != this);
      },
      onAcceptWithDetails: (details) {
        ECategory parent = details.data.getParent(root: EItem.all)!;
        parent.editorItems.remove(details.data);

        details.data.rank = rank + 1;
        details.data.parentId = id;
        editorItems.add(details.data);

        switch (details.data) {
          case ECategory _ : {
            parent.category.catalogItems.remove((details.data as ECategory).category);
            category.catalogItems.add((details.data as ECategory).category);
            (details.data as ECategory).category.parentId = id;
          }
          case EProduct _ : {
            parent.category.catalogItems.remove((details.data as EProduct).product);
            category.catalogItems.add((details.data as EProduct).product);
            (details.data as EProduct).product.parentId = id;
          }
        }
      },
      builder: (context, accepted, rejected) {
        Widget widget = Draggable<EItem> (
          data: this,
          onDragStarted: () {
            if (onDragStarted != null) onDragStarted();
          },
          onDragCompleted: () {
            if (onDragCompleted != null) onDragCompleted();
          },
          onDraggableCanceled: (v, o) {
            if (onDragCanceled != null) onDragCanceled();
          },
          feedback: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(10),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.move_up),
                  const SizedBox(width: 5),
                  Text(category.name)
                ]
              )
            )
          ),
          child: InkWell(
            onTap: () {
              if (onEditCallback != null) {onEditCallback();}
            },
            child: ListTile(
              visualDensity: VisualDensity.compact,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onArrowCallback != null) 
                    open ?
                      InkWell(
                        onTap: () {
                          open = false;
                          play = true;
                          onArrowCallback();
                        }, 
                        child: (openTween != null && play) ? 
                          RotationTransition(turns: openTween.animate(controller!), child: const Icon(Icons.keyboard_arrow_down)) 
                          : const Icon(Icons.keyboard_arrow_down)
                      )
                      : InkWell(
                        onTap: () {
                          open = true;
                          play = true;
                          onArrowCallback();
                        },
                        child: (closeTween != null && play) ? 
                          RotationTransition(turns: closeTween.animate(controller!), child: const Icon(Icons.keyboard_arrow_down)) 
                          : Transform.rotate(angle: -90*math.pi/180, child: const Icon(Icons.keyboard_arrow_down)),
                      ),
                  const Icon(Icons.folder_outlined, size: 20),
                  const SizedBox(width: 5),
                  Expanded(child: Text(category.name, style: const TextStyle(color: Colors.black, fontSize: 14.0))),
                ]
              ),
              //subtitle: const Text("Category", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic)),
              trailing: (index != null) ? ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)) : const SizedBox(),
            )
          )
        );
        play = false;
        return widget;
      }
    );
  }

  @override
  ECategory? getParent({required root}) {
    return EItem.getItemById(root: root, id: parentId) as ECategory;
  }

  List<ECategory> getSubCategories({List<ECategory>? categoriesToExclude}) {
    List<ECategory> subCategories = [];

    void traverseCategories(ECategory category) {
      subCategories.add(category); // Add the current category to the list

      // Traverse subcategories recursively
      for (var item in category.editorItems) {
        if (item is ECategory) {
          traverseCategories(item);
        }
      }
    }

    traverseCategories(this);

    if (categoriesToExclude != null) {
      for (ECategory eCategory in categoriesToExclude) {
        subCategories.remove(eCategory);
      }
    }

    return subCategories;
  }

  void addItem(EItem item) {
    switch (item) {
      case ECategory _ :
        item.parentId = id;
        editorItems.add(item);
        category.catalogItems.add(item.category);
      case EProduct _ :
        item.parentId = id;
        editorItems.add(item);
        category.catalogItems.add(item.product);
    }
  }

  Future<void> setImagePaths() async {
    if (imagePath != null) {
      return;
    }
    else if (category.imageProvider != null) {
      if (category.imageUrl != null) {
        imagePath = category.imageUrl;
      }
    }
    else {
      imagePath = '';
    }
  }

  Future<void> setImageFiles() async {
    if (imageFile != null) {
      return;
    }
    else {
      final basePath = await getTemporaryDirectory();
      if (imagePath == null) {
        return;
      }
      else if (isURL(imagePath)) {
        final imageRef = FirebaseUtils.storage.refFromURL(imagePath!);
        final file = File('${basePath.path}/${imageRef.name}');

        await imageRef.writeToFile(file);
        imageFile = file;
      }
      else if (imagePath != '') {
        imageFile = File(imagePath!);
      }
    }
  }
}

class EProduct extends EItem {
  final Product product;
  List<String>? imagePaths;
  List<File>? imageFiles;
  int primaryImageIndex;
  EProduct({required this.product, required super.rank, this.imagePaths, primaryImageIndex}) : primaryImageIndex = primaryImageIndex ?? 0, super(id: product.id, parentId: product.parentId) {
    if (imagePaths != null) {
      imageFiles = [];
      for (var path in imagePaths!) {
        try {
          imageFiles!.add(File(path));
        }
        catch (e, trace) {
          Log.logger.w("Failed to add image at $path", error: e, stackTrace: trace);
        }
      }
    }
  }

  Widget buildListTile({int? index, VoidCallback? onEditCallback, VoidCallback? onDragCompleted, VoidCallback? onDragStarted, VoidCallback? onDragCanceled}) {
    return Draggable<EItem> (
      data: this,
      onDragStarted: () {
        if (onDragStarted != null) onDragStarted();
      },
      onDragCompleted: () {
        if (onDragCompleted != null) onDragCompleted();
      },
      onDraggableCanceled: (v, o) {
        if (onDragCanceled != null) onDragCanceled();
      },
      feedback: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(10),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              const Icon(Icons.move_up),
              const SizedBox(width: 5),
              Text(product.name)
            ]
          )
        )
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      child: 
        InkWell(
          onTap: () {
            if (onEditCallback != null) {onEditCallback();}
          },
          child: ListTile(
            visualDensity: VisualDensity.compact,
            title: Row(
              children: [
                const Icon(Icons.conveyor_belt, size: 20,),
                const SizedBox(width: 10),
                Expanded(child: Text(product.name, style: const TextStyle(color: Colors.black, fontSize: 14.0))), 
              ]  
            ),
            // subtitle: const Padding(
            //   padding: EdgeInsets.only(left: 30), 
            //   child: Text("Product", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic)),
            // ),
            trailing: (index != null) ? ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)) : const SizedBox(),
          )
        )
    );
  }

  @override
  ECategory? getParent({required root}) {
    return EItem.getItemById(root: root, id: parentId) as ECategory;
  }

  Future<void> setImagePaths() async {
    if (imagePaths != null) {
      return;
    }
    else {
      imagePaths = [];
      if (product.productImageProviders.isNotEmpty) {
        if (product.productImageUrls != null) {
          for (var url in product.productImageUrls!) {
            imagePaths!.add(url);
          }
        }
      }
    }
  }

  Future<void> setImageFiles() async {
    if (imageFiles != null) {
      return;
    }
    else {
      final basePath = await getTemporaryDirectory();
      imageFiles = [];
      for (var path in imagePaths!) {
        if (isURL(path)) {
          final imageRef = FirebaseUtils.storage.refFromURL(path);
          final file = File('${basePath.path}/${imageRef.name}');

          await imageRef.writeToFile(file);
          imageFiles!.add(file);
        }
        else {
          imageFiles!.add(File(path));
        }
      }
    }
  }
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