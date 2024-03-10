import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/themes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:weightechapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(title: 'Weightech Inc.', theme: WeightechThemes.lightTheme, home: const IdlePage()));
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
      pageBuilder: (context, animation, secondaryAnimation) => ListingPage(),
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

class ListingPage extends StatefulWidget {
  final ProductCategory productManager = ProductCategory(name: 'All'); // Initialize the ProductManager

  ListingPage({Key? key}) : super(key: key) {
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
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dividerWidthAnimation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 30, bottom: 0),
        
        child: Column(
          children: <Widget>[
            Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,)),
            SizedBox(height: 5, child: SizeTransition(sizeFactor: _dividerWidthAnimation, axis: Axis.horizontal, child: FadeTransition(opacity: _fadeAnimation, child: const Divider(color: Color(0xFF224190), height: 8, thickness: 2, indent: 30, endIndent: 30,)))),
            Expanded(
              child: 
                ShaderMask(
                  shaderCallback: (Rect rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.transparent, Colors.transparent, Colors.white],
                      stops: [0.0, 0.1, 0.8, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstOut,
                  child:
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: 
                        GridView.builder(
                          padding: const EdgeInsets.only(top: 30, bottom: 30),
                          itemCount: widget.productManager.products.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width<600 ? 1 : 4,
                            childAspectRatio: 0.95,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemBuilder: (context, index) => CatalogItemTile(
                            product: widget.productManager.products[index],
                          ),
                        )
                    ),
                )
            )
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

