import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/rendering.dart';
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



abstract class BrochureItem {
  Widget buildItem(BuildContext context);
}

class BrochureHeader implements BrochureItem {
  String header;
  final TextEditingController _controller;

  BrochureHeader({required this.header}) : _controller = TextEditingController(text: header);

  @override
  Widget buildItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.menu, size: 30,), 
      title: TextFormField(
        controller: _controller, 
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      )
    );
  }

  BrochureHeader.basic() : header="New Header", _controller = TextEditingController(text: "New Header");

}

class BrochureSubheader implements BrochureItem {
  String subheader;
  final TextEditingController _controller;

  BrochureSubheader({required this.subheader}) : _controller = TextEditingController(text: subheader);

  @override
  Widget buildItem(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 50), child: ListTile(leading: const Icon(Icons.menu, size: 30), title: TextFormField(controller: _controller, textCapitalization: TextCapitalization.words, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,))));
  }

  BrochureSubheader.basic() : subheader="New Subheader", _controller = TextEditingController(text: "New Subheader");

}

class BrochureEntry implements BrochureItem {
  String entry;
  final TextEditingController _controller;

  BrochureEntry({required this.entry}) : _controller = TextEditingController(text: entry);

  BrochureEntry.basic() : entry="New Entry", _controller = TextEditingController(text: "New Entry");

  @override
  Widget buildItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 100), 
      child: 
        ListTile(
          leading: const Icon(Icons.menu, size: 30), 
          title: TextFormField(controller: _controller,)));
  }
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

  List<BrochureItem> _brochure = [BrochureHeader(header: "Header1"), BrochureSubheader(subheader: "Subheader1"), BrochureEntry(entry: "Entry1"), BrochureEntry(entry: "Entry2"), BrochureHeader(header: "Header2")];

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
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
          )
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
    );
  }
}