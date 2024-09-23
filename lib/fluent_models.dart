import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' as material;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path_handler;
import 'package:string_validator/string_validator.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/models.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons, TreeView, TreeViewItem;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';


class CatalogEditor {
  CatalogEditor(ProductCategory catalog) {
    name = 'Untitled 1';
    isLocal = false;
    createEditorCatalog(catalog);
    if (AppInfo.hasInternet) {
      publishedCatalog = getPublishedVersion(ProductCategory.fromJson(ProductManager.all!.toJson()));
    }
    else {
      publishedCatalog = null;
    }
  }
  static late ECategory all;
  static late ECategory? publishedCatalog;
  static late String name;
  static late bool isLocal;
  static File? currentFile;

  static void createEditorCatalog(ProductCategory catalogCopy) {

    ECategory traverseCategory(category) {
      List<EItem> editorItems = [];

      for (var item in category.catalogItems) {
        switch (item) {
          case ProductCategory _ : {
            ECategory newItem = traverseCategory(item);
            editorItems.add(newItem);
          }
          case Product _ : {
            editorItems.add(EProduct(product: item,));
          }
        }
      }

      return ECategory(category: category, editorItems: editorItems);
    }


    all = traverseCategory(catalogCopy);
  }

  static ECategory getPublishedVersion(ProductCategory catalogCopy) {

    ECategory traverseCategory(category) {
      List<EItem> editorItems = [];

      for (var item in category.catalogItems) {
        switch (item) {
          case ProductCategory _ : {
            ECategory newItem = traverseCategory(item);
            editorItems.add(newItem);
          }
          case Product _ : {
            editorItems.add(EProduct(product: item,));
          }
        }
      }

      return ECategory(category: category, editorItems: editorItems);
    }


    return traverseCategory(catalogCopy);
  }

  static Future<void> saveCatalogToCloud({StreamController? streamController}) async {
    try {
      await updateImages(streamController);
      Log.logger.t("Product images updated.");
      ProductManager.all = all.category;
      streamController?.add("Updating catalog...");
      await ProductManager.postCatalogToFirestore();
      Log.logger.t("Catalog update completed.");
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateImages(StreamController? stream) async {
    final storageRef = FirebaseUtils.storage.ref().child("devImages3");

    Future<void> traverseItems(ECategory category) async {
      if (category.imageFile != null) {
        stream?.add(category);
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
            if (item.branchHasChanges) await traverseItems(item);
          }
          case EProduct _: {
            if (item.hasChanges) {
              if (item.mediaPaths != null) {
                stream?.add(item);
                
                ApiVideoService.deleteExistingForId(item.id);
                item.product.productMedia = [];

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
                        item.product.productMedia!.insert(0, 
                        {
                          'name': baseRefName,
                          'contentType': (extension == 'mp4' ? 'video' : 'image'),
                          'fileType': extension,
                          'downloadUrl': imageUrl
                        });
                      });
                    } catch (e, stackTrace) {
                      Log.logger.e("Error encountered while updating primary product image.", error: e, stackTrace: stackTrace);
                    }
                  }
                  else {
                      try {
                        baseRefName = "${item.id}_${nonPrimaryCount+1}";
                        String extension = path_handler.extension(imageFile.path).substring(1);

                        if (extension == 'jpg') {
                          extension = 'jpeg';
                        }
                        if (extension == 'jpeg' || extension == 'png') {
                            try {
                              await storageRef.child("$baseRefName.$extension").putFile(imageFile, SettableMetadata(contentType: 'images/$extension'))
                              .then((value) async {
                                final imageUrl = await storageRef.child("$baseRefName.$extension").getDownloadURL();
                                item.product.productMedia!.add( 
                                {
                                  'name': baseRefName,
                                  'contentType': 'image',
                                  'fileType' : extension,
                                  'downloadUrl': imageUrl,
                                });
                              });
                              nonPrimaryCount++;
                            } catch (e, stackTrace) {
                              Log.logger.e("Error encountered while updating non-primary product images.", error: e, stackTrace: stackTrace);
                            }
                        }
                        else if (extension == 'mp4') {
                          await storageRef.child("$baseRefName.$extension").putFile(imageFile, SettableMetadata(contentType: 'video/mp4'))
                          .then((value) async {
                            final videoUrl = await storageRef.child("$baseRefName.$extension").getDownloadURL();
                            final videoResponse = await ApiVideoService.createVideo(title: '$baseRefName.$extension', source: videoUrl);
                            final videoData = {
                              'downloadUrl' : videoUrl,
                              'streamUrl' : videoResponse['assets']['hls'],
                              'thumbnailUrl' : videoResponse['assets']['thumbnail'],
                              'playerUrl' : videoResponse['assets']['player'],
                              'videoId' : videoResponse['videoId']
                            };
                            // final videoId = video['videoId'];
                            // final videoData = await ApiVideoService.uploadVideo(videoId, imageFile.path);
                            item.product.productMedia!.add({
                              'name': baseRefName,
                              'contentType': 'video',
                              'fileType' : 'mp4',
                              ...
                              videoData
                            });
                          });
                          nonPrimaryCount++;
                        }
                      } catch (e) {
                        Log.logger.w("Failed to upload media for $baseRefName: $e");
                      }
                    }
                  }
              }
                  
            }
          }
        }
      }
    }

    await traverseItems(all);
    Log.logger.t("Images updated.");
  }

  static Future<void> saveCatalogLocal({required String path}) async {

    Log.logger.i("Attempting to save");
    Log.logger.t("Save file path: $path");

    File saveFile = File(path);
    Directory directory = saveFile.parent;

    Directory tempDirectory = directory.createTempSync();

    String name = FileUtils.filename(path);
    
    File jsonFile = await File('${tempDirectory.path}/$name.json').create();
    
    ECategory copyOfAll = ECategory.fromJson(all.toJson());
    
    try {
      List<ArchiveFile> archiveImages = await _storeBackupImages(catalog: copyOfAll, directory: tempDirectory, name: name);
      jsonFile.writeAsStringSync(jsonEncode(copyOfAll.toJson()), mode: FileMode.write);
      final bytes = jsonFile.readAsBytesSync();


      final ArchiveFile jsonArchive = ArchiveFile(FileUtils.filenameWithExtension(jsonFile.path), bytes.length, bytes);

      final archive = Archive();

      archive.addFile(jsonArchive);
      for (ArchiveFile file in archiveImages) {
        archive.addFile(file);
      }
      
      final encoder = ZipEncoder();
      final encodedArchive = encoder.encode(archive);

      if (encodedArchive == null) {
        Log.logger.w("Failed to create save!");
      }
      else {
        saveFile.writeAsBytesSync(encodedArchive); 
      }

      tempDirectory.deleteSync(recursive: true);

      currentFile = saveFile;
      isLocal = true;
      
    } catch (e, stackTrace) {
      Log.logger.e(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> uploadCatalogLocal({required String path, VoidCallback? onComplete}) async {
    
    File uploadFile = File(path);
    Directory uploadDirectory = uploadFile.parent;

    String name = FileUtils.filenameWithExtension(uploadFile.path);
    Directory tempDirectory = await uploadDirectory.createTemp('~$name');


    try {
      // Read the Zip file from disk.
      List<int> bytes = uploadFile.readAsBytesSync();

      final Archive archive = ZipDecoder().decodeBytes(bytes);
      
      for (final ArchiveFile file in archive) {
        final String filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('${tempDirectory.path}/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
          try {
            final json = jsonDecode(utf8.decode(data));
            final newAll = ECategory.fromJson(json);
            all = newAll;
            Log.logger.i("Save file retrieved and decoded: $name");
            // Log.logger.t("Here's the json:");
            // Log.logger.t((const JsonEncoder.withIndent(' ')).convert(json));
            CatalogEditor.name = name;
            currentFile = uploadFile;
            isLocal = true;
            if (onComplete != null) onComplete();
          } catch (e) {
            // caught error
          }
        }
        else {// it should be a directory
            Directory('${tempDirectory.path}/$filename').create(recursive: true);
        }
      }
      // return catalog;
    } catch (e) {
      throw();
    }
  }

  static Future<List<ArchiveFile>> _storeBackupImages({required ECategory catalog, required Directory directory, required String name}) async {
    Directory imageDirectory = await Directory('${directory.path}/$name/images').create(recursive: true);
    final List<FileSystemEntity> entities = await imageDirectory.list().toList();

    final archiveList = <ArchiveFile>[];

    for (var entity in entities) {
      entity.deleteSync();
    }

    Future<void> traverseCatalog(EItem item) async {
      switch (item) {
        case ECategory _ : {
          if (item.imageFile != null) {
            try {
              late String newPath;
              late File newFile;

              if (FileUtils.isURL(path: item.imagePath!)) {
                  newFile = await FirebaseUtils.downloadFromFirebaseStorage(url: item.imagePath!, directory: imageDirectory, suffix: '_saved');
                  newPath = newFile.path;
                  item.imagePath =  newPath;

                }
                else {
                  newPath = '${imageDirectory.path}/${FileUtils.filenameWithExtension(item.imagePath!)}';
                  newFile = item.imageFile!.copySync(newPath);
                  item.imagePath = newPath;
                }

              final bytes = newFile.readAsBytesSync();

              archiveList.add(ArchiveFile(FileUtils.filenameWithExtension(newPath), bytes.length, bytes));
            } catch (e) {
              throw();
            }
          }
          for (var subItem in item.editorItems) {
            await traverseCatalog(subItem);
          }
        }
        case EProduct _ : {
          if (item.mediaFiles?.isNotEmpty ?? false) {
            for (int i = 0; i < item.mediaFiles!.length; i++) {
              try {
                late String newPath;
                late File newFile;

                if (FileUtils.isURL(path: item.mediaPaths![i])) {
                  newFile = await FirebaseUtils.downloadFromFirebaseStorage(url: item.mediaPaths![i], directory: imageDirectory, suffix: '_saved');
                  newPath =  newFile.path;
                  item.mediaPaths![i] = newPath;
                }
                else {
                  newPath = '${imageDirectory.path}/${FileUtils.filenameWithExtension(item.mediaPaths![i])}';
                  newFile = item.mediaFiles![i].copySync(newPath);
                  item.mediaPaths![i] = newPath;
                }

                final bytes = newFile.readAsBytesSync();
                archiveList.add(ArchiveFile(FileUtils.filenameWithExtension(newPath), bytes.length, bytes));
              } catch (e) {
                throw();
              }
            }
          }
        }
      }
    }

    await traverseCatalog(catalog);

    return archiveList;
  }
}


sealed class EItem {
  String name;
  final String id;
  String? parentId;
  bool hasChanges;
  EItem({required this.id, required this.name, this.parentId, this.hasChanges = false});

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

  ECategory? getParent() {
    return getItemById(root: CatalogEditor.all, id: parentId) as ECategory?;
  }

  List<EItem> getSubItems();

  void removeFromParent() {
    final ECategory? parent = getItemById(root: CatalogEditor.all, id: parentId) as ECategory?;

    if (parent != null) {
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
  }

  void reassignParent({required ECategory newParent, int? atIndex}) {
    removeFromParent();

    newParent.addItem(this, index: atIndex);
  }

  void reorderItem({required newIndex}) {
    final parent = getParent();
    if (parent!.editorItems.indexOf(this) <= newIndex) {
      newIndex -= 1;
    }
    removeFromParent();
    parent.addItem(this, index: newIndex);
  }

  void setHasChangesRecursive() {
    
    void traverse(ECategory? item) {
      if (item != null) {
        item.branchHasChanges = true;
        traverse(item.getParent());
      }
    }

    hasChanges = true;
    traverse(getParent());
  }

  void save();

  void delete() {
    getParent()?.setHasChangesRecursive();
    removeFromParent();
  }

  Map<String, dynamic> toJson() {
    return {
      'name' : name,
      'id' : id,
      'parentId' : parentId,
      'hasChanges' : false,
    };
  }

  static EItem fromJson(Map<String, dynamic> json) {
    if (json['editorItems'] != null) {
      return ECategory.fromJson(json);
    }
    else {
      return EProduct.fromJson(json);
    }
  }

  Future<void> revertToPublished() async {}
}

class ECategory extends EItem {
  final ProductCategory category;
  List<EItem> editorItems;
  String? imagePath;
  File? imageFile;
  bool branchHasChanges = false;
  ECategory({required this.category, required this.editorItems, this.imagePath}) : super(id: category.id, name: category.name, parentId: category.parentId) {
    if (imagePath != null) imageFile = File(imagePath!);
  }

  ECategory.temp() : this(category: ProductCategory.temp(), editorItems: []);

  @override
  List<EItem> getSubItems() {
    return editorItems;
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

  void addItem(EItem item, {int? index}) {
    switch (item) {
      case ECategory _ :
        item.parentId = id;
        item.category.parentId = id;
        if (index != null) {
           editorItems.insert(index, item);
           category.catalogItems.insert(index, item.category);
        }
        else {
          editorItems.add(item);
          category.catalogItems.add(item.category);
        }
        Log.logger.i("Added ${item.category.name} to ${category.name}");
      case EProduct _ :
        item.parentId = id;
        item.product.parentId = id;
        if (index != null) {
           editorItems.insert(index, item);
           category.catalogItems.insert(index, item.product);
        }
        else {
          editorItems.add(item);
          category.catalogItems.add(item.product);
        }
        Log.logger.i("Added ${item.product.name} to ${category.name}");
    }
  }

  Future<String?> getImagePaths() async {
    if (imagePath != null) {
      return imagePath!;
    }
    else if (hasChanges) {
      return imagePath;
    }
    else if (category.imageProvider != null) {
      if (category.imageUrl != null) {
        return category.imageUrl!;
      }
    }
    return '';
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

  Future<File?> getImageFiles({String? path}) async {
    if (imageFile != null) {
      return imageFile!;
    }
    else {
      if (hasChanges) {
        return imageFile;
      }
      else {
        final basePath = await getTemporaryDirectory();
        if (path == null) {
          Log.logger.e("Must set image path before creating file!");
          throw 'Must provide path before creating file';
        }
        else if (path == "") {
          Log.logger.t('This looks like a new category is being created. If something bad happens, idk');
          return null;
        }
        else if (isURL(path)) {
          try {
            final cacheFile = await DefaultCacheManager().getSingleFile(path);
            return cacheFile;
          } catch (e) {
            try {
              final file = await FirebaseUtils.downloadFromFirebaseStorage(url: path, directory: basePath, returnFile: true);

              return file;

            } catch (e2) {
              Log.logger.w("Failed to download image from $path. Removing from media paths...", error: [e,e2]);
            }
          }
        }
      }
    }
    Log.logger.f('No image file found at $path for $id.');
    return null;
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
        try {
          final imageRef = FirebaseUtils.storage.refFromURL(imagePath!);
          final file = File('${basePath.path}/${imageRef.name}');

          await imageRef.writeToFile(file);
          imageFile = file;
        } catch (e) {
          Log.logger.e("Failed to download image from $imagePath");

        }
      }
      else if (imagePath != '') {
        imageFile = File(imagePath!);
      }
    }
  }

  @override
  void save({
    String? name,
    ECategory? parent,
    String? imagePath,
    File? imageFile,
  }) {

    Log.logger.t(
      """
        Saving product...

        Previous attributes: 
        ${category.toJson()}
      """
    );

    if (parentId == null) {
      (parent ?? CatalogEditor.all).addItem(this);
    }
    else {
      if (parentId != (parent ?? CatalogEditor.all).id) {
        reassignParent(newParent: parent ?? CatalogEditor.all);
      }
    }
    if (name != null) {
      category.name = name;
      super.name = name;
    }
    this.imagePath = imagePath;
    this.imageFile = imageFile;

    setHasChangesRecursive();

    Log.logger.t(
      """
        New attributes:
        ${category.toJson()}
      """
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['category'] = category.toJson();
    json['editorItems'] = editorItems.map((item) => item.toJson()).toList();
    json['imagePath'] = imagePath;
    return json;
  }

  factory ECategory.fromJson(Map<String, dynamic> json) {
    // Log.logger.t("Converting the following JSON to an ECategory. Here's the JSON:");
    // Log.logger.t("------");
    // Log.logger.t((const JsonEncoder.withIndent('   ')).convert(json));
    // Log.logger.t("------");
    return ECategory(
      category: ProductCategory.fromJson(json['category']),
      editorItems: (json['editorItems'] as List<dynamic>).map((itemJson) => EItem.fromJson(itemJson)).toList(),
      imagePath: json['imagePath']
    );
  }

  @override
  Future<void> revertToPublished() async {
    super.revertToPublished();

    final publishedVersion = EItem.getItemById(root: CatalogEditor.publishedCatalog, id: id) as ECategory?;
    if (publishedVersion != null) {
      String? newPath = await publishedVersion.getImagePaths();
      File? newFile = (newPath != null) ? await publishedVersion.getImageFiles(path: newPath) : null;
      save(
        name: publishedVersion.name,
        imagePath: newPath,
        imageFile: newFile,
      );
    }
  }
}

class EProduct extends EItem {
  final Product product;
  List<String>? mediaPaths;
  List<File>? mediaFiles;
  int primaryImageIndex;
  EProduct({required this.product, this.mediaPaths, primaryImageIndex}) : primaryImageIndex = primaryImageIndex ?? 0, super(id: product.id, name: product.name, parentId: product.parentId) {
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

  factory EProduct.fromJson(Map<String, dynamic> json) {
    return EProduct(
      product: Product.fromJson(json['product']),
      mediaPaths: json['mediaPaths'] != null ? List<String>.from(json['mediaPaths']) : null,
      primaryImageIndex: json['primaryImageIndex'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['product'] = product.toJson();
    json['mediaPaths'] = mediaPaths;
    json['primaryImageIndex'] = primaryImageIndex;

    return json;
  }

  EProduct.temp() : this(product: Product.temp());

  @override
  List<EItem> getSubItems() {
    return [];
  }

  Future<List<String>?> getImagePaths() async {
    if (mediaPaths != null) {
      return mediaPaths!;
    }
    else {
      if (hasChanges) {
        return mediaPaths;
      }
      else {
        List<String> paths = [];
        if (product.productMedia?.isNotEmpty ?? false) {
          for (var media in product.productMedia!) {
            paths.add(media['downloadUrl']);
          }
        }
        return paths;
      }
    }
  }

  Future<void> setImagePaths() async {
    if (mediaPaths != null) {
      return;
    }
    else {
      mediaPaths = [];
      if (product.productMedia?.isNotEmpty ?? false) {
        for (var media in product.productMedia!) {
          mediaPaths!.add(media['downloadUrl']);
        }
      }
    }
  }

  Future<List<File>?> getImageFiles({List<String>? paths}) async {
    if (mediaFiles != null) {
      return mediaFiles!;
    }
    else {
      if (hasChanges) {
        return mediaFiles;
      }
      else {
        final basePath = await getTemporaryDirectory();
        List<File> files = [];
        List<String> tempCopy = [];
        if (paths == null) {
          throw "CANNOT CREATE FILE LIST WITHOUT SETTING PATHS";
        }
        for (var path in paths) {
          if (isURL(path)) {
            try {
              final cacheFile = await DefaultCacheManager().getSingleFile(path);
              files.add(cacheFile);
              tempCopy.add(path);
            } catch (e) {
              try {
                final file = await FirebaseUtils.downloadFromFirebaseStorage(url: path, directory: basePath, returnFile: true);

                files.add(file);
                tempCopy.add(path);
              } catch (e) {
                try {
                  final idx = mediaPaths!.indexOf(path);
                  final file = await ApiVideoService.downloadVideo(path, '${basePath.path}/${id}_$idx');
                  files.add(file);
                  tempCopy.add(path);
                } catch (e) {
                  Log.logger.w("Failed to download image from $path. Removing from media paths...");
                }
              }
            }
          }
          else {
            files.add(File(path));
            tempCopy.add(path);
          }
        }
        // mediaPaths = tempCopy;
        return files;
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
      List<String> tempCopy = [];
      for (var path in mediaPaths!) {
        if (isURL(path)) {
          try {
            final cacheFile = await DefaultCacheManager().getSingleFile(path);
            mediaFiles!.add(cacheFile);
            tempCopy.add(path);
          } catch (e) {
            try {
              final file = await FirebaseUtils.downloadFromFirebaseStorage(url: path, directory: basePath, returnFile: true);

              mediaFiles!.add(file);
              tempCopy.add(path);
            } catch (e) {
              try {
                final idx = mediaPaths!.indexOf(path);
                final file = await ApiVideoService.downloadVideo(path, '${basePath.path}/${id}_$idx');
                mediaFiles!.add(file);
                tempCopy.add(path);
              } catch (e) {
                Log.logger.w("Failed to download image from $path. Removing from media paths...");
              }
            }
          }
        }
        else {
          mediaFiles!.add(File(path));
        }
      }
    }
  }

  @override
  Future<void> revertToPublished() async {
    super.revertToPublished();

    final publishedVersion = EItem.getItemById(root: CatalogEditor.publishedCatalog, id: id) as EProduct?;
    if (publishedVersion != null) {
      List<String>? newPaths = await publishedVersion.getImagePaths();
      List<File>? newFiles = (newPaths != null) ? await publishedVersion.getImageFiles(paths: newPaths) : null;
      save(
        name: publishedVersion.name,
        modelNumber: publishedVersion.product.modelNumber,
        description: publishedVersion.product.description,
        brochure: publishedVersion.product.brochure,
        mediaPaths: newPaths,
        mediaFiles: newFiles,
      );
    }
  }

  @override
  void save({
    String? name,
    ECategory? parent,
    String? modelNumber,
    String? description,
    List<Map<String, dynamic>>? brochure,
    List<String>? mediaPaths,
    List<File>? mediaFiles,
    int primaryImageIndex = 0,
  }) {

    const encoder = JsonEncoder.withIndent('  ');

    Log.logger.t(
      """
        Saving product...

        Previous attributes: 
        ${encoder.convert(product.toJson())}
      """
    );

    if (parentId == null) {
      (parent ?? CatalogEditor.all).addItem(this);
    }
    else {
      if (parent != null) {
        if (parentId != parent.id) {
          reassignParent(newParent: parent);
        }
      }
    }


    if (name != null) {
      product.name = name;
      super.name = name;
    }
    if (modelNumber != null) product.modelNumber = modelNumber;
    if (description != null) product.description = description;
    if (brochure != null) product.brochure = brochure;
    if (mediaPaths != null) this.mediaPaths = List.from(mediaPaths);
    if (mediaFiles != null) {
      this.mediaFiles = List.from(mediaFiles);
      if (mediaFiles.isNotEmpty) {
        if (mediaFiles[primaryImageIndex].path.endsWith('.mp4')) {
          final newPrimaryIndex = (mediaFiles.map((x) => x.path).toList()).indexWhere((y) => !y.endsWith('.mp4'));
          if (newPrimaryIndex != -1) {
            primaryImageIndex = newPrimaryIndex;
          }
        }
      }
    }
    else {
      this.mediaFiles = null;
    }
    primaryImageIndex = primaryImageIndex;
    
    setHasChangesRecursive();


    Log.logger.t(
      """
        New attributes:
        ${encoder.convert(product.toJson())}
      """
    );
  }
}

