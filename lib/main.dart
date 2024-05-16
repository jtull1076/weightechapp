import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:updat/updat.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/themes.dart';
import 'package:weightechapp/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weightechapp/extra_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:feedback_github/feedback_github.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shortid/shortid.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';


//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(850, 550));
  }

  await AppInfo().init();
  await Log().init();
  Log.logger.i('Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}, SessionId: ${AppInfo.sessionId}');

  runApp(
    BetterFeedback(
      feedbackBuilder: (context, onSubmit, scrollController) {
        return CustomFeedbackForm(
          onSubmit: onSubmit,
          scrollController: scrollController,
        );
      },
      localeOverride: const Locale('en'),
      theme: FeedbackThemeData(
        background: Colors.grey,
        feedbackSheetColor: Colors.white,
        sheetIsDraggable: false,
        bottomSheetDescriptionStyle: const TextStyle(color: Colors.black),
        bottomSheetTextInputStyle: const TextStyle(color: Colors.black),
        activeFeedbackModeColor: const Color(0xFF224190),
        colorScheme: WeightechThemes.lightTheme.colorScheme,
      ),
      child: 
        WeightechApp()
    )
  );
}

/// A class that defines the widget tree.
class WeightechApp extends StatelessWidget {
  WeightechApp() : super(key: GlobalKey());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Weightech Inc. Sales",
      theme: WeightechThemes.lightTheme, 
      home: const StartupPage()
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
                            if (status == UpdatStatus.checking) {
                              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                setState(() => _checkingForUpdate = true);
                              });
                            }
                            if (status == UpdatStatus.available || status == UpdatStatus.availableWithChangelog) {
                              setState(() => _checkingForUpdate = false);
                            }
                            if (status == UpdatStatus.upToDate) {
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

//MARK: IDLE PAGE
/// A class defining the stateless [IdlePage]. Used as the landing page (though not called "LandingPage" because "IdlePage" seemed more apt). 
class IdlePage extends StatelessWidget {
  const IdlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(_routeToHome());
        },
        onLongPress: () {
          Navigator.of(context).push(_routeToControl());
        },
        child: Center(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo_beta.png', fit: BoxFit.scaleDown))
                    ), 
                    const Text('MANAGER', style: TextStyle(fontSize: 30, color: Color(0xFF224190))),
                    const Text('Press anywhere to begin.', style: TextStyle(fontSize: 18.0, fontStyle: FontStyle.normal))],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text('${AppInfo.packageInfo.version} ${AppInfo.sessionId}')
              )
            ]
          )
        )
      )
    );
  }

  Route _routeToHome() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child){
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.fastLinearToSlowEaseIn;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return FadeTransition(opacity: animation.drive(tween), child: child);
        
      },
      transitionDuration: const Duration(seconds: 2)
    );
  }

  Route _routeToControl() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const ControlPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child){
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.fastLinearToSlowEaseIn;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return FadeTransition(opacity: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(seconds: 2)
    );
  }
}

//MARK: HOME PAGE

/// A class defining the stateful HomePage, i.e. the 'All' category listing page. 
/// 
/// Defined separately as stateful to handle all animations from [IdlePage]. 
/// 
/// See also: [_HomePageState]
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dividerWidthAnimation;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(duration : const Duration(seconds: 5), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.7, curve: Curves.ease)));
    _dividerWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.ease)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //Future.delayed(const Duration(seconds: 5), () =>
      _controller.forward();
      //);
    });

    _timer = Timer(const Duration(minutes: 10), () {
      if (mounted){
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => IdlePage()));
        Log.logger.t("--Idle Timeout--");
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void catalogNavigation(BuildContext context, dynamic item){
    if (item is ProductCategory) {
      Log.logger.t('...Rerouting to ${item.name} listing...');
      _timer.cancel();
      Navigator.push(context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ListingPage(category: item, animateDivider: true,),
          transitionsBuilder: (context, animation, secondaryAnimation, child){
            var begin = 0.0;
            var end = 1.0;
            var curve = Curves.fastLinearToSlowEaseIn;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return FadeTransition(opacity: animation.drive(tween),child: child);
          },
          transitionDuration: const Duration(seconds: 2)
        )
      );
    }
    else if (item is Product) {
      Log.logger.t('...Rerouting to ${item.name} product page...');
      _timer.cancel();
      Navigator.push(context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProductPage(product: item, animateDivider: true,),
          transitionsBuilder: (context, animation, secondaryAnimation, child){
            var begin = 0.0;
            var end = 1.0;
            var curve = Curves.fastLinearToSlowEaseIn;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return FadeTransition(opacity: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(seconds: 2)
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Stack(
          children: <Widget>[
            Flex(
              direction: Axis.vertical,
              children: <Widget>[
                Flexible(
                  child: 
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: 
                        GridView.builder(
                          padding: const EdgeInsets.only(top: 110, bottom: 20, left: 20, right: 20),
                          itemCount: ProductManager.all!.catalogItems.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 4 : MediaQuery.of(context).size.width > 800 ? 3 : MediaQuery.of(context).size.width > 500 ? 2 : 1,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                          ),
                          itemBuilder: (context, index) => ProductManager.all!.catalogItems[index].buildCard(() => catalogNavigation(context, ProductManager.all!.getAllCatalogItems()[index])),
                        )
                    ),
                )],//)
            ),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: 
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
                        child: 
                              ShaderMask(
                                shaderCallback: (Rect rect) {
                                  return const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [Colors.white, Colors.transparent, Colors.transparent, Colors.white],
                                    stops: [0.0, 0.38, 0.62, 1.0],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstOut,
                                child:
                                  Container(color: Colors.white.withOpacity(1.0))
                              )
                      )
                    )
                ),
                Column(
                  children: [
                    GestureDetector(
                      onDoubleTap: (){
                        Log.logger.t('---Return to Idle Interaction---');
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IdlePage()));
                      },
                      child: Padding(padding: const EdgeInsets.only(top: 10.0), child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo_beta.png', height: 100, alignment: Alignment.center,))),
                    ),
                    SizeTransition(sizeFactor: _dividerWidthAnimation, axis: Axis.horizontal, child: FadeTransition(opacity: _fadeAnimation, child: const Hero(tag: 'divider', child: Divider(color: Color(0xFF224190), height: 2, thickness: 2, indent: 25.0, endIndent: 25.0,)))),
                    const SizedBox(height: 10),
                  ]
                )
              ]
            ),
            
          ]
        )
      )
    );
  }
}


//MARK: PRODUCT PAGE

/// A class defining the stateful [ProductPage]. All products use this page as their primary outlet for displaying information. 
/// 
/// Stateful for handling [ListingPage] -> [ProductPage] animation
/// 
/// See also: [_ProductPageState]
class ProductPage extends StatefulWidget {
  ProductPage({super.key, required this.product, this.animateDivider = true});

  final Product product;
  final bool animateDivider;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _dividerHeightAnimation;
  late Animation<double> _fadeAnimation;
  late Timer _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(duration : const Duration(seconds: 2), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Interval(widget.animateDivider ? 0.3 : 0.1, widget.animateDivider ? 0.6 : 0.4, curve: Curves.ease)));
    _dividerHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.ease)));
    
    _timer = Timer(const Duration(minutes: 10), () {
      if (mounted){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IdlePage()));
        Log.logger.t("--Idle Timeout--");
      }
    });


    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () =>
      _animationController.forward());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 110,
            child: 
              Stack(
                children: [
                  Center(
                    child: 
                      GestureDetector(
                        onDoubleTap: (){
                          Log.logger.t('---Return to Idle Interaction---');
                          _timer.cancel();
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IdlePage()));
                        },
                        child: Padding(padding: const EdgeInsets.only(top: 10.0), child: Image.asset('assets/weightech_logo_beta.png', height: 100, cacheHeight: 150, cacheWidth: 394, alignment: Alignment.center,)),
                      ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: 
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: 
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            iconSize: 30,
                            color: const Color(0xFF224190),
                            onPressed: () => Navigator.pop(context),
                          )
                      )
                  ),
                ]
              ),
          ),
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                child: Container(
                  color: const Color(0xFF224190),
                  height: 2.0
                )
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                child: 
                  widget.animateDivider ?
                    SizeTransition(
                      sizeFactor: _dividerHeightAnimation, 
                      axis: Axis.vertical, 
                      child: Container(
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                          color: const Color(0xFF224190),
                          border: Border.all(color: const Color(0xFF224190))
                        ),
                        width: double.infinity,
                        child: 
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child:
                              Text(widget.product.name, 
                                textAlign: TextAlign.center, 
                                style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
                              )
                          )
                      )
                    )
                  : Container(
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        color: const Color(0xFF224190),
                        border: Border.all(color: const Color(0xFF224190))
                      ),
                      width: double.infinity,
                      child: 
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child:
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: 
                                Text(widget.product.name, 
                                  textAlign: TextAlign.center, 
                                  style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                            )
                        )
                      )
              ),
            ]
          ),
          Expanded(
            child:
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                scrollDirection: Axis.vertical,
                child: MediaQuery.of(context).size.width > 600 ? 
                  pageForLandscape()
                  : pageForPortrait()
              ),
          ),
        ]
      )
    );
  }

  Widget pageForPortrait() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView(
          padding: const EdgeInsets.only(left: 40, right: 40, top: 30),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            widget.product.description?.isNotEmpty ?? false ?
              FadeTransition(
                opacity: _fadeAnimation,
                child:
                  Align(
                    alignment: Alignment.center,
                    child: SimpleRichText(widget.product.description!, textAlign: TextAlign.justify, style: GoogleFonts.openSans(color: Colors.black, fontSize: 18.0)) 
                  )
              )
            : const SizedBox(height: 50),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _fadeAnimation,
              child:
                Column(
                  children: [
                    CarouselSlider.builder(
                      options: CarouselOptions(
                        enableInfiniteScroll: widget.product.productImageProviders.length > 1 ? true : false, 
                        enlargeCenterPage: true,
                        enlargeFactor: 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index;
                          });
                        },
                      ),
                      itemCount: widget.product.productImageProviders.length,
                      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(30.0),
                          child: Image(image: widget.product.productImageProviders[itemIndex], fit: BoxFit.fitWidth, width: double.infinity)
                        );
                      }
                    ),
                    const SizedBox(height: 10),
                    if (widget.product.productImageProviders.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.product.productImageProviders.asMap().entries.map((entry) {
                          return Container(
                              width: 10.0,
                              height: 10.0,
                              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFFC9C9CC)
                                          : const Color(0xFF224190))
                                      .withOpacity(_current == entry.key ? 1 : 0.3)),
                            );
                        }).toList(),
                      ),
                  ]
                ),
            )
          ]
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: 
            Padding(
              padding: const EdgeInsets.only(left: 60, right: 60, top: 5),
              child: 
                ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 20),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.product.brochure!.length,
                  itemBuilder: (context, index) {
                    final headerKey = widget.product.brochure![index].keys.first;
                    final headerValue = widget.product.brochure![index][headerKey] as List;
                    final headerEntries = headerValue.singleWhere((element) => (element as Map).keys.first == "Entries", orElse: () => <String, List<String>>{})["Entries"];
                    final subheaders = List.from(headerValue);
                    subheaders.removeWhere((element) => element.keys.first == "Entries");

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headerKey, style: const TextStyle(color: Color(0xFF224190), fontSize: 28.0, fontWeight: FontWeight.bold), softWrap: true,),
                        if (headerEntries?.isNotEmpty ?? false)
                          ListView.builder(
                            padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: headerEntries.length,
                            itemBuilder: (context, entryIndex) {
                              final entry = headerEntries[entryIndex];
                              return Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child:
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start, 
                                    children: [
                                      const Text("\u2022"),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(entry, style: const TextStyle(fontSize: 16.0), softWrap: true,))
                                    ]
                                  )
                              );
                            }
                          ),
                        const SizedBox(height: 10),
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
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Text(subheaderKey, style: const TextStyle(color: Color(0xFF333333), fontSize: 22.0, fontWeight: FontWeight.w800), softWrap: true,),
                                ),
                                ListView.builder(
                                  padding: const EdgeInsets.only(left: 5.0, top: 5.0),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: subheaderValue.length,
                                  itemBuilder: (context, entryIndex) {
                                    final entry = subheaderValue[entryIndex];
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start, 
                                      children: [
                                        const Text("\u2022"),
                                        const SizedBox(width: 5),
                                        Expanded(child: Text(entry, style: const TextStyle(fontSize: 16.0), softWrap: true,))
                                      ]
                                    );
                                  }
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                        )
                      ]
                    );
                  }
                )
            )
        )
      ],
    );
  }

  Widget pageForLandscape() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child:
            ListView(
              padding: const EdgeInsets.only(left: 60, right: 20, top: 30),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                widget.product.description?.isNotEmpty ?? false ?
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child:
                      Align(
                        alignment: Alignment.center,
                        child: SimpleRichText(widget.product.description!, textAlign: TextAlign.justify, style: GoogleFonts.openSans(color: Colors.black, fontSize: 18.0)) 
                      )
                  )
                : const SizedBox(height: 50),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child:
                    Column(
                      children: [
                        CarouselSlider.builder(
                          options: CarouselOptions(
                            enableInfiniteScroll: widget.product.productImageProviders.length > 1 ? true : false, 
                            enlargeCenterPage: true,
                            enlargeFactor: 1,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            },
                          ),
                          itemCount: widget.product.productImageProviders.length,
                          itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(30.0),
                              child: Image(image: widget.product.productImageProviders[itemIndex],),
                            );
                          }
                        ),
                        const SizedBox(height: 10),
                        if (widget.product.productImageProviders.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: widget.product.productImageProviders.asMap().entries.map((entry) {
                              return Container(
                                  width: 10.0,
                                  height: 10.0,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFFC9C9CC)
                                              : const Color(0xFF224190))
                                          .withOpacity(_current == entry.key ? 1 : 0.3)),
                                );
                            }).toList(),
                          ),
                      ]
                    ),
                )
              ]
            ),
        ),
        Flexible(
          child:    
            FadeTransition(
              opacity: _fadeAnimation,
              child: 
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 60, top: 5),
                  child: 
                    ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 20),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.product.brochure!.length,
                      itemBuilder: (context, index) {
                        final headerKey = widget.product.brochure![index].keys.first;
                        final headerValue = widget.product.brochure![index][headerKey] as List;
                        final headerEntries = headerValue.singleWhere((element) => (element as Map).keys.first == "Entries", orElse: () => <String, List<String>>{})["Entries"];
                        final subheaders = List.from(headerValue);
                        subheaders.removeWhere((element) => element.keys.first == "Entries");

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(headerKey, style: const TextStyle(color: Color(0xFF224190), fontSize: 28.0, fontWeight: FontWeight.bold), softWrap: true,),
                            if (headerEntries?.isNotEmpty ?? false)
                              ListView.builder(
                                padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: headerEntries.length,
                                itemBuilder: (context, entryIndex) {
                                  final entry = headerEntries[entryIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child:
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start, 
                                        children: [
                                          const Text("\u2022"),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(entry, style: const TextStyle(fontSize: 16.0), softWrap: true,))
                                        ]
                                      )
                                  );
                                }
                              ),
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: subheaders.length,
                              itemBuilder: (context, subIndex) {
                                final subheaderKey = subheaders[subIndex].keys.first;
                                final subheaderValue = subheaders[subIndex][subheaderKey] as List;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5.0),
                                      child: Text(subheaderKey, style: const TextStyle(color: Color(0xFF333333), fontSize: 22.0, fontWeight: FontWeight.w800), softWrap: true,),
                                    ),
                                    ListView.builder(
                                      padding: const EdgeInsets.only(left: 5.0, top: 5.0),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: subheaderValue.length,
                                      itemBuilder: (context, entryIndex) {
                                        final entry = subheaderValue[entryIndex];
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start, 
                                          children: [
                                            const Text("\u2022"),
                                            const SizedBox(width: 5),
                                            Expanded(child: Text(entry, style: const TextStyle(fontSize: 16.0), softWrap: true,))
                                          ]
                                        );
                                      }
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ]
                        );
                      }
                    )
                )
            )
        )
      ],
    );
  }
}


// MARK: LISTING PAGE

/// A class defining the stateless [ListingPage]. These are used to navigate the catalog tree. 
class ListingPage extends StatefulWidget {
  ListingPage({super.key, required this.category, this.animateDivider = false}) : catalogItems = category.catalogItems;

  final ProductCategory category;
  final List<CatalogItem> catalogItems;
  bool animateDivider;

  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dividerHeightAnimation;
  
  late final Timer _timer;

  void catalogNavigation(BuildContext context, dynamic item){
    if (item is ProductCategory) {
      Log.logger.t('...Rerouting to ${item.name} listing...');
      _timer.cancel();
      Navigator.push(context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ListingPage(category: item, animateDivider: false),
          transitionsBuilder: (context, animation, secondaryAnimation, child){
            var begin = 0.0;
            var end = 1.0;
            var curve = Curves.fastLinearToSlowEaseIn;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return FadeTransition(opacity: animation.drive(tween),child: child);
          },
          transitionDuration: const Duration(seconds: 2)
        )
      );
    }
    else if (item is Product) {
      Log.logger.t('Rerouting to ${item.name} product page.');
      _timer.cancel();
      Navigator.push(context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProductPage(product: item, animateDivider: false,),
          transitionsBuilder: (context, animation, secondaryAnimation, child){
            var begin = 0.0;
            var end = 1.0;
            var curve = Curves.fastLinearToSlowEaseIn;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return FadeTransition(opacity: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(seconds: 1)
        )
      );
    }
  }

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(duration : const Duration(seconds: 2), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.5, curve: Curves.ease)));
    _dividerHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.ease)));

    _timer = Timer(const Duration(minutes: 10), () {
      if (mounted){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IdlePage()));
        Log.logger.t("--Idle Timeout--");
      }
    });


    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () =>
      _animationController.forward());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Stack(
          children: <Widget>[
            Flex(
              direction: Axis.vertical,
              children: <Widget>[
                Flexible(
                  child: 
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: 
                        GridView.builder(
                          padding: const EdgeInsets.only(top: 165, bottom: 20, left: 20, right: 20),
                          itemCount: widget.catalogItems.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width<600 ? 1 : 4,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                          ),
                          itemBuilder: (context, index) => widget.catalogItems[index].buildCard(() => catalogNavigation(context, widget.catalogItems[index])),)
                    )
                )
              ],
            ),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: 
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
                        child: 
                              ShaderMask(
                                shaderCallback: (Rect rect) {
                                  return const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [Colors.white, Colors.transparent, Colors.transparent, Colors.white],
                                    stops: [0.0, 0.38, 0.62, 1.0],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstOut,
                                child:
                                  Container(color: Colors.white.withOpacity(1.0))
                              )
                      )
                    )
                ),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 110,
                      child: 
                        Stack(
                          children: [
                            Center(
                              child: 
                                GestureDetector(
                                  onDoubleTap: (){
                                    Log.logger.t('---Return to Idle Interaction---');
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IdlePage()));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10.0), 
                                    child: Image.asset('assets/weightech_logo_beta.png', height: 100, cacheHeight: 150, cacheWidth: 394, alignment: Alignment.center,)
                                  )
                                ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: 
                                Padding(
                                  padding: const EdgeInsets.only(left: 30),
                                  child: 
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      iconSize: 30,
                                      color: const Color(0xFF224190),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      }
                                    )
                                )
                            ),
                          ]
                        ),
                    ),
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                          child: Container(
                            color: const Color(0xFF224190),
                            height: 2.0
                          )
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                          child: 
                            widget.animateDivider ?
                              SizeTransition(
                                sizeFactor: _dividerHeightAnimation, 
                                axis: Axis.vertical, 
                                child: Container(
                                  alignment: Alignment.topCenter,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF224190),
                                    border: Border.all(color: const Color(0xFF224190))
                                  ),
                                  width: double.infinity,
                                  child: 
                                    Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child:
                                        Text(widget.category.name, 
                                          textAlign: TextAlign.center, 
                                          style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
                                        )
                                    )
                                )
                              )
                            : Container(
                                alignment: Alignment.topCenter,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF224190),
                                  border: Border.all(color: const Color(0xFF224190))
                                ),
                                width: double.infinity,
                                child: 
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child:
                                      FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: 
                                          Text(widget.category.name, 
                                            textAlign: TextAlign.center, 
                                            style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
                                          )
                                      )
                                  )
                                )
                        ),
                      ]
                    ),                      
                  ]
                )
              ]
            ),
            
          ]
        )
      )
    );
  }
}


enum ItemSelect {product, category}

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
                                                                final dir = p.dirname(_imagePaths[index]);
                                                                final uri = Uri.parse(dir);
                                                                launchUrl(uri);
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
                                                            icon: const Icon(Icons.star),
                                                            color: (index == _primaryImageIndex) ? Colors.yellow : Colors.white,
                                                            hoverColor: const Color(0xFF808082),
                                                            iconSize: 18,
                                                            onPressed: () => setState(() => _primaryImageIndex = index)
                                                          ),
                                                          const SizedBox(width: 10),
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
                                                              await _previewImage(context, image);
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
                                                              _imagePaths.removeAt(index);
                                                              _imageFiles.removeAt(index);
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
                    backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFF224190)),
                    foregroundColor: MaterialStatePropertyAll<Color>(Colors.white)
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
                                                      child: Stack(
                                                        children: [
                                                          Image.file(_imageFiles[0], height: 300),
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
                                                                        _imageFiles.clear();
                                                                        _imagePaths.clear();
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
                ElevatedButton(
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(Color(0xFF224190)),
                    foregroundColor: MaterialStatePropertyAll<Color>(Colors.white)
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
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(""),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(imageFile, width: 600),
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
