import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weightechapp/firebase_options.dart';
import 'package:wakelock/wakelock.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:carousel_slider/carousel_slider.dart';


//MARK: MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  debugPrint('...System behavior setup...');
  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // Set to full screen
    Wakelock.enable(); // Enable wakelock to prevent the device from sleeping
  }

  debugPrint('...Initializing Firebase...');
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase

  debugPrint('...App Startup...');
  runApp(WeightechApp());
}

/// A class that defines the widget tree.
class WeightechApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductManager>(
      create: (_) => ProductManager(),
      child: MaterialApp(
        title: "Weightech Inc. Sales",
        theme: WeightechThemes.lightTheme, 
        initialRoute: '/',
        routes: {
          '/': (context) => const IdlePage(),
          '/home': (context) => HomePage(),
        },
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', fit: BoxFit.scaleDown))
              ), 
              const Text('Press anywhere to begin.', style: TextStyle(fontSize: 18.0, fontStyle: FontStyle.normal))],
          )
        )
      )
    );
  }

  Route _routeToHome() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
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
  HomePage({Key? key}) : super(key: key);

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

    _timer = Timer(const Duration(minutes: 10 ), () {
      if (mounted){
        Navigator.popUntil(context, (route) => route.isFirst);
        debugPrint("--Idle Timeout--");
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
      debugPrint('Rerouting to ${item.name} listing.');
      _timer.cancel();
      Navigator.push(context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ListingPage(category: item),
          transitionsBuilder: (context, animation, secondaryAnimation, child){
            var begin = 0.0;
            var end = 1.0;
            var curve = Curves.fastLinearToSlowEaseIn;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return FadeTransition(opacity: animation.drive(tween),child: child);
          },
          transitionDuration: const Duration(milliseconds: 500)
        )
      );
    }
    else if (item is Product) {
      debugPrint('Rerouting to ${item.name} product page.');
      _timer.cancel();
      Navigator.push(context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProductPage(product: item),
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
    return Consumer<ProductManager>(
      builder: (context, productManager, child) {
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
                              itemCount: ProductManager.all.catalogItems.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width<600 ? 1 : 4,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                              ),
                              itemBuilder: (context, index) => ProductManager.all.catalogItems[index].buildCard(() => catalogNavigation(context, ProductManager.all.getAllCatalogItems()[index])),
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
                            debugPrint('---Return to Idle Interaction---');
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const IdlePage()));
                          },
                          child: Padding(padding: const EdgeInsets.only(top: 10.0), child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,))),
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
  ProductPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _dividerHeightAnimation;
  late Animation<double> _fadeAnimation;
  late Timer _timer;
  int _current = 0;
  final CarouselController _carouselController = CarouselController();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(duration : const Duration(seconds: 2), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.3, 0.6, curve: Curves.ease)));
    _dividerHeightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.ease)));

    _timer = Timer(const Duration(minutes: 10), () {
      if (mounted){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IdlePage()));
        debugPrint("--Idle Timeout--");
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
                          debugPrint('---Return to Idle Interaction---');
                          _timer.cancel();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const IdlePage()));
                        },
                        child: Padding(padding: const EdgeInsets.only(top: 10.0), child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,)),
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
                              style: const TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                        )
                    )
                  ),
              ),
            ]
          ),
          Expanded(
            child:
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                scrollDirection: Axis.vertical,
                child: 
                  Row(
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
                                      child: SimpleRichText(widget.product.description!, style: GoogleFonts.openSans(color: Colors.black, fontSize: 18.0)) 
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
                                          enableInfiniteScroll: widget.product.productImages!.length > 1 ? true : false, 
                                          enlargeCenterPage: true,
                                          enlargeFactor: 1,
                                          onPageChanged: (index, reason) {
                                            setState(() {
                                              _current = index;
                                            });
                                          },
                                        ),
                                        itemCount: widget.product.productImages!.length,
                                        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(30.0),
                                            child: widget.product.productImages![itemIndex]
                                          );
                                        }
                                      ),
                                      const SizedBox(height: 10),
                                      if (widget.product.productImages!.length > 1)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: widget.product.productImages!.asMap().entries.map((entry) {
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
                                          Text(headerKey, style: const TextStyle(color: Color(0xFF224190), fontSize: 32.0, fontWeight: FontWeight.bold), softWrap: true,),
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
                                                    child: Text(subheaderKey, style: const TextStyle(color: Color(0xFF333333), fontSize: 27.0, fontWeight: FontWeight.w800), softWrap: true,),
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
                      )
                    ],
                  )
                ),
          ),
        ]
      )
    );
  }
}


// MARK: LISTING PAGE

/// A class defining the stateless [ListingPage]. These are used to navigate the catalog tree. 
class ListingPage extends StatelessWidget {
  ListingPage({super.key, required this.category}) : catalogItems = category.catalogItems;

  final ProductCategory category;
  final List<CatalogItem> catalogItems;

  late final Timer _timer;

  void catalogNavigation(BuildContext context, dynamic item){
    if (item is ProductCategory) {
      debugPrint('Rerouting to ${item.name} listing.');
      _timer.cancel();
      Navigator.push(context, MaterialPageRoute(builder: (context) => ListingPage(category: item)));
    }
    else if (item is Product) {
      debugPrint('Rerouting to ${item.name} product page.');
      _timer.cancel();
      Navigator.push(context, 
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProductPage(product: item),
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
    _timer = Timer(const Duration(minutes: 10), () {
      Navigator.of(context).popUntil((route) => route.isFirst);
      debugPrint("--Idle Timeout--");
    });

    return Consumer<ProductManager>(
      builder: (context, productManager, child) {
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
                        GridView.builder(
                          padding: const EdgeInsets.only(top: 110, bottom: 20, left: 20, right: 20),
                          itemCount: catalogItems.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width<600 ? 1 : 4,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                          ),
                          itemBuilder: (context, index) => catalogItems[index].buildCard(() => catalogNavigation(context, catalogItems[index])),)
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
                                        debugPrint('---Return to Idle Interaction---');
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const IdlePage()));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10.0), 
                                        child: Hero(
                                          tag: 'main-logo',
                                          child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,)
                                        ),
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
                                          onPressed: () => Navigator.pop(context),
                                        )
                                    )
                                ),
                              ]
                            ),
                        ),
                        const Hero(tag: 'divider', child: Divider(color: Color(0xFF224190), height: 2, thickness: 2, indent: 25.0, endIndent: 25.0,)),
                      ]
                    )
                  ]
                ),
                
              ]
            )
          )
        );
      }
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
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dividerWidthAnimation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductManager>(
      builder: (context, productManager, child) {
        return Scaffold(
          body: Column(
            children: <Widget>[
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
                              debugPrint('---Return to Idle Interaction---');
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const IdlePage()));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10.0), 
                              child: Hero(
                                tag: 'main-logo',
                                child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,)
                              ),
                            )
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
                                    onPressed: () => Navigator.pop(context),
                                  )
                              )
                          )
                      ),
                    ]
                  ),
              ),
              SizeTransition(sizeFactor: _dividerWidthAnimation, axis: Axis.horizontal, child: FadeTransition(opacity: _fadeAnimation, child: const Hero(tag: 'divider', child: Divider(color: Color(0xFF224190), height: 2, thickness: 2, indent: 25.0, endIndent: 25.0,)))),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _fadeAnimation,
                child: 
                  ElevatedButton(
                    style: const ButtonStyle(foregroundColor: MaterialStatePropertyAll<Color>(Color(0xFF000000)),),
                    onPressed: (){
                      debugPrint("Product List Updating..."); 
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemPage()));
                    },
                    child: const Text("Add Catalog Item")
                  )
              ),
              Center(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF224190),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10, ),
                  child:
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 130), 
                      child: Text("Product Catalog", style: TextStyle(color: Colors.white, fontSize: 28.0),)
                    )
                )
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
                height: MediaQuery.of(context).size.height - 154,
                child: 
                  SingleChildScrollView(
                    child: 
                      catalogBuilder(ProductManager.all, 0)
                  )
              )
            ]
          )
        );
      }
    );
  }

  Widget catalogBuilder(var item, double leftPadding){

    switch (item) {
      case ProductCategory _: {
        return Column (
          crossAxisAlignment: CrossAxisAlignment.center,
          key: Key(item.id),
          children: [
            if (item.name != 'All') item.buildListTile(),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: item.catalogItems.length,
              itemBuilder:(context, index) => catalogBuilder(item.catalogItems[index], leftPadding + 10),
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final itemToMove = item.catalogItems.removeAt(oldIndex);
                  item.catalogItems.insert(newIndex, itemToMove);
                });
              },
            )
          ]
        );
      }
      case Product _: {
        return item.buildListTile();
      }
    }
    return const Text("Invalid item encountered.");
  }
}

// MARK: ADDITEM PAGE

enum ItemSelect {product, category}

/// A class defining the stateful [AddItemPage]. This is used for adding new items to the catalog. 
/// 
/// Stateful for handling the updating dynamically in response to the user's input. 
/// 
/// See also: [_AddItemPageState]
class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key}); 

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  var _itemSelection = ItemSelect.category;
  ProductCategory _selectedCategory = ProductManager.all;

  final TextEditingController _dropdownController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();

  final List<BrochureItem> _brochure = [BrochureHeader(header: "Header1"), BrochureSubheader(subheader: "Subheader1"), BrochureEntry(entry: "Entry1"), BrochureEntry(entry: "Entry2"), BrochureHeader(header: "Header2")];

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    _dropdownController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _modelNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Consumer<ProductManager>(
      builder: (context, productManager, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(padding: const EdgeInsets.only(top: 10.0, bottom: 5.0), child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,))),
              const Hero(tag: 'divider', child: Divider(color: Color(0xFF224190), height: 2, thickness: 2, indent: 25.0, endIndent: 25.0,)),
              Expanded(
                child:
                  ListView(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: 
                          SizedBox(
                            width: 300,
                            child: 
                              SegmentedButton<ItemSelect>(
                                style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -1)),
                                segments: const <ButtonSegment<ItemSelect>>[
                                  ButtonSegment<ItemSelect>(value: ItemSelect.category, label: Text('Category')),
                                  ButtonSegment<ItemSelect>(value: ItemSelect.product, label: Text("Product"))
                                ], 
                                selected: <ItemSelect>{_itemSelection},
                                onSelectionChanged: (newSelection) {
                                  setState(() {
                                    _itemSelection = newSelection.first;
                                  });
                                },
                              ),
                          )
                      ),
                      (_itemSelection == ItemSelect.category)? _categoryForm(productManager) : _productForm(productManager)
                    ]
                  )
                ),
              const SizedBox(height: 20),
            ]
          )
        );
      }
    );
  }

  int _addBrochureItemIndex = -1; // -1 if not to show add buttons, otherwise represents index of where the buttons should be

  Widget _productForm(productManager) {
  return Form(
    key: _formKey,
    child: 
      Column(
        children: [
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 40, right: 40, bottom: 20, top: 20),
                        child:
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Product Name *"
                            ),
                            validator: (String? value) {
                              return (value == null) ? 'Name required.' : null;
                            },
                          ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 40, right: 40, bottom: 30),
                        child:
                          TextFormField(
                            controller: _modelNumberController,
                            decoration: const InputDecoration(
                              labelText: "Product Model Number"
                            ),
                          ),
                      ),
                      DropdownMenu<ProductCategory>(
                        label: const Text("Category *"),
                        controller: _dropdownController,
                        initialSelection: ProductManager.all,
                        dropdownMenuEntries: productManager.getAllCategories(ProductManager.all).map<DropdownMenuEntry<ProductCategory>>((ProductCategory category){
                          return DropdownMenuEntry<ProductCategory>(
                            value: category,
                            label: category.name,
                          );
                        }).toList(),
                        onSelected: (newValue) {
                          setState((){
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                    ]
                  ),
              ),
              Expanded(
                child: 
                  Column(
                    children: <Widget>[
                      const SizedBox(height: 10),
                      const Text("[Insert best-practices for image/video upload here.]"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DottedBorder(
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(8),
                            padding: const EdgeInsets.all(6),
                            dashPattern: const [6, 3],
                            color: Colors.black,
                            strokeWidth: 1,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              child: 
                                Container(
                                  height: 230,
                                  width: 200,
                                  color: const Color(0x55C9C9CC),
                                  child:
                                    const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, size: 70),
                                        Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center, 
                                          children: [
                                            Expanded(child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 70, endIndent: 15)), 
                                            Text("or"), 
                                            Expanded(child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 15, endIndent: 70))
                                          ]
                                        ),
                                        SizedBox(height: 10),
                                        OutlinedButton(onPressed: null , child: Text("Browse Files")),
                                        SizedBox(height: 10),
                                        Text("File must be .jpg or .png", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic))
                                      ]
                                    )
                                )
                            )
                          ),
                          const SizedBox(width: 20),
                          DottedBorder(
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(8),
                            padding: const EdgeInsets.all(6),
                            dashPattern: const [6, 3],
                            color: Colors.black,
                            strokeWidth: 1,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              child: 
                                Container(
                                  height: 230,
                                  width: 200,
                                  color: const Color(0x55C9C9CC),
                                  child:
                                    const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.videocam, size: 70),
                                        Text("Drag and drop file here", style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center, 
                                          children: [
                                            Flexible(flex: 1, child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 70, endIndent: 15)), 
                                            Text("or"), 
                                            Flexible(flex: 1, child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 15, endIndent: 70))
                                          ]
                                        ),
                                        SizedBox(height: 10),
                                        OutlinedButton(onPressed: null , child: Text("Browse Files")),
                                        SizedBox(height: 10),
                                        Text("File must be .mp4", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic))
                                      ]
                                    )
                                )
                            )
                          )
                        ]
                      )
                    ]
                  )
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20, left: 150, right: 150, bottom: 10), 
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
                      
                      if (defaultTargetPlatform==TargetPlatform.macOS || defaultTargetPlatform==TargetPlatform.windows || defaultTargetPlatform==TargetPlatform.linux) {
                        return MouseRegion(
                          key: Key('Mouse_$index'),
                          onEnter: (PointerEnterEvent evt) {
                            setState((){
                              _addBrochureItemIndex = index;
                            });
                          },
                          onExit: (PointerExitEvent evt) {
                            setState((){
                              _addBrochureItemIndex = -1;
                            });
                          },
                          child:
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 0),
                                  child: 
                                    ReorderableDelayedDragStartListener(
                                      index: index,
                                      child:
                                        item.buildItem(context)
                                    )
                                ),
                                if(_addBrochureItemIndex == index)
                                  Container(
                                    width: 400,
                                    height: 30,
                                    alignment: Alignment.bottomCenter,
                                    child:
                                        Row(
                                          children: [
                                            Expanded(
                                              child: 
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState((){
                                                    int newItemIndex = index+1;
                                                    _brochure.insert(newItemIndex, BrochureHeader.basic());
                                                  });
                                                }, 
                                                child: const Text("Header+")
                                              ),
                                            ),
                                            Expanded(
                                              child: 
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState((){
                                                      int newItemIndex = index+1;
                                                      _brochure.insert(newItemIndex, BrochureSubheader.basic());
                                                    });
                                                  }, 
                                                  child: const Text("Subheader+")
                                                ),
                                            ),
                                            Expanded(
                                              child:
                                                ElevatedButton(
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
                      }
                      else {
                        return 
                          Column(
                            key: Key('col_$index'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 0),
                                child: 
                                  ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: item.buildItem(context),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => setState(() {
                                            _addBrochureItemIndex = index;
                                          })
                                        )
                                      ]
                                    )
                                  ),
                              ),
                              if(_addBrochureItemIndex == index)
                                TapRegion(
                                  key: Key('Tap_$index'),
                                  onTapOutside: (event) {
                                    setState((){
                                      _addBrochureItemIndex = -1;
                                    });
                                  },
                                  child:
                                    Container(
                                      width: 400,
                                      height: 30,
                                      alignment: Alignment.bottomCenter,
                                      child:
                                          Row(
                                            children: [
                                              Expanded(
                                                child: 
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState((){
                                                      int newItemIndex = index+1;
                                                      _brochure.insert(newItemIndex, BrochureHeader.basic());
                                                    });
                                                  }, 
                                                  child: const Text("Header+")
                                                ),
                                              ),
                                              Expanded(
                                                child: 
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      setState((){
                                                        int newItemIndex = index+1;
                                                        _brochure.insert(newItemIndex, BrochureSubheader.basic());
                                                      });
                                                    }, 
                                                    child: const Text("Subheader+")
                                                  ),
                                              ),
                                              Expanded(
                                                child:
                                                  ElevatedButton(
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
                                )
                            ]
                          );
                        }
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _brochure.removeAt(oldIndex);
                        _brochure.insert(newIndex, item);
                      });
                    },                                                            
                  )
              ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: const ButtonStyle(foregroundColor: MaterialStatePropertyAll(Colors.white), backgroundColor: MaterialStatePropertyAll(Color(0xFF224190))),
            child: const Text('Save & Exit'),
            onPressed: () {
                _selectedCategory.addProduct(
                  Product(
                    name: _nameController.text,
                    modelNumber: _modelNumberController.text,
                    parentId: _selectedCategory.id,
                    description: _descriptionController.text,
                    brochure: Product.mapListToBrochure(_brochure),
                  )
                );
                Navigator.pop(context);
            }
          ),
        const SizedBox(height: 20)
        ],
      )
    );
  }

  Widget _categoryForm(productManager) {
  return Form(
    key: _formKey,
    child: 
      Column(
        children: [
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 80, right: 40, bottom: 20),
                        child:
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Category Name"
                            ),
                            validator: (String? value) {
                              return (value == null) ? 'Name required.' : null;
                            },
                          ),
                      ),
                      DropdownMenu<ProductCategory>(
                        label: const Text("Parent Category: "),
                        initialSelection: ProductManager.all,
                        dropdownMenuEntries: productManager.getAllCategories(ProductManager.all).map<DropdownMenuEntry<ProductCategory>>((ProductCategory category){
                          return DropdownMenuEntry<ProductCategory>(
                            value: category,
                            label: category.name,
                          );
                        }).toList(),
                      )
                    ]
                  ),
              ),
              Expanded(
                child: 
                  Column(
                    children: <Widget>[
                      DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(8),
                        padding: const EdgeInsets.all(6),
                        dashPattern: const [6, 3],
                        color: Colors.black,
                        strokeWidth: 1,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: 
                            Container(
                              alignment: Alignment.center,
                              height: 200,
                              width: 300,
                              color: const Color(0x55C9C9CC)
                            )
                        )
                      )
                    ]
                  )
              )
            ],
          )
        ],
      )
    );
  }
}