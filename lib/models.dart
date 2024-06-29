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
    try {
      Map<String, dynamic> catalogJson = await getCatalogFromFirestore();
      all = ProductCategory.fromJson(catalogJson);
      //timestamp = catalogJson["timestamp"];
    } catch (e) {
      rethrow;
    }
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
  }) : super(imageUrl: imageUrl ?? ((productMediaUrls?.isNotEmpty ?? false) ? productMediaUrls![0] : null))
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
    try {
      await updateImages(editorCatalog);
      Log.logger.t("Product images updated.");
      ProductManager.all = editorCatalog.category;
      await ProductManager.postCatalogToFirestore();
      Log.logger.t("Catalog update completed.");
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateImages(ECategory editorCatalog) async {
    final storageRef = FirebaseUtils.storage.ref().child("devImages2");

    Future<void> traverseItems(ECategory category) async {
      if (category.imageFile != null) {
        final refName = "${category.id}_0${path_handler.extension(category.imageFile!.path)}";

        final SettableMetadata metadata = SettableMetadata(contentType: 'images/${path_handler.extension(category.imageFile!.path)}');

        try {
          await storageRef.child(refName).putFile(category.imageFile!, metadata).then((value) async {
            await storageRef.child(refName).getDownloadURL().then((value) {
              category.category.imageUrl = value;
              Log.logger.t("Category image url updated.");
            });
          });
        } catch (e, stackTrace) {
          Log.logger.e("Error encountered while updating category image", error: e, stackTrace: stackTrace);
        }
      }
      for (var item in category.editorItems) {
        switch (item) {
          case ECategory _: {
            await traverseItems(item);
          }
          case EProduct _: {
            if (item.mediaPaths != null) {

              // if (item.product.productImageUrls != null) {
              //   await Future.wait([
              //     for (var url in item.product.productImageUrls!)
              //       FirebaseUtils.storage.refFromURL(url).delete(),
              //   ]);
              // }

              item.product.productMediaUrls = [];

              int nonPrimaryCount = 0;
              for (int i = 0; i < item.mediaFiles!.length; i++) {
                File imageFile = item.mediaFiles![i];
                String baseRefName = '';
                if (i == item.primaryImageIndex) {
                  baseRefName = "${item.id}_0";
                  String extension = path_handler.extension(imageFile.path).substring(1);

                  if (extension == 'jpg') {
                    extension = 'jpeg';
                  }
                  
                  try {
                    await storageRef.child("$baseRefName.$extension").putFile(imageFile, SettableMetadata(contentType: 'images/$extension')).then((value) async {
                      final imageUrl = await storageRef.child("$baseRefName.$extension").getDownloadURL();
                      item.product.productMediaUrls!.insert(0, imageUrl);
                    });
                  } catch (e, stackTrace) {
                    Log.logger.e("Error encountered while updating primary product image.", error: e, stackTrace: stackTrace);
                  }
                }
                else {
                  baseRefName = "${item.id}_${nonPrimaryCount+1}";
                  String extension = path_handler.extension(imageFile.path).substring(1);

                  if (extension == 'jpg') {
                    extension = 'jpeg';
                  }
                  if (extension == 'jpeg' || extension == 'png') {
                    try {
                      await storageRef.child("$baseRefName.$extension").putFile(imageFile, SettableMetadata(contentType: 'images/$extension')).then((value) async {
                        final imageUrl = await storageRef.child("$baseRefName.$extension").getDownloadURL();
                        item.product.productMediaUrls!.add(imageUrl);
                      });
                      nonPrimaryCount++;
                    } catch (e, stackTrace) {
                      Log.logger.e("Error encountered while updating non-primary product images.", error: e, stackTrace: stackTrace);
                    }
                  }
                  else if (extension == 'mp4') {
                    final video = await ApiVideoService.createVideo('$baseRefName.$extension');
                    final videoId = video['videoId'];
                    final url = await ApiVideoService.uploadVideo(videoId, imageFile.path);
                    item.product.productMediaUrls!.add(url);
                    nonPrimaryCount++;
                  }
                }
                
              }
            }
          }
        }
      }
    }

    await traverseItems(editorCatalog);
    Log.logger.t("Images updated.");
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

  ECategory? getParent({required root}) {
    return getItemById(root: root, id: parentId) as ECategory;
  }

  void removeFromParent() {
    final ECategory parent = getItemById(root: all, id: parentId) as ECategory;

    parent.editorItems.remove(this);
    parentId = null;

    switch (this) {
      case ECategory _ : {
        parent.category.catalogItems.remove((this as ECategory).category);
        Log.logger.i("Removed ${(this as ECategory).category.name} from ${parent.category.name}");
      }
      case EProduct _ : {
        parent.category.catalogItems.remove((this as EProduct).product);
        Log.logger.i("Removed ${(this as EProduct).product.name} from ${parent.category.name}");
      }
    }
  }

  void reassignParent({required ECategory newParent}) {
    removeFromParent();
    newParent.addItem(this);
  }
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
        item.rank = rank+1;
        editorItems.add(item);
        category.catalogItems.add(item.category);
        Log.logger.i("Added ${item.category.name} to ${category.name}");
      case EProduct _ :
        item.parentId = id;
        item.rank = rank+1;
        editorItems.add(item);
        category.catalogItems.add(item.product);
        Log.logger.i("Added ${item.product.name} to ${category.name}");
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
  List<String>? mediaPaths;
  List<File>? mediaFiles;
  int primaryImageIndex;
  EProduct({required this.product, required super.rank, this.mediaPaths, primaryImageIndex}) : primaryImageIndex = primaryImageIndex ?? 0, super(id: product.id, parentId: product.parentId) {
    if (mediaPaths != null) {
      mediaFiles = [];
      for (var path in mediaPaths!) {
        try {
          mediaFiles!.add(File(path));
        }
        catch (e, trace) {
          Log.logger.w("Failed to add file at $path", error: e, stackTrace: trace);
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
                const SizedBox(width: 24),
                const Icon(Icons.conveyor_belt, size: 20,),
                const SizedBox(width: 5),
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

  Future<void> setImagePaths() async {
    if (mediaPaths != null) {
      return;
    }
    else {
      mediaPaths = [];
      if (product.productMediaUrls?.isNotEmpty ?? false) {
        for (var url in product.productMediaUrls!) {
          mediaPaths!.add(url);
        }
      }
    }
  }

  Future<void> setImageFiles() async {
    if (mediaFiles != null) {
      return;
    }
    else {
      final basePath = await getTemporaryDirectory();
      mediaFiles = [];
      for (var path in mediaPaths!) {
        if (isURL(path)) {
          try {
            final imageRef = FirebaseUtils.storage.refFromURL(path);
            final file = File('${basePath.path}/${imageRef.name}');

            await imageRef.writeToFile(file);
            mediaFiles!.add(file);
          } catch (e) {
            try {
              final file = await ApiVideoService.downloadVideo(path, '$path');
            } catch (e) {
              rethrow;
            }
          }
        }
        else {
          mediaFiles!.add(File(path));
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