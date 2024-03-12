import 'package:flutter/services.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/themes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weightechapp/firebase_options.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // Set to full screen
  Wakelock.enable(); // Enable wakelock to prevent the device from sleeping
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase
  runApp(MaterialApp(
    title: 'Weightech Inc.', 
    theme: WeightechThemes.lightTheme, 
    home: const IdlePage()));
}


class IdlePage extends StatelessWidget {
  const IdlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(_routeToMainListing());
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
              const Text('Press anywhere to begin.')],
          )
        )
      )
    );
  }

  Route _routeToMainListing() {
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

class HomePage extends StatefulWidget {
  final ProductCategory productManager = ProductCategory(name: 'All'); // Initialize the ProductManager

  HomePage({Key? key}) : super(key: key) {
    // Add some dummy products
    productManager.addProduct(
      Product(
        name: "Microweigh Indicators",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 1",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    productManager.addProduct(
      Product(
        name: "Case Weigher",
        category: "In-Line Weighers",
        imagePath: "assets/product_images/case_weigher_front.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    productManager.addProduct(
      Product(
        name: "Sizer System",
        category: "Sizers",
        imagePath: "assets/product_images/sizer.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    productManager.addProduct(
      Product(
        name: "Trimline Station",
        category: "Trimlines",
        imagePath: "assets/product_images/trimline_station.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      ),
    );
    productManager.addProduct(
      Product(
        name: "Microweigh Indicator 2",
        category: "Indicators",
        imagePath: "assets/product_images/microweigh_indicators.png",
        description: "Description of Product 2",
        brochure: {"key1": "value1", "key2": "value2"},
      )
    );
    // Add more products as needed
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dividerWidthAnimation;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(duration : const Duration(seconds: 5), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.7, curve: Curves.ease)));
    _dividerWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.ease)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //Future.delayed(const Duration(seconds: 5), () =>
      _controller.forward();
      //);
    });

    timer = Timer(const Duration(minutes: 10), () {
      dispose();
      Navigator.push(context, MaterialPageRoute(builder: (context) => const IdlePage()));
      debugPrint("--Idle Timeout--");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // var stopwatch = Stopwatch();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 5, bottom: 0),
        
        child: Column(
          children: <Widget>[
            GestureDetector(
              // onLongPressDown: (details) {
              //   stopwatch.start();
              // },
              // onLongPressUp: () {
              //   stopwatch.stop();
              //   var timeElapsedInSeconds = stopwatch.elapsed.inSeconds;
              //   debugPrint('Hold time: $timeElapsedInSeconds');
              //   if (timeElapsedInSeconds > 5) {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => const IdlePage()));
              //   }
              // },
              onDoubleTap: (){
                debugPrint('Return to Idle Interaction');
                Navigator.push(context, MaterialPageRoute(builder: (context) => const IdlePage()));
              },
              child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,)),
            ),
            const SizedBox(height: 5),
            SizedBox(height: 1, child: SizeTransition(sizeFactor: _dividerWidthAnimation, axis: Axis.horizontal, child: FadeTransition(opacity: _fadeAnimation, child: const Divider(color: Color(0xFF224190), height: 1, thickness: 1, indent: 25.0, endIndent: 25.0,)))),
            Expanded(
              child: 
                // I think I'm gonna ditch the shader effect for now
                // To re-implement, un-comment and add a parenthesis
                // later where VS code says so. I'm gonna keep this
                // here in case I change my mind. --JT
                // ShaderMask(
                //   shaderCallback: (Rect rect) {
                //     return const LinearGradient(
                //       begin: Alignment.topCenter,
                //       end: Alignment.bottomCenter,
                //       colors: [Colors.white, Colors.white, Colors.transparent, Colors.transparent, Colors.white],
                //       stops: [0.0, 0.01, 0.1, 0.8, 1.0],
                //     ).createShader(rect);
                //   },
                //   blendMode: BlendMode.dstOut,
                //   child:
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: 
                    GridView.builder(
                      padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
                      itemCount: widget.productManager.products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width<600 ? 1 : 4,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                      ),
                      itemBuilder: (context, index) => CatalogItemTile(
                        product: widget.productManager.products[index],
                      ),
                    )
                ),
              )//)
          ]
        )
      )
    );
  }
}




class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 30, bottom: 30),
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: const ButtonStyle(foregroundColor: MaterialStatePropertyAll<Color>(Color(0xFF000000))),
              onPressed: (){debugPrint("Product List Updating...");}, 
              child: const Text("Update Product List")),
          ]
        )
      )
    );
  }
}

