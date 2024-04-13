import 'package:flutter/material.dart';
import 'package:shortid/shortid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:math' as math;


class ProductManager extends ChangeNotifier {
  static ProductCategory all = ProductCategory.all();

  ProductManager() {
    all.addCategory(
      ProductCategory(
        name: "Microweigh Indicators",
        image: Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
    all.addProduct(
      Product(
        name: "Portion Scale",
        productImages: [Image.asset(
          'assets/product_images/qa-new.jpg',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "The WeighTech line of Portion Scales is designed to cover a multitude of uses – QA checks, portioning and verifying correct product weights on the production line. Our small scale line comes in a variety of base sizes to meet your weighing requirements.",
        brochure: [
          {"Features" : [{"Entries" : [
            "Permanently sealed, high impact, ABS alloy construction for enclosure" , 
            "Highly visible display with adjustable contrast and backlight",
            "Touch sensitive operator control panel",
            "Displays in lbs., kg., g., or oz.", 
            "Communications available in infrared, RS-232, RS-485, Ethernet and Bluetooth",
            "Data collection available through tablet with WeighTech Update App",
            ]}]
          },
          {"Options" : [{"Entries" : [
            "Detachable or hardwired power cord", 
            "Stainless steel swivel bracket",
            "Multiple tower heights",
            "MicroArmor",
            "Custom firmware for data collection and customized reporting"
            ]}]
          },
          {"Advantages" : [{"Entries" : [
            "Ease of operation requiring minimal training" , 
            "No double boxing required",
            "Low Maintenance",
            "Operates as individual unit or integrated multiple scale system"
            ]}]
          },
        ],
      ),
    );
    all.addProduct(
      Product(
        name: "Sizing System",
        productImages: [Image.asset(
          'assets/product_images/sizer.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "WeighTech’s sizing systems are built with the operator and maintenance personnel in mind. With it’s simplistic yet rigid design and proven controller it requires minimal training. Optional webserver with the ability to check totals from your phone, tablet, or desktop.",
        brochure: [
          {"Features" : [{"Entries" : [
            "Up to 150 pieces per minute per lane" , 
            "Gapper ensures proper singulation while maintaining a compact footprint", 
            "Can be fed via an operator or a conveyor",
            "+/- 5 grams accuracy", 
            "Weigh in units of pounds, ounces, grams, or kilograms",
            ]}]
          },
          {"Advantages" : [{"Entries" : [
            "Industry proven MicroWeigh controller" , 
            "Designed for simple operation and easy maintenance",
            "Phone/tablet friendly",
            ]}]
          },
          {"Options" : [{"Entries" : [
            "Single or dual lanes", 
            "Web server over Ethernet",
            "Can fill boxes, bags, combos, or conveyors",
            "Industrial communication protocols (OPC-UA, Modbus/TCP, MQTT, EtherNet/IP, etc.)",
            ]}]
          }
        ],
      ),
    );
    all.addProduct(
      Product(
        name: "Trimline Systems",
        productImages: [
          Image.asset(
          'assets/product_images/trimline_station.png',
          width: double.infinity,
          fit: BoxFit.cover,
          ),
          Image.asset(
          'assets/product_images/trimline_shop.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          )
        ],
        description: "WeighTech’s *Trimline Systems* can take care of all your portion control or de-boning needs. Constructed out of polished 304 stainless steel with an emphasis on durability and easy cleaning. Its large cutting stations, easy to read scale displays, and data tracking make for minimal training. The QC station allows for checks throughout each shift with up to ten customizable questions. The totals can be viewed easily with a phone or tablet anytime.",
        brochure: [
          {"Features" : [{"Entries" : [
            "Data tracking for up to 3 products per station" , 
            "Highly visible scale display with backlight at each station", 
            "Open frame design with 304 polished stainless steel",
            "Integrated scale at each station", 
            "Modes included de-boning portion control",
            ]}]
          },
          {"Advantages" : [{"Entries" : [
            "Ease of operation, minimal training required" , 
            "Ability to QC each product with up to 10 questions per product",
            "Can utilize numerous products",
            "Modular design for potential future expansion",
            "Minimal support staff required",
            "Accurate pounds per hour tracking",
            ]}]
          },
          {"Options" : [{"Entries" : [
            "One to three finished product versions", 
            "Web server over Ethernet",
            "Infeed system with de-icer capabilities",
            "Large color scoreboards",
            "Phone/tablet friendly"
            ]}]
          }
        ],
      ),
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 2",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "The patented industry leading electronic indicator for harsh washdown environments. MicroWeigh, the flagship product of the WeighTech line, was designed to outperform and outlast other indicators. This is accomplished through the use of several key features such as its highly durable IP69K housing. Touch sensitive keypads responds to human touch – not to knives or other sharp instruments. Safety issues are also addressed through the use of potted electrical parts for safety when the panel is exposed or taken off. The indicator is used in many applications including scales and processing equipment. MicroWeigh has been tested for compliance with industry standards for protection from water ingress under IP69K (pressure washing), NEMA 4 (hosedown), NEMA 6 (water immersion), IP67 (water immersion), and IP68 (water immersion simulating water pressure over 80-feet deep). MicroWeigh has also satisfied tests for dust resistance under IP6. We know of no other manufacturer of an electronic indicator that has passed all these tests.",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 3",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 4",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 5",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 6",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 7",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 8",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 9",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 10",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
    all.getItemByName("Microweigh Indicators").addProduct(
      Product(
        name: "Microweigh Indicator 11",
        productImages: [Image.asset(
          'assets/product_images/microweigh_indicator.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        )],
        description: "Description of Product 2",
        brochure: [
          {"Header1" : [{"Entries" : ["Entry1" , "Entry2"]}, {"Subheader1" : ["Entry1" , "Entry2"]}]},
          {"Header2" : [{"Subheader1" : ["Entry1", "Entry2"]}, {"Subheader2" : ["Entry1", "Entry2"]}]}
        ],
      )
    );
  }

  List<ProductCategory> getAllCategories(ProductCategory? category) {
    final ProductCategory root = category ?? all;

    List<ProductCategory> allCategories = [];

    void traverseCategories(ProductCategory category) {
      allCategories.add(category); // Add the current category to the list

      // Traverse subcategories recursively
      for (var item in category.catalogItems) {
        if (item.runtimeType == ProductCategory) {
          traverseCategories(item as ProductCategory);
        }
      }
    }

    traverseCategories(root);

    return allCategories;
  }

  static CatalogItem? getItemById(String id, {ProductCategory? category}) {
    final ProductCategory root = category ?? all;

    CatalogItem? result;

    void traverseItems(ProductCategory category) {
      if (category.id == id) {
        result = category;
        return;
      }
      for (var item in category.catalogItems) {
        switch (item) {
          case ProductCategory _: {
            traverseItems(item);
            if (result != null) {
              return;
            }
          }
          case Product _: {
            if (item.id == id) {
              result = item;
            }
          }
        }
      }
    }

    traverseItems(root);

    return result;
  }
}

sealed class CatalogItem {
  late String id;
  late String name;
  late String? parentId;
  late Image? image;

  CatalogItem({required this.name, this.parentId, String? id, Image? image}) 
  : id = id ?? shortid.generate(), 
    image = image ?? Image.asset('assets/weightech_logo.png', width: double.infinity, fit: BoxFit.fitWidth );

  Widget buildCard(VoidCallback onTapCallback) {
    return Card(
      surfaceTintColor: Colors.white,
      shadowColor: const Color(0xAA000000),
      margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0, top: 30.0),
      child: Stack( 
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: 
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                      Hero(tag: '${name}_htag', child: image!),
                  ),
              ),
              Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: Colors.black)), // Handle if name is null
              const SizedBox(height: 10),
            ],
          ),
          Positioned.fill(
            child: 
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    debugPrint('Item tapped: $name');
                    onTapCallback();
                  }
                )
              )
          )
        ]
      )
    );
  }

  Widget buildListTile({int? index}) {
    return ListTile(title: Text(name));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'image': image?.toString(),
    };
  }

  static CatalogItem fromJson(Map<String, dynamic> json) {
    if (json['catalogItems'] != null) {
      return ProductCategory.fromJson(json);
    }
    else {
      return Product.fromJson(json);
    }
  }

  ProductCategory? getParentById() {
    if (parentId != null) {
      return ProductManager.getItemById(parentId!) as ProductCategory;
    }
    debugPrint("Parent doesn't exist");
    return null;
  }
}

class ProductCategory extends CatalogItem {
  late List<CatalogItem> catalogItems;
  static const String buttonRoute = '/listing';

  ProductCategory({
    required super.name,
    super.id,
    super.parentId,
    super.image,
    List<CatalogItem>? catalogItems,
  }) : catalogItems = catalogItems ?? [];

  ProductCategory.all() : catalogItems = [], super(name: 'All');

  // Function to add a product to the list1
  void addProduct(Product product) {
    product.parentId = id;
    catalogItems.add(product);
  }

  void addCategory(ProductCategory category){
    category.parentId = id;
    catalogItems.add(category);
  }

  // Function to remove a product from the list
  void removeProduct(Product product) {
    catalogItems.remove(product);
  }

  void removeCategory(ProductCategory category){
    catalogItems.remove(category);
  }

  // Function to get all products
  List<Product> getAllProducts() {
    return catalogItems.where((item) => item.runtimeType == Product).toList() as List<Product>;
  }

  List<dynamic> getAllCatalogItems() {
    return catalogItems;
  }

  dynamic getItemByName(String? name) {
    if (name == null || name.isEmpty) {
      // Handle null argument
      return null;
    }

    // Check if the item exists in subcategories
    for (var item in catalogItems) {
      if (item.name == name) {
        return item;
      }
    }

    // If the item is not found in subcategories or products, return null
    return null;
  }

  void addProductByParentId(Product newProduct) {
    if (id == newProduct.parentId) {
      addProduct(newProduct);
      debugPrint('${newProduct.name} (id: ${newProduct.id}) added to $name (id: $id)');
      return;
    }
    for (var item in catalogItems) {
      if (item is ProductCategory && item.id == newProduct.parentId) {
        item.addProduct(newProduct);
        debugPrint('${newProduct.name} (id: ${newProduct.id}) added to ${item.name} (id: ${item.id})');
        return;
      }
    }
    // If not found in the current category, recursively search in subcategories
    for (var item in catalogItems) {
      if (item is ProductCategory) {
        item.addProductByParentId(newProduct); // Recursively search in subcategories
      }
    }
    debugPrint('Parent category with ID ${newProduct.parentId} not found in category $name (id: $id).');
  }

  
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['catalogItems'] = catalogItems.map((item) => item.toJson()).toList();
    return json;
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    // debugPrint("Converting the following JSON to a ProductCategory. Here's the JSON:");
    // debugPrint("------");
    // debugPrint((const JsonEncoder.withIndent('   ')).convert(json));
    // debugPrint("------");
    return ProductCategory(
      name: json['name'],
      id: json['id'],
      parentId: json['parentId'],
      catalogItems: (json['catalogItems'] as List<dynamic>).map((itemJson) => CatalogItem.fromJson(itemJson)).toList()
    );
  }

}

class Product extends CatalogItem {
  String? modelNumber;
  List<Image> productImages;
  String? description;
  List<Map<String, dynamic>>? brochure;
  static const String buttonRoute = '/product';

  Product({
    required super.name,
    super.parentId,
    super.id,
    List<Image>? productImages,
    this.modelNumber,
    this.description,
    this.brochure,
  }) 
  : productImages = productImages ??= [Image.asset('assets/weightech_logo.png', width: double.infinity, fit: BoxFit.fitWidth,)], 
    super(image: productImages[0]);

  //
  // Maps the list of brochure items to the brochure json structure. 
  //
  // TODO: This needs to be rewritten after the BrochureItem update. It's really inefficient code. -JT
  //
  static List<Map<String, dynamic>> mapListToBrochure(List<BrochureItem> brochure) {

    List<String> entries = [];
    List<dynamic> subheaders = [];
    final List<Map<String, dynamic>> brochureMap = [];

    for (var item in brochure.reversed) {
      switch (item) {
        case BrochureEntry _: {
          entries.insert(0, item.entry);
        }
        case BrochureSubheader _: {
          subheaders.insert(0, {item.subheader : List<String>.from(entries)}
          );
          entries.clear();
        }
        case BrochureHeader _: {
          if (entries.isNotEmpty && subheaders.isNotEmpty){
            brochureMap.insert(0, {item.header : [{"Entries" : List.from(entries)}, List.from(subheaders)]});
          }
          else if (entries.isNotEmpty) {
            brochureMap.insert(0, {item.header : [{"Entries" : List.from(entries)}]});
          }
          else if (subheaders.isNotEmpty) {
            brochureMap.insert(0, {item.header : List.from(subheaders)});
          }
          else {
            brochureMap.insert(0, {item.header : []});
          }
          subheaders.clear();
          entries.clear();
        }
      }
    }

    return brochureMap;
  }

  List<BrochureItem> retrieveBrochureList() {
    List<BrochureItem> brochureList = [];

    if (brochure == null) {
      return brochureList;
    }
    else {
      for (var mapItem in brochure!) {
        String key = mapItem.keys.first;
        brochureList.add(BrochureHeader(header: key));
        if (mapItem[key] is List) {
          for (var item in mapItem[key]) {
            item.forEach((key, value) {
              if (key == "Entries") {
                for (var entry in value) {
                  brochureList.add(BrochureEntry(entry: entry));
                }
              }
              else {
                String subKey = key;
                brochureList.add(BrochureSubheader(subheader: subKey));
                for (var entry in item[subKey]) {
                  brochureList.add(BrochureEntry(entry: entry));
                }
              }
            });
          }
        }
        else if (mapItem[key] is Map) {
          mapItem[key].forEach((key, value) {
            if (key == "Entries") {
              for (var entry in value) {
                brochureList.add(BrochureEntry(entry: entry));
              }
            }
            else {
              String subKey = key;
              brochureList.add(BrochureSubheader(subheader: subKey));
              for (var entry in mapItem[key][subKey]) {
                brochureList.add(BrochureEntry(entry: entry));
              }
            }
          });
        }
      }
    }

    return brochureList;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();
    json['modelNumber'] = modelNumber;
    json['productImages'] = productImages.map((image) => image.toString()).toList();
    json['description'] = description;
    json['brochure'] = brochure;
    json['parentId'] = parentId;
    return json;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      id: json['id'],
      modelNumber: json['modelNumber'],
      description: json['description'],
      brochure: json['brochure'],
      parentId: json['parentId']
    );
  }
}


sealed class EItem {
  late int rank;
  EItem({required this.rank});

  static ECategory createEditorCatalog(ProductCategory catalogCopy) {

    ECategory traverseCategory(category, rank) {
      List<EItem> editorItems = [];

      for (var item in category.catalogItems) {
        switch (item) {
          case ProductCategory _ : {
            ECategory newItem = traverseCategory(item, rank+1);
            editorItems.add(newItem);
          }
          case Product _ : {
            editorItems.add(EProduct(product: item, rank: rank));
          }
        }
      }

      return ECategory(category: category, editorItems: editorItems, rank: rank-1);
    }


    return traverseCategory(catalogCopy, 0);
  }

  static EItem? getItemById({required root, required id}) {
    EItem? result;

    void traverseItems(ECategory category) {
      if (category.id == id) {
        result = category;
        return;
      }
      for (var item in category.editorItems) {
        switch (item) {
          case ECategory _: {
            traverseItems(item);
            if (result != null) {
              return;
            }
          }
          case EProduct _: {
            if (item.id == id) {
              result = item;
            }
          }
        }
      }
    }

    traverseItems(root);

    return result;
  }

  ECategory? getParent({required root});
}

class ECategory extends EItem {
  final ProductCategory category;
  final String id;
  final String? parentId;
  late List<EItem> editorItems;
  bool showChildren = false;
  ECategory({required this.category, required this.editorItems, required super.rank}) : id = category.id, parentId = category.parentId;

  bool open = false;
  bool previousOpen = false; 

  
  Widget buildListTile({int? index, VoidCallback? onArrowCallback, VoidCallback? onEditCallback, VoidCallback? onDragStarted, VoidCallback? onDragCompleted, TickerProvider? ticker}) {
    Tween<double>? closeTween;
    Tween<double>? openTween;
    AnimationController? controller; 


    if (ticker != null) {
      closeTween = Tween<double>(begin: 1, end: 0.75);
      openTween = Tween<double>(begin: 0.75, end: 1);
      controller = AnimationController(vsync: ticker, duration: const Duration(milliseconds: 100));
      controller.forward();
    }

    return DragTarget<EItem>(
      onWillAcceptWithDetails: (details) {
        return (!editorItems.contains(details.data) && details.data != this);
      },
      onAcceptWithDetails: (details) {
        details.data.rank += 1;
        editorItems.add(details.data);
      },
      builder: (context, accepted, rejected) {
        return Draggable<EItem> (
          data: this,
          onDragStarted: () {
            if (onDragStarted != null) onDragStarted();
          },
          onDragCompleted: () {
            if (onDragCompleted != null) onDragCompleted();
          },
          feedback: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(10),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.move_up),
                  const SizedBox(width: 5),
                  Text(category.name)
                ]
              )
            )
          ),
          child: InkWell(
            onTap: () {
              previousOpen = open;
              if (onEditCallback != null) {onEditCallback();}
            },
            child: ListTile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onArrowCallback != null) 
                    open ?
                      InkWell(
                        onTap: () {
                          open = false;
                          previousOpen = true;
                          onArrowCallback();
                        }, 
                        child: (open == previousOpen) ? 
                          const Icon(Icons.keyboard_arrow_down)
                          : (openTween != null) ? 
                            RotationTransition(turns: openTween.animate(controller!), child: const Icon(Icons.keyboard_arrow_down)) 
                            : const Icon(Icons.keyboard_arrow_down)
                      )
                      : InkWell(
                        onTap: () {
                          open = true; 
                          previousOpen = false;
                          onArrowCallback();
                        },
                        child: (open == previousOpen) ? 
                          Transform.rotate(angle: -math.pi/2, child: const Icon(Icons.keyboard_arrow_down))
                          : (closeTween != null) ? 
                            RotationTransition(turns: closeTween.animate(controller!), child: const Icon(Icons.keyboard_arrow_down)) 
                            : const Icon(Icons.keyboard_arrow_down),
                      ),
                  const Icon(Icons.folder_outlined, size: 20),
                  const SizedBox(width: 5),
                  Expanded(child: Text(category.name, style: const TextStyle(color: Colors.black, fontSize: 14.0))),
                ]
              ),
              //subtitle: const Text("Category", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic)),
              trailing: (index != null) ? ReorderableDelayedDragStartListener(index: index, child: const Icon(Icons.drag_handle)) : const SizedBox(),
            )
          )
        );
      }
    );
  }

  @override
  ECategory? getParent({required root}) {
    return EItem.getItemById(root: root, id: parentId) as ECategory;
  }

  List<ECategory> getSubCategories() {
    List<ECategory> subCategories = [];

    void traverseCategories(ECategory category) {
      subCategories.add(category); // Add the current category to the list

      // Traverse subcategories recursively
      for (var item in category.editorItems) {
        if (item is ECategory) {
          traverseCategories(item);
        }
      }
    }

    traverseCategories(this);

    return subCategories;
  }
}

class EProduct extends EItem {
  final Product product;
  final String id;
  final String? parentId;
  EProduct({required this.product, required super.rank}) : id = product.id, parentId = product.parentId;


  Widget buildListTile({int? index, VoidCallback? onEditCallback, VoidCallback? onDragCompleted}) {
    return Draggable<EItem> (
      data: this,
      onDragCompleted: () {
        if (onDragCompleted != null) onDragCompleted();
      },
      feedback: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(10),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              const Icon(Icons.move_up),
              const SizedBox(width: 5),
              Text(product.name)
            ]
          )
        )
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      child: 
        InkWell(
          onTap: () {
            if (onEditCallback != null) {onEditCallback();}
          },
          child: ListTile(
            title: Row(
              children: [
                const Icon(Icons.conveyor_belt, size: 20,),
                const SizedBox(width: 10),
                Expanded(child: Text(product.name, style: const TextStyle(color: Colors.black, fontSize: 14.0))), 
              ]  
            ),
            // subtitle: const Padding(
            //   padding: EdgeInsets.only(left: 30), 
            //   child: Text("Product", style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic)),
            // ),
            trailing: (index != null) ? ReorderableDelayedDragStartListener(index: index, child: const Icon(Icons.drag_handle)) : const SizedBox(),
          )
        )
    );
  }

  @override
  ECategory? getParent({required root}) {
    return EItem.getItemById(root: root, id: parentId) as ECategory;
  }
}


sealed class BrochureItem {
  Widget buildItem(BuildContext context);
}

class BrochureHeader implements BrochureItem {
  String header;
  List<BrochureItem> items;
  final TextEditingController controller;

  BrochureHeader({required this.header}) : controller = TextEditingController(text: header), items = [];
  BrochureHeader.basic() : header="New Header", controller = TextEditingController(), items = [];

  @override
  Widget buildItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.menu, size: 30,), 
      title: TextFormField(
        controller: controller, 
        decoration: 
          const InputDecoration(
            label: Text("Header")
          ),
        validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      )
    );
  }
}

class BrochureSubheader implements BrochureItem {
  String subheader;
  List<BrochureEntry> entries;
  final TextEditingController controller;

  BrochureSubheader({required this.subheader}) : controller = TextEditingController(text: subheader), entries = [];
  BrochureSubheader.basic() : subheader="New Subheader", controller = TextEditingController(), entries = [];

  @override
  Widget buildItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50), 
      child: ListTile(
        leading: const Icon(Icons.drag_handle, size: 30), 
        title: TextFormField(
          controller: controller, 
          decoration: 
            const InputDecoration(
              label: Text("Subheader")
            ),
          validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          textCapitalization: TextCapitalization.words, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,)
        ),
      )
    );
  }
}

class BrochureEntry implements BrochureItem {
  String entry;
  final TextEditingController controller;

  BrochureEntry({required this.entry}) : controller = TextEditingController(text: entry);

  BrochureEntry.basic() : entry="New Entry", controller = TextEditingController();

  @override
  Widget buildItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 100), 
      child: 
        ListTile(
          leading: const Icon(Icons.menu, size: 30), 
          title: TextFormField(
            controller: controller,
            decoration: 
              const InputDecoration(
                label: Text("Entry")
              ),
            validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          )
        )
    );
  }
}