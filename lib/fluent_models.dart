import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as path_handler;
import 'package:string_validator/string_validator.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/models.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons, TreeView, TreeViewItem;
import 'package:archive/archive_io.dart';



/// The [CatalogEditor] class manages editing operations for catalogs, including 
/// creating editor versions of catalogs, saving locally, uploading to the cloud, 
/// and managing media files.
class CatalogEditor {
  
  /// The main catalog currently being edited.
  static late ECategory all;

  /// The published version of the catalog, fetched if internet is available.
  static late ECategory? publishedCatalog;

  /// The timestamp of the published catalog
  static late DateTime? publishedCatalogTimestamp;

  /// The name of the catalog being edited.
  static late String name;

  /// Whether this catalog is stored locally.
  static late bool isLocal;

  /// Whether the catalog has changes from the local or online file.
  static late bool isUnsaved;

  /// The file where the current catalog is stored locally.
  static File? currentFile;

  /// Constructs a [CatalogEditor] instance using a given [catalog] of type [ProductCategory].
  ///
  /// If internet is available, it retrieves the published catalog version.
  CatalogEditor(ProductCategory catalog) {
    name = ProductManager.name ?? 'Untitled';
    isLocal = false;
    isUnsaved = false;
    createEditorCatalog(catalog);
    if (AppInfo.hasInternet) {
      publishedCatalog = getPublishedVersion(ProductCategory.fromJson(ProductManager.all!.toJson()));
      publishedCatalogTimestamp = ProductManager.timestamp;
    } else {
      publishedCatalog = null;
    }
  }

  /// Creates an editable version of the catalog by transforming a [ProductCategory]
  /// into an [ECategory] structure for easier management in the editor.
  ///
  /// The editor items are recursively processed to maintain hierarchy.
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


  /// Retrieves the published version of the catalog in an editable
  /// format.
  ///
  /// This method is typically used when the app detects internet access.
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


  /// Saves the current catalog to the cloud by updating product images and 
  /// posting the catalog to Firestore.
  ///
  /// An optional [streamController] can be provided to track the progress of 
  /// the operation.
  static Future<void> saveCatalogToCloud({StreamController? streamController}) async {
    try {
      await updateImages(streamController);
      Log.logger.t("Product images updated.");
      ProductManager.all = all.category;
      ProductManager.name = CatalogEditor.name;
      final refer = CatalogEditor.name;
      streamController?.add("Updating catalog...");
      await ProductManager.postCatalogToFirestore(name: name);
      Log.logger.t("Catalog update completed.");
    } catch (e) {
      rethrow;
    }
  }


  /// Updates images associated with the catalog by uploading them to Firebase
  /// storage.
  ///
  /// An optional [stream] can be provided to report progress.
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


  /// Saves the catalog locally to a specified [path], creating a zip encoded file 
  /// that includes both the catalog JSON and any associated media files.
  ///
  /// This method uses temporary directories to store backup images before 
  /// packaging..
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


  /// Uploads a locally saved catalog from the specified [path].
  ///
  /// The catalog is expected to be a WTF (zip-encoded) file containing the JSON representation 
  /// of the catalog and its associated media files. The ZIP file is extracted, 
  /// and the catalog is deserialized into an [ECategory] object, which is then set 
  /// as the current catalog for editing.
  ///
  /// If provided, the optional [onComplete] callback will be invoked after 
  /// the catalog is successfully uploaded and processed.
  ///
  /// Throws an exception if there is an error during the upload or extraction process.
  ///
  /// - [path] : The path of the WTF (zip) file to be uploaded.
  /// - [onComplete] : A callback function that is called when the upload process completes.
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


  /// Recursively stores backup images for the catalog by copying media files
  /// into a specified [directory] and creating archive files from them.
  ///
  /// Returns a list of [ArchiveFile]s representing the media files.
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


/// A sealed class representing an item in the catalog, which can be either a category or a product.
sealed class EItem {
  /// The name of the item.
  String name;

  /// The unique identifier for the item.
  final String id;

  /// The identifier of the parent item, if any.
  String? parentId;

  /// A flag indicating whether the item has unsaved changes.
  bool hasChanges;

  /// Creates an instance of [EItem].
  ///
  /// - [id] : The unique identifier for the item.
  /// - [name] : The name of the item.
  /// - [parentId] : The identifier of the parent item (optional).
  /// - [hasChanges] : Indicates whether the item has unsaved changes (default is false).
  EItem({required this.id, required this.name, this.parentId, this.hasChanges = false});


  /// Retrieves an item by its unique identifier from the catalog hierarchy.
  ///
  /// - [root] : The root category from which the search starts.
  /// - [id] : The unique identifier of the item to find.
  /// 
  /// Returns the [EItem] if found, otherwise returns null.
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


  /// Retrieves an item by its name from the catalog hierarchy.
  ///
  /// - [root] : The root category from which the search starts.
  /// - [name] : The name of the item to find.
  /// 
  /// Returns the [EItem] if found, otherwise returns null.
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

  /// Gets the parent category of the item.
  ///
  /// Returns the parent [ECategory] if found, otherwise returns null.
  ECategory? getParent() {
    return getItemById(root: CatalogEditor.all, id: parentId) as ECategory?;
  }


  /// Retrieves the sub-items of this item.
  List<EItem> getSubItems() {
    return [];
  }


  /// Removes the item from its parent category.
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


  /// Reassigns the item to a new parent category.
  ///
  /// - [newParent]  The new parent category to assign to.
  /// - [atIndex] : The index at which to add the item (optional).
  void reassignParent({required ECategory newParent, int? atIndex}) {
    removeFromParent();

    newParent.addItem(this, index: atIndex);
  }


  /// Reorders the item within its parent category.
  ///
  /// - [newIndex] : The new index for the item.
  void reorderItem({required newIndex}) {
    final parent = getParent();
    if (parent!.editorItems.indexOf(this) <= newIndex) {
      newIndex -= 1;
    }
    removeFromParent();
    parent.addItem(this, index: newIndex);
  }

  /// Marks the item and its ancestors as having changes.
  void setHasChangesRecursive() {
    
    void traverse(ECategory? item) {
      if (item != null) {
        item.branchHasChanges = true;
        traverse(item.getParent());
      }
    }

    hasChanges = true;
    traverse(getParent());
    CatalogEditor.isUnsaved = true;
  }

  /// Saves the item. Must be implemented by subclasses.
  void save();

  /// Deletes the item from its parent category and marks its parent as changed.
  void delete() {
    getParent()?.setHasChangesRecursive();
    removeFromParent();
  }

  /// Serializes the item to a JSON representation.
  ///
  /// Returns a map containing the item's properties.
  Map<String, dynamic> toJson() {
    return {
      'name' : name,
      'id' : id,
      'parentId' : parentId,
      'hasChanges' : false,
    };
  }


  /// Deserializes an item from a JSON representation.
  ///
  /// - [json] : A map containing the item's properties.
  /// 
  /// Returns an instance of [EItem], either [ECategory] or [EProduct].
  static EItem fromJson(Map<String, dynamic> json) {
    if (json['editorItems'] != null) {
      return ECategory.fromJson(json);
    }
    else {
      return EProduct.fromJson(json);
    }
  }


  /// Reverts the item to its published state.
  ///
  /// This method can be overridden by subclasses to provide specific functionality.
  Future<void> revertToPublished() async {}
}


/// Represents a category in the catalog, extending [EItem].
class ECategory extends EItem {
  /// The underlying [ProductCategory] that this category represents.
  final ProductCategory category;

  /// A list of editor items (subcategories or products) within this category.
  List<EItem> editorItems;

  /// The path to the category's image, if available.
  String? imagePath;

  /// The image file associated with this category, if available.
  File? imageFile;

  /// A flag indicating whether the category or any of its subcategories have changes.
  bool branchHasChanges = false;

  /// Creates an instance of [ECategory].
  ///
  /// - [category] : The underlying [ProductCategory].
  /// - [editorItems] : A list of editor items within this category.
  /// - [imagePath] : The path to the category's image (optional).
  ECategory({required this.category, required this.editorItems, this.imagePath}) 
      : super(id: category.id, name: category.name, parentId: category.parentId) {
    if (imagePath != null) imageFile = File(imagePath!);
  }

  /// Creates a temporary instance of [ECategory] with an empty list of editor items.
  ECategory.temp() : this(category: ProductCategory.temp(), editorItems: []);

  /// Returns the list of editor items (subcategories or products) contained in this category.
  @override
  List<EItem> getSubItems() {
    return editorItems;
  }


  /// Retrieves all subcategories of this category, optionally excluding specified categories.
  /// 
  /// - [categoriesToExclude] : A list of categories to exclude from the result (optional).
  /// - Returns: A list of all subcategories within this category, excluding any specified in [categoriesToExclude].
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


  /// Adds an item (either an [ECategory] or [EProduct]) to this category.
  ///
  /// The item is assigned a parent ID corresponding to this category's ID.
  /// 
  /// If an index is provided, the item is inserted at that index; otherwise, it is appended to the end of the list.
  ///
  /// - [item] : The item to be added, which can be either an [ECategory] or [EProduct].
  /// - [index] : The optional index at which to insert the item. If not provided, the item is added to the end of the list.
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


  /// Retrieves the image path for this category.
  ///
  /// If [imagePath] is already set, it returns that path.
  /// If there are changes but no image path, it returns the existing path.
  /// If the category has an image provider, it checks for an image URL and returns it.
  /// Returns an empty string if no valid path is found.
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


  /// Sets the image path for this category.
  ///
  /// If [imagePath] is already set, it does nothing.
  /// If the category has an image provider and a valid image URL, it sets the [imagePath].
  /// Otherwise, it sets the [imagePath] to an empty string.
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


  /// Retrieves the image file associated with this category.
  ///
  /// If [imageFile] is already set, it returns that file.
  /// If there are changes, it returns the existing image file.
  /// If [path] is not provided or is an empty string, it logs an error or a warning accordingly.
  /// If the [path] is a URL, it attempts to download the image and return the file.
  /// Returns `null` if no valid file is found.
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
            final cacheFile = await FileUtils.cacheManager.getSingleFile(path);
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


  /// Sets the image file for this category.
  ///
  /// If [imageFile] is already set, it does nothing.
  /// If the [imagePath] is a valid URL, it attempts to download the image and sets the [imageFile].
  /// If the [imagePath] is not empty, it creates a File instance from the path.
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


  /// Saves the current state of the category, including optional updates to its name,
  /// parent category, image path, and image file.
  ///
  /// If [parent] is not specified, the category will be added to the current parent
  /// (or the root if no parent exists). If the category already has a parent and the 
  /// new parent is different, it will reassign the parent. It will also update the 
  /// image path and image file if provided.
  ///
  /// The method sets the `hasChanges` flag recursively to indicate changes have been made.
  ///
  /// [name] - The new name for the category. If null, the name will remain unchanged.
  /// [parent] - The new parent category. If null, it defaults to the current parent.
  /// [imagePath] - The new image path for the category. If null, the image path will remain unchanged.
  /// [imageFile] - The new image file associated with the category. If null, the image file will remain unchanged.
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


  /// Converts this category instance to a JSON-compatible map.
  ///
  /// Returns a map representation of the category, including its ID, name, parent ID,
  /// the associated category, and its editor items.
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['category'] = category.toJson();
    json['editorItems'] = editorItems.map((item) => item.toJson()).toList();
    json['imagePath'] = imagePath;
    return json;
  }


  /// Creates a new instance of [ECategory] from a JSON map.
  ///
  /// The [json] parameter must contain the keys 'category', 'editorItems', and 'imagePath'.
  /// Returns an [ECategory] populated with the data from the JSON map.
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


  /// Reverts the category to its published state by restoring its attributes from the published catalog.
  ///
  /// This method retrieves the published version of the category using its ID, then sets
  /// the current category's attributes (name, image path, and image file) to match the 
  /// published version. It calls the superclass method to handle any additional revert logic.
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


/// Represents a product in the catalog, extending [EItem].
class EProduct extends EItem {
  /// The underlying product data.
  final Product product;

  /// A list of media paths associated with the product.
  List<String>? mediaPaths;

  /// A list of media files associated with the product.
  List<File>? mediaFiles;

  /// The index of the primary image in the media files.
  int primaryImageIndex;

  
  /// Creates an instance of [EProduct].
  ///
  /// [product] is the underlying product data.
  /// [mediaPaths] is an optional list of media paths.
  /// [primaryImageIndex] is an optional index for the primary image, defaulting to 0.
  EProduct({
    required this.product,
    this.mediaPaths,
    primaryImageIndex,
  })  : primaryImageIndex = primaryImageIndex ?? 0,
        super(id: product.id, name: product.name, parentId: product.parentId) {
    if (mediaPaths != null) {
      mediaFiles = [];
      for (var path in mediaPaths!) {
        try {
          mediaFiles!.add(File(path));
        } catch (e, trace) {
          Log.logger.w("Failed to add file at $path", error: e, stackTrace: trace);
        }
      }
    }
  }

  /// Creates a temporary instance of [EProduct].
  ///
  /// This constructor initializes the product with a temporary product.
  EProduct.temp() : this(product: Product.temp());

  /// Creates an instance of [EProduct] from a JSON map.
  ///
  /// [json] - a map containing the product data.
  factory EProduct.fromJson(Map<String, dynamic> json) {
    return EProduct(
      product: Product.fromJson(json['product']),
      mediaPaths: json['mediaPaths'] != null ? List<String>.from(json['mediaPaths']) : null,
      primaryImageIndex: json['primaryImageIndex'],
    );
  }


  /// Converts the [EProduct] instance to a JSON map.
  ///
  /// This method overrides the [toJson] method from [EItem] and adds
  /// the product-specific properties to the resulting JSON map.
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['product'] = product.toJson();
    json['mediaPaths'] = mediaPaths;
    json['primaryImageIndex'] = primaryImageIndex;

    return json;
  }


  /// Retrieves the list of image paths associated with the product.
  ///
  /// If [mediaPaths] is already set, it returns those paths.
  /// If there are changes, it returns the current [mediaPaths].
  /// Otherwise, it checks the product's media and builds a list of
  /// download URLs from it.
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

  /// Sets the list of image paths based on the product's media.
  ///
  /// This method initializes [mediaPaths] with download URLs from the 
  /// product's media if [mediaPaths] is not already set.
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


  /// Retrieves the list of image files associated with the product.
  ///
  /// If [mediaFiles] is already set, it returns those files.
  /// If there are changes, it returns the current [mediaFiles].
  /// Otherwise, it checks the provided [paths] to build a list of files,
  /// attempting to download them from URLs or create files from local paths.
  /// 
  /// Throws an error if [paths] is null.
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
              final cacheFile = await FileUtils.cacheManager.getSingleFile(path);
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

  /// Sets the list of image files based on the media paths.
  ///
  /// This method initializes [mediaFiles] with files corresponding to the
  /// URLs or local paths in [mediaPaths]. 
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
            final cacheFile = await FileUtils.cacheManager.getSingleFile(path);
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

  /// Reverts the current product to its published version.
  ///
  /// If no published version is found, the current product remains unchanged.
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


  /// Saves the attributes of the product, updating its details and media files.
  /// 
  /// This method allows updating the following attributes of the product:
  /// - [name] : The name of the product.
  /// - [parent] : The new parent category for this product, if applicable.
  /// - [modelNumber] : The model number of the product.
  /// - [description] : A description of the product.
  /// - [brochure] : A brochure associated with the product, represented as a list of key-value maps.
  /// - [mediaPaths] : A list of paths to media files associated with the product.
  /// - [mediaFiles] : A list of media files represented as [File] objects.
  /// - [primaryImageIndex] : The index of the primary image in the media files list.
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

