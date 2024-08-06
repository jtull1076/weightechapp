import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/universal_routes.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
    return ScaffoldPage(
      content: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Image.asset('assets/icon/wt_icon.ico', height: 200),
            ),
            const SizedBox(height: 10), 
            Text(AppInfo.packageInfo.version),
            const SizedBox(height: 10),
            const ProgressBar(),
            const SizedBox(height: 5),
            Text(_startupTaskMessage),
            StreamBuilder(
              stream: _progressStreamController.stream,
              initialData: '',
              builder:(context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const SizedBox(); // Or any loading indicator
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

  int _selectedIndex = 0;

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

    // toggleEditorItem(_focusItem);

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
      content: NavigationView(
        pane: NavigationPane(
          selected: _selectedIndex,
          onChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          displayMode: PaneDisplayMode.top,
          items: [
            PaneItem(
              title: const Text('Home', style: TextStyle(fontWeight: FontWeight.w600)),
              icon: const Icon(FluentIcons.home_20_regular),
              body: Container(
                alignment: Alignment.topCenter,
                height: 50,
                child: CommandBarCard(
                  child: CommandBar(
                    primaryItems: _commandBars[_selectedIndex],
                  ),
                )
              )
            ),
            PaneItem(
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
              icon: const Icon(FluentIcons.settings_20_regular),
              body: Container(
                alignment: Alignment.topCenter,
                height: 50,
                child: CommandBarCard(
                  child: CommandBar(
                    primaryItems: _commandBars[_selectedIndex],
                  ),
                )
              )
            ),
          ],
        ),
      ),
      //content: const SizedBox(height: 0),
    );
  }


  final List<List<CommandBarItem>> _commandBars = [
    // First category of commands
    [
      CommandBarButton(
        icon: const Icon(FluentIcons.add_20_regular),
        label: const Text('Add'),
        onPressed: () {},
      ),
      CommandBarButton(
        icon: const Icon(FluentIcons.delete_20_regular),
        label: const Text('Delete'),
        onPressed: () {},
      ),
    ],
    // Second category of commands
    [
      CommandBarButton(
        icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
        label: const Text('Refresh'),
        onPressed: () {},
      ),
      CommandBarButton(
        icon: const Icon(FluentIcons.save_20_regular),
        label: const Text('Save'),
        onPressed: () {},
      ),
    ],
  ];
}