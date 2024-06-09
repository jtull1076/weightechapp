import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:updat/updat.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/themes.dart';
import 'package:weightechapp/utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:file_saver/file_saver.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';


//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  MediaKit.ensureInitialized();


  await AppInfo().init();
  await Log().init();
  Log.logger.i('Version: ${AppInfo.packageInfo.version}, Build: ${AppInfo.packageInfo.buildNumber}, SessionId: ${AppInfo.sessionId}');

  runApp(
    WeightechApp()
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
    try {
  
      await ProductManager.create();
    } catch (e, stackTrace) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => ErrorPage(message: e.toString())));
      });
    }

    Log.logger.t('...Precaching images...');
    _progressStreamController.add('...Caching images...');
    if (mounted) await ProductManager.precacheImages(context);
    } catch (e) {
      Log.logger.e("Error encountered retrieving catalog.", error: e);
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => ErrorPage(message: e.toString())));
      }
    }

    Log.logger.t('...App Startup...');
    _progressStreamController.add('...App Startup...');

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _progressStreamController.close();
      Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const IdlePage()));
    });
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
                // else if (snapshot.connectionState == ConnectionState.done) {
                //   return Stack(
                //     children: [
                //       const Center(child: Text("...Checking for updates...")),
                //       Center(
                //         child: UpdatWidget(
                //           currentVersion: AppInfo.packageInfo.version,
                //           getLatestVersion: () async {
                //             // Use Github latest endpoint
                //             try {
                //               final data = await http.get(
                //                 Uri.parse(
                //                 "https://api.github.com/repos/jtull1076/weightechapp/releases/latest"
                //                 ),
                //                 headers: {
                //                   'Authorization': 'Bearer ${FirebaseUtils.githubToken}'
                //                 }
                //               );
                //               final latestVersion = jsonDecode(data.body)["tag_name"];
                //               final verCompare = AppInfo.versionCompare(latestVersion, AppInfo.packageInfo.version);
                //               Log.logger.i('Latest version: $latestVersion : This app version is ${(verCompare == 0) ? "up-to-date." : (verCompare == 1) ? "deprecated." : "in development."}');
                //               return latestVersion;
                //             }
                //             catch (e, stackTrace) {
                //               Log.logger.w("Could not retrieve latest app version.", error: e, stackTrace: stackTrace);
                //               return null;
                //             }
                //           },
                //           getBinaryUrl: (version) async {
                //             return "https://github.com/jtull1076/weightechapp/releases/download/$version/weightechsales-android-$version.apk";
                //           },
                //           appName: "WeighTech Inc. Sales",
                //           getChangelog: (_, __) async {
                //             final data = await http.get(
                //               Uri.parse(
                //               "https://api.github.com/repos/jtull1076/weightechapp/releases/latest"
                //               ),
                //               headers: {
                //                 'Authorization': 'Bearer ${FirebaseUtils.githubToken}'
                //               }
                //             );
                //             Log.logger.t('Changelog: ${jsonDecode(data.body)["body"]}');
                //             return jsonDecode(data.body)["body"];
                //           },
                //           callback: (status) {
                //             if (status == UpdatStatus.upToDate) {
                //               WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                //                 Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const IdlePage()));
                //               });
                //             }
                //             if (status == UpdatStatus.error) {
                //               Log.logger.w("Error encountered retrieving update.");
                //               WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                //                 Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const IdlePage()));
                //               });
                //             }
                //             // else if (status == UpdatStatus.readyToInstall) {
                //             //   setState(() => _updateReady = true);
                //             // }
                //           }
                //         )
                //       ),
                //     ]
                //   );
                // }
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
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const IdlePage()));
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
          pageBuilder: (context, animation, secondaryAnimation) => ListingPage(category: item, animateDivider: true),
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
          pageBuilder: (context, animation, secondaryAnimation) => ProductPage(product: item, animateDivider: true),
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
                            mainAxisSpacing: 0.7,
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
  ProductPage({super.key, required this.product, this.animateDivider = false});

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
                        enableInfiniteScroll: widget.product.productMediaUrls!.length > 1 ? true : false, 
                        enlargeCenterPage: true,
                        enlargeFactor: 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index;
                          });
                        },
                      ),
                      itemCount: widget.product.productMediaUrls!.length,
                      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(30.0),
                          child: FutureBuilder(
                            future: DefaultCacheManager().getSingleFile(widget.product.productMediaUrls![itemIndex]),
                            builder: ((context, snapshot) {
                              if (snapshot.hasData) {
                                if (p.extension(snapshot.data!.path) == '.mp4') {
                                  late final player = Player();
                                  late final controller = VideoController(player);
                                  player.open(Media(snapshot.data!.path));
                                  return Video(
                                    controller: controller, 
                                    fit: BoxFit.fitWidth, 
                                    width: double.infinity
                                  );
                                }
                                else {
                                  return Image.file(snapshot.data!, fit: BoxFit.fitWidth, width: double.infinity);
                                }
                              }
                              else {
                                return LoadingAnimationWidget.newtonCradle(color: const Color(0xFF224190), size: 50);
                              }
                            })
                          )
                        );
                      }
                    ),
                    const SizedBox(height: 10),
                    if (widget.product.productMediaUrls!.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.product.productMediaUrls!.asMap().entries.map((entry) {
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
                            final subheaderValue = subheaders[subIndex][subheaderKey] as List<dynamic>;

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
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SimpleRichText(widget.product.description!, textAlign: TextAlign.justify, style: GoogleFonts.openSans(color: Colors.black, fontSize: 18.0)) 
                      )
                  )
                : const SizedBox(height: 0),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child:
                    Column(
                      children: [
                        CarouselSlider.builder(
                          options: CarouselOptions(
                            enableInfiniteScroll: widget.product.productMediaUrls!.length > 1 ? true : false, 
                            enlargeCenterPage: true,
                            enlargeFactor: 1,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            },
                          ),
                          itemCount: widget.product.productMediaUrls!.length,
                          itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(30.0),
                              child: FutureBuilder(
                                future: DefaultCacheManager().getSingleFile(widget.product.productMediaUrls![itemIndex]),
                                builder: ((context, snapshot) {
                                  if (snapshot.hasData) {
                                    if (p.extension(snapshot.data!.path) == '.mp4') {
                                      late final player = Player();
                                      late final controller = VideoController(player);
                                      player.open(Media(snapshot.data!.path));
                                      return Video(
                                        controller: controller, 
                                        // controls: (VideoState state) => MaterialVideoControls(state), // Uncomment for app usage
                                        fit: BoxFit.fitWidth, 
                                        width: double.infinity
                                      );
                                    }
                                    else {
                                      return Image.file(snapshot.data!, fit: BoxFit.fitWidth, width: double.infinity);
                                    }
                                  }
                                  else {
                                    return LoadingAnimationWidget.newtonCradle(color: const Color(0xFF224190), size: 50);
                                  }
                                })
                              )
                            );
                          }
                        ),
                        const SizedBox(height: 10),
                        if (widget.product.productMediaUrls!.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: widget.product.productMediaUrls!.asMap().entries.map((entry) {
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
  final bool animateDivider;

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