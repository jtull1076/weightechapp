import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons, TreeView;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:weightechapp/utils.dart';

extension BrochureTreeMixin on BrochureItem {
  void removeFromParent(root) {
      final BrochureItem? parent = getParent(root);

      if (parent != null) {
        if (parent is BrochureHeader) {
          parent.items.remove(this);
        }
        else if (parent is BrochureSubheader) {
          parent.entries.remove(this);
        }
      }
      else {
        root.remove(this);
      }
  }

  void reassignParent({required List<BrochureItem> root, required BrochureItem newParent, int? atIndex}) {
    removeFromParent(root);

    if (newParent is BrochureHeader) {
      (atIndex != null) ? newParent.items.insert(atIndex, this) : newParent.items.add(this);
    }
    else if (newParent is BrochureSubheader && this is BrochureEntry) {
      (atIndex != null) ? newParent.entries.insert(atIndex, this as BrochureEntry) : newParent.entries.add(this as BrochureEntry);
    }
  }

  void reorderItem({required List<BrochureItem> root, required int newIndex}) {
    final parent = getParent(root);
    if (parent is BrochureHeader) {
      if (parent.items.indexOf(this) <= newIndex) {
        newIndex -= 1;
      }
      removeFromParent(root);
      parent.items.insert(newIndex, this);
    }
    else if (parent is BrochureSubheader) {
      if (parent.entries.indexOf(this as BrochureEntry) <= newIndex) {
        newIndex -= 1;
      }
      removeFromParent(root);
      parent.entries.insert(newIndex, this as BrochureEntry);
    }
    else if (parent == null) {
      if (root.indexOf(this) <= newIndex) {
        newIndex -= 1;
      }
      root.remove(this);
      root.insert(newIndex, this);
    }
  }

  // Add a method to lazily find the parent node
  BrochureItem? getParent(List<BrochureItem> roots) {
    for (var root in roots) {
      if (_findParent(root, this) != null) {
        return _findParent(root, this);
      }
    }
    return null;
  }

  BrochureItem? _findParent(BrochureItem parent, BrochureItem child) {
    for (var item in parent.getChildren()) {
      if (item == child) {
        return parent;
      } else {
        var foundParent = _findParent(item, child);
        if (foundParent != null) {
          return foundParent;
        }
      }
    }
    return null;
  }
}

sealed class BrochureItem {
  String text;
  BrochureItem({required this.text});
  Widget buildListTile({Widget? leading, Widget? trailing});
  List<BrochureItem> getChildren(); 
}

class BrochureHeader implements BrochureItem {
  @override String text;
  late TextEditingController _controller;
  List<BrochureItem> items;
  final key = GlobalKey();
  BrochureHeader({this.text = 'Your header here.', List<BrochureItem>? items}) : items = items ?? [] {
    _controller = TextEditingController(text: text);
  }

  @override
  Widget buildListTile({Widget? leading, Widget? trailing}) {
    return ListTile(
      key: key,
      contentPadding: const EdgeInsets.all(0),
      title: TextBox(
        controller: _controller, 
        onChanged: (String newText) => text = newText,
        style: const TextStyle(
          color: Color(0xFF224190), 
          fontSize: 20, 
          fontWeight: FontWeight.w700
        ),
      ),
      leading: leading,
      trailing: trailing
    );
  }

  @override
  List<BrochureItem> getChildren() {
    return items;
  }
}

class BrochureSubheader implements BrochureItem {
  @override String text;
  late TextEditingController _controller;
  List<BrochureEntry> entries;
  final key = GlobalKey();
  BrochureSubheader({this.text = 'Your subheader here.', List<BrochureEntry>? entries}) : entries = entries ?? [] {
    _controller = TextEditingController(text: text);
  }

  @override
  Widget buildListTile({Widget? leading, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: ListTile(
        key: key,
        contentPadding: const EdgeInsets.all(0),
        title: TextBox(
          controller: _controller, 
          style: const TextStyle(fontSize: 16, color: Color(0xFF333333), fontWeight: FontWeight.w700)
        ),
        leading: leading,
        trailing: trailing
      )
    );
  }

  @override
  List<BrochureItem> getChildren() {
    return entries;
  }
}

class BrochureEntry implements BrochureItem {
  @override String text;
  late TextEditingController _controller;
  final key = GlobalKey();
  BrochureEntry({this.text = 'Your entry here.'}) {
    _controller = TextEditingController(text: text);
  }

  @override
  Widget buildListTile({Widget? leading, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ListTile(
        key: key,
        contentPadding: const EdgeInsets.all(0),
        title: TextBox(
          controller: _controller, 
          style: const TextStyle(fontSize: 14)
        ),
        leading: leading,
        trailing: trailing
      )
    );
  }

  @override
  List<BrochureItem> getChildren() {
    return [];
  }
}

//
// Maps the list of brochure items to the brochure json structure. 
//
List<Map<String, dynamic>> mapListToBrochure(List<BrochureItem> brochure) {
  List<String> entries = [];
  List<dynamic> subheaders = [];
  final List<Map<String, dynamic>> brochureMap = [];

  for (var item in brochure.reversed) {
    switch (item) {
      case BrochureEntry _: {
        entries.insert(0, item.text);
      }
      case BrochureSubheader _: {
        subheaders.insert(0, {item.text : List.from(entries)});
        entries.clear();
      }
      case BrochureHeader _: {
        if (entries.isNotEmpty && subheaders.isNotEmpty){
          brochureMap.insert(0, {item.text : [{"Entries" : List.from(entries)}, ...List.from(subheaders)]});
        }
        else if (entries.isNotEmpty) {
          brochureMap.insert(0, {item.text : [{"Entries" : List.from(entries)}]});
        }
        else if (subheaders.isNotEmpty) {
          brochureMap.insert(0, {item.text : List.from(subheaders)});
        }
        else {
          brochureMap.insert(0, {item.text : []});
        }
        subheaders.clear();
        entries.clear();
      }
    }
  }

  return brochureMap;
}

List<BrochureItem> flattenList(List<BrochureItem> brochure) {
  List<BrochureItem> brochureList = [];

  void addRecursive(BrochureItem item) {
    brochureList.add(item);
    for (BrochureItem subItem in item.getChildren()) {
      addRecursive(subItem);
    }
  }

  for (BrochureItem item in brochure) {
    addRecursive(item);
  }
  
  return brochureList;
}


Widget buildBrochureList({List<BrochureItem>? brochure,}) {
  brochure ??= [];
  int? brochureActiveIndex;

  return StatefulBuilder(
    builder: (context, setState) {
      if (brochure!.isNotEmpty) {
        return ReorderableListView.builder(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          footer: (brochureActiveIndex == -1) ?
            Container(
              padding: const EdgeInsets.only(top: 10),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Text('+Header', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => brochure!.add(BrochureHeader()));
                    }
                  ),
                  IconButton(
                    icon: const Text('+Subheader', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => brochure!.add(BrochureSubheader()));
                    }
                  ),
                  IconButton(
                    icon: const Text('+Entry', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => brochure!.add(BrochureEntry()));
                    }
                  )
                ]
              )
            )
            : null,
          itemBuilder: (context, index) {
            return MouseRegion(
              key: Key('$index'),
              onEnter: (onEnter) {
                setState(() {
                  brochureActiveIndex = index;
                });
              },
              onExit: (onExit) {
                setState(() {
                  brochureActiveIndex = -1;
                });
              },
              child: (index == brochureActiveIndex) 
                ? Column(
                  key: Key('$index'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    brochure![index].buildListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(FluentIcons.chevron_up_down_20_regular),
                      ),
                      trailing: (brochureActiveIndex == index) 
                        ? IconButton(
                          icon: const Icon(FluentIcons.delete_20_regular),
                          onPressed: () => setState(() => brochure!.removeAt(index)),
                        )
                        : null,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Text('+Header', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() => brochure!.insert(index+1, BrochureHeader()));
                          }
                        ),
                        IconButton(
                          icon: const Text('+Subheader', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() => brochure!.insert(index+1, BrochureSubheader()));
                          }
                        ),
                        IconButton(
                          icon: const Text('+Entry', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() => brochure!.insert(index+1, BrochureEntry()));
                          }
                        )
                      ]
                    )
                  ]
                )
                : brochure![index].buildListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(FluentIcons.chevron_up_down_20_regular),
                  ),
                  trailing: (brochureActiveIndex == index) 
                    ? IconButton(
                      icon: const Icon(FluentIcons.delete_20_regular),
                      onPressed: () => setState(() => brochure!.removeAt(index)),
                    )
                    : null,
                )
            );
          }, 
          itemCount: brochure.length, 
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > brochure!.length) newIndex = brochure.length;
              if (oldIndex < newIndex) newIndex--;
              final item = brochure.removeAt(oldIndex);
              brochure.insert(newIndex, item);
            });
          },
        );
      }
      else {
        return Column(
          children: [
            const Text(
              "The Brochure feature lets you organize information into sections."
              " You can type in headers and subheaders to outline different parts"
              " of your content, and entries beneath each subheader let you add"
              " detailed information. Simply tap on the text fields to fill in your"
              " content.",
              style: TextStyle(fontStyle: FontStyle.italic)
            ),
            Container(
              padding: const EdgeInsets.only(top: 10),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Text('+Header', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => brochure!.add(BrochureHeader()));
                    }
                  ),
                  IconButton(
                    icon: const Text('+Subheader', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => brochure!.add(BrochureSubheader()));
                    }
                  ),
                  IconButton(
                    icon: const Text('+Entry', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => brochure!.add(BrochureEntry()));
                    }
                  )
                ]
              )
            )
          ]
        );
      }
    }
  );
}


Widget buildBrochureTree({List<BrochureItem>? brochure}) {
  brochure ??= [];

  final TreeController<BrochureItem> controller = TreeController<BrochureItem>(
    roots: brochure,
    defaultExpansionState: true,
    childrenProvider: (node) => node.getChildren(),
    parentProvider: (node) => node.getParent(brochure!),
  );

  return AnimatedTreeView(
    treeController: controller,
    shrinkWrap: true,
    nodeBuilder: (BuildContext context, TreeEntry<BrochureItem> entry) {
      return TreeDragTarget<BrochureItem>(
      toggleExpansionDelay: const Duration(milliseconds: 750),
      canToggleExpansion: false,
      node: entry.node,
      onNodeAccepted: (TreeDragAndDropDetails details) {
        // Optionally make sure the target node is expanded so the dragging
        // node is visible in its new vicinity when the tree gets rebuilt.
        // _treeController.setExpansionState(details.targetNode as EItem, true);

        // TODO: implement your tree reorder logic
        final targetNode = details.targetNode as BrochureItem;
        final draggedNode = details.draggedNode as BrochureItem;
        final targetParent = targetNode.getParent(brochure!);

        if (targetParent == draggedNode.getParent(brochure)) {
          details.mapDropPosition(
            whenAbove: () {
              int newIndex = 0;
              if (targetParent != null) {
                newIndex = targetParent.getChildren().indexOf(targetNode);
              }
              else {
                newIndex = brochure!.indexOf(targetNode);
              }
              draggedNode.reorderItem(root: brochure!, newIndex: newIndex);
            }, 
            whenInside: () {
              if (targetNode is BrochureHeader || targetNode is BrochureSubheader) {
                (draggedNode).reassignParent(root: brochure!, newParent: targetNode);
              }
            }, 
            whenBelow: () {
              if (entry.isExpanded) {
                if (targetNode is BrochureHeader || targetNode is BrochureSubheader) {
                  draggedNode.reassignParent(root: brochure!, newParent: targetNode, atIndex: 0);
                }
              }
              else {
                int targetIndex = 0;
                if (targetParent != null) {
                  targetIndex = targetParent.getChildren().indexOf(targetNode);
                }
                else {
                  targetIndex = brochure!.indexOf(targetNode);
                }
                draggedNode.reorderItem(root: brochure!, newIndex: targetIndex + 1);
              }
            }, 
          );
        }
        else {
          details.mapDropPosition(
            whenAbove: () {
              int newIndex = 0;
              if (targetParent != null) {
                newIndex = targetParent.getChildren().indexOf(targetNode);
              }
              else {
                newIndex = brochure!.indexOf(targetNode);
              }
              (draggedNode).reassignParent(root: brochure!, newParent: targetNode, atIndex: newIndex);
            }, 
            whenInside: () {
              if (targetNode is BrochureHeader || targetNode is BrochureSubheader) {
                (draggedNode).reassignParent(root: brochure!, newParent: targetNode);
              }
            }, 
            whenBelow: () {
              if (entry.isExpanded) {
                if (targetNode is BrochureHeader || targetNode is BrochureSubheader) {
                  (draggedNode).reassignParent(root: brochure!, newParent: targetNode, atIndex: 0);
                }
              }
              else {
                int newIndex = 0;
                if (targetParent != null) {
                  newIndex = targetParent.getChildren().indexOf(targetNode);
                }
                else {
                  newIndex = brochure!.indexOf(targetNode);
                }
                (draggedNode).reassignParent(root: brochure!, newParent: targetNode, atIndex: newIndex + 1);
              }
            }, 
          );
        }

        // Make sure to rebuild your tree view to show the reordered nodes
        // in their new vicinity.
        controller.rebuild();
      },
      builder: (BuildContext context, TreeDragAndDropDetails? details) {

        // If details is not null, a dragging tree node is hovering this
        // drag target. Add some decoration to give feedback to the user.
        Decoration? decoration;
        const borderSide = BorderSide(color: Color(0xFF9E9E9E), width: 1.5);


        if (details != null) {
          // Add a border to indicate in which portion of the target's height
          // the dragging node will be inserted.
          decoration = BoxDecoration(
            border: details.mapDropPosition(
              whenAbove: () => const Border(top: borderSide),
              whenInside: () => (entry.node is BrochureHeader || entry.node is BrochureSubheader) ? const Border.fromBorderSide(borderSide) : null,
              whenBelow: () => entry.isExpanded ? null : const Border(bottom: borderSide),
            ),
          );
        }

        return TreeIndentation(
          guide: const IndentGuide.connectingLines(
            thickness: 2,
            indent: 50
          ),
          entry: entry,
          child: TreeDraggable<BrochureItem>(
            node: entry.node,
            childWhenDragging: null,
            collapseOnDragStart: false,
            dragAnchorStrategy: (draggable, context, position) => childDragAnchorStrategy(draggable, context, position),
            //longPressDelay: const Duration(milliseconds: 300),

            // Show some feedback to the user under the dragging pointer,
            // this can be any widget.
            feedback: Container(
              color: Colors.white,
              height: 50,
              width: 250,
              child: entry.node.buildListTile()
            ),
            child: Container(
              decoration: decoration,
              child: entry.node.buildListTile(
              ),
            )
          )
        );
      },);
    },
  );
}