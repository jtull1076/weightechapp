
import 'package:weightechapp/themes.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/fluent_models.dart';
import 'package:weightechapp/models.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart' show Scaffold, Theme;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:updat/updat.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:feedback_github/feedback_github.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shortid/shortid.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_saver/file_saver.dart';


class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> with TickerProviderStateMixin {
  late String _startupTaskMessage;
  late StreamController<String> _progressStreamController;
  late bool _updateReady;

  @override
  void initState() {
    super.initState();
    _startupTaskMessage = '';
    _progressStreamController = StreamController<String>();
    _updateReady = false;
    _runStartupTasks();
  }

  Future<void> _runStartupTasks() async { 

    Log.logger.t('...Clearing existing cache');
    _progressStreamController.add('...Clearing cache...');
    await DefaultCacheManager().emptyCache();

    Log.logger.t('...Initializing Firebase...');
    _progressStreamController.add('...Initializing Firebase...');
    await FirebaseUtils().init();

    Log.logger.t('...Initializing Product Manager...');
    _progressStreamController.add('...Initializing Product Manager...');
    await ProductManager.create();

    Log.logger.t('...App Startup...');
    _progressStreamController.add('...App Startup...');

    _progressStreamController.close();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WeightechThemes.startupScaffoldColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Image.asset('assets/icon/wt_icon.ico', height: 200),
            ),
            const SizedBox(height: 10), 
            Text("App Version: ${AppInfo.packageInfo.version}", style: TextStyle(color: WeightechThemes.fluentTheme.resources.textFillColorPrimary)),
            Text(_startupTaskMessage, style: TextStyle(color: WeightechThemes.fluentTheme.resources.textFillColorPrimary)),
            StreamBuilder(
              stream: _progressStreamController.stream,
              initialData: '',
              builder:(context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!, style: TextStyle(color: WeightechThemes.fluentTheme.resources.textFillColorPrimary));
                  } else {
                    return const ProgressRing(); // Or any loading indicator
                  }
                }
                else if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      Center(child: Text("...Checking for updates...", style: TextStyle(color: WeightechThemes.fluentTheme.resources.textFillColorPrimary))),
                      Center(
                        child: UpdatWidget(
                          currentVersion: AppInfo.packageInfo.version,
                          getLatestVersion: () async {
                            // Use Github latest endpoint
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
                            if (status == UpdatStatus.upToDate) {
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
                  );
                }
                else {
                  return const Text("Other");
                }
              }
            )
          ]
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

class _ControlPageState extends State<ControlPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dividerWidthAnimation;
  late Animation<double> _editorHeightAnimation;
  late ProductCategory _catalogCopy;

  late ItemSelect _itemSelection;

  late ECategory _selectedCategory;
  late List<BrochureItem> _brochure;

  late ECategory _editorAll;

  EItem? _focusItem;
  late bool _addingItem;
  late bool _dragging;
  late List<EItem> _itemsToDisplay;

  final TextEditingController _dropdownController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  late int _brochureActiveIndex;
  final _formKey = GlobalKey<FormState>();

  final ScrollController _scrollController = ScrollController();

  late List<String> _imagePaths;
  late List<File> _imageFiles;
  late int _primaryImageIndex;
  late bool _fileDragging;
  late bool _hoverOnAll;
  late bool _hoverOnDelete;

  late bool _loadingSomething;
  late bool _ignoringPointer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(duration : const Duration(seconds: 4), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 0.6, curve: Curves.ease)));
    _dividerWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.5, 0.7, curve: Curves.ease)));
    _editorHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.6, 1.0, curve: Curves.ease)));

    _catalogCopy = CatalogItem.fromJson(ProductManager.all!.toJson()) as ProductCategory;

    _editorAll = EItem.createEditorCatalog(ProductManager.all!);
    _editorAll.showChildren = true;
    
    _itemsToDisplay = _editorAll.editorItems;
    _selectedCategory = _editorAll;

    _addingItem = false;
    _dragging = false;
    _hoverOnAll = false;
    _hoverOnDelete = false;

    _brochureActiveIndex = -1;
    _imagePaths = [];
    _imageFiles = [];
    _primaryImageIndex = 0;
    _fileDragging = false;

    _loadingSomething = false;
    _ignoringPointer = true;

    toggleEditorItem(_focusItem);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //Future.delayed(const Duration(seconds: 5), () =>
      _animationController.forward().whenComplete(() {
         setState(() => _ignoringPointer = false);
      });
      //);
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _dropdownController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _modelNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: Container(
        height: 80,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: WeightechThemes.commandBarColor,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFC9C9CC), width: 0.5),
          )
        ),
        child: CommandBar(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              onPressed: () async {
                Log.logger.t("...Saving product catalog...");
                setState(() {
                  _ignoringPointer = true;
                });
                _showSaveLoading(context);
                try {
                  await EItem.updateProductCatalog(_editorAll);
                }
                catch (error, stackTrace) {
                  Log.logger.e("Error encountered while updating product catalog: ", error: error, stackTrace: stackTrace);
                }
                await ProductManager.create();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
                setState(() {
                  _ignoringPointer = false;
                });
              },
              label: const Text("Save & Exit"),
              icon: const Icon(FluentIcons.save_20_regular), 
            )
          ],
          secondaryItems: [
            CommandBarButton(
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
              icon: const Icon(FluentIcons.bug_20_filled),
              label: Text("Feedback", style: TextStyle(color: WeightechThemes.defaultTextColor))
            ),
            CommandBarButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return ContentDialog(
                    constraints: const BoxConstraints(
                      maxWidth: 450
                    ),
                    title: Center(child: Image.asset('assets/skullbadge_small.gif', height: 120)),
                    content: Container(
                      alignment: Alignment.center,
                      height: 130,
                      width: 450,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/icon/wt_icon.ico', height: 100),
                          const SizedBox(width: 30),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppInfo.packageInfo.appName, style: const TextStyle(fontSize: 28)),
                              Text("AppVer: ${AppInfo.packageInfo.version}", style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 10),
                              Button(
                                child: const Text("View Licenses"),
                                onPressed: () {}
                              ),
                            ]
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
              ),
              label: Text("About", style: TextStyle(color: WeightechThemes.defaultTextColor)),
              icon: const Icon(FluentIcons.info_16_regular),
            )
          ]
        )
      ),
      content: IgnorePointer(
        ignoring: _ignoringPointer,
        child: 
          Stack(
            children: [
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: Listener(
                      onPointerMove: (PointerMoveEvent event) {
                        if (_dragging) {
                          if ((event.position.dy > MediaQuery.of(context).size.height - 50)) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeInOut,
                            );
                          }
                          else if ((event.position.dy < 200)) {
                            _scrollController.animateTo(
                              _scrollController.position.minScrollExtent,
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      },
                      child: Container(
                          decoration: BoxDecoration(
                            color: WeightechThemes.commandBarColor,
                          ),
                          height: MediaQuery.of(context).size.height - 80,
                          width: double.infinity,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: catalogBuilder(item: _editorAll)
                          ),
                      )
                    )                            
                  ),
                  Flexible(
                    flex: 5,
                    child: 
                      switch(_focusItem) {
                        EProduct _ => productEditor(product : _focusItem as EProduct),
                        ECategory _ => categoryEditor(category : _focusItem as ECategory),
                        null => _addingItem ?
                          switch(_itemSelection) {
                            ItemSelect.category => categoryEditor(),
                            ItemSelect.product => productEditor(),
                          }
                          : Container(
                            alignment: Alignment.center,
                            height: MediaQuery.of(context).size.height - 158,
                            child: const Text("To begin, select a product/category to the left, or select '+' to add a new item.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16))
                        )
                      }
                  )
                ]
              ),
              if (_loadingSomething)
                const Center(
                  child: 
                    ProgressRing(),
                )
            ]
          )
      )
    );
  }

  Widget catalogBuilder({required ECategory item}) {
    return Column(
      children: [
        buildItemsList(item: item),
        const SizedBox(height: 100),
      ]
    );
  }

  Widget buildItemsList({required ECategory item}) {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: item.editorItems.length, 
          itemBuilder: (context, index) {
            var subItem = item.editorItems[index];
            switch (subItem) {
              case ECategory _ : {
                return Padding(
                  key: Key(subItem.id),
                  padding: EdgeInsets.only(left: subItem.rank*20),
                  child: Column(
                    children: [
                      subItem.buildListTile(
                        index: index, 
                        onArrowCallback: () => setState(() => subItem.showChildren = !subItem.showChildren), 
                        onEditCallback: () async => toggleEditorItem(subItem),
                        onDragStarted: () => setState(() {
                          subItem.showChildren = false; 
                          _dragging = true;
                        }),
                        onDragCompleted: () => setState(() {
                          _dragging = false;
                          _hoverOnAll = false;
                          _hoverOnDelete = false;
                        }),
                        onDragCanceled: () => setState(() {
                          _dragging = false;
                          _hoverOnAll = false;
                          _hoverOnDelete = false;
                        }),                       
                        ticker: this,
                      ),
                      const Divider(),
                      if (subItem.showChildren) buildItemsList(item: subItem),
                    ]
                  )
                );
              }
              case EProduct _ : {
                return Padding(
                  key: Key(subItem.id),
                  padding: EdgeInsets.only(left: subItem.rank*20 + 26),
                  child: Column(
                    children: [
                      subItem.buildListTile(
                        index: index, 
                        onEditCallback: () async => await toggleEditorItem(subItem),
                        onDragCompleted: () => setState(() {
                          _dragging = false;
                          _hoverOnAll = false;
                          _hoverOnDelete = false;
                        }),
                        onDragStarted: () => setState(() {
                          _dragging = true;
                        }),
                        onDragCanceled: () => setState(() {
                          _dragging = false;
                          _hoverOnAll = false;
                          _hoverOnDelete = false;
                        })
                      ),
                      const Divider()
                    ]
                  )
                );
              }
            }
          }, 
          onReorder: (int oldIndex, int newIndex) {
            if (newIndex > item.editorItems.length) newIndex = item.editorItems.length;
            if (oldIndex < newIndex) newIndex--;
            var dragItem = item.editorItems.removeAt(oldIndex);
            item.editorItems.insert(newIndex, dragItem);
          },
          onReorderStart: (_) {
            setState(() => _dragging = true);
          },
          onReorderEnd: (_) {
            setState(() => _dragging = false);
          }
        ),
      ]
    );
  }

  Widget productEditor({EProduct? product}) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 158,
      width: double.infinity,
      child:
        SingleChildScrollView(
          child: Form (
            key: _formKey,
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 360),
                  child: 
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 25),
                        Flexible(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.only(left: 50, right: 30),
                            alignment: Alignment.center,
                            height: 360,
                            child: 
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextFormBox(
                                    controller: _nameController,
                                    placeholder: "Product Name *",
                                    validator: (String? value) {
                                      return (value == null || value == '' || value == 'All') ? "Name required (and cannot be 'All')." : null;
                                    }
                                  ),
                                  TextFormBox(
                                    controller: _modelNumberController,
                                    placeholder: "Product Model Number"
                                  ),
                                  const SizedBox(height: 20),
                                  InfoLabel(label: "Category *"),
                                  ComboBox<ECategory>(
                                    value: _focusItem?.getParent(root: _editorAll) ?? _editorAll,
                                    items: _editorAll.getSubCategories().map<ComboBoxItem<ECategory>>((ECategory category){
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
                        ),
                        Flexible(
                          flex: 2,
                          child:
                            Container(
                              padding: const EdgeInsets.only(left: 30, right: 50, top: 60),
                              alignment: Alignment.center,
                              child:
                                Column(
                                  children: [
                                    DropTarget(
                                      onDragDone: (detail) {
                                        List<String> paths = [];

                                        Log.logger.t("...Image drop-upload encounter...");
                                        for (var file in detail.files) {
                                          if (_imagePaths.contains(file.path)) {
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
                                          _imagePaths.addAll(paths);
                                          for (var path in paths) {
                                            _imageFiles.add(File(path));
                                          }
                                        });
                                      },
                                      onDragEntered: (details) => setState(() => _fileDragging = true),
                                      onDragExited: (details) => setState(() => _fileDragging = false),
                                      child: SizedBox(
                                        height: (_imagePaths.isNotEmpty) ? 100 : 250,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          padding: EdgeInsets.symmetric(horizontal: _fileDragging ? 0 : 15, vertical: _fileDragging ? 0 : 15),
                                          width: 400,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.black),
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 50),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: _fileDragging ? const Color(0x88396CED) : const Color(0x55C9C9CC),
                                            ),
                                            height: (_imagePaths.isNotEmpty) ? 100 : 250,
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                            alignment: Alignment.center,
                                            child: 
                                              _imagePaths.isEmpty ?
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(FluentIcons.image_16_regular, size: 70),
                                                    const Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 10),
                                                    const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center, 
                                                      children: [
                                                        Expanded(child: Divider()), 
                                                        Text("or"), 
                                                        Expanded(child: Divider())
                                                      ]
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Button(
                                                      style: ButtonStyle(
                                                        foregroundColor: ButtonState.all<Color>(Colors.black)
                                                      ),                 
                                                      onPressed: () async {
                                                        FilePickerResult? _ = 
                                                          await FilePicker.platform.
                                                            pickFiles(allowMultiple: true, type: FileType.image, allowedExtensions: ['png', 'jpg'])
                                                            .then((result) {
                                                              if (result != null) {
                                                                List<String> paths = [];

                                                                for (var path in result.paths) {
                                                                  if (_imagePaths.contains(path)) {
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
                                                                  _imagePaths.addAll(paths);
                                                                  for (var path in paths) {
                                                                    _imageFiles.add(File(path));
                                                                  }
                                                                });
                                                              }
                                                              else {
                                                                Log.logger.t("-> File upload aborted/failed.");
                                                              }
                                                            });
                                                      },
                                                      child: const Text("Browse Files")
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text("File must be .jpg or .png", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic))
                                                  ]
                                                )
                                              : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text("Drag and drop", style: TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 20),
                                                  const Column(
                                                    mainAxisAlignment: MainAxisAlignment.center, 
                                                    children: [
                                                      Expanded(child: Divider(direction: Axis.vertical)), 
                                                      Text("or"), 
                                                      Expanded(child: Divider(direction: Axis.vertical))
                                                    ]
                                                  ),
                                                  const SizedBox(width: 20),
                                                  Button(
                                                    style: ButtonStyle(
                                                      foregroundColor: ButtonState.all<Color>(Colors.black)
                                                    ),                 
                                                    onPressed: () async {
                                                      Log.logger.t("...Image upload encountered...");
                                                      FilePickerResult? _ = 
                                                        await FilePicker.platform.
                                                          pickFiles(allowMultiple: true, type: FileType.image, allowedExtensions: ['png', 'jpg'])
                                                          .then((result) {
                                                            if (result != null) {
                                                              List<String> paths = [];

                                                              for (var path in result.paths) {
                                                                if (_imagePaths.contains(path)) {
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
                                                                else {
                                                                  Log.logger.t("-> Invalid file type: File type $extension not supported.");
                                                                }
                                                              }

                                                              setState(() {
                                                                _imagePaths.addAll(paths);
                                                                for (var path in paths) {
                                                                  _imageFiles.add(File(path));
                                                                }
                                                              });
                                                            }
                                                            else {
                                                              Log.logger.t("-> File upload aborted/failed.");
                                                            }
                                                          });
                                                    },
                                                    child: const Text("Browse Files")
                                                  ),
                                                ]
                                              )
                                          ),
                                        ), 
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: 340,
                                      child: ReorderableListView.builder(
                                        shrinkWrap: true,
                                        buildDefaultDragHandles: false,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _imagePaths.length,
                                        itemBuilder:(context, index) {

                                          bool isFromCloud = false;
                                          bool isDownloading = false;

                                          final image = _imageFiles[index];
                                          String imageText = '';
                                          if (isURL(_imagePaths[index])) {
                                            final ref = FirebaseUtils.storage.refFromURL(_imagePaths[index]);
                                            imageText = ref.name;
                                            isFromCloud = true;
                                          }
                                          else {
                                            imageText = image.uri.pathSegments.last;
                                          }

                                          return Column(
                                            key: Key('image_$index'),
                                            children: [
                                              ReorderableDragStartListener(
                                                index: index,
                                                child: 
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF404040),
                                                      borderRadius: BorderRadius.circular(4)
                                                    ),
                                                    alignment: Alignment.center,
                                                    height: 33,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                    child:
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text("${index+1}."),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: Row(
                                                              children: [
                                                                Expanded(child: Text(imageText, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
                                                                // if (isFromCloud) const SizedBox(width: 1),
                                                                // if (isFromCloud) const Icon(Icons.cloud_outlined, color: Color(0xFFA9A9AA), size: 12.0)
                                                              ]
                                                            )
                                                          ),
                                                          const SizedBox(width: 10),
                                                          FluentTheme(
                                                            data: WeightechThemes.fluentTheme,
                                                            child: (isFromCloud) ?
                                                              StatefulBuilder(
                                                                builder: (context, setState) {
                                                                  return Row(
                                                                    children: [
                                                                      IconButton(
                                                                        icon: isDownloading ? 
                                                                          LoadingAnimationWidget.bouncingBall(color: const Color(0xFFA9A9AA), size: 15) 
                                                                          : const Icon(FluentIcons.cloud_arrow_down_16_regular, color: Colors.white, size: 18),
                                                                        onPressed: () async {
                                                                          setState(() => isDownloading = true);
                                                                          _imageFiles[index].setLastModified(DateTime.now());
                                                                          await FileSaver.instance.saveFile(name: imageText, file: _imageFiles[index]);
                                                                          await getDownloadsDirectory().then((dir) async {
                                                                            if (dir != null) {
                                                                              launchUrl(dir.uri);
                                                                            }
                                                                          });
                                                                          setState(() => isDownloading = false);
                                                                        }
                                                                      ),
                                                                    ]
                                                                  );
                                                                }
                                                              )
                                                            : IconButton(
                                                                icon: const Icon(FluentIcons.open_folder_16_regular, color: Color(0xFFA9A9AA), size: 16),
                                                                onPressed: () async {
                                                                  final dir = p.dirname(_imagePaths[index]);
                                                                  final uri = Uri.parse(dir);
                                                                  launchUrl(uri);
                                                                }
                                                              ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          FluentTheme(
                                                            data: WeightechThemes.fluentTheme,
                                                            child: IconButton(
                                                              icon: (index == _primaryImageIndex) 
                                                                ? Icon(FluentIcons.star_16_filled, color: Colors.yellow, size: 18 ) 
                                                                : const Icon(FluentIcons.star_16_regular, color: Colors.white, size: 18),
                                                              onPressed: () => setState(() => _primaryImageIndex = index)
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          FluentTheme(
                                                            data: WeightechThemes.fluentTheme,
                                                            child: IconButton(
                                                              icon: const Icon(FluentIcons.eye_16_regular, color: Colors.white, size: 18),
                                                              onPressed: () async {
                                                                await _previewImage(context, image);
                                                              }
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          FluentTheme(
                                                            data: WeightechThemes.fluentTheme,
                                                            child: IconButton(
                                                              icon: const Icon(FluentIcons.dismiss_16_regular, color: Colors.white, size: 18),
                                                              onPressed: () => setState(() {
                                                                _imagePaths.removeAt(index);
                                                                _imageFiles.removeAt(index);
                                                              })
                                                            )
                                                          )
                                                        ],
                                                      )
                                                  ),
                                              ),
                                              const SizedBox(height: 5),
                                            ]
                                          );
                                        },
                                        onReorder: (oldIndex, newIndex) {
                                          // These two lines are workarounds for ReorderableListView problems
                                          if (newIndex > _imagePaths.length) newIndex = _imagePaths.length;
                                          if (oldIndex < newIndex) newIndex--;

                                          

                                          String pathToMove = _imagePaths.removeAt(oldIndex);
                                          File fileToMove = _imageFiles.removeAt(oldIndex);
                                          _imagePaths.insert(newIndex, pathToMove);
                                          _imageFiles.insert(newIndex, fileToMove);
                                          setState(() {});
                                        }
                                      )
                                    )
                                  ]
                                )
                            )
                        )
                      ]
                    ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 150, right: 150, bottom: 10), 
                  child: 
                    Text("Product Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 150, right: 150, bottom: 20),
                  child: 
                    TextFormBox(
                      controller: _descriptionController,
                      placeholder: "Overview",
                      minLines: 1,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    )
                ),
                Padding( 
                  padding: const EdgeInsets.symmetric(horizontal: 150),
                  child:
                    Container(
                      alignment: Alignment.centerLeft,
                      child: 
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: _brochure.length,
                          itemBuilder: (context, index) {
                            final item = _brochure[index];
                            
                            return MouseRegion(
                              key: Key('Mouse_$index'),
                              onEnter: (PointerEnterEvent evt) {
                                setState((){
                                  _brochureActiveIndex = index;
                                });
                              },
                              onExit: (PointerExitEvent evt) {
                                setState((){
                                  _brochureActiveIndex = -1;
                                });
                              },
                              child:
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 0),
                                      child: 
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: item.buildItem(context)
                                              ), 
                                              if (index == _brochureActiveIndex)
                                                IconButton(
                                                  icon: const Icon(FluentIcons.delete_16_regular), 
                                                  onPressed: () => setState(()=> _brochure.removeAt(index)) 
                                                )
                                            ]
                                          )
                                        )
                                    ),
                                    if(_brochureActiveIndex == index)
                                      Container(
                                        padding: const EdgeInsets.only(top: 10),
                                        width: 450,
                                        height: 50,
                                        alignment: Alignment.topCenter,
                                        child:
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: 
                                                  Button(
                                                    style: ButtonStyle(
                                                      backgroundColor: ButtonState.all<Color>(const Color(0xFFC9C9CC)),
                                                      foregroundColor: ButtonState.all<Color>(Colors.black),
                                                    ),
                                                    onPressed: () {
                                                      setState((){
                                                        int newItemIndex = index+1;
                                                        _brochure.insert(newItemIndex, BrochureHeader.basic());
                                                      });
                                                    }, 
                                                    child: const Text("Header+")
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: 
                                                    Button(
                                                      style: ButtonStyle(
                                                        backgroundColor: ButtonState.all<Color>(const Color(0xFFC9C9CC)),
                                                        foregroundColor: ButtonState.all<Color>(Colors.black),
                                                      ),
                                                      onPressed: () {
                                                        setState((){
                                                          int newItemIndex = index+1;
                                                          _brochure.insert(newItemIndex, BrochureSubheader.basic());
                                                        });
                                                      }, 
                                                      child: const Text("Subheader+")
                                                    ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child:
                                                    Button(
                                                      style: ButtonStyle(
                                                        backgroundColor: ButtonState.all<Color>(const Color(0xFFC9C9CC)),
                                                        foregroundColor: ButtonState.all<Color>(Colors.black),
                                                      ),
                                                      onPressed: () {
                                                        setState((){
                                                          int newItemIndex = index+1;
                                                          _brochure.insert(newItemIndex, BrochureEntry.basic());
                                                        });
                                                      }, 
                                                      child: const Text("Entry+")
                                                    )
                                                )
                                              ]
                                            )
                                      )
                                  ]
                                )
                              );
                          },
                          onReorder: (int oldIndex, int newIndex) {
                            setState(() {
                              if (newIndex > _brochure.length) newIndex = _brochure.length;
                              if (oldIndex < newIndex) newIndex--;
                              final item = _brochure.removeAt(oldIndex);
                              _brochure.insert(newIndex, item);
                            });
                          },                                                            
                        )
                    ),
                ),
                const SizedBox(height: 20),
                Button(
                  child: const Text("Preview"),
                  onPressed: () {
                    _showPreviewDialog(context);
                  },
                ),
                const SizedBox(height: 10),
                Button(
                  child: _addingItem ? const Text("Add") : const Text("Save"),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_addingItem) {
                        Product newProduct = Product(
                          name: _nameController.text,
                          parentId: _selectedCategory.id,
                          modelNumber: _modelNumberController.text,
                          description: _descriptionController.text,
                          brochure: Product.mapListToBrochure(_brochure)
                        );
                        EProduct newEProduct = EProduct(product: newProduct, rank: _selectedCategory.rank+1, imagePaths: List.from(_imagePaths), primaryImageIndex: _primaryImageIndex);
                        _selectedCategory.addItem(newEProduct);
                      }
                      else if (product != null) {
                        if (product.parentId != _selectedCategory.id) {
                          product.reassignParent(newParent: _selectedCategory);
                        }
                        product.product.name = _nameController.text;
                        product.product.modelNumber = _modelNumberController.text;
                        product.product.description = _descriptionController.text;
                        product.product.brochure = Product.mapListToBrochure(_brochure);
                        product.imagePaths = List.from(_imagePaths);
                        product.imageFiles = List.from(_imageFiles);
                        product.primaryImageIndex = _primaryImageIndex;
                      }
                      setState(() {
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

  Widget categoryEditor({ECategory? category}) {
    
    bool hoverOnImageRemove = false;

    return SizedBox(
      height: MediaQuery.of(context).size.height - 158,
      width: double.infinity,
      child:
        SingleChildScrollView(
          child: 
            Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 360),
                  child: 
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 25),
                        Flexible(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.only(left: 20),
                            alignment: Alignment.center,
                            height: 340,
                            child: 
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextFormBox(
                                    controller: _nameController,
                                    placeholder: "Category Name *",
                                    validator: (String? value) {
                                      return (value == null || value == '' || value == 'All') ? "Name required (and cannot be 'All')." : null;
                                    }
                                  ),
                                  const SizedBox(height: 20),
                                  InfoLabel(label: "Parent Category *"),
                                  ComboBox<ECategory>(
                                    value: _focusItem?.getParent(root: _editorAll) ?? _editorAll,
                                    items: (_editorAll.getSubCategories(categoriesToExclude : (category != null) ? [category] : null)).map<ComboBoxItem<ECategory>>((ECategory categoryOption){
                                      return ComboBoxItem<ECategory>(
                                        value: categoryOption,
                                        child: Text(categoryOption.category.name),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState((){
                                        _selectedCategory = newValue!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  (category != null) ?
                                    SizedBox(
                                      height: 20,
                                      child: Text("Item ID: ${category.id}", style: const TextStyle(fontStyle: FontStyle.italic)),
                                    )
                                  : const SizedBox(height: 20),
                                ]
                              )
                          )
                        ),
                        Flexible(
                          flex: 3,
                          child:
                            Container(
                              padding: const EdgeInsets.only(left: 50, right: 50, top: 60),
                              child:
                                Column(
                                  children: [
                                    DropTarget(
                                      onDragDone: (detail) {
                                        List<String> paths = [];

                                        for (var file in detail.files) {
                                          if (_imagePaths.contains(file.path)) {
                                            Log.logger.t("Image already assigned to item.");
                                            continue;
                                          }
                                          String extension = file.path.substring(file.path.length - 4);
                                          if (extension == ".jpg" || extension == ".png") {
                                            Log.logger.t("Image added to paths: ${file.path}");
                                            paths.add(file.path);
                                          }
                                          else if (file.path.substring(file.path.length - 5) == ".jpeg") {
                                            Log.logger.t("Image added to paths: ${file.path}");
                                            paths.add(file.path);
                                          }
                                          else {
                                            Log.logger.t("Invalid file type: File type $extension not supported.");
                                          }
                                        }

                                        setState(() {
                                          _imagePaths = [];
                                          _imageFiles = [];
                                          _imagePaths.add(paths[0]);
                                          _imageFiles.add(File(paths[0]));
                                        });
                                      },
                                      onDragEntered: (details) => setState(() => _fileDragging = true),
                                      onDragExited: (details) => setState(() => _fileDragging = false),
                                      child: SizedBox(
                                        height: 250,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          padding: EdgeInsets.symmetric(horizontal: _fileDragging ? 0 : 15, vertical: _fileDragging ? 0 : 15),
                                          width: 400,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.black),
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 50),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: _fileDragging ? const Color(0x88396CED) : const Color(0x55C9C9CC),
                                            ),
                                            height: 250,
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                            alignment: Alignment.center,
                                            child: 
                                              _imagePaths.isEmpty ?
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(FluentIcons.image_16_regular, size: 70),
                                                    const Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 10),
                                                    const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center, 
                                                      children: [
                                                        Expanded(child: Divider()), 
                                                        Text("or"), 
                                                        Expanded(child: Divider())
                                                      ]
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Button(
                                                      style: ButtonStyle(
                                                        foregroundColor: ButtonState.all<Color>(Colors.black)
                                                      ),                 
                                                      onPressed: () async {
                                                        FilePickerResult? _ = 
                                                          await FilePicker.platform.
                                                            pickFiles(allowMultiple: false, type: FileType.image, allowedExtensions: ['png', 'jpg'])
                                                            .then((result) {
                                                              if (result != null) {
                                                                List<String> paths = [];

                                                                for (var path in result.paths) {
                                                                  if (_imagePaths.contains(path)) {
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
                                                                  _imagePaths = [];
                                                                  _imageFiles = [];
                                                                  _imagePaths.add(paths[0]);
                                                                  _imageFiles.add(File(paths[0]));
                                                                });
                                                              }
                                                              else {
                                                                Log.logger.t("File upload aborted/failed.");
                                                              }
                                                            });
                                                      },
                                                      child: const Text("Browse Files")
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text("File must be .jpg or .png", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic))
                                                  ]
                                                )
                                              : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(height: 10),
                                                  Flexible(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: StatefulBuilder(
                                                        builder: ((context, setState) {
                                                          return MouseRegion(
                                                            onEnter: (event) {
                                                              hoverOnImageRemove = true;
                                                            },
                                                            onExit: (event) {
                                                              hoverOnImageRemove = false;
                                                            },
                                                            child: Stack(
                                                              children: [
                                                                Image.file(_imageFiles[0], height: 300),
                                                                IconButton(
                                                                  onPressed: () {
                                                                    _imageFiles.clear();
                                                                    _imagePaths.clear();
                                                                    super.setState(() {});
                                                                  },
                                                                  icon: const Icon(FluentIcons.dismiss_16_regular, size:40, color: Color(0xFFC9C9CC))
                                                                )
                                                              ]
                                                            )
                                                          );
                                                        })
                                                      )
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  SizedBox(
                                                    height: 50,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                                                        const SizedBox(width: 20),
                                                        const Column(
                                                          mainAxisAlignment: MainAxisAlignment.center, 
                                                          children: [
                                                            Expanded(child: Divider(direction: Axis.vertical)), 
                                                            Text("or"), 
                                                            Expanded(child: Divider(direction: Axis.vertical))
                                                          ]
                                                        ),
                                                        const SizedBox(width: 20),
                                                        Button(
                                                          style: ButtonStyle(
                                                            foregroundColor: ButtonState.all<Color>(Colors.black)
                                                          ),                 
                                                          onPressed: () async {
                                                            FilePickerResult? _ = 
                                                              await FilePicker.platform.
                                                                pickFiles(allowMultiple: false, type: FileType.image, allowedExtensions: ['png', 'jpg'])
                                                                .then((result) {
                                                                  if (result != null) {
                                                                    List<String> paths = [];

                                                                    for (var path in result.paths) {
                                                                      if (_imagePaths.contains(path)) {
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
                                                                      _imagePaths = [];
                                                                      _imageFiles = [];
                                                                      _imagePaths.add(paths[0]);
                                                                      _imageFiles.add(File(paths[0]));
                                                                    });
                                                                  }
                                                                  else {
                                                                    Log.logger.t("File upload aborted/failed.");
                                                                  }
                                                                });
                                                          },
                                                          child: const Text("Browse Files")
                                                        ),
                                                      ]
                                                    )
                                                  )
                                                ]
                                              )
                                          ),
                                        ), 
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ]
                                )
                            )
                        )
                      ]
                    ),
                ),
                const SizedBox(height: 20),
                Button(
                  style: ButtonStyle(
                    backgroundColor: ButtonState.all<Color>(Color(0xFF224190)),
                    foregroundColor: ButtonState.all<Color>(Colors.white)
                  ),
                  child: _addingItem ? const Text("Add") : const Text("Save"),
                  onPressed: () {
                    if (_addingItem) {
                      ProductCategory newCategory = ProductCategory(
                        name: _nameController.text,
                        parentId: _selectedCategory.id,
                      );
                      ECategory newECategory = ECategory(category: newCategory, rank: _selectedCategory.rank+1, editorItems: [], imagePath: _imagePaths.isNotEmpty ? _imagePaths[0] : null);
                      _selectedCategory.addItem(newECategory);
                    }
                    else if (category != null) {
                      if (category.parentId != _selectedCategory.id) {
                        category.reassignParent(newParent: _selectedCategory);
                      }
                      category.category.name = _nameController.text;
                      category.imagePath = _imagePaths.isNotEmpty ? _imagePaths[0] : null;
                      category.imageFile = _imageFiles.isNotEmpty ? _imageFiles[0] : null;
                      category.rank = _selectedCategory.rank+1;
                    }
                    setState(() {
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


  Future<void> _previewImage(BuildContext context, File imageFile) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text(""),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(imageFile, width: 600),
          ),
          actions: <Widget>[
            Button(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop()
            )
          ]
        );
      }
    );
  }

  Future<void> _showSaveLoading(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text(""),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.hexagonDots(color: const Color(0xFF224190), size: 60),
              const SizedBox(height: 50),
              const Text("Saving changes... this may take a moment.")
            ]
          )
        );
      }
    );
  }
  
  Future<void> _showPreviewDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int? current;
            List<Map<String, dynamic>> tempBrochure = Product.mapListToBrochure(_brochure);

            return ContentDialog(
              style: const ContentDialogThemeData(
                bodyPadding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                actionsPadding: EdgeInsets.fromLTRB(20, 2, 20, 20),
              ),
              content: SizedBox(
                height: MediaQuery.of(context).size.height*0.7,
                width: MediaQuery.of(context).size.width*0.7,
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        color: const Color(0xFF224190),
                        border: Border.all(color: const Color(0xFF224190))
                      ),
                      width: double.infinity,
                      child: 
                        Padding(
                          padding: const EdgeInsets.all(1.4),
                          child:
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: 
                                Text(_nameController.text, 
                                  textAlign: TextAlign.center, 
                                  style: const TextStyle(fontSize: 22.4, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                            )
                        )
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
                                                enableInfiniteScroll: _imageFiles.length > 1 ? true : false, 
                                                enlargeCenterPage: true,
                                                enlargeFactor: 1,
                                                onPageChanged: (index, reason) {
                                                  setState(() {
                                                    current = index;
                                                  });
                                                },
                                              ),
                                              itemCount: _imageFiles.length,
                                              itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(30.0),
                                                  child: Image.file(_imageFiles[itemIndex])
                                                );
                                              }
                                            ),
                                            const SizedBox(height: 7),
                                            if (_imageFiles.length > 1)
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: _imageFiles.asMap().entries.map((entry) {
                                                  return Container(
                                                    width: 7,
                                                    height: 7,
                                                    margin: const EdgeInsets.symmetric(vertical: 5.6, horizontal: 2.8),
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: const Color(0xFF224190)
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
                                                Text(headerKey, style: const TextStyle(color: Color(0xFF224190), fontSize: 19.6, fontWeight: FontWeight.bold), softWrap: true,),
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
                                                    final subheaderValue = subheaders[subIndex][subheaderKey] as List<String>;

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
                        
                    )
                  ]
                )
              ),
              actions: <Widget>[
                Button(
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<String> writeImageToStorage(Uint8List feedbackScreenshot) async {
    final Directory? output = await getDownloadsDirectory();
    if (output != null) {
      final String screenshotFilePath = '${output.path}/feedback.png';
      final File screenshotFile = File(screenshotFilePath);
      await screenshotFile.writeAsBytes(feedbackScreenshot);
      return screenshotFilePath;
    }
    return '';
  }


  Future<bool> _showExitDialog(BuildContext context) async {
    bool hoverOnYes = false;
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ContentDialog(
              title: const Text("Warning!"),
              content: const Text("Are you sure you want to exit? Your progress will not be saved."),
              actions: <Widget>[
                Button(
                  child: const Text("Return"),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  }
                ),
                MouseRegion(
                  onEnter: (event) => hoverOnYes = true,
                  onExit: (event) => hoverOnYes = false,
                  child: Button(
                    style: hoverOnYes ? 
                      ButtonStyle(
                        foregroundColor: ButtonState.all<Color>(Colors.white), 
                        backgroundColor: ButtonState.all<Color>(Color(0xFFC3291B))
                      ) :
                      const ButtonStyle(),
                    child: Text("Exit", style: hoverOnYes ? const TextStyle(color: Colors.white) : const TextStyle(color: Color(0xFFC32918))),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    }
                  )
                )
              ]
            );
          }
        );
      }
    ) ?? false;
  }

  Future<bool> _showAlertDialog(BuildContext context, EItem data) async {
    bool? confirmation = false;
    bool hoverOnYes = false;
    switch (data) {
      case ECategory _ : {
        confirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return ContentDialog(
                  title: const Text("Warning!"),
                  content: Text("You are about to delete ${data.category.name} and all of its contents (including sub-products). \nThis action cannot be undone. Are you sure?"),
                  actions: <Widget>[
                    Button(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    ),
                    MouseRegion(
                      onEnter:(event) => hoverOnYes = true,
                      onExit: (event) => hoverOnYes = false,
                      child: Button(
                        style: hoverOnYes ? 
                          ButtonStyle(
                            foregroundColor: ButtonState.all<Color>(Colors.white), 
                            backgroundColor: ButtonState.all<Color>(const Color(0xFFC3291B))) : 
                          const ButtonStyle(),
                        child: const Text("Yes"),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        }
                      )
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
                  content: Text("You are about to delete ${data.product.name} and all of its contents. \nThis action cannot be undone. Are you sure?"),
                  actions: <Widget>[
                    Button(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    ),
                    Button(
                      style: hoverOnYes ? 
                        ButtonStyle(
                          foregroundColor: ButtonState.all<Color>(Colors.white), 
                          backgroundColor: ButtonState.all<Color>(const Color(0xFFC3291B))) : 
                        const ButtonStyle(),
                      child: const Text("Yes"),
                      onPressed: () {
                        Navigator.of(context).pop(true);
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

  Future<void> toggleEditorItem(EItem? focusItem) async {
    switch (focusItem) {
      case EProduct _ : {
        setState(() => _loadingSomething = true);
        await focusItem.setImagePaths();
        await focusItem.setImageFiles();
        _imagePaths.clear();
        _imageFiles.clear();
        setState(() {
          _focusItem = focusItem;
          _imagePaths = List.from(focusItem.imagePaths!);
          _imageFiles = List.from(focusItem.imageFiles!);
          _nameController.text = focusItem.product.name;
          _modelNumberController.text = focusItem.product.modelNumber ?? '';
          _brochure = focusItem.product.retrieveBrochureList();
          _descriptionController.text = focusItem.product.description ?? '';
          _selectedCategory = focusItem.getParent(root: _editorAll) ?? _editorAll;
          _loadingSomething = false;
        });
        setState(() => _loadingSomething = false);
      }
      case ECategory _ : {
        setState(() => _loadingSomething = true);
        await focusItem.setImagePaths();
        await focusItem.setImageFiles();
        _imagePaths.clear();
        _imageFiles.clear();
        setState(() {
          _focusItem = focusItem;
          if (focusItem.imagePath != null) _imagePaths.add(focusItem.imagePath!);
          if (focusItem.imageFile != null) _imageFiles.add(focusItem.imageFile!);
          _nameController.text = focusItem.category.name;
          _selectedCategory = focusItem.getParent(root: _editorAll) ?? _editorAll;
        });
        setState(() => _loadingSomething = false);
      }
      case null : {
        _imagePaths.clear();
        _imageFiles.clear();
        _brochure = [BrochureHeader.basic(), BrochureSubheader.basic(), BrochureEntry.basic(), BrochureHeader.basic(), BrochureEntry.basic()];
        _nameController.text = '';
        _descriptionController.text = '';
        _modelNumberController.text = '';
        _selectedCategory = _editorAll;
      }
    }
  }

  void toggleDisplayItems(List<EItem> itemsToToggle, int index) {
    for (var item in itemsToToggle) {
      if (_itemsToDisplay.contains(item)) {
        _itemsToDisplay.remove(item);
      }
      else {
        _itemsToDisplay.insert(index, item);
      }
    }
  }
}



enum ItemSelect {product, category}
