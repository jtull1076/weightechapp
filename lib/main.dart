import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
import 'dart:async';
import 'dart:ui';
import 'dart:io';

Future<void> main() async {


  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter Bindings

  debugPrint('...System behavior setup...');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // Set to full screen
  Wakelock.enable(); // Enable wakelock to prevent the device from sleeping

  debugPrint('...Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase

  debugPrint('...App Startup...');
  runApp(WeightechApp());
}


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
              const Text('Press anywhere to begin.', style: TextStyle(fontSize: 18.0, fontStyle: FontStyle.normal))],
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

    _timer = Timer(const Duration(minutes: 10), () {
      if (mounted){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IdlePage()));
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => ListingPage(category: item)));
    }
    else if (item is Product) {
      debugPrint('Rerouting to ${item.name} product page.');
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductPage(product: item)));
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
                              itemCount: productManager.all.products.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width<600 ? 1 : 4,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                              ),
                              itemBuilder: (context, index) => CatalogItemTile(
                                item: productManager.all.getAllCatalogItems()[index],
                                onTapCallback: () => catalogNavigation(context, productManager.all.getAllCatalogItems()[index])
                              ),
                            )
                        ),
                    )],//)
                ),
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    SizedBox(
                      height: 115,
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
                        const SizedBox(height: 5),
                        SizeTransition(sizeFactor: _dividerWidthAnimation, axis: Axis.horizontal, child: FadeTransition(opacity: _fadeAnimation, child: const Hero(tag: 'divider', child: Divider(color: Color(0xFF224190), height: 2, thickness: 2, indent: 25.0, endIndent: 25.0,)))),
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



class ProductPage extends StatelessWidget {
  ProductPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 100,
      child: Text('${product.name}'),
    );
  }
}



class ListingPage extends StatelessWidget {
  ListingPage({super.key, required this.category}) : catalogItems = category.getAllCatalogItems();

  final ProductCategory category;
  final List<dynamic> catalogItems;

  void catalogNavigation(BuildContext context, dynamic item){
    if (item is ProductCategory) {
      debugPrint('Rerouting to ${item.name} listing.');
      Navigator.push(context, MaterialPageRoute(builder: (context) => ListingPage(category: item)));
    }
    else if (item is Product) {
      debugPrint('Rerouting to ${item.name} product page.');
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductPage(product: item)));
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
                        GridView.builder(
                          padding: const EdgeInsets.only(top: 110, bottom: 20, left: 20, right: 20),
                          itemCount: catalogItems.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width<600 ? 1 : 4,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                          ),
                          itemBuilder: (context, index) => CatalogItemTile(
                            item: catalogItems[index],
                            onTapCallback: () => catalogNavigation(context, productManager.all.products[index])
                          ),
                        )
                    )],//)
                ),
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    SizedBox(
                      height: 115,
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
                        const SizedBox(height: 5),
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Padding(padding: const EdgeInsets.only(top: 10.0, bottom: 5.0), child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,))),
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
                  child: const Text("Update Catalog")
                )
            ) 
          ]
        )
      )
    );
  }
}





/// The base class for the different types of items the list can contain.
abstract class ListItem {
  /// The title line to show in a list item.
  Widget buildTitle(BuildContext context);

  /// The subtitle line, if any, to show in a list item.
  Widget buildSubtitle(BuildContext context);
}

class BrochureItem {
  final BrochureHeader header;
  final List<BrochureBody> body;

  BrochureItem(this.header, this.body);

  Widget buildItem(BuildContext context) {
    return Column(
      children: [
        header.buildTitle(context),
        for (var child in body) child.buildBody(context),
      ]
    );
  }
}


class BrochureHeader implements ListItem {
  final String heading;

  BrochureHeader(this.heading);

  @override
  Widget buildTitle(BuildContext context){
    return Text(
      heading,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();
}


class BrochureBody implements ListItem {
  final String? subheader;
  final String item;

  BrochureBody(this.subheader, this.item);

  Widget buildBody(BuildContext context){
    return Column(
      children: [
        buildTitle(context),
        buildSubtitle(context),
      ]
    );
  }

  @override
  Widget buildTitle(BuildContext context){
    if (subheader != null && subheader!.isNotEmpty) {
      return Text(subheader!);
    }
    else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget buildSubtitle(BuildContext context) => Text(item);
}


enum ItemSelect {product, category}

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key}); 

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  var _itemSelection = ItemSelect.category;
  final List<BrochureItem> _brochure = [];


  @override
  void deactivate() {
    if (_controller != null) {
      _controller!.setVolume(0.0);
      _controller!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductManager>(
      builder: (context, productManager, child) {
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(padding: const EdgeInsets.only(top: 10.0, bottom: 5.0), child: Hero(tag: 'main-logo', child: Image.asset('assets/weightech_logo.png', height: 100, alignment: Alignment.center,))),
              const Hero(tag: 'divider', child: Divider(color: Color(0xFF224190), height: 2, thickness: 2, indent: 25.0, endIndent: 25.0,)),
              Expanded(
                child:
                  SingleChildScrollView(
                    child: SizedBox(
                      height: 800,
                      child: 
                        Column(
                          children: [
                            SizedBox(
                              width: 250,
                              child: 
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: 
                                    SegmentedButton<ItemSelect>(
                                      style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -1)),
                                      segments: const <ButtonSegment<ItemSelect>>[
                                        ButtonSegment<ItemSelect>(value: ItemSelect.category, label: Text('Category')),
                                        ButtonSegment<ItemSelect>(value: ItemSelect.product, label: Text("Product"))
                                      ], 
                                      selected: <ItemSelect>{_itemSelection},
                                      onSelectionChanged: (Set<ItemSelect> newSelection) {
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
                    )
                  ),
              )
            ]
          )
        );
      }
    );
  }

  Widget _productForm(productManager) {
  return Expanded(
    child: 
      Form(
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
                                  labelText: "Product Name *"
                                ),
                                validator: (String? value) {
                                  return (value == null) ? 'Name required.' : null;
                                },
                              ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 80, right: 40, bottom: 30),
                            child:
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Product Model Number"
                                ),
                              ),
                          ),
                          DropdownMenu<ProductCategory>(
                            label: const Text("Category *"),
                            initialSelection: productManager.all,
                            dropdownMenuEntries: productManager.getAllCategories(productManager.all).map<DropdownMenuEntry<ProductCategory>>((ProductCategory category){
                              return DropdownMenuEntry<ProductCategory>(
                                value: category,
                                label: category.name,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 30),
                          // Divider(color: Theme.of(context).colorScheme.primary, indent: 60, endIndent: 20, height: 2, thickness: 2),
                          const Padding(
                            padding: EdgeInsets.only(top: 20, left: 80, right: 40, bottom: 10), 
                            child: 
                              Text("Product Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 80, right: 40, bottom: 20),
                            child: 
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Overview"
                                ),
                                minLines: 1,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                              )
                          ),

                        ]
                      ),
                  ),
                  Expanded(
                    child: 
                      Column(
                        children: <Widget>[
                          const SizedBox(height: 10),
                          const SizedBox(
                            width: 350, 
                            child: Text("[Insert best-practices for image/video upload here.]")
                          ),
                          const SizedBox(height: 10),
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
                                  height: 250,
                                  width: 300,
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
                                            Flexible(flex: 1, child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 70, endIndent: 15)), 
                                            Text("or"), 
                                            Flexible(flex: 1, child: Divider(color: Colors.black, height: 1, thickness: 1, indent: 15, endIndent: 70))
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
                          const SizedBox(height: 20),
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
                                  height: 250,
                                  width: 300,
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
                  )
                ],
              )
            ],
          )
        )
    );
  }

  Widget _categoryForm(productManager) {
  return Expanded(
    child: 
      Form(
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
                            initialSelection: productManager.all,
                            dropdownMenuEntries: productManager.getAllCategories(productManager.all).map<DropdownMenuEntry<ProductCategory>>((ProductCategory category){
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
        )
      );
    }
      
      
  //     Center(
  //       child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
  //           ? FutureBuilder<void>(
  //               future: retrieveLostData(),
  //               builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
  //                 switch (snapshot.connectionState) {
  //                   case ConnectionState.none:
  //                   case ConnectionState.waiting:
  //                     return const Text(
  //                       'You have not yet picked an image.',
  //                       textAlign: TextAlign.center,
  //                     );
  //                   case ConnectionState.done:
  //                     return _handlePreview();
  //                   case ConnectionState.active:
  //                     if (snapshot.hasError) {
  //                       return Text(
  //                         'Pick image/video error: ${snapshot.error}}',
  //                         textAlign: TextAlign.center,
  //                       );
  //                     } else {
  //                       return const Text(
  //                         'You have not yet picked an image.',
  //                         textAlign: TextAlign.center,
  //                       );
  //                     }
  //                 }
  //               },
  //             )
  //           : _handlePreview(),
  //     ),
  //     floatingActionButton: Column(
  //       mainAxisAlignment: MainAxisAlignment.end,
  //       children: <Widget>[
  //         Semantics(
  //           label: 'image_picker_example_from_gallery',
  //           child: FloatingActionButton(
  //             onPressed: () {
  //               isVideo = false;
  //               _onImageButtonPressed(ImageSource.gallery, context: context);
  //             },
  //             heroTag: 'image0',
  //             tooltip: 'Pick Image from Gallery',
  //             child: const Icon(Icons.photo),
  //           ),
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.only(top: 16.0),
  //           child: FloatingActionButton(
  //             backgroundColor: Colors.red,
  //             onPressed: () {
  //               isVideo = true;
  //               _onImageButtonPressed(ImageSource.gallery, context: context);
  //             },
  //             heroTag: 'video0',
  //             tooltip: 'Pick Video from Gallery',
  //             child: const Icon(Icons.video_library),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

    List<XFile>? _mediaFileList;

    void _setImageFileListFromFile(XFile? value) {
      _mediaFileList = value == null ? null : <XFile>[value];
    }

    dynamic _pickImageError;
    bool isVideo = false;

    VideoPlayerController? _controller;
    VideoPlayerController? _toBeDisposed;
    String? _retrieveDataError;

    final ImagePicker _picker = ImagePicker();

    Future<void> _playVideo(XFile? file) async {
    if (file != null && mounted) {
      await _disposeVideoController();
      late VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
      } else {
        controller = VideoPlayerController.file(File(file.path));
      }
      _controller = controller;
      // In web, most browsers won't honor a programmatic call to .play
      // if the video has a sound track (and is not muted).
      // Mute the video so it auto-plays in web!
      // This is not needed if the call to .play is the result of user
      // interaction (clicking on a "play" button, for example).
      const double volume = 0.0; // kIsWeb ? 0.0 : 1.0;
      await controller.setVolume(volume);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    }
  }

  Future<void> _onImageButtonPressed(
    ImageSource source, {
    required BuildContext context,
  }) async {
    if (_controller != null) {
      await _controller!.setVolume(0.0);
    }
    if (context.mounted) {
      if (isVideo) {
        final XFile? file = await _picker.pickVideo(
            source: source, maxDuration: const Duration(seconds: 30));
        await _playVideo(file);
      } else {
          try {
            final XFile? pickedFile = await _picker.pickImage(
              source: source,
            );
            setState(() {
              _setImageFileListFromFile(pickedFile);
            });
          } catch (e) {
            setState(() {
              _pickImageError = e;
            });
          }
      }
    }
  }

    Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    _controller = null;
  }

  Widget _previewVideo() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_controller == null) {
      return const Text(
        'No video selected.',
        textAlign: TextAlign.center,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AspectRatioVideo(_controller),
    );
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_mediaFileList != null) {
      return Semantics(
        label: 'image_picker_example_picked_images',
        child: ListView.builder(
          key: UniqueKey(),
          itemBuilder: (BuildContext context, int index) {
            final String? mime = lookupMimeType(_mediaFileList![index].path);

            // Why network for web?
            // See https://pub.dev/packages/image_picker_for_web#limitations-on-the-web-platform
            return Semantics(
              label: 'image_picker_example_picked_image',
              child: kIsWeb
                  ? Image.network(_mediaFileList![index].path)
                  : (mime == null || mime.startsWith('image/')
                      ? Image.file(
                          File(_mediaFileList![index].path),
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? stackTrace) {
                            return const Center(
                                child:
                                    Text('This image type is not supported'));
                          },
                        )
                      : _buildInlineVideoPlayer(index)),
            );
          },
          itemCount: _mediaFileList!.length,
        ),
      );
    } else if (_pickImageError != null) {
      return Text(
        'Error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'No image selected.',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildInlineVideoPlayer(int index) {
    final VideoPlayerController controller =
        VideoPlayerController.file(File(_mediaFileList![index].path));
    const double volume = kIsWeb ? 0.0 : 1.0;
    controller.setVolume(volume);
    controller.initialize();
    controller.setLooping(true);
    controller.play();
    return Center(child: AspectRatioVideo(controller));
  }

  Widget _handlePreview() {
    if (isVideo) {
      return _previewVideo();
    } else {
      return _previewImages();
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      if (response.type == RetrieveType.video) {
        isVideo = true;
        await _playVideo(response.file);
      } else {
        isVideo = false;
        setState(() {
          if (response.files == null) {
            _setImageFileListFromFile(response.file);
          } else {
            _mediaFileList = response.files;
          }
        });
      }
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }
}

typedef OnPickImageCallback = void Function(
    double? maxWidth, double? maxHeight, int? quality);

class AspectRatioVideo extends StatefulWidget {
  const AspectRatioVideo(this.controller, {super.key});

  final VideoPlayerController? controller;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  VideoPlayerController? get controller => widget.controller;
  bool initialized = false;

  void _onVideoControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (initialized != controller!.value.isInitialized) {
      initialized = controller!.value.isInitialized;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    controller!.addListener(_onVideoControllerUpdate);
  }

  @override
  void dispose() {
    controller!.removeListener(_onVideoControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: VideoPlayer(controller!),
        ),
      );
    } else {
      return Container();
    }
  }
}










  // @override
  // void initState() {
  //   super.initState();
  // }




  // @override
  // Widget build(BuildContext context) {

  //   return Scaffold(
  //     body: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       mainAxisAlignment: MainAxisAlignment.start,
  //       children: <Widget>[
  //         const SizedBox(height: 10),
  //         SegmentedButton<ItemSelect>(
  //           segments: const <ButtonSegment<ItemSelect>>[
  //             ButtonSegment<ItemSelect>(value: ItemSelect.category, label: Text('Category')),
  //             ButtonSegment<ItemSelect>(value: ItemSelect.product, label: Text("Product"))
  //           ], 
  //           selected: <ItemSelect>{_itemSelection},
  //           onSelectionChanged: (Set<ItemSelect> newSelection) {
  //             setState(() {
  //               _itemSelection = newSelection.first;
  //             });
  //           },
  //         ),

  //       ]
  //     )
  //   );
  // }