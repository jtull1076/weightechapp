import 'package:google_fonts/google_fonts.dart';
import 'package:weightechapp/extra_fluent_widgets.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/themes.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/brochure.dart';
import 'package:weightechapp/universal_routes.dart';
import 'package:weightechapp/fluent_models.dart';
import 'package:flutter/material.dart' as material hide CarouselController;
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons, TreeView, TreeViewItem;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:weightechapp/extra_material_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:feedback_github/feedback_github.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shortid/shortid.dart';
import 'package:string_validator/string_validator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_saver/file_saver.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:updat/updat.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';


//MARK: OFFLINE PAGE

/// A class defining the stateful HomePage, i.e. the 'All' category listing page. 
/// 
/// Defined separately as stateful to handle all animations from [IdlePage]. 
/// 
/// See also: [_OfflinePageState]
class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> with TickerProviderStateMixin {
  late StreamSubscription listener;
  
  @override
  void initState() {
    super.initState();
    Log.logger.w("System is offline! Waiting for Internet connection...");
    listener = InternetConnection().onStatusChange
      .listen((InternetStatus status) {
        switch (status) {
          case InternetStatus.connected:
            // The internet is now connectioni
            if (mounted) Navigator.of(context).pop();
            break;
          case InternetStatus.disconnected:
            // The internet is now disconnected
            break;
        }
      });
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: Stack(
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              alignment: Alignment.topCenter,
              child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo_beta.png', fit: BoxFit.scaleDown))
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("You're offline", style: TextStyle(fontSize: 25)),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(FluentIcons.wifi_off_20_regular, size: 50,),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: LoadingAnimationWidget.twoRotatingArc(color: WeightechThemes.weightechBlue, size: 100)
                      )
                    ]
                  ),
                  const Text("Waiting for Internet connection"),
                ]
              )
            )
          ]
        )
      )
    );
  }
}


//MARK: ERROR PAGE
/// A class defining the stateless [ErrorPage]. Used as the landing page (though not called "LandingPage" because "IdlePage" seemed more apt). 
class ErrorPage extends StatelessWidget {
  final Object? message;
  const ErrorPage({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: Stack(
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              alignment: Alignment.topCenter,
              child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo_beta.png', fit: BoxFit.scaleDown))
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Error Occurred", style: TextStyle(fontSize: 25)),
                  const Icon(FluentIcons.error_circle_20_regular, size: 160),
                  (message != null)
                  ? Text("$message")
                  : const Text("Unknown error."),
                  const Text("Restart the app to try again."),
                ]
              )
            )
          ]
        )
      )
    );
  }
}


class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> with TickerProviderStateMixin {
  late String _startupTaskMessage;
  late StreamController<String> _progressStreamController;
  late bool _updateReady;
  late bool _checkingForUpdate;

  @override
  void initState() {
    super.initState();
    _startupTaskMessage = '';
    _progressStreamController = StreamController<String>();
    _updateReady = false;
    _checkingForUpdate = false;
    _runStartupTasks();
  }

  Future<void> _runStartupTasks() async { 

    if (!await InternetConnection().hasInternetAccess) {
      if (mounted) {
        await Navigator.of(context).push(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const OfflinePage()));
      }
    }

    try {
      Log.logger.t('...Clearing existing cache');
      _progressStreamController.add('...Clearing cache...');
      await FileUtils.cacheManager.emptyCache();

      Log.logger.t('...Initializing Firebase...');
      _progressStreamController.add('...Initializing Firebase...');
      await FirebaseUtils().init();

      Log.logger.t('...Initializing Product Manager...');
      _progressStreamController.add('...Initializing Product Manager...');

      await ProductManager.create();
    } catch (e) {
      Log.logger.e("Error encountered retrieving catalog.", error: e);
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => ErrorPage(message: e)));
      }
    }

    Log.logger.t('...App Startup...');
    _progressStreamController.add('...App Startup...');

    _progressStreamController.close();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: 
            StreamBuilder(
              stream: _progressStreamController.stream,
              initialData: '',
              builder:(context, AsyncSnapshot<String> snapshot) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: Image.asset('assets/icon/wt_icon.ico', height: 200),
                    ),
                    const SizedBox(height: 10), 
                    (snapshot.connectionState == ConnectionState.active) 
                    ? (snapshot.hasData) 
                      ? Column(
                          children: [
                            Text(AppInfo.packageInfo.version),
                            const SizedBox(height: 5),
                            const ProgressBar(activeColor: WeightechThemes.weightechBlue),
                            const SizedBox(height: 10),
                            Text(snapshot.data!)
                          ]
                        )
                      : const ProgressBar(activeColor: WeightechThemes.weightechBlue)
                    : (snapshot.connectionState == ConnectionState.done)
                      ? Stack(
                        children: [
                          Center(
                            child: UpdatWidget(
                              updateChipBuilder: fluentChip,
                              updateDialogBuilder: fluentUpdateDialog,
                              currentVersion: AppInfo.packageInfo.version,
                              getLatestVersion: () async {
                                // Use Github latest endpoint
                                try {
                                  final data = await http.get(
                                    Uri.parse(
                                    "https://api.github.com/repos/jtull1076/weightechapp/releases/latest"
                                    ),
                                    headers: {
                                      'Authorization': 'Bearer ${FirebaseUtils.githubToken}'
                                    }
                                  );
                                  final latestVersion = jsonDecode(data.body)["tag_name"];
                                  final verCompare = AppInfo.versionCompare(latestVersion, AppInfo.packageInfo.version);
                                  Log.logger.i('Latest version: $latestVersion : This app version is ${(verCompare == 0) ? "up-to-date." : (verCompare == 1) ? "deprecated." : "in development."}');
                                  return latestVersion;
                                } catch (e) {
                                  Log.logger.e("Error encounted retrieving latest version.", error: e);
                                }
                                return null;
                              },
                              getBinaryUrl: (version) async {
                                return "https://github.com/jtull1076/weightechapp/releases/download/$version/weightechsales-windows-$version.exe";
                              },
                              appName: "WeighTech Inc. Sales",
                              getChangelog: (_, __) async {
                                final data = await http.get(
                                  Uri.parse(
                                  "https://api.github.com/repos/jtull1076/weightechapp/releases/latest"
                                  ),
                                  headers: {
                                    'Authorization': 'Bearer ${FirebaseUtils.githubToken}'
                                  }
                                );
                                Log.logger.t('Changelog: ${jsonDecode(data.body)["body"]}');
                                return jsonDecode(data.body)["body"];
                              },
                              callback: (status) {
                                if (status == UpdatStatus.upToDate || status == UpdatStatus.error || status == UpdatStatus.dismissed) {
                                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                    Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const ControlPage()));
                                  });
                                }
                                // else if (status == UpdatStatus.readyToInstall) {
                                //   setState(() => _updateReady = true);
                                // }
                              }
                            )
                          ),
                        ]
                      )
                    : const Text("Other")
                  ]
                );
              }
            )
      )
    );
  }
}


//MARK: CONTROL PAGE

/// A class defining the stateful [ControlPage]. This is used for controlling (obviously) the app settings and editing the catalog. 
/// 
/// Stateful for handling [IdlePage] -> [ControlPage] animation
/// 
/// See also: [_ControlPageState]
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}


class _ControlPageState extends State<ControlPage> with TickerProviderStateMixin, WindowListener {

  late TextEditingController _filenameController;
  late bool _editingName;

  late List<CommandBarItem> _secondaryCommands;

  late ECategory _selectedCategory;
  late List<BrochureItem> _brochure;


  EItem? _focusItem;
  late bool _addingItem;

  final TextEditingController _dropdownController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late List<String> _mediaPaths;
  late List<File> _mediaFiles;
  late int _primaryImageIndex;
  late bool _fileDragging;

  late bool _loadingSomething;
  late Widget _loadingWidget;
  late bool _ignoringPointer;

  late TreeController<EItem> _treeController;


  // ignore: unused_field
  late ECategory _editorAll;

  // ignore: unused_field
  late ECategory _cloudVersion;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    
    CatalogEditor(ProductManager.all!);
    _editorAll = CatalogEditor.all;
    _cloudVersion = CatalogEditor.all;

    _filenameController = TextEditingController(text: CatalogEditor.name);
    _editingName = false;

    _treeController = TreeController<EItem>(
      // Provide the root nodes that will be used as a starting point when
      // traversing your hierarchical data.
      roots: CatalogEditor.all.editorItems,
      // Provide a callback for the controller to get the children of a
      // given node when traversing your hierarchical data. Avoid doing
      // heavy computations in this method, it should behave like a getter.
      childrenProvider: (EItem item) => item.getSubItems(),
      parentProvider: (EItem item) => item.getParent()
    );
    
    _selectedCategory = CatalogEditor.all;

    _addingItem = false;

    _mediaPaths = [];
    _mediaFiles = [];
    _primaryImageIndex = 0;
    _fileDragging = false;

    _loadingSomething = true;
    _loadingWidget = const ProgressRing();
    _ignoringPointer = true;

    _secondaryCommands = [
      // TODO : implement this
      CommandBarButton(
        icon: const Icon(FluentIcons.settings_20_regular),
        label: const Text('Settings'),
        onPressed: () {},
      ),
      CommandBarButton(
        icon: const Icon(FluentIcons.info_20_regular),
        label: const Text('Info'),
        onPressed: () async {
          _showInfoDialog(context);
        },
      ),
      CommandBarButton(
        icon: const Icon(FluentIcons.arrow_sync_checkmark_20_regular),
        label: const Text('Check For Update'),
        onPressed: () async {
          await _checkForUpdate(context);
        },
      ),
      CommandBarButton(
        icon: const Icon(FluentIcons.bug_20_regular),
        label: const Text('Report Bug'),
        onPressed: () async {
          String id = shortid.generate();
          BetterFeedback.of(context).showAndUploadToGitHub(
            username: 'jtull1076',
            repository: 'weightechapp',
            authToken:  FirebaseUtils.githubToken,
            labels: ['feedback'],
            assignees: ['jtull1076'],
            imageId: id,
          );
        },
      )
    ];

    toggleEditorItem(_focusItem);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //Future.delayed(const Duration(seconds: 5), () =>
      setState(() => _toggleLoading());
      //);
    });
  }
  
  @override
  void dispose() {
    _dropdownController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _modelNumberController.dispose();
    _treeController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: Container(
        alignment: Alignment.topCenter,
        height: 50,
        width: MediaQuery.of(context).size.width,
        child: 
          CommandBarCard(
            borderRadius: const BorderRadius.all(Radius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            // margin: const EdgeInsets.symmetric(horizontal: 5),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: 
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WeightechThemes.wtGray.darker,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      width: 100,
                      height: 40,
                      child: IntrinsicWidth(
                        child: TapRegion(
                          onTapOutside: (e) => setState(() => _editingName = false),
                          child: TextBox(
                            controller: _filenameController,
                            decoration: const BoxDecoration(color: Colors.transparent),
                            textAlign: TextAlign.center,
                            padding: EdgeInsets.zero,
                            suffix: (CatalogEditor.isUnsaved) ? const Text('*', style: TextStyle(color: Colors.white, fontSize: 12)) : null,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            onEditingComplete: () {
                              CatalogEditor.name = _filenameController.text;
                              _editingName = false;
                            },
                            onTap: () => setState(() => _editingName = true),
                            onChanged: (s) => setState(() => _editingName = true),
                          ),
                        )
                      )
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      fit: FlexFit.loose,
                      child: CommandBar(
                        overflowBehavior: CommandBarOverflowBehavior.scrolling,
                        primaryItems: [
                          CommandBarButton(
                            icon: const Icon(FluentIcons.save_edit_20_regular),
                            label: const Text('Save As', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              FilePickerResult? _ = 
                                await FilePicker.platform
                                  .saveFile(dialogTitle: 'Save As', fileName: '${_filenameController.text}.wtf', allowedExtensions: ['wtf'], type: FileType.custom)
                                  .then((result) async {
                                    if (result != null) {
                                      if (FileUtils.extension(result) != '.wtf') {
                                        result += '.wtf';
                                      }
                                      await CatalogEditor.saveCatalogLocal(path: result);
                                      setState(() => _filenameController.text = FileUtils.filename(CatalogEditor.currentFile!.path));
                                    }
                                    else {
                                      Log.logger.t("-> File save aborted/failed.");
                                      return null;
                                    }
                                    return null;
                                  });
                            },
                          ),
                          if (CatalogEditor.isLocal)
                            CommandBarButton(
                              icon: const Icon(FluentIcons.save_20_regular),
                              label: const Text('Save', style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                if (CatalogEditor.currentFile != null) {
                                    await CatalogEditor.saveCatalogLocal(path: CatalogEditor.currentFile!.path);
                                }
                              }
                            ),
                          CommandBarButton(
                            icon: const Icon(FluentIcons.folder_open_20_regular),
                            label: const Text('Open', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              FilePickerResult? _ =
                                await FilePicker.platform.
                                  pickFiles(dialogTitle: "Open", type: FileType.custom, allowedExtensions: ['wtf'])
                                  .then((result) async {
                                    if (result != null) {
                                      setState(() {
                                        _toggleLoading();
                                        _focusItem = null;
                                      });
                                      await CatalogEditor.uploadCatalogLocal(
                                        path: result.paths.first!,
                                        onComplete: () {
                                          _treeController.rebuild();
                                          setState(() {
                                            _editorAll = CatalogEditor.all;
                                            _selectedCategory = CatalogEditor.all;
                                            _filenameController.text = CatalogEditor.name;

                                            _treeController = TreeController<EItem>(
                                              // Provide the root nodes that will be used as a starting point when
                                              // traversing your hierarchical data.
                                              roots: CatalogEditor.all.editorItems,
                                              // Provide a callback for the controller to get the children of a
                                              // given node when traversing your hierarchical data. Avoid doing
                                              // heavy computations in this method, it should behave like a getter.
                                              childrenProvider: (EItem item) => item.getSubItems(),
                                              parentProvider: (EItem item) => item.getParent()
                                            );
                                          
                                            _toggleLoading();
                                          });
                                        }
                                      );
                                      
                                    }
                                    else {
                                      Log.logger.t("-> File open aborted/failed.");
                                    }
                                    return null;
                                  });
                            },
                          ),
                          const CommandBarSeparator(
                            thickness: 0.5,
                            color: Colors.black,
                          ),
                          CommandBarButton(
                            icon: const Icon(FluentIcons.cloud_arrow_up_20_regular),
                            label: const Text('Publish', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              StreamController<dynamic> streamController = StreamController<dynamic>();
                              setState(() => _toggleLoading(dynamicStream: streamController.stream));
                              CatalogEditor.name = _filenameController.text;
                              await CatalogEditor.saveCatalogToCloud(streamController: streamController);
                              streamController.add(
                                const Icon(
                                  FluentIcons.checkmark_circle_48_filled, 
                                  color: WeightechThemes.weightechBlue, 
                                  size: 30
                                )
                              );
                              await Future.delayed(const Duration(seconds: 2))
                                .then((value) {
                                  setState(() => _toggleLoading());
                                });
                            },
                          ),
                          CommandBarButton(
                            icon: const Icon(FluentIcons.clock_arrow_download_20_regular),
                            label: const Text('Restore Previous', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final chosenCatalog = await _showRestorationDialog(context);
                              if (chosenCatalog != null) {
                                Log.logger.i(
                                  """ Catalog restored to previous version. Version info: 
                                  Name: ${chosenCatalog['name']}
                                  Timestamp: ${chosenCatalog['timestamp']}
                                  """
                                );
                                await ProductManager.createFromMap(chosenCatalog);
                                CatalogEditor.createEditorCatalog(ProductManager.all!);
                                _treeController.rebuild();
                                setState(() {
                                  _editorAll = CatalogEditor.all;

                                  _treeController = TreeController<EItem>(
                                    // Provide the root nodes that will be used as a starting point when
                                    // traversing your hierarchical data.
                                    roots: CatalogEditor.all.editorItems,
                                    // Provide a callback for the controller to get the children of a
                                    // given node when traversing your hierarchical data. Avoid doing
                                    // heavy computations in this method, it should behave like a getter.
                                    childrenProvider: (EItem item) => item.getSubItems(),
                                    parentProvider: (EItem item) => item.getParent()
                                  );
                                
                                  _selectedCategory = CatalogEditor.all;
                                });
                              }
                            },
                          ),
                          const CommandBarSeparator(
                            thickness: 0.5,
                            color: Colors.black,
                          ),
                          CommandBarButton(
                            icon: const Icon(FluentIcons.production_20_regular),
                            label: const Text('New Product', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              final newProduct = EProduct.temp();
                              toggleEditorItem(newProduct, newItem: true);
                            },
                          ),
                          CommandBarButton(
                            icon: const Icon(FluentIcons.list_bar_20_regular),
                            label: const Text('New Category', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              final newCategory = ECategory.temp();
                              toggleEditorItem(newCategory, newItem: true);
                            },
                          ),
                          if (_focusItem != null) ... [
                            const CommandBarSeparator(
                              thickness: 0.5,
                              color: Colors.black,
                            ),
                            const CommandBarSeparator(),
                            CommandBarBuilderItem(
                              builder: (context, displayMode, child) {
                                return Container(
                                  constraints: const BoxConstraints(minWidth: 80),
                                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: WeightechThemes.wtGray.light,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    )
                                  ),
                                  child: child
                                );
                              }, 
                              wrappedItem: CommandBarButton(
                                icon: const Icon(FluentIcons.document_save_20_regular, color: Colors.black),
                                label: const Text('Save', style: TextStyle(fontSize: 12, color: Colors.black)),
                                onPressed: () {
                                  if (_focusItem is EProduct) {
                                    if (_formKey.currentState!.validate()) {
                                      if (_addingItem) {
                                        Product newProduct = Product(
                                          name: _nameController.text,
                                          modelNumber: _modelNumberController.text,
                                          description: _descriptionController.text,
                                          brochure: mapListToBrochure(_brochure)
                                        );
                                        EProduct newEProduct = EProduct(product: newProduct,);
                                        
                                        newEProduct.save(
                                          parent: _selectedCategory,
                                          mediaPaths: List.from(_mediaPaths),
                                          mediaFiles: List.from(_mediaFiles)
                                        );
                                      }
                                      else {
                                        final product = _focusItem as EProduct;
                                        product.save(
                                          name: _nameController.text,
                                          parent: _selectedCategory,
                                          modelNumber: _modelNumberController.text,
                                          description: _descriptionController.text,
                                          brochure: mapListToBrochure(_brochure),
                                          mediaPaths: List.from(_mediaPaths),
                                          mediaFiles: List.from(_mediaFiles),
                                          primaryImageIndex: _primaryImageIndex,
                                        );                       
                                      }
                                      setState(() {
                                        _treeController.rebuild();
                                        _addingItem = false;
                                        _focusItem = null;
                                      });
                                    }
                                  }
                                  else if (_focusItem is ECategory) {
                                    if (_addingItem) {
                                      ProductCategory newCategory = ProductCategory(
                                        name: _nameController.text,
                                      );
                                      ECategory newECategory = ECategory(category: newCategory, editorItems: []);
                                      
                                      newECategory.save(
                                        parent: _selectedCategory,
                                        imagePath: (_mediaPaths.isEmpty) ? null : _mediaPaths.first,
                                        imageFile: (_mediaFiles.isEmpty) ? null : _mediaFiles.first
                                      );
                                    }
                                    else {
                                      final category = _focusItem as ECategory;
                                      category.save(
                                        name: _nameController.text,
                                        parent: _selectedCategory,
                                        imagePath: (_mediaPaths.isEmpty) ? null : _mediaPaths.first,
                                        imageFile: (_mediaFiles.isEmpty) ? null : _mediaFiles.first,
                                      );
                                    }
                                    setState(() {
                                      _treeController.rebuild();
                                      _addingItem = false;
                                      _focusItem = null;
                                    });
                                  }
                                }
                              )
                            ),
                            if (_focusItem is EProduct) 
                              CommandBarBuilderItem(
                                builder: (context, displayMode, child) {
                                  return Container(
                                    constraints: const BoxConstraints(minWidth: 80),
                                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: WeightechThemes.wtGray.light,
                                    ),
                                    child: child
                                  );
                                }, 
                                wrappedItem: CommandBarButton(
                                  icon: const Icon(FluentIcons.eye_20_regular, color: Colors.black),
                                  label: const Text('Preview', style: TextStyle(fontSize: 12, color: Colors.black)),
                                  onPressed: () {
                                    _showPreviewDialog(context);
                                  },
                                )
                              ),
                            if (!_addingItem && (CatalogEditor.publishedCatalog != null))
                              CommandBarBuilderItem(
                                builder: (context, displayMode, child) {
                                  return Container(
                                    constraints: const BoxConstraints(minWidth: 80),
                                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: WeightechThemes.wtGray.light,
                                    ),
                                    child: child
                                  );
                                }, 
                                wrappedItem: CommandBarButton(
                                  icon: const Icon(FluentIcons.arrow_counterclockwise_20_regular, color: Colors.black),
                                  label: const Text('Revert', style: TextStyle(fontSize: 12, color: Colors.black)),
                                  onPressed: () async {
                                    final confirmed = await _showItemRevertDialog(context, _focusItem!, currentName: _nameController.text);
                                    if (confirmed) {
                                      setState(() => _toggleLoading());

                                      final item = _focusItem!;

                                      Log.logger.i('Reverting ${item.name} (ID: ${item.id}) to its published version...');

                                      final id = item.id;
                                      setState(() => _focusItem = null);

                                      await item.revertToPublished();

                                      Log.logger.i('-> Done');

                                      _treeController.rebuild();
                                      final newVersion = EItem.getItemById(root: CatalogEditor.all, id: id);
                                      setState(() => _toggleLoading());
                                      toggleEditorItem(newVersion);
                                    }
                                  },
                                )
                              ),
                            CommandBarBuilderItem(
                              builder: (context, displayMode, child) {
                                return Container(
                                  constraints: const BoxConstraints(minWidth: 80),
                                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: WeightechThemes.wtGray.light,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    )
                                  ),
                                  child: child
                                );
                              }, 
                              wrappedItem: CommandBarButton(
                                icon: const Icon(FluentIcons.delete_20_regular, color: Colors.black),
                                label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.black)),
                                onPressed: () async {
                                  final confirmed = await _showItemDeleteDialog(context, _focusItem!, currentName: _nameController.text);
                                  if (confirmed) {
                                    _focusItem!.delete();
                                    _treeController.rebuild();
                                    setState(() => _focusItem = null);
                                  }
                                },
                              )
                            )
                          ]
                        ],
                      ),
                    ),
                    IntrinsicWidth(
                      child: CommandBar(
                        overflowBehavior: CommandBarOverflowBehavior.wrap,
                        mainAxisAlignment: material.MainAxisAlignment.end,
                        primaryItems: const [
                          CommandBarSeparator()
                        ],
                        secondaryItems: _secondaryCommands,
                      )
                    )
                  ]
                )
                
            )
          )
      ),
      content: IgnorePointer(
        ignoring: _ignoringPointer,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: 1,
                    color: Color(0x19000000)
                  )
                )
              ),
              child: 
                Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F3F3),
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: Color(0x19000000)
                            ),
                          )
                        ),
                        child: catalogBuilder(item: CatalogEditor.all)
                      ),
                    ),
                    Flexible(
                      flex: 3,
                      child: (_focusItem != null) ?
                        (_focusItem is ECategory) ? 
                          categoryEditor(category: _focusItem as ECategory)
                          : productEditor(product: _focusItem as EProduct)
                        : const Center(
                            child: Text("Select a catalog item on the left side to begin.")
                          )
                    )
                  ]
                ),
            ),
            if (_loadingSomething) 
                // child: LoadingAnimationWidget.twistingDots(
                //   leftDotColor: WeightechThemes.weightechBlue, 
                //   rightDotColor: WeightechThemes.weightechGray, 
                //   size: 40
                // ),=
              _loadingWidget
          ]
        )
      )
    );
  }

  Widget catalogBuilder({required ECategory item}) {
    return buildItemsList(item: item);
  }

  Widget buildItemsList({required ECategory item}) {
    final flyoutController = FlyoutController();

    return AnimatedTreeView<EItem>(
      shrinkWrap: false,
      treeController: _treeController,
      nodeBuilder: (BuildContext context, TreeEntry<EItem> entry) {
        return TreeDragTarget<EItem>(
        toggleExpansionDelay: const Duration(milliseconds: 750),
        node: entry.node,
        onNodeAccepted: (TreeDragAndDropDetails details) {
          // Optionally make sure the target node is expanded so the dragging
          // node is visible in its new vicinity when the tree gets rebuilt.
          // _treeController.setExpansionState(details.targetNode as EItem, true);

          // TODO: implement your tree reorder logic
          final targetNode = details.targetNode as EItem;
          final draggedNode = details.draggedNode as EItem;
          final targetParent = targetNode.getParent();

          if (targetParent == draggedNode.getParent()) {
            details.mapDropPosition(
              whenAbove: () {
                final newIndex = targetParent!.editorItems.indexOf(targetNode);

                draggedNode.reorderItem(newIndex: newIndex);
              }, 
              whenInside: () {
                if (targetNode is ECategory) {
                  (draggedNode).reassignParent(newParent: targetNode);
                }
              }, 
              whenBelow: () {
                if (entry.isExpanded) {
                  if (targetNode is ECategory) {
                    final newParent = targetNode;

                    draggedNode.reassignParent(newParent: newParent, atIndex: 0);
                  }
                }
                else {
                  final newIndex = targetParent!.editorItems.indexOf(targetNode) + 1;

                  draggedNode.reorderItem(newIndex: newIndex);
                }
              }, 
            );
          }
          else {
            details.mapDropPosition(
              whenAbove: () {
                final newIndex = targetParent!.editorItems.indexOf(targetNode);

                (draggedNode).reassignParent(newParent: targetParent, atIndex: newIndex);
              }, 
              whenInside: () {
                if (targetNode is ECategory) {
                  (draggedNode).reassignParent(newParent: targetNode);
                }
              }, 
              whenBelow: () {
                if (entry.isExpanded) {
                  if (targetNode is ECategory) {
                    (draggedNode).reassignParent(newParent: targetNode, atIndex: 0);
                  }
                }
                else {
                  final newIndex = targetParent!.editorItems.indexOf(targetNode) + 1;

                  (draggedNode).reassignParent(newParent: targetParent, atIndex: newIndex);
                }
              }, 
            );
          }

          // Make sure to rebuild your tree view to show the reordered nodes
          // in their new vicinity.
          _treeController.rebuild();
        },
        builder: (BuildContext context, TreeDragAndDropDetails? details) {
          // If details is not null, a dragging tree node is hovering this
          // drag target. Add some decoration to give feedback to the user.
          Decoration? decoration;
          const borderSide = BorderSide(color: Color(0xFF9E9E9E), width: 1.5);


          if (details != null) {
            // Add a border to indicate in which portion of the target's height
            // the dragging node will be inserted.
            decoration = BoxDecoration(
              border: details.mapDropPosition(
                whenAbove: () => const Border(top: borderSide),
                whenInside: () => (entry.node is ECategory) ? const Border.fromBorderSide(borderSide) : null,
                whenBelow: () => entry.isExpanded ? null : const Border(bottom: borderSide),
              ),
            );
          }

          return TreeDraggable<EItem>(
            node: entry.node,
            childWhenDragging: null,
            //longPressDelay: const Duration(milliseconds: 300),

            // Show some feedback to the user under the dragging pointer,
            // this can be any widget.
            feedback: SizedBox(
              height: 50,
              width: 250,
              child: ListTile(
                tileColor: WidgetStatePropertyAll<Color>(WeightechThemes.wtGray.light),
                contentPadding: const EdgeInsets.all(0),
                onPressed: null,
                leading: (entry.node is ECategory) 
                  ? (entry.isExpanded)
                    ? const Icon(FluentIcons.list_bar_tree_20_regular)
                    : const Icon(FluentIcons.list_bar_20_regular) 
                  : const Icon(FluentIcons.production_20_regular),
                title: Text(entry.node.name, style: const TextStyle(fontSize: 14)),
              ),
            ),
            child: TreeIndentation(
              guide: const IndentGuide.connectingLines(
                thickness: 2,
                indent: 50
              ),
              entry: entry,
              child: Container(
                decoration: decoration,
                child: GestureDetector(
                  onSecondaryTapUp:(details) async {
                    flyoutController.showFlyout(
                      barrierColor: Colors.black.withOpacity(0.1),
                      barrierDismissible: true,
                      dismissWithEsc: true,
                      placementMode: FlyoutPlacementMode.topCenter,
                      position: details.globalPosition,
                      builder: (context) {
                        return FlyoutContent(
                          child: SizedBox(
                            child: IntrinsicHeight(
                              child: CommandBar(
                                direction: Axis.vertical,
                                overflowBehavior: CommandBarOverflowBehavior.noWrap,
                                primaryItems: [
                                  if (entry.node != _focusItem)
                                    CommandBarButton(
                                      label: const Text("Edit"),
                                      onPressed: () async {
                                        toggleEditorItem(entry.node);
                                        Flyout.of(context).close();
                                      }
                                    ),
                                  CommandBarButton(
                                    label: const Text("Delete"),
                                    onPressed: () async {
                                      final confirmed = await _showItemDeleteDialog(context, entry.node,);
                                      if (confirmed) {
                                        _focusItem!.delete();
                                        _treeController.rebuild();
                                        setState(() => _focusItem = null);
                                      }
                                      if (context.mounted) Flyout.of(context).close();
                                    }
                                  ),
                                  if (entry.node is ECategory) 
                                    ...[
                                      CommandBarButton(
                                        label: const Text("Add Product"),
                                        onPressed: () async {
                                          final newProduct = EProduct.temp();
                                          toggleEditorItem(newProduct, newItem: true);
                                          setState(() => _selectedCategory = entry.node as ECategory);
                                          Flyout.of(context).close();
                                        },
                                      ),
                                      CommandBarButton(
                                        label: const Text("Add Category"),
                                        onPressed: () async {
                                          final newProduct = EProduct.temp();
                                          toggleEditorItem(newProduct, newItem: true);
                                          setState(() => _selectedCategory = entry.node as ECategory);
                                          Flyout.of(context).close();
                                        },
                                      ),
                                    ]
                                ],
                              )
                            )
                          )
                        );
                      }
                    );
                  },
                  child: FlyoutTarget(
                    controller: flyoutController,
                    child: ListTile(
                      tileColor: (entry.node == _focusItem) 
                        ? const WidgetStatePropertyAll<Color>(Color(0xFF696969))
                        : entry.isExpanded ? WidgetStatePropertyAll<Color>(WeightechThemes.wtGray.light) : null,
                      contentPadding: const EdgeInsets.only(right: 10),
                      onPressed: () {
                        if (entry.node is ECategory) {
                          if (!entry.isExpanded) {
                            _treeController.toggleExpansion(entry.node);
                          }
                          else {
                            if (entry.node != _focusItem) {
                              toggleEditorItem(entry.node);
                            }
                            else {
                              _treeController.collapseCascading([entry.node]);
                            }
                          }
                        }
                        else {
                          toggleEditorItem(entry.node);
                        }
                      },
                      leading: (entry.node is ECategory) ?
                        IconButton(
                          icon: (entry.isExpanded)
                            ? Icon(FluentIcons.list_bar_tree_20_regular, color: (entry.node == _focusItem) ? Colors.white : Colors.black)
                            : Icon(FluentIcons.list_bar_20_regular, color: (entry.node == _focusItem) ? Colors.white : Colors.black),
                          onPressed: () {
                            (!entry.isExpanded) 
                            ? _treeController.toggleExpansion(entry.node)
                            : _treeController.collapseCascading([entry.node]);
                          }
                        )
                        : Icon(FluentIcons.production_20_regular, color: (entry.node == _focusItem) ? Colors.white : Colors.black),
                      title: Text(
                        entry.node.name, 
                        style: TextStyle(
                          color: (entry.node == _focusItem) ? Colors.white : Colors.black,
                          fontSize: 14
                        )
                      ),
                    )
                  )
                )
              )
            )
          );
        },);
      }
    );
  }

  Widget productEditor({EProduct? product}) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child:
        SingleChildScrollView(
          child: Form (
            key: _formKey,
            child: Column(
              children: [
                productNameWidget(),
                productInfoWidget(product),
                Container(
                  constraints: const BoxConstraints(minHeight: 360),
                  child: 
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // const Padding(
                              //   padding: EdgeInsets.only(left: 150, right: 150, bottom: 10), 
                              //   child: 
                              //     Text("Product Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              // ),
                              overviewWidget(),
                              if (_mediaFiles.isNotEmpty) carouselWidget(),
                              Flexible(
                                fit: FlexFit.loose,
                                child:
                                  AnimatedContainer(
                                    duration: const Duration(seconds: 1),
                                    padding: const EdgeInsets.only(left: 30, right: 20, top: 10),
                                    alignment: (_mediaFiles.isNotEmpty) ? Alignment.bottomCenter : Alignment.topCenter,
                                    child:
                                      imageUploadWidget()
                                  )
                              )
                            ]
                          )
                        ),
                        Flexible(
                          flex: 1,
                          child: Padding( 
                            padding: const EdgeInsets.fromLTRB(0, 0, 30, 10),
                            child:
                              Container(
                                alignment: Alignment.centerLeft,
                                child: buildBrochureList(brochure: _brochure)
                              ),
                          ),
                        )
                      ]
                    ),
                ),
                const SizedBox(height: 20),
                Button(
                  child: const Text("Preview"),
                  onPressed: () {
                    // _showPreviewDialog(context);
                  },
                ),
                const SizedBox(height: 10),
                Button(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(WeightechThemes.weightechBlue),
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                  ),
                  child: _addingItem ? const Text("Add") : const Text("Save"),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_addingItem) {
                        Product newProduct = Product(
                          name: _nameController.text,
                          modelNumber: _modelNumberController.text,
                          description: _descriptionController.text,
                          brochure: mapListToBrochure(_brochure)
                        );
                        EProduct newEProduct = EProduct(product: newProduct,);
                        
                        newEProduct.save(
                          parent: _selectedCategory,
                          mediaPaths: List.from(_mediaPaths),
                          mediaFiles: List.from(_mediaFiles)
                        );
                      }
                      else if (product != null) {
                        product.save(
                          name: _nameController.text,
                          parent: _selectedCategory,
                          modelNumber: _modelNumberController.text,
                          description: _descriptionController.text,
                          brochure: mapListToBrochure(_brochure),
                          mediaPaths: List.from(_mediaPaths),
                          mediaFiles: List.from(_mediaFiles),
                          primaryImageIndex: _primaryImageIndex,
                        );                       
                      }
                      setState(() {
                        _treeController.rebuild();
                        _addingItem = false;
                        _focusItem = null;
                      });
                    }
                  }
                ),
                const SizedBox(height: 20),
              ]
            )
          )
        )
    );
  }

  Widget productNameWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        children: [
          TextFormBox(
            decoration: const BoxDecoration(
              color: WeightechThemes.weightechBlue,
              borderRadius: BorderRadius.zero,
            ),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            controller: _nameController,
            placeholder: "Product Name *",
            placeholderStyle: const TextStyle(color: Colors.white, fontSize: 32, fontStyle: FontStyle.italic),
            validator: (String? value) {
              return (value == null || value == '' || value == 'All') ? "Name required (and cannot be 'All')." : null;
            }
          ),
          Container(
            color: WeightechThemes.weightechGray,
            height:  5,
            width: double.infinity
          )
        ]
      )
    );
  }

  Widget overviewWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 50, right: 50, bottom: 20, top: 2),
      child: 
        FluentTheme(
          data: WeightechThemes.fluentLightTheme,
          child: Tooltip(
            richMessage: const TextSpan(
              children: [
                TextSpan(
                  text: "*Bold* for "
                ),
                TextSpan(
                  text: "Bold\n",
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                TextSpan(
                  text: "_Underline_ for "
                ),
                TextSpan(
                  text: "Underline",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                )
              ]
            ),
            child: TextFormBox(
              placeholder: "Overview",
              controller: _descriptionController,
              minLines: 4,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            )
          )
        )
    );
  }

  Widget imageUploadWidget() {
    return DropTarget(
      onDragDone: (detail) {
        List<String> paths = [];

        Log.logger.t("...Image drop-upload encounter...");
        for (var file in detail.files) {
          if (_mediaPaths.contains(file.path)) {
            Log.logger.t("-> Image already assigned to item.");
            continue;
          }
          String extension = file.path.substring(file.path.length - 4);
          if (extension == ".jpg" || extension == ".png") {
            Log.logger.t("-> Image added to paths: ${file.path}");
            paths.add(file.path);
          }
          else if (file.path.substring(file.path.length - 5) == ".jpeg") {
            Log.logger.t("-> Image added to paths: ${file.path}");
            paths.add(file.path);
          }
          else if (file.path.substring(file.path.length - 4) == ".mp4") {
            Log.logger.t("-> Video added to paths: ${file.path}");
            paths.add(file.path);
          }
          else {
            Log.logger.t("-> Invalid file type: File type $extension not supported.");
          }
        }

        setState(() {
          _mediaPaths.addAll(paths);
          for (var path in paths) {
            _mediaFiles.add(File(path));
          }
        });
      },
      onDragEntered: (details) => setState(() => _fileDragging = true),
      onDragExited: (details) => setState(() => _fileDragging = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 400,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black),
          color: _fileDragging ? WeightechThemes.wtGray.normal : WeightechThemes.wtGray.lighter,
        ),
        child: _mediaPaths.isEmpty ?
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FluentIcons.image_20_regular, size: 70),
                const Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Expanded(child: Divider(style: DividerThemeData(decoration: BoxDecoration(color: Colors.black), thickness: 1, horizontalMargin: EdgeInsets.symmetric(horizontal: 35)))), 
                    Text("or"), 
                    Expanded(child: Divider(style: DividerThemeData(decoration: BoxDecoration(color: Colors.black), thickness: 1, horizontalMargin: EdgeInsets.symmetric(horizontal: 35))))
                  ]
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: const ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.black)
                  ),                 
                  onPressed: () async {
                    FilePickerResult? _ = 
                      await FilePicker.platform.
                        pickFiles(allowMultiple: true, type: FileType.media, allowedExtensions: ['png', 'jpg', 'mp4'])
                        .then((result) {
                          if (result != null) {
                            List<String> paths = [];

                            for (var path in result.paths) {
                              if (_mediaPaths.contains(path)) {
                                Log.logger.t("Image already assigned to item.");
                                continue;
                              }
                              String extension = path!.substring(path.length - 4);
                              if (extension == ".jpg" || extension == ".png") {
                                Log.logger.t("Image added to paths: $path");
                                paths.add(path);
                              }
                              else if (path.substring(path.length - 5) == ".jpeg") {
                                Log.logger.t("Image added to paths: $path");
                                paths.add(path);
                              }
                              else if (extension == ".mp4") {
                                Log.logger.t("-> Video added to paths: $path");
                                paths.add(path);
                              }
                              else {
                                Log.logger.t("Invalid file type: File type $extension not supported.");
                              }
                            }

                            setState(() {
                              _mediaPaths.addAll(paths);
                              for (var path in paths) {
                                _mediaFiles.add(File(path));
                              }
                            });
                          }
                          else {
                            Log.logger.t("-> File upload aborted/failed.");
                          }
                          return null;
                        });
                  },
                  child: const Text("Browse Files")
                ),
                const SizedBox(height: 10),
                const Text("File must be .jpg, .png, or .mp4", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic))
              ]
            )
          : ReorderableListView.builder(
            padding: const EdgeInsets.all(15),
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _mediaPaths.length,
            itemBuilder:(context, index) {

              bool isFromCloud = false;
              bool isDownloading = false;

              final image = _mediaFiles[index];
              String imageText = '';
              if (isURL(_mediaPaths[index])) {
                final ref = FirebaseUtils.storage.refFromURL(_mediaPaths[index]);
                imageText = ref.name;
                isFromCloud = true;
              }
              else {
                imageText = image.uri.pathSegments.last;
              }

              return ReorderableDragStartListener(
                key: Key('$index'),
                index: index,
                child: 
                  ListTile(
                    tileColor: WidgetStatePropertyAll<Color>(WeightechThemes.wtGray.light),
                    leading: Text('${index+1}.'),
                    title: Text(imageText, style: const TextStyle(fontSize: 14)),
                    trailing: Row(
                      children: [
                        (isFromCloud) ?
                            StatefulBuilder(
                              builder: (context, setState) {
                                return IconButton(
                                  icon: isDownloading ? 
                                    LoadingAnimationWidget.bouncingBall(color: WeightechThemes.loadingAnimationColor, size: 15) 
                                    : const Icon(FluentIcons.cloud_arrow_down_20_regular),
                                  onPressed: () async {
                                    setState(() => isDownloading = true);
                                    _mediaFiles[index].setLastModified(DateTime.now());
                                    await FileSaver.instance.saveFile(name: imageText, file: _mediaFiles[index]);
                                    await getDownloadsDirectory().then((dir) async {
                                      if (dir != null) {
                                        launchUrl(dir.uri);
                                      }
                                    });
                                    setState(() => isDownloading = false);
                                  }
                                );
                              }
                            )
                            : SmallIconButton(
                              child: IconButton(
                              icon: const Icon(FluentIcons.desktop_20_regular),
                              onPressed: () async {
                                final dir = FileUtils.dirname(_mediaPaths[index]);
                                final uri = Uri.parse(dir);
                                launchUrl(uri);
                              }
                            ),
                          ),
                        const SizedBox(width: 10),
                          if (!imageText.endsWith('.mp4'))
                            Row(
                              children: [
                                IconButton(
                                  style: ButtonStyle(
                                    backgroundColor: (index == _primaryImageIndex) ? const WidgetStatePropertyAll<Color>(WeightechThemes.weightechGray) : null
                                  ),
                                  icon: Icon(
                                    (index == _primaryImageIndex) ? FluentIcons.star_20_filled : FluentIcons.star_20_regular,
                                    color: (index == _primaryImageIndex) ? Colors.yellow : null,
                                  ),
                                  onPressed: () => setState(() => _primaryImageIndex = index)
                                ),
                                const SizedBox(width: 10),
                              ]
                            ),
                          IconButton(
                            icon: const Icon(FluentIcons.eye_20_regular),
                            onPressed: () async {
                              //await _previewMedia(context, image);
                            }
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(FluentIcons.dismiss_20_regular),
                            onPressed: () => setState(() {
                              _mediaPaths.removeAt(index);
                              _mediaFiles.removeAt(index);
                            })
                          )

                        ],
                      )
                  ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              // These two lines are workarounds for ReorderableListView problems
              if (newIndex > _mediaPaths.length) newIndex = _mediaPaths.length;
              if (oldIndex < newIndex) newIndex--;

              String primaryImage = _mediaPaths[_primaryImageIndex];

              String pathToMove = _mediaPaths.removeAt(oldIndex);
              File fileToMove = _mediaFiles.removeAt(oldIndex);
              _mediaPaths.insert(newIndex, pathToMove);
              _mediaFiles.insert(newIndex, fileToMove);
              
              _primaryImageIndex = _mediaPaths.indexOf(primaryImage);

              setState(() {});
            },
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Drag and drop", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(fit: FlexFit.loose, child: Divider(direction: Axis.vertical, style: DividerThemeData(thickness: 1, horizontalMargin: EdgeInsets.symmetric(vertical: 15)))), 
                    Text("or"), 
                    Flexible(fit: FlexFit.loose, child: Divider(direction: Axis.vertical, style: DividerThemeData(thickness: 1, horizontalMargin: EdgeInsets.symmetric(vertical: 15))))
                  ]
                ),
                const SizedBox(width: 20),
                OutlinedButton(
                  style: const ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.black)
                  ),                 
                  onPressed: () async {
                    Log.logger.t("...Image upload encountered...");
                    FilePickerResult? _ = 
                      await FilePicker.platform.
                        pickFiles(allowMultiple: true, type: FileType.media, allowedExtensions: ['png', 'jpg', 'mp4'])
                        .then((result) {
                          if (result != null) {
                            List<String> paths = [];

                            for (var path in result.paths) {
                              if (_mediaPaths.contains(path)) {
                                Log.logger.t("-> Image already assigned to item.");
                                continue;
                              }
                              String extension = path!.substring(path.length - 4);
                              if (extension == ".jpg" || extension == ".png") {
                                Log.logger.t("-> Image added to paths: $path");
                                paths.add(path);
                              }
                              else if (path.substring(path.length - 5) == ".jpeg") {
                                Log.logger.t("-> Image added to paths: $path");
                                paths.add(path);
                              }
                              else if (extension == ".mp4") {
                                Log.logger.t("-> Video added to paths: $path");
                                paths.add(path);
                              }
                              else {
                                Log.logger.t("-> Invalid file type: File type $extension not supported.");
                              }
                            }

                            setState(() {
                              _mediaPaths.addAll(paths);
                              for (var path in paths) {
                                _mediaFiles.add(File(path));
                              }
                            });
                          }
                          else {
                            Log.logger.t("-> File upload aborted/failed.");
                          }
                          return null;
                        });
                  },
                  child: const Text("Browse Files")
                ),
              ]
          ),
        )
      ),
    );
  }

  Widget carouselWidget() {
    int current = _primaryImageIndex;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            children: [
              CarouselSlider.builder(
                options: CarouselOptions(
                  enableInfiniteScroll: _mediaPaths.length > 1 ? true : false, 
                  enlargeCenterPage: true,
                  enlargeFactor: 1,
                  viewportFraction: 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      current = index;
                    });
                  },
                ),
                itemCount: _mediaFiles.length,
                itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                  if (FileUtils.isLocalPathAndExists(path: _mediaPaths[itemIndex])) {
                    final file = _mediaFiles[itemIndex];
                    if (FileUtils.extension(file.path) == '.mp4') {
                      late final player = Player();
                      late final controller = VideoController(player);
                      player.open(Media(file.path));
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: FullScreenWidget(
                          disposeLevel: DisposeLevel.low,
                          child: Hero(
                            tag: "$itemIndex-hero",
                            child: Video(
                              controller: controller, 
                              // controls: (VideoState state) => MaterialVideoControls(state), // Uncomment for app usage
                              fit: BoxFit.fitWidth, 
                              width: double.infinity
                            )
                          )
                        )
                      );
                    }
                    else {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: FullScreenWidget(
                          disposeLevel: DisposeLevel.low,
                          child: Hero(
                            tag: "$itemIndex-hero",
                            child: Center(
                              child: Image.file(file, fit: BoxFit.fitWidth, width: double.infinity)
                            )
                          )
                        )
                      );
                    }
                  }
                  else {
                    final path = _mediaPaths[itemIndex];
                    return FutureBuilder(
                      future: FileUtils.cacheManager.getSingleFile(path),
                      builder: ((context, snapshot) {
                        if (snapshot.hasData) {
                          if (FileUtils.isMP4(snapshot.data!.path)) {
                            late final player = Player();
                            late final controller = VideoController(player);
                            player.open(Media(snapshot.data!.path));
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FullScreenWidget(
                                disposeLevel: DisposeLevel.low,
                                child: Hero(
                                  tag: "$itemIndex-hero",
                                  child: Video(
                                    controller: controller, 
                                    // controls: (VideoState state) => MaterialVideoControls(state), // Uncomment for app usage
                                    fit: BoxFit.fitWidth, 
                                    width: double.infinity
                                  )
                                )
                              )
                            );
                          }
                          else {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FullScreenWidget(
                                disposeLevel: DisposeLevel.low,
                                child: Hero(
                                  tag: "$itemIndex-hero",
                                  child: Center(
                                    child: Image.file(snapshot.data!, fit: BoxFit.fitWidth, width: double.infinity)
                                  )
                                )
                              )
                            );
                          }
                        }
                        else {
                          return LoadingAnimationWidget.newtonCradle(color: WeightechThemes.weightechBlue, size: 50);
                        }
                      })
                    );
                  }
                }
              ),
              const SizedBox(height: 10),
              if (_mediaFiles.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _mediaFiles.asMap().entries.map((entry) {
                    return Container(
                        width: 6.0,
                        height: 6.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (FluentTheme.of(context).brightness == Brightness.dark
                                    ? WeightechThemes.weightechGray
                                    : WeightechThemes.weightechBlue)
                                .withOpacity(current == entry.key ? 1 : 0.3)),
                      );
                  }).toList(),
                )
            ]
          )
        );
      }
    );
  }

  Widget productInfoWidget(product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 20),
      child: Container(
        decoration: BoxDecoration(
          color: WeightechThemes.infoWidgetColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
          // border: Border.all(
          //   color: const Color(0xFF898988),
          //   width: 1,
          // )
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 280,
              child: TextFormBox(
                controller: _modelNumberController,
                placeholder: "Product Model Number",
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 280,
              child: ComboBox<ECategory>(
                placeholder: const Text("Category *"),
                value: _selectedCategory,
                items: CatalogEditor.all.getSubCategories().map<ComboBoxItem<ECategory>>((ECategory category){
                  return ComboBoxItem<ECategory>(
                    value: category,
                    child: Text(category.category.name),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState((){
                    _selectedCategory = newValue!;
                  });
                },
              )
            ),
            const SizedBox(height: 10),
            (product != null) ?
              SizedBox(
                height: 20,
                child: Text("Item ID: ${product.id}", style: const TextStyle(fontStyle: FontStyle.italic)),
              )
            : const SizedBox(height: 20),
          ]
        )
      )
    );
  }

  Widget categoryEditor({ECategory? category}) {

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            categoryInfoWidget(category),
            Container(
              constraints: const BoxConstraints(minHeight: 300),
              child: 
                buildCategoryEditorCard()
            ),
            const SizedBox(height: 0),
            Button(
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(WeightechThemes.weightechBlue),
                foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
              ),
              child: _addingItem ? const Text("Add") : const Text("Save"),
              onPressed: () {
                if (_addingItem) {
                  ProductCategory newCategory = ProductCategory(
                    name: _nameController.text,
                  );
                  ECategory newECategory = ECategory(category: newCategory, editorItems: []);
                  
                  newECategory.save(
                    parent: _selectedCategory,
                    imagePath: (_mediaPaths.isEmpty) ? null : _mediaPaths.first,
                    imageFile: (_mediaFiles.isEmpty) ? null : _mediaFiles.first
                  );
                }
                else if (category != null) {
                  category.save(
                    name: _nameController.text,
                    parent: _selectedCategory,
                    imagePath: (_mediaPaths.isEmpty) ? null : _mediaPaths.first,
                    imageFile: (_mediaFiles.isEmpty) ? null : _mediaFiles.first,
                  );
                }
                setState(() {
                  _treeController.rebuild();
                  _addingItem = false;
                  _focusItem = null;
                });
              }
            ),
            const SizedBox(height: 20),
          ]
        )
      )
    );
  }

  Widget buildCategoryEditorCard() {
    bool hoverOnImageRemove = false;

    return SizedBox(
      height: 400,
      width: 400,
      child: material.Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 30.0, top: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10,15,10,15),
                child: (_mediaFiles.isNotEmpty)
                  ? Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: ResizeImage(
                              FileImage(_mediaFiles.first),
                              policy: ResizeImagePolicy.fit,
                              height: 400,
                            )
                          )
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return Positioned.fill(
                            child: material.Material(
                              color: Colors.transparent,
                              child: material.InkWell(
                                borderRadius: BorderRadius.circular(5),
                                hoverColor: const Color(0x55000000),
                                onHover: (isHovering) {
                                  if (isHovering) {
                                    setState(() => hoverOnImageRemove = true);
                                  }
                                  else {
                                    setState(() => hoverOnImageRemove = false);
                                  }
                                },
                                onTap: () {
                                  _mediaFiles.clear();
                                  _mediaPaths.clear();
                                  super.setState(() {});
                                },
                                child: hoverOnImageRemove ? const Icon(FluentIcons.dismiss_20_regular, size:40, color: WeightechThemes.weightechGray) : const SizedBox()
                              )
                            )
                          );
                        }
                      )
                    ]
                  )
                  : DropTarget(
                    onDragDone: (detail) {
                      List<String> paths = [];

                      Log.logger.t("...Image drop-upload encounter...");
                      for (var file in detail.files) {
                        if (_mediaPaths.contains(file.path)) {
                          Log.logger.t("-> Image already assigned to item.");
                          continue;
                        }
                        String extension = file.path.substring(file.path.length - 4);
                        if (extension == ".jpg" || extension == ".png") {
                          Log.logger.t("-> Image added to paths: ${file.path}");
                          paths.add(file.path);
                        }
                        else if (file.path.substring(file.path.length - 5) == ".jpeg") {
                          Log.logger.t("-> Image added to paths: ${file.path}");
                          paths.add(file.path);
                        }
                        else {
                          Log.logger.t("-> Invalid file type: File type $extension not supported.");
                        }
                      }

                      setState(() {
                        _mediaPaths.add(paths.first);
                        _mediaFiles.add(File(_mediaPaths.first));
                      });
                    },
                    onDragEntered: (details) => setState(() => _fileDragging = true),
                    onDragExited: (details) => setState(() => _fileDragging = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WeightechThemes.weightechGray),
                        color: _fileDragging ? WeightechThemes.fileDropColor : WeightechThemes.wtGray.lighter,
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FluentIcons.image_20_regular, size: 70),
                          const Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              Expanded(child: Divider(direction: Axis.vertical, style: DividerThemeData(thickness: 1, horizontalMargin: EdgeInsets.symmetric(vertical: 15)))), 
                              Text("or"), 
                              Expanded(child: Divider(direction: Axis.vertical, style: DividerThemeData(thickness: 1, horizontalMargin: EdgeInsets.symmetric(vertical: 15))))
                            ]
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            style: const ButtonStyle(
                              foregroundColor: WidgetStatePropertyAll<Color>(Colors.black)
                            ),                 
                            onPressed: () async {
                              FilePickerResult? _ = 
                                await FilePicker.platform.
                                  pickFiles(allowMultiple: false, type: FileType.image, allowedExtensions: ['png', 'jpg'])
                                  .then((result) {
                                    if (result != null) {
                                      List<String> paths = [];

                                      for (var path in result.paths) {
                                        if (_mediaPaths.contains(path)) {
                                          Log.logger.t("Image already assigned to item.");
                                          continue;
                                        }
                                        String extension = path!.substring(path.length - 4);
                                        if (extension == ".jpg" || extension == ".png") {
                                          Log.logger.t("Image added to paths: $path");
                                          paths.add(path);
                                        }
                                        else if (path.substring(path.length - 5) == ".jpeg") {
                                          Log.logger.t("Image added to paths: $path");
                                          paths.add(path);
                                        }
                                        else {
                                          Log.logger.t("Invalid file type: File type $extension not supported.");
                                        }
                                      }

                                      setState(() {
                                        _mediaPaths = [];
                                        _mediaFiles = [];
                                        _mediaPaths.add(paths[0]);
                                        _mediaFiles.add(File(paths[0]));
                                      });
                                    }
                                    else {
                                      Log.logger.t("File upload aborted/failed.");
                                    }
                                    return null;
                                  });
                            },
                            child: const Text("Browse Files")
                          ),
                          const SizedBox(height: 10),
                          const Text("File must be .jpg or .png", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic))
                        ]
                      )
                    ),
                  )
              )
            ),
            Container(
              height: 35,
              width: 400,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextFormBox(
                textAlign: TextAlign.center,
                controller: _nameController,
                placeholder: "Category Name *",
                style: const TextStyle(fontSize: 16, color: Colors.black),
                validator: (String? value) {
                  return (value == null || value == '' || value == 'All') ? "Name required (and cannot be 'All')." : null;
                }
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      )
    );
  }

  Widget categoryInfoWidget(category) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(150, 20, 150, 0),
      child: Container(
        decoration: BoxDecoration(
          color: WeightechThemes.infoWidgetColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
          // border: Border.all(
          //   color: const Color(0xFF898988),
          //   width: 1,
          // )
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              width: 280,
              child: ComboBox<ECategory>(
                placeholder: const Text("Category *"),
                value: category.getParent() ?? CatalogEditor.all,
                items: CatalogEditor.all.getSubCategories().map<ComboBoxItem<ECategory>>((ECategory category){
                  return ComboBoxItem<ECategory>(
                    value: category,
                    child: Text(category.category.name),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState((){
                    _selectedCategory = newValue!;
                  });
                },
              )
            ),
            const SizedBox(height: 10),
            Button(
              onPressed: () async {
                final firstItem = category.editorItems.first;
                switch (firstItem) {
                  case ECategory _ : {
                    _mediaPaths = [(await category.editorItems.first.getImagePaths())];
                    _mediaFiles = [(await category.editorItems.first.getImageFiles(path: _mediaPaths[0]))];
                  }
                  case EProduct _ : {
                    _mediaPaths = [(await category.editorItems.first.getImagePaths())[0]];
                    _mediaFiles = [(await category.editorItems.first.getImageFiles(paths: [_mediaPaths[0]]))[0]];
                  }
                }
                setState(() {});
              },
              child: const Text('Use Default Image')
            ),
            const SizedBox(height: 10),
            (category != null) ?
              SizedBox(
                height: 20,
                child: Text("Item ID: ${category.id}", style: const TextStyle(fontStyle: FontStyle.italic)),
              )
            : const SizedBox(height: 10),
          ]
        )
      )
    );
  }

  Future<void> toggleEditorItem(EItem? focusItem, {bool newItem = false}) async {
    StreamController<String> updateStreamController = StreamController<String>();

    setState(() => _toggleLoading(dynamicStream: updateStreamController.stream));
    switch (focusItem) {
      case EProduct _ : {
        List<String> newImagePaths = await focusItem.getImagePaths() ?? [];

        updateStreamController.add("Downloading product media...\nThis might take a moment...");
        List<File> newImageFiles = await focusItem.getImageFiles(paths: newImagePaths) ?? [];
        updateStreamController.add('Loading...');
        _mediaPaths.clear();
        _mediaFiles.clear();
        _focusItem = focusItem;
        _mediaPaths = List.from(newImagePaths);
        _mediaFiles = List.from(newImageFiles);
        _nameController.text = focusItem.product.name;
        _modelNumberController.text = focusItem.product.modelNumber ?? '';
        updateStreamController.add('Mapping brochure...');
        _brochure = focusItem.product.retrieveBrochureList();
        updateStreamController.add('Loading...');
        _descriptionController.text = focusItem.product.description ?? '';
        _selectedCategory = focusItem.getParent() ?? CatalogEditor.all;
        _addingItem = newItem;
      }
      case ECategory _ : {
        String newImagePath = await focusItem.getImagePaths() ?? '';
        updateStreamController.add('Downloading category image...');
        File? newImageFile = await focusItem.getImageFiles(path: newImagePath);
        updateStreamController.add('Loading...');
        _mediaPaths.clear();
        _mediaFiles.clear();
        _focusItem = focusItem;
        _mediaPaths = List.from([newImagePath]);
        _mediaFiles = (newImageFile != null) ? List.from([newImageFile]) : [];
        _nameController.text = focusItem.category.name;
        _selectedCategory = focusItem.getParent() ?? CatalogEditor.all;
        _addingItem = newItem;
      }
      case null : {
        _mediaPaths.clear();
        _mediaFiles.clear();
        _focusItem = null;
      }
    }
    setState(() => _toggleLoading());
  }


  void _toggleLoading({Stream<dynamic>? dynamicStream, Widget? loadingWidget, bool? loadingSomething}) {

    if (loadingSomething != null) {
      _loadingSomething = loadingSomething;
      _ignoringPointer = loadingSomething;
    }
    else {
      _loadingSomething = !_loadingSomething;
      _ignoringPointer = !_ignoringPointer;
    }

    if (loadingWidget != null) {
      _loadingWidget = loadingWidget;
    }
    else {
      _loadingWidget = (dynamicStream != null)
        ? StreamBuilder(
          stream: dynamicStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data is String) {
                return ContentDialog(
                  title: Center(
                    heightFactor: 1,
                    child: Text(snapshot.data!, style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor), textAlign: TextAlign.center),
                  ),
                  content: const Center(
                    heightFactor: 1,
                    child: ProgressBar(
                      activeColor: WeightechThemes.weightechBlue,
                    )
                  )
                );
              }
              else if (snapshot.data is EItem) {
                final item = snapshot.data;
                return ContentDialog(
                  title: 
                    Center(
                      heightFactor: 1,
                      child: (item is ECategory)
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.imagePath != null) Image.file((File(item.imagePath!))),
                            Expanded(
                              child: Text("${item.name}...", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor))
                            )
                          ]
                        )
                      : (item is EProduct)
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.mediaFiles?.isNotEmpty ?? false) 
                              if (!FileUtils.isMP4(item.mediaPaths![0]))
                                Image.file((File(item.mediaPaths![0]))),
                            Expanded(
                              child: Text("${item.name}...", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor))
                            )
                          ]
                        )
                        : Text('Loading...', style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor), textAlign: TextAlign.center,),
                    ),
                  content: const Center(
                    heightFactor: 1,
                    child: ProgressBar(
                      activeColor: WeightechThemes.weightechBlue,
                    )
                  )
                );
              }
              else if (snapshot.data is Widget) {
                return ContentDialog(
                  title: Center(
                    heightFactor: 1,
                    child: Text('Success!', style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor), textAlign: TextAlign.center,),
                  ),
                  content: Center(
                    heightFactor: 1,
                    child: snapshot.data
                  )
                );
              }
              else {
                return ContentDialog(
                  title: Center(
                    heightFactor: 1,
                    child: Text('Loading...', style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor), textAlign: TextAlign.center,),
                  ),
                  content: const Center(
                    heightFactor: 1,
                    child: ProgressBar(
                      activeColor: WeightechThemes.weightechBlue,
                    )
                  )
                );
              }
            }
            else {
              return ContentDialog(
                title: Text('Loading...', style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor), textAlign: TextAlign.center,),
                content: const Center(
                  heightFactor: 1,
                  child: ProgressBar(
                    activeColor: WeightechThemes.weightechBlue,
                  )
                )
              );
            }
          }
        )
        : ContentDialog(
          title: Text('Loading...', style: TextStyle(fontSize: 14, color: WeightechThemes.defaultTextColor), textAlign: TextAlign.center,),
          content: const Center(
            heightFactor: 1,
            child: ProgressBar(
              activeColor: WeightechThemes.weightechBlue,
            )
          )
        );
    }
  }


  Future<bool> _showItemDeleteDialog(BuildContext context, EItem data, {String? currentName}) async {
    bool? confirmation = false;
    
    switch (data) {
      case ECategory _ : {
        confirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ContentDialog(
                  title: const Text("Warning!"),
                  content: Text("You are about to delete ${currentName ?? data.category.name} and all of its contents (including sub-products). This action cannot be undone. \n\nAre you sure?"),
                  actions: <Widget>[
                    Button(
                      child: const Text("Delete"),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      }
                    ),
                    FilledButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    )
                  ]
                );
              }
            );
          }
        );
      }
      case EProduct _ : {
        confirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ContentDialog(
                  title: const Text("Warning!"),
                  content: Text("You are about to delete ${currentName ?? data.product.name} and all of its contents. This action cannot be undone. \n\nAre you sure?"),
                  actions: <Widget>[
                    Button(
                      child: const Text("Delete"),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      }
                    ),
                    FilledButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    )
                  ]
                );
              }
            );
          }
        );
      }
    }
    return confirmation ?? false;
  }

  Future<bool> _showItemRevertDialog(BuildContext context, EItem data, {String? currentName}) async {
    bool? confirmation = false;
    
    switch (data) {
      case ECategory _ : {
        confirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ContentDialog(
                  title: const Text("Warning!"),
                  content: Text("You are about to revert ${currentName ?? data.category.name} (ID: ${data.id}) to its most-recent published version. Note that this will revert all of its contents. This action cannot be undone. \n\nAre you sure?"),
                  actions: <Widget>[
                    Button(
                      child: const Text("Revert"),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      }
                    ),
                    FilledButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    )
                  ]
                );
              }
            );
          }
        );
      }
      case EProduct _ : {
        confirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ContentDialog(
                  title: const Text("Warning!"),
                  content: Text("You are about to revert ${currentName ?? data.product.name} to its most-recent published version. This action cannot be undone. \n\nAre you sure?"),
                  actions: <Widget>[
                    Button(
                      child: const Text("Revert"),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      }
                    ),
                    FilledButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    )
                  ]
                );
              }
            );
          }
        );
      }
    }
    return confirmation ?? false;
  }

  Future<void> _showPreviewDialog(BuildContext context) async {
    
    int? current;

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Map<String, dynamic>> tempBrochure = mapListToBrochure(_brochure);

            return ContentDialog(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width*0.7,
                minHeight: MediaQuery.of(context).size.height*0.7,
                maxWidth: MediaQuery.of(context).size.width*0.7,
                maxHeight: MediaQuery.of(context).size.height*0.7,
              ),
              style: const ContentDialogThemeData(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
              ),
              content: SizedBox(
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        color: WeightechThemes.weightechBlue,
                        border: Border.all(color: WeightechThemes.weightechBlue)
                      ),
                      width: double.infinity,
                      child: 
                        Padding(
                          padding: const EdgeInsets.all(1.4),
                          child:
                            Text(_nameController.text, 
                              textAlign: TextAlign.center, 
                              style: const TextStyle(fontSize: 22.4, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                        )
                    ),
                    Container(
                      color: WeightechThemes.weightechGray,
                      height:  4,
                      width: double.infinity
                    ),
                    Expanded(
                      child: 
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: 
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child:
                                    ListView(
                                      padding: const EdgeInsets.only(left: 42, right: 14, top: 21),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: [
                                        SimpleRichText(_descriptionController.text, textAlign: TextAlign.justify, style: GoogleFonts.openSans(color: Colors.black, fontSize: 12.6)),
                                        const SizedBox(height: 21),
                                        Column(
                                          children: [
                                            CarouselSlider.builder(
                                              options: CarouselOptions(
                                                enableInfiniteScroll: _mediaFiles.length > 1 ? true : false, 
                                                enlargeCenterPage: true,
                                                enlargeFactor: 1,
                                                onPageChanged: (index, reason) {
                                                  setState(() {
                                                    current = index;
                                                  });
                                                },
                                              ),
                                              itemCount: _mediaFiles.length,
                                              itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                                                return FutureBuilder(
                                                  future: (FileUtils.isURL(path: _mediaPaths[itemIndex])) ? FileUtils.cacheManager.getSingleFile(_mediaPaths[itemIndex]) : Future.delayed(const Duration(milliseconds: 1), () async {return _mediaFiles[itemIndex];}),
                                                  builder: ((context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      if (FileUtils.isMP4(snapshot.data!.path)) {
                                                        late final player = Player();
                                                        late final controller = VideoController(player);
                                                        player.open(Media(snapshot.data!.path));
                                                        return ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: FullScreenWidget(
                                                            disposeLevel: DisposeLevel.low,
                                                            child: Hero(
                                                              tag: "$itemIndex-hero",
                                                              child: Video(
                                                                controller: controller, 
                                                                // controls: (VideoState state) => MaterialVideoControls(state), // Uncomment for app usage
                                                                fit: BoxFit.fitWidth, 
                                                                width: double.infinity
                                                              )
                                                            )
                                                          )
                                                        );
                                                      }
                                                      else {
                                                        return ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: FullScreenWidget(
                                                            disposeLevel: DisposeLevel.low,
                                                            child: Hero(
                                                              tag: "$itemIndex-hero",
                                                              child: Center(
                                                                child: Image.file(snapshot.data!, fit: BoxFit.fitWidth, width: double.infinity)
                                                              )
                                                            )
                                                          )
                                                        );
                                                      }
                                                    }
                                                    else {
                                                      return LoadingAnimationWidget.newtonCradle(color: WeightechThemes.weightechBlue, size: 50);
                                                    }
                                                  })
                                                );
                                              }
                                            ),
                                            const SizedBox(height: 7),
                                            if (_mediaFiles.length > 1)
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: _mediaFiles.asMap().entries.map((entry) {
                                                  return Container(
                                                    width: 7,
                                                    height: 7,
                                                    margin: const EdgeInsets.symmetric(vertical: 5.6, horizontal: 2.8),
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: (FluentTheme.of(context).brightness == Brightness.dark
                                                                ? WeightechThemes.weightechGray
                                                                : WeightechThemes.weightechBlue)
                                                            .withOpacity((current ?? 0) == entry.key ? 1 : 0.3)),
                                                  );
                                                }).toList(),
                                              ),
                                          ]
                                        )
                                      ]
                                    ),
                                ),
                                Flexible(
                                  child:    
                                    Padding(
                                      padding: const EdgeInsets.only(left: 28, right: 42, top: 3.5),
                                      child: 
                                        ListView.builder(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.only(top: 14),
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: tempBrochure.length,
                                          itemBuilder: (context, index) {
                                            final headerKey = tempBrochure[index].keys.first;
                                            final headerValue = tempBrochure[index][headerKey] as List;
                                            final headerEntries = headerValue.singleWhere((element) => (element as Map).keys.first == "Entries", orElse: () => <String, List<String>>{})["Entries"];
                                            final subheaders = List.from(headerValue);
                                            subheaders.removeWhere((element) => element.keys.first == "Entries");

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(headerKey, style: const TextStyle(color: WeightechThemes.weightechBlue, fontSize: 19.6, fontWeight: FontWeight.bold), softWrap: true,),
                                                if (headerEntries?.isNotEmpty ?? false)
                                                  ListView.builder(
                                                    padding: const EdgeInsets.only(top: 3.5, left: 3.5),
                                                    shrinkWrap: true,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    itemCount: headerEntries.length,
                                                    itemBuilder: (context, entryIndex) {
                                                      final entry = headerEntries[entryIndex];
                                                      return Padding(
                                                        padding: const EdgeInsets.only(top: 3.5),
                                                        child:
                                                          Row(
                                                            crossAxisAlignment: CrossAxisAlignment.start, 
                                                            children: [
                                                              const Text("\u2022"),
                                                              const SizedBox(width: 5.6),
                                                              Expanded(child: Text(entry, style: const TextStyle(fontSize: 11.2), softWrap: true,))
                                                            ]
                                                          )
                                                      );
                                                    }
                                                  ),
                                                const SizedBox(height: 7),
                                                ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: subheaders.length,
                                                  itemBuilder: (context, subIndex) {
                                                    final subheaderKey = subheaders[subIndex].keys.first;
                                                    final subheaderValue = subheaders[subIndex][subheaderKey] as List<dynamic>;

                                                    return Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 3.5),
                                                          child: Text(subheaderKey, style: const TextStyle(color: Color(0xFF333333), fontSize: 15.4, fontWeight: FontWeight.w800), softWrap: true,),
                                                        ),
                                                        ListView.builder(
                                                          padding: const EdgeInsets.only(left: 3.5, top: 3.5),
                                                          shrinkWrap: true,
                                                          physics: const NeverScrollableScrollPhysics(),
                                                          itemCount: subheaderValue.length,
                                                          itemBuilder: (context, entryIndex) {
                                                            final entry = subheaderValue[entryIndex];
                                                            return Row(
                                                              crossAxisAlignment: CrossAxisAlignment.start, 
                                                              children: [
                                                                const Text("\u2022"),
                                                                const SizedBox(width: 3.5),
                                                                Expanded(child: Text(entry, style: const TextStyle(fontSize: 11.2), softWrap: true,))
                                                              ]
                                                            );
                                                          }
                                                        ),
                                                        const SizedBox(height: 7),
                                                      ],
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 7),
                                              ]
                                            );
                                          }
                                        )
                                    )
                                )
                              ],
                            ),
                        )   
                    ),
                  ]
                )
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Note that there might be minor differences between this preview and how it appears in the mobile app', 
                        style: TextStyle(fontStyle: FontStyle.italic)
                      ),
                    ),
                    Button(
                      child: const Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      }
                    )
                  ]
                )
              ],
            );
          }
        );
      }
    );
  }
  
  Future<Map<String,dynamic>?> _showRestorationDialog(BuildContext context,) async {
    _toggleLoading();
    List<Map<String, dynamic>> catalogOptions = await FirebaseUtils.getLastFromFirestore(3);
    _toggleLoading();
    
    if (context.mounted) {
      return await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (BuildContext context) {
          return ContentDialog(
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              alignment: Alignment.center,
              child: const Text("Previous Catalog Versions")
            ),
            content: ListView.builder(
              itemCount: catalogOptions.length,
              shrinkWrap: true,
              itemBuilder: (statefulContext, index) {
                return ListTile(
                  leading: Text('$index.'),
                  title: Row(
                    mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (catalogOptions[index]['catalogName'] ?? 'Untitled') + '  ',
                        style: const TextStyle(fontSize: 16)
                      ),
                      Text(
                        DateFormat('MMM d, y h:mm a').format(DateTime.fromMillisecondsSinceEpoch(catalogOptions[index]['timestamp'].millisecondsSinceEpoch)),
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)
                      ),
                    ]
                  ),
                  onPressed: () async {
                    final confirmed = await _showRestorationConfirmation(context, DateFormat('MMM d, y h:mm a').format(DateTime.fromMillisecondsSinceEpoch(catalogOptions[index]['timestamp'].millisecondsSinceEpoch)));
                    if (confirmed) {
                      if (context.mounted) {
                        Navigator.of(context).pop(catalogOptions[index]);
                      }
                    }
                    else {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  }
                );
              },
            ),
            actions: <Widget>[
              Button(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop(null);
                }
              ),
            ]
          );
        }
      );
    }
    return null;
  }


  Future<bool> _showRestorationConfirmation(BuildContext context, String date) async {
    bool? confirmation = false;

    confirmation = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ContentDialog(
              title: const Text("Warning!"),
              content: Text("You are about to restore this catalog to one from $date. You will lose your unsaved progress.\n\nAre you sure?"),
              actions: <Widget>[
                Button(
                  child: const Text("Restore"),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  }
                ),
                FilledButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  }
                )
              ]
            );
          }
        );
      }
    );
    return confirmation ?? false;
  }



  Future<void> _checkForUpdate(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          content: Center(
            heightFactor: 1,
            child: UpdatWidget(
              updateChipBuilder: fluentChip,
              updateDialogBuilder: fluentUpdateDialog,
              currentVersion: AppInfo.packageInfo.version,
              getLatestVersion: () async {
                // Use Github latest endpoint
                try {
                  final data = await http.get(
                    Uri.parse(
                    "https://api.github.com/repos/jtull1076/weightechapp/releases/latest"
                    ),
                    headers: {
                      'Authorization': 'Bearer ${FirebaseUtils.githubToken}'
                    }
                  );
                  final latestVersion = jsonDecode(data.body)["tag_name"];
                  final verCompare = AppInfo.versionCompare(latestVersion, AppInfo.packageInfo.version);
                  Log.logger.i('Latest version: $latestVersion : This app version is ${(verCompare == 0) ? "up-to-date." : (verCompare == 1) ? "deprecated." : "in development."}');
                  return latestVersion;
                } catch (e) {
                  Log.logger.e("Error encounted retrieving latest version.", error: e);
                }
                return null;
              },
              getBinaryUrl: (version) async {
                return "https://github.com/jtull1076/weightechapp/releases/download/$version/weightechsales-windows-$version.exe";
              },
              appName: "WeighTech Inc. Sales",
              getChangelog: (_, __) async {
                final data = await http.get(
                  Uri.parse(
                  "https://api.github.com/repos/jtull1076/weightechapp/releases/latest"
                  ),
                  headers: {
                    'Authorization': 'Bearer ${FirebaseUtils.githubToken}'
                  }
                );
                Log.logger.t('Changelog: ${jsonDecode(data.body)["body"]}');
                return jsonDecode(data.body)["body"];
              },
              callback: (status) async {
                if (status == UpdatStatus.upToDate || status == UpdatStatus.dismissed) {
                  await Future.delayed(const Duration(seconds: 1)).then((value) => Navigator.of(context).pop());
                }
              }
            )
          )
        );
      }
    );
  }


  Future<void> _showInfoDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) {
        return ContentDialog(
          title: Center(child: Image.asset('assets/skullanimation_v2.gif', height: 120)),
          content: Container(
            alignment: Alignment.center,
            height: 150,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon/wt_icon.ico', height: 100),
                const SizedBox(width: 30),
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(AppInfo.packageInfo.appName, style: FluentTheme.of(context).typography.title),
                      ),
                      const SizedBox(height: 5),
                      Text("App Version: ${AppInfo.packageInfo.version}", style: FluentTheme.of(context).typography.bodyLarge?.copyWith(fontSize: 16)),
                      const SizedBox(height: 8),
                      Button(
                        child: const Text("View Licenses"),
                        onPressed: () => material.showLicensePage(
                          context: context, 
                          applicationName: AppInfo.packageInfo.appName, 
                          applicationVersion: AppInfo.packageInfo.version, 
                          applicationIcon: Image.asset('assets/icon/wt_icon.ico', height: 200)
                        ),
                      ),
                    ]
                  )
                )
              ]
            )
          ),
          actions: <Widget>[
            Button(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop()
            )
          ],
        );
      }
    );
  }


  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    TextEditingController unsavedNameController = TextEditingController(text: CatalogEditor.name);
    Directory currentDirectory = (CatalogEditor.currentFile != null) ? CatalogEditor.currentFile!.parent : await getApplicationDocumentsDirectory();


    if (isPreventClose && CatalogEditor.isUnsaved) {
      await showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setState) {
              return ContentDialog(
                title: const Text('Save your changes to this file?'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: material.CrossAxisAlignment.start,
                  children: [
                    const Text("File name", textAlign: TextAlign.left),
                    TextBox(
                      controller: unsavedNameController,
                      suffix: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(".wtf")
                      )
                    ),
                    const SizedBox(height: 10),
                    const Text("Choose a location"),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ListTile(
                        leading: const Icon(FluentIcons.folder_20_regular),
                        title: Text(FileUtils.filename(currentDirectory.path)),
                        onPressed: () async {
                          FilePickerResult? _ = 
                            await FilePicker.platform
                              .saveFile(dialogTitle: 'Save As', fileName: '${unsavedNameController.text}.wtf', allowedExtensions: ['wtf'], type: FileType.custom)
                              .then((result) async {
                                if (result != null) {
                                  if (FileUtils.extension(result) != '.wtf') {
                                    result += '.wtf';
                                  }
                                  await CatalogEditor.saveCatalogLocal(path: unsavedNameController.text);
                                }
                                else {
                                  Log.logger.t("-> File save aborted/failed.");
                                  return null;
                                }
                                return null;
                              });
                        }
                      )
                    )
                  ]
                ),
                actions: [
                  FilledButton(
                    child: const Text('Save'),
                    onPressed: () async {
                      await CatalogEditor.saveCatalogLocal(path: unsavedNameController.text);
                      Navigator.of(context).pop();
                    },
                  ),
                  Button(
                    child: const Text("Don't Save"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      windowManager.destroy();
                    },
                  ),
                  Button(
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    }
                  )
                ],
              );
            }
          );
        },
      );
    }
    else {
      windowManager.destroy();
    }
  }
}