import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/universal_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:weightechapp/extra_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
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
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:updat/updat.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


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
    listener = InternetConnection().onStatusChange
      .listen((InternetStatus status) {
        switch (status) {
          case InternetStatus.connected:
            // The internet is now connectioni
            Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const IdlePage()));
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
    return Scaffold(
      body: Center(
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
                      const Icon(Icons.signal_wifi_bad, size: 50,),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: LoadingAnimationWidget.twoRotatingArc(color: const Color(0xFF224190), size: 100)
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
    return Scaffold(
      body: Center(
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
                  const Icon(Icons.error_outline, size: 160),
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
        Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const OfflinePage()));
      }
    }

    try {
      Log.logger.t('...Clearing existing cache');
      _progressStreamController.add('...Clearing cache...');
      await DefaultCacheManager().emptyCache();

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
  void dispose() {
    _progressStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Image.asset('assets/icon/wt_icon.ico', height: 200),
            ),
            const SizedBox(height: 10), 
            Text("App Version: ${AppInfo.packageInfo.version}"),
            Text(_startupTaskMessage),
            StreamBuilder(
              stream: _progressStreamController.stream,
              initialData: '',
              builder:(context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const CircularProgressIndicator(); // Or any loading indicator
                  }
                }
                else if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      if (_checkingForUpdate) const Center(child: Text("...Checking for updates...")),
                      Center(
                        child: UpdatWidget(
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
                            if (status == UpdatStatus.upToDate || status == UpdatStatus.error) {
                              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const IdlePage()));
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

  late List<String> _mediaPaths;
  late List<File> _mediaFiles;
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
    _mediaPaths = [];
    _mediaFiles = [];
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7E7E80),
        foregroundColor: Colors.white,
        hoverColor: const Color(0xFF224190),
        label: const Text("Save & Exit"),
        onPressed: () async {
          Log.logger.t("...Saving product catalog...");
          setState(() {
            _ignoringPointer = true;
          });
          _showSaveLoading(context);
          try {
            await toggleEditorItem(null);
            await EItem.updateProductCatalog(_editorAll);
          }
          catch (error, stackTrace) {
            Log.logger.e("Error encountered while updating product catalog: ", error: error, stackTrace: stackTrace);
            setState(() {
              _ignoringPointer = false;
            });
            return;
          }
          await ProductManager.create();
          setState(() {
            _ignoringPointer = false;
          });
          if (context.mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        }
      ),
      body: IgnorePointer(
        ignoring: _ignoringPointer,
        child: 
          Stack(
            children: [
              Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: 110,
                    child: 
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: 
                              Padding(
                                padding: const EdgeInsets.only(right: 30),
                                child: 
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: MenuAnchor(
                                      style: const MenuStyle(surfaceTintColor: MaterialStatePropertyAll<Color>(Colors.white)),
                                      menuChildren: [
                                        MenuItemButton(
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
                                          child: const Row(
                                            children: [
                                              Icon(Icons.feedback_outlined, color: Color(0xFF224190)),
                                              SizedBox(width: 10),
                                              Text("Feedback")
                                            ]
                                          )
                                        ),
                                        MenuItemButton(
                                          onPressed: () => showDialog<void>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                surfaceTintColor: Colors.transparent,
                                                title: Image.asset('assets/skullanimation_v2.gif', height: 120),
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
                                                          TextButton(
                                                            child: const Text("View Licenses"),
                                                            onPressed: () => showLicensePage(
                                                              context: context, 
                                                              applicationName: AppInfo.packageInfo.appName, 
                                                              applicationVersion: AppInfo.packageInfo.version, 
                                                              applicationIcon: Image.asset('assets/icon/wt_icon.ico', height: 200)
                                                            ),
                                                          ),
                                                        ]
                                                      )
                                                    ]
                                                  )
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text("Close"),
                                                    onPressed: () => Navigator.of(context).pop()
                                                  )
                                                ],
                                                actionsAlignment: MainAxisAlignment.center,
                                              );
                                            }
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.info_outline, color: Color(0xFF224190)),
                                              SizedBox(width: 10),
                                              Text("About")
                                            ]
                                          )
                                        )
                                      ],
                                      builder: (BuildContext context, MenuController controller, Widget? child) {
                                        return IconButton(
                                          icon: const Icon(Icons.menu), 
                                          color: const Color(0xFF224190),
                                          onPressed: () {
                                            if (controller.isOpen) {
                                              controller.close();
                                            }
                                            else {
                                              controller.open();
                                            }
                                          }
                                        );
                                      },
                                    )
                                  )
                              )
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10.0), 
                              child: Hero(
                                tag: 'main-logo',
                                child: Image.asset('assets/weightech_logo_beta.png', height: 100, alignment: Alignment.center,)
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: 
                              Padding(
                                padding: const EdgeInsets.only(left: 30),
                                child: 
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: 
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        iconSize: 30,
                                        color: const Color(0xFF224190),
                                        onPressed: () async {
                                          bool confirm = await _showExitDialog(context);
                                          if (confirm) {
                                            setState(() => _loadingSomething = true);
                                            await ProductManager.create();
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          }
                                        },
                                      )
                                  )
                              )
                          ),
                        ]
                      ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    alignment: Alignment.centerLeft,
                    child: SizeTransition(
                      sizeFactor: _dividerWidthAnimation, 
                      axis: Axis.vertical,
                      child: FadeTransition(
                        opacity: _fadeAnimation, 
                        child: Column(
                          children: [
                            const Divider(color: Color(0xFF224190), height: 2, thickness: 2, indent: 0, endIndent: 0,),
                            Container(
                              alignment: Alignment.topCenter,
                              decoration: const BoxDecoration(
                                color: Color(0xFF224190),
                              ),
                              width: double.infinity,
                              child: const Text("Catalog Editor", 
                                textAlign: TextAlign.center, 
                                style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                            )
                          ]
                        )
                      )
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SizeTransition(
                      sizeFactor: _editorHeightAnimation,
                      axis: Axis.vertical,
                      axisAlignment: 1,
                      child: 
                      Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                decoration: const BoxDecoration(
                                  color: Color(0x99C9C9CC),
                                  border: Border(
                                    right: BorderSide(color: Color(0xFF224190), width: 2.0),
                                    left: BorderSide(color: Color(0xFF224190), width: 2.0),
                                    bottom: BorderSide(color: Color(0xFF224190), width: 2.0),
                                  )
                                ),
                                height: MediaQuery.of(context).size.height - 158,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    SingleChildScrollView(
                                      controller: _scrollController,
                                      child: catalogBuilder(item: _editorAll)
                                    ),
                                    if (_dragging)
                                      Positioned(
                                        bottom: 20,
                                        left: 20,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            InkWell(
                                              onTap: () {},
                                              onHover: (isHovering) {
                                                if (isHovering) {
                                                  setState(() => _hoverOnAll = true);
                                                }
                                                else {
                                                  setState(() => _hoverOnAll = false);
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                                alignment: Alignment.center,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  child: DragTarget<EItem>(
                                                    onWillAcceptWithDetails: (details) {
                                                      return (!_editorAll.editorItems.contains(details.data));
                                                    },
                                                    onAcceptWithDetails: (details) {
                                                      ECategory parent = details.data.getParent(root: _editorAll)!;
                                                      parent.editorItems.remove(details.data);

                                                      details.data.rank = 0;
                                                      details.data.parentId = _editorAll.id;
                                                      _editorAll.editorItems.add(details.data);
                                                    },
                                                    builder: (context, accepted, rejected) {
                                                      return AnimatedContainer(
                                                        alignment: Alignment.center,
                                                        duration: const Duration(milliseconds: 100),
                                                        transformAlignment: Alignment.center,
                                                        color: _hoverOnAll ? const Color(0xFF224190) : const Color(0xFF808082),
                                                        width: _hoverOnAll ? 120 : 80,
                                                        height: _hoverOnAll ? 60 : 40,
                                                        child: const Icon(Icons.vertical_align_top, color: Colors.white)
                                                      );
                                                    }
                                                  )
                                                )
                                              )
                                            ),
                                            const SizedBox(height: 20),
                                            InkWell(
                                              onTap: () {},
                                              onHover: (isHovering) {
                                                if (isHovering) {
                                                  setState(() => _hoverOnDelete = true);
                                                }
                                                else {
                                                  setState(() => _hoverOnDelete = false);
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  child: DragTarget<EItem>(
                                                    onWillAcceptWithDetails: (details) {
                                                      return true;
                                                    },
                                                    onAcceptWithDetails: (details) async {
                                                      bool confirm = await _showAlertDialog(context, details.data);
                                                      if (confirm) {
                                                        details.data.removeFromParent();
                                                        setState(() => _focusItem = null);
                                                      }
                                                    },
                                                    builder: (context, accepted, rejected) {
                                                      return AnimatedContainer(
                                                        alignment: Alignment.center,
                                                        duration: const Duration(milliseconds: 100),
                                                        transformAlignment: Alignment.center,
                                                        width: _hoverOnDelete ? 120 : 80,
                                                        height: _hoverOnDelete ? 60 : 40,
                                                        color: _hoverOnDelete ? const Color(0xFFC3291B) : const Color(0xFF808082),
                                                        child: const Icon(Icons.delete, color: Colors.white)
                                                      );
                                                    }
                                                  )
                                                )
                                              )
                                            ),
                                          ]
                                        ),
                                      ),
                                    ExpandableFab(
                                      distance: 60,
                                      children: [
                                        ActionButton(
                                          onPressed: () async {
                                            _focusItem = null;
                                            await toggleEditorItem(_focusItem);
                                            setState(() {
                                              _addingItem = true;
                                              _itemSelection = ItemSelect.category;
                                            });
                                          },
                                          icon: const Icon(Icons.folder),
                                        ),
                                        ActionButton(
                                          onPressed: () async {
                                            _focusItem = null;
                                            await toggleEditorItem(_focusItem);
                                            setState(() {
                                              _addingItem = true;
                                              _itemSelection = ItemSelect.product;
                                            });
                                          },
                                          icon: const Icon(Icons.conveyor_belt),
                                        ),
                                      ],
                                    )
                                  ]
                                )
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
                    )
                    ),
                  ),
                ]
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text("${AppInfo.packageInfo.version} ${AppInfo.sessionId}")
              ),
              if (_loadingSomething)
                const Center(
                  child: 
                    CircularProgressIndicator(),
                ),
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
                      const Divider(color: Colors.grey, indent: 20, endIndent: 20, height: 1, thickness: 1),
                      if (subItem.showChildren) buildItemsList(item: subItem),
                    ]
                  )
                );
              }
              case EProduct _ : {
                return Padding(
                  key: Key(subItem.id),
                  padding: EdgeInsets.only(left: subItem.rank*20),
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
                      const Divider(color: Colors.grey, indent: 30, endIndent: 30, height: 1, thickness: 1,)
                    ]
                  )
                );
              }
            }
          }, 
          onReorder: (int oldIndex, int newIndex) {
            if (newIndex > item.editorItems.length) newIndex = item.editorItems.length;
            if (oldIndex < newIndex) newIndex--;
            var dragEItem = item.editorItems.removeAt(oldIndex);
            var dragItem = item.category.catalogItems.removeAt(oldIndex);
            
            item.editorItems.insert(newIndex, dragEItem);
            item.category.catalogItems.insert(newIndex, dragItem);
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
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: "Product Name *"
                                    ),
                                    validator: (String? value) {
                                      return (value == null || value == '' || value == 'All') ? "Name required (and cannot be 'All')." : null;
                                    }
                                  ),
                                  TextFormField(
                                    controller: _modelNumberController,
                                    decoration: const InputDecoration(
                                      labelText: "Product Model Number"
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownMenu<ECategory>(
                                    label: const Text("Category *"),
                                    controller: _dropdownController,
                                    initialSelection: _focusItem?.getParent(root: _editorAll) ?? _editorAll,
                                    dropdownMenuEntries: _editorAll.getSubCategories().map<DropdownMenuEntry<ECategory>>((ECategory category){
                                      return DropdownMenuEntry<ECategory>(
                                        value: category,
                                        label: category.category.name,
                                      );
                                    }).toList(),
                                    onSelected: (newValue) {
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
                                      child: SizedBox(
                                        height: (_mediaPaths.isNotEmpty) ? 100 : 250,
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
                                            height: (_mediaPaths.isNotEmpty) ? 100 : 250,
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                            alignment: Alignment.center,
                                            child: 
                                              _mediaPaths.isEmpty ?
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.image, size: 70),
                                                    const Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 10),
                                                    const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center, 
                                                      children: [
                                                        Expanded(child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 70, endIndent: 15)), 
                                                        Text("or"), 
                                                        Expanded(child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 15, endIndent: 70))
                                                      ]
                                                    ),
                                                    const SizedBox(height: 10),
                                                    OutlinedButton(
                                                      style: const ButtonStyle(
                                                        foregroundColor: MaterialStatePropertyAll<Color>(Colors.black)
                                                      ),                 
                                                      onPressed: () async {
                                                        FilePickerResult? _ = 
                                                          await FilePicker.platform.
                                                            pickFiles(allowMultiple: true, type: FileType.image, allowedExtensions: ['png', 'jpg'])
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
                                                            });
                                                      },
                                                      child: const Text("Browse Files")
                                                    ),
                                                    const SizedBox(height: 10),
                                                    const Text("File must be .jpg, .png, or .mp4", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic))
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
                                                      Expanded(child: VerticalDivider(color: Colors.black, width: 1, thickness: 1, indent: 10, endIndent: 1)), 
                                                      Text("or"), 
                                                      Expanded(child: VerticalDivider(color: Colors.black, width: 1, thickness: 1, indent: 1, endIndent: 10))
                                                    ]
                                                  ),
                                                  const SizedBox(width: 20),
                                                  OutlinedButton(
                                                    style: const ButtonStyle(
                                                      foregroundColor: MaterialStatePropertyAll<Color>(Colors.black)
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

                                          return Column(
                                            key: Key('image_$index'),
                                            children: [
                                              ReorderableDragStartListener(
                                                index: index,
                                                child: 
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(0x55C9C9CC),
                                                      borderRadius: BorderRadius.circular(15)
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
                                                                Expanded(child: Text(imageText, overflow: TextOverflow.ellipsis)),
                                                                // if (isFromCloud) const SizedBox(width: 1),
                                                                // if (isFromCloud) const Icon(Icons.cloud_outlined, color: Color(0xFFA9A9AA), size: 12.0)
                                                              ]
                                                            )
                                                          ),
                                                          const SizedBox(width: 10),
                                                          (isFromCloud) ?
                                                            StatefulBuilder(
                                                              builder: (context, setState) {
                                                                return Row(
                                                                  children: [
                                                                    IconButton(
                                                                      style: const ButtonStyle(
                                                                        minimumSize: MaterialStatePropertyAll<Size>(Size(25,25)),
                                                                        fixedSize: MaterialStatePropertyAll<Size>(Size(25,25))
                                                                      ),
                                                                      padding: EdgeInsets.zero,
                                                                      icon: isDownloading ? 
                                                                        LoadingAnimationWidget.bouncingBall(color: const Color(0xFFA9A9AA), size: 15) 
                                                                        : const Icon(Icons.cloud_download_outlined),
                                                                      color: const Color(0xFFA9A9AA),
                                                                      hoverColor: const Color(0xFFD9D9DD),
                                                                      iconSize: 18,
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
                                                                    ),
                                                                  ]
                                                                );
                                                              }
                                                            )
                                                          : IconButton(
                                                              style: const ButtonStyle(
                                                                minimumSize: MaterialStatePropertyAll<Size>(Size(25,25)),
                                                                fixedSize: MaterialStatePropertyAll<Size>(Size(25,25))
                                                              ),
                                                              padding: EdgeInsets.zero,
                                                              icon: const Icon(Icons.computer),
                                                              color: const Color(0xFFA9A9AA),
                                                              hoverColor: const Color(0xFFD9D9DD),
                                                              iconSize: 16,
                                                              onPressed: () async {
                                                                final dir = p.dirname(_mediaPaths[index]);
                                                                final uri = Uri.parse(dir);
                                                                launchUrl(uri);
                                                              }
                                                            ),
                                                          const SizedBox(width: 10),
                                                          if (!imageText.endsWith('.mp4'))
                                                            Row(
                                                              children: [
                                                                IconButton(
                                                                  style: const ButtonStyle(
                                                                    backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFA9A9AA)),
                                                                    minimumSize: MaterialStatePropertyAll<Size>(Size(25,25)),
                                                                    fixedSize: MaterialStatePropertyAll<Size>(Size(25,25))
                                                                  ),
                                                                  padding: EdgeInsets.zero,
                                                                  icon: const Icon(Icons.star),
                                                                  color: (index == _primaryImageIndex) ? Colors.yellow : Colors.white,
                                                                  hoverColor: const Color(0xFF808082),
                                                                  iconSize: 18,
                                                                  onPressed: () => setState(() => _primaryImageIndex = index)
                                                                ),
                                                                const SizedBox(width: 10),
                                                              ]
                                                            ),
                                                          IconButton(
                                                            style: const ButtonStyle(
                                                              backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFA9A9AA)),
                                                              minimumSize: MaterialStatePropertyAll<Size>(Size(25,25)),
                                                              fixedSize: MaterialStatePropertyAll<Size>(Size(25,25))
                                                            ),
                                                            padding: EdgeInsets.zero,
                                                            icon: const Icon(Icons.remove_red_eye),
                                                            color: Colors.white,
                                                            hoverColor: const Color(0xFF224190),
                                                            iconSize: 18,
                                                            onPressed: () async {
                                                              await _previewMedia(context, image);
                                                            }
                                                          ),
                                                          const SizedBox(width: 10),
                                                          IconButton(
                                                            style: const ButtonStyle(
                                                              backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFA9A9AA)),
                                                              minimumSize: MaterialStatePropertyAll<Size>(Size(25,25)),
                                                              fixedSize: MaterialStatePropertyAll<Size>(Size(25,25))
                                                            ),
                                                            padding: EdgeInsets.zero,
                                                            icon: const Icon(Icons.close),
                                                            color: Colors.white,
                                                            hoverColor: const Color(0xFFC3291B),
                                                            iconSize: 18,
                                                            onPressed: () => setState(() {
                                                              _mediaPaths.removeAt(index);
                                                              _mediaFiles.removeAt(index);
                                                            })
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
                                          if (newIndex > _mediaPaths.length) newIndex = _mediaPaths.length;
                                          if (oldIndex < newIndex) newIndex--;

                                          String primaryImage = _mediaPaths[_primaryImageIndex];

                                          String pathToMove = _mediaPaths.removeAt(oldIndex);
                                          File fileToMove = _mediaFiles.removeAt(oldIndex);
                                          _mediaPaths.insert(newIndex, pathToMove);
                                          _mediaFiles.insert(newIndex, fileToMove);
                                          
                                          _primaryImageIndex = _mediaPaths.indexOf(primaryImage);

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
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Overview"
                      ),
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
                                                  hoverColor: const Color(0x55C3291B),
                                                  icon: const Icon(Icons.delete), 
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
                                        height: 30,
                                        alignment: Alignment.bottomCenter,
                                        child:
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: 
                                                  ElevatedButton(
                                                    style: const ButtonStyle(
                                                      backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFC9C9CC)),
                                                      foregroundColor: MaterialStatePropertyAll<Color>(Colors.black),
                                                      visualDensity: VisualDensity(horizontal: -4),
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
                                                    ElevatedButton(
                                                      style: const ButtonStyle(
                                                        backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFC9C9CC)),
                                                        foregroundColor: MaterialStatePropertyAll<Color>(Colors.black),
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
                                                    ElevatedButton(
                                                      style: const ButtonStyle(
                                                        backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFC9C9CC)),
                                                        foregroundColor: MaterialStatePropertyAll<Color>(Colors.black),
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
                TextButton(
                  child: const Text("Preview"),
                  onPressed: () {
                    _showPreviewDialog(context);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF224190)),
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                  ),
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
                        if (_mediaFiles[_primaryImageIndex].path.endsWith('.mp4')) {
                          final newPrimaryIndex = (_mediaFiles.map((x) => x.path).toList()).indexWhere((y) => !y.endsWith('.mp4'));
                          if (newPrimaryIndex != -1) {
                            _primaryImageIndex = newPrimaryIndex;
                          }
                        }
                        EProduct newEProduct = EProduct(product: newProduct, rank: _selectedCategory.rank+1, mediaPaths: List.from(_mediaPaths), primaryImageIndex: _primaryImageIndex);
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
                        product.mediaPaths = List.from(_mediaPaths);
                        product.mediaFiles = List.from(_mediaFiles);
                        if (_mediaFiles[_primaryImageIndex].path.endsWith('.mp4')) {
                          final newPrimaryIndex = (_mediaFiles.map((x) => x.path).toList()).indexWhere((y) => !y.endsWith('.mp4'));
                          if (newPrimaryIndex != -1) {
                            _primaryImageIndex = newPrimaryIndex;
                          }
                        }
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
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: "Category Name *"
                                    ),
                                    validator: (String? value) {
                                      return (value == null || value == '' || value == 'All') ? "Name required (and cannot be 'All')." : null;
                                    }
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownMenu<ECategory>(
                                    label: const Text("Parent Category *"),
                                    controller: _dropdownController,
                                    initialSelection: _focusItem?.getParent(root: _editorAll) ?? _editorAll,
                                    dropdownMenuEntries: (_editorAll.getSubCategories(categoriesToExclude : (category != null) ? [category] : null)).map<DropdownMenuEntry<ECategory>>((ECategory categoryOption){
                                      return DropdownMenuEntry<ECategory>(
                                        value: categoryOption,
                                        label: categoryOption.category.name,
                                      );
                                    }).toList(),
                                    onSelected: (newValue) {
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
                                          if (_mediaPaths.contains(file.path)) {
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
                                          _mediaPaths = [];
                                          _mediaFiles = [];
                                          _mediaPaths.add(paths[0]);
                                          _mediaFiles.add(File(paths[0]));
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
                                              _mediaPaths.isEmpty ?
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.image, size: 70),
                                                    const Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 10),
                                                    const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center, 
                                                      children: [
                                                        Expanded(child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 70, endIndent: 15)), 
                                                        Text("or"), 
                                                        Expanded(child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 15, endIndent: 70))
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
                                              : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(height: 10),
                                                  Flexible(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Stack(
                                                        children: [
                                                          Image.file(_mediaFiles[0], height: 300),
                                                          StatefulBuilder(
                                                            builder: (context, setState) {
                                                              return Positioned.fill(
                                                                child: Material(
                                                                    color: Colors.transparent,
                                                                    child: InkWell(
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
                                                                      child: hoverOnImageRemove ? const Icon(Icons.clear, size:40, color: Color(0xFFC9C9CC)) : const SizedBox()
                                                                    )
                                                                  )
                                                              );
                                                            }
                                                          )
                                                        ]
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
                                                            Expanded(child: VerticalDivider(color: Colors.black, width: 1, thickness: 1, indent: 10, endIndent: 1)), 
                                                            Text("or"), 
                                                            Expanded(child: VerticalDivider(color: Colors.black, width: 1, thickness: 1, indent: 1, endIndent: 10))
                                                          ]
                                                        ),
                                                        const SizedBox(width: 20),
                                                        OutlinedButton(
                                                          style: const ButtonStyle(
                                                            foregroundColor: MaterialStatePropertyAll<Color>(Colors.black)
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
                ElevatedButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF224190)),
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                  ),
                  child: _addingItem ? const Text("Add") : const Text("Save"),
                  onPressed: () {
                    if (_addingItem) {
                      ProductCategory newCategory = ProductCategory(
                        name: _nameController.text,
                        parentId: _selectedCategory.id,
                      );
                      ECategory newECategory = ECategory(category: newCategory, rank: _selectedCategory.rank+1, editorItems: [], imagePath: _mediaPaths.isNotEmpty ? _mediaPaths[0] : null);
                      _selectedCategory.addItem(newECategory);
                    }
                    else if (category != null) {
                      if (category.parentId != _selectedCategory.id) {
                        category.reassignParent(newParent: _selectedCategory);
                      }
                      category.category.name = _nameController.text;
                      category.imagePath = _mediaPaths.isNotEmpty ? _mediaPaths[0] : null;
                      category.imageFile = _mediaFiles.isNotEmpty ? _mediaFiles[0] : null;
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


  Future<void> _previewMedia(BuildContext context, File mediaFile) async {
    if (p.extension(mediaFile.path) == '.mp4') {
      late final player = Player();
      late final controller = VideoController(player);
      player.open(Media(mediaFile.path));
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text(""),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Video(
                controller: controller,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Close"),
                onPressed: () {
                  player.dispose();
                  Navigator.of(context).pop();
                }
              )
            ]
          );
        }
      );
    }
    else {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text(""),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(mediaFile, width: 600),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Close"),
                onPressed: () => Navigator.of(context).pop()
              )
            ]
          );
        }
      );
    }
  }

  Future<void> _showSaveLoading(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
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

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
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
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(30.0),
                                                  child: Image.file(_mediaFiles[itemIndex])
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
                                                        color: (Theme.of(context).brightness == Brightness.dark
                                                                ? const Color(0xFFC9C9CC)
                                                                : const Color(0xFF224190))
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
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              actions: <Widget>[
                TextButton(
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }
                )
              ],
              actionsPadding: const EdgeInsets.fromLTRB(20, 2, 20, 20)
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
            return AlertDialog(
              title: const Text("Warning!"),
              content: const Text("Are you sure you want to exit? Your progress will not be saved."),
              actions: <Widget>[
                TextButton(
                  child: const Text("Return"),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  }
                ),
                TextButton(
                  style: hoverOnYes ? 
                    const ButtonStyle(
                      foregroundColor: MaterialStatePropertyAll<Color>(Colors.white), 
                      backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFC3291B))
                    ) :
                    const ButtonStyle(),
                  onHover: (hovering) {
                    setState(() => hoverOnYes = hovering);
                  },
                  child: Text("Exit", style: hoverOnYes ? const TextStyle(color: Colors.white) : const TextStyle(color: Color(0xFFC32918))),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  }
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
                return AlertDialog(
                  title: const Text("Warning!"),
                  content: Text("You are about to delete ${data.category.name} and all of its contents (including sub-products). \nThis action cannot be undone. Are you sure?"),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    ),
                    TextButton(
                      style: hoverOnYes ? 
                        const ButtonStyle(
                          foregroundColor: MaterialStatePropertyAll<Color>(Colors.white), 
                          backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFC3291B))) : 
                        const ButtonStyle(),
                      onHover: (hovering) {
                        setState(() => hoverOnYes = hovering);
                      },
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
      case EProduct _ : {
        confirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text("Warning!"),
                  content: Text("You are about to delete ${data.product.name} and all of its contents. \nThis action cannot be undone. Are you sure?"),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }
                    ),
                    TextButton(
                      style: hoverOnYes ? 
                        const ButtonStyle(
                          foregroundColor: MaterialStatePropertyAll<Color>(Colors.white), 
                          backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFFC3291B))) : 
                        const ButtonStyle(),
                      onHover: (hovering) {
                        setState(() => hoverOnYes = hovering);
                      },
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
        List<String> newImagePaths = await focusItem.getImagePaths();
        List<File> newImageFiles = await focusItem.getImageFiles(paths: newImagePaths);
        _mediaPaths.clear();
        _mediaFiles.clear();
        setState(() {
          _focusItem = focusItem;
          _mediaPaths = List.from(newImagePaths);
          _mediaFiles = List.from(newImageFiles);
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
        String newImagePath = await focusItem.getImagePaths();
        File newImageFile = await focusItem.getImageFiles(path: newImagePath);
        _mediaPaths.clear();
        _mediaFiles.clear();
        setState(() {
          _focusItem = focusItem;
          _mediaPaths.add(newImagePath);
          _mediaFiles.add(newImageFile);
          _nameController.text = focusItem.category.name;
          _selectedCategory = focusItem.getParent(root: _editorAll) ?? _editorAll;
        });
        setState(() => _loadingSomething = false);
      }
      case null : {
        _mediaPaths.clear();
        _mediaFiles.clear();
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
