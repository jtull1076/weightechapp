import 'package:flutter/material.dart';


class ProductManager extends ChangeNotifier {
  static final ProductCategory all = ProductCategory.all();

  ProductManager() {
    all.addCategory(
      ProductCategory(
        name: "Microweigh Indicators",
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
        parent: all,
      ),
    );
    all.addProduct(
      Product(
        name: "Portion Scale",
        image: Image.asset(
          'assets/product_images/qa-new.jpg',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
        category: all,
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
        image: Image.asset(
          'assets/product_images/sizer.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
        category: all,
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
        name: "Trimline Station",
        image: Image.asset(
          'assets/product_images/trimline_station.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
        category: all,
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
        category: all.getItemByName("Indicators"),
        image: Image.asset(
          'assets/product_images/microweigh_indicators.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
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
      for (var subcategory in category.subcategories) {
        traverseCategories(subcategory);
      }
    }

    traverseCategories(root);

    return allCategories;
  }

}


class ProductCategory {
  late String name;
  ProductCategory? parent;
  late List<ProductCategory> subcategories;
  late List<Product> products;
  Image? image;
  static const String buttonRoute = '/listing';

  ProductCategory({
    required this.name,
    required parent,
    List<ProductCategory>? subcategories,
    List<Product>? products,
    Image? image,
  }) : subcategories = subcategories ?? [], products = products ?? [], image = image ?? Image.asset('assets/weightech_logo.png', width: double.infinity, fit: BoxFit.fitWidth );

  ProductCategory.all() : name='All', subcategories = [], products = [];

  // Function to add a product to the list
  void addProduct(Product product) {
    products.add(product);
  }

  void addCategory(ProductCategory category){
    subcategories.add(category);
  }

  // Function to remove a product from the list
  void removeProduct(Product product) {
    products.remove(product);
  }

  void removeCategory(ProductCategory category){
    subcategories.remove(category);
  }

  // Function to get all products
  List<Product> getAllProducts() {
    return products;
  }

  List<dynamic> getAllCatalogItems() {
    List<dynamic> catalogItems = [];
    catalogItems.addAll(subcategories);
    catalogItems.addAll(products);
    return catalogItems;
  }

  dynamic getItemByName(String? name) {
    if (name == null || name.isEmpty) {
      // Handle null argument
      return null;
    }

    // Check if the item exists in subcategories
    for (var category in subcategories) {
      if (category.name == name) {
        return category;
      }
    }

    // Check if it exists in products
    for (var product in products) {
      if (product.name == name) {
        return product;
      }
    }

    // If the item is not found in subcategories or products, return null
    return null;
  }
}


class Product {
  String name;
  String? modelNumber;
  double? price;
  ProductCategory? category;
  Image? image;
  String? description;
  List<Map<String, dynamic>>? brochure;
  static const String buttonRoute = '/product';

  Product({
    required this.name,
    this.modelNumber,
    this.price,
    this.category,
    Image? image,
    this.description,
    this.brochure,
  }) : image = image ?? Image.asset('assets/weightech_logo.png', width: double.infinity, fit: BoxFit.fitWidth,);

  static List<Map<String, dynamic>> mapListToBrochure(List<BrochureItem> brochure) {

    List<String> entries = [];
    List<dynamic> subheaders = [];
    final List<Map<String, dynamic>> brochureMap = [];

    for (var item in brochure.reversed) {
      switch (item.runtimeType) {
        case BrochureEntry : {
          entries.add((item as BrochureEntry).entry);
        }
        case BrochureSubheader : {
          subheaders.add(
            {
              (item as BrochureSubheader).subheader : List<String>.from(entries.reversed)
            }
          );
          entries.clear();
        }
        case BrochureHeader : {
          if (entries.isNotEmpty && subheaders.isNotEmpty){
            brochureMap.add({(item as BrochureHeader).header : [{"Entries" : entries}, subheaders]});
          }
          else if (entries.isNotEmpty) {
            brochureMap.add({(item as BrochureHeader).header : {"Entries" : entries}});
          }
          else if (subheaders.isNotEmpty) {
            brochureMap.add({(item as BrochureHeader).header : subheaders});
          }
          else {
            brochureMap.add({(item as BrochureHeader).header : []});
          }
          subheaders.clear();
          entries.clear();
        }
      }
    }

    return brochureMap;
  }
}


class CatalogItemTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTapCallback;

  const CatalogItemTile({super.key, required this.item, required this.onTapCallback});

  @override
  Widget build(BuildContext context) {
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
                      Hero(tag: '${item.name}_htag', child: item.image),
                  ),
              ),
              Text(item.name ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, color: Colors.black)), // Handle if name is null
              const SizedBox(height: 10),
            ],
          ),
          Positioned.fill(
            child: 
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    debugPrint('Item tapped: ${item.name}');
                    onTapCallback();
                  }
                )
              )
          )
        ]
      )
    );
  }
}


abstract class BrochureItem {
  Widget buildItem(BuildContext context);
}

class BrochureHeader implements BrochureItem {
  String header;
  final TextEditingController controller;

  BrochureHeader({required this.header}) : controller = TextEditingController(text: header);
  BrochureHeader.basic() : header="New Header", controller = TextEditingController();

  @override
  Widget buildItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.menu, size: 30,), 
      title: TextFormField(
        controller: controller, 
        decoration: 
          InputDecoration(
            label: Text(header)
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
  final TextEditingController controller;

  BrochureSubheader({required this.subheader}) : controller = TextEditingController(text: subheader);
  BrochureSubheader.basic() : subheader="New Subheader", controller = TextEditingController();

  @override
  Widget buildItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50), 
      child: ListTile(
        leading: const Icon(Icons.menu, size: 30), 
        title: TextFormField(
          controller: controller, 
          decoration: 
            InputDecoration(
              label: Text(subheader)
            ),
          validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          textCapitalization: TextCapitalization.words, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,)
        )
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
              InputDecoration(
                label: Text(entry)
              ),
            validator: (String? value) => (value == null) ? 'Cannot be empty.' : null,
          )
        )
    );
  }
}