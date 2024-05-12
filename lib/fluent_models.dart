import 'package:weightechapp/models.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path_handler;
import 'dart:math' as math;
import 'package:string_validator/string_validator.dart';
import 'package:weightechapp/utils.dart';


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
    Log.logger.t("Catalog update completed.");
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
            Log.logger.t("Category image url updated.");
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
            child: Row(
              children: [
                const Icon(FluentIcons.drag_20_regular),
                const SizedBox(width: 5),
                Text(category.name)
              ]
            )
          ),
          child: ListTile(
            onPressed: () {
              if (onEditCallback != null) {onEditCallback();}
            },
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onArrowCallback != null) 
                  open ?
                    IconButton(
                      onPressed: () {
                        open = false;
                        play = true;
                        onArrowCallback();
                      }, 
                      icon: (openTween != null && play) ? 
                        RotationTransition(turns: openTween.animate(controller!), child: const Icon(FluentIcons.chevron_down_16_regular)) 
                        : const Icon(FluentIcons.chevron_down_16_regular)
                    )
                    : IconButton(
                      onPressed: () {
                        open = true;
                        play = true;
                        onArrowCallback();
                      },
                      icon: (closeTween != null && play) ? 
                        RotationTransition(turns: closeTween.animate(controller!), child: const Icon(FluentIcons.chevron_down_16_regular)) 
                        : Transform.rotate(angle: -90*math.pi/180, child: const Icon(FluentIcons.chevron_down_16_regular)),
                    ),
                const Icon(FluentIcons.folder_16_regular,),
                const SizedBox(width: 10),
                Expanded(child: Text(category.name, style: const TextStyle(fontSize: 14))),
              ]
            ),
            trailing: (index != null) ? ReorderableDragStartListener(index: index, child: const Icon(FluentIcons.drag_20_regular)) : const SizedBox(),
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
        child: Row(
          children: [
            const Icon(FluentIcons.drag_20_regular),
            const SizedBox(width: 5),
            Text(product.name)
          ]
        )
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      child: 
        ListTile(
          onPressed: () {
            if (onEditCallback != null) {onEditCallback();}
          },
          title: Row(
            children: [
              const Icon(FluentIcons.production_20_regular,),
              const SizedBox(width: 10),
              Expanded(child: Text(product.name, style: const TextStyle(fontSize: 14))), 
            ]  
          ),
          trailing: (index != null) ? ReorderableDragStartListener(index: index, child: const Icon(FluentIcons.drag_20_regular)) : const SizedBox(),
        )
    );
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
