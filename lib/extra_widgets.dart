import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:feedback/feedback.dart';
import 'dart:async';
import 'package:weightechapp/themes.dart';

class FullScreenWidget extends StatelessWidget {
  const FullScreenWidget(
      {required this.child,
      super.key,
      this.backgroundColor = Colors.black,
      this.backgroundIsTransparent = true,
      required this.disposeLevel});

  final Widget child;
  final Color backgroundColor;
  final bool backgroundIsTransparent;
  final DisposeLevel disposeLevel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(
                opaque: false,
                barrierColor: backgroundIsTransparent
                    ? Colors.white.withOpacity(0)
                    : backgroundColor,
                pageBuilder: (BuildContext context, _, __) {
                  return FullScreenPage(
                    backgroundColor: backgroundColor,
                    backgroundIsTransparent: backgroundIsTransparent,
                    disposeLevel: disposeLevel,
                    child: child,
                  );
                }));
      },
      child: child,
    );
  }
}

enum DisposeLevel { high, medium, low }

class FullScreenPage extends StatefulWidget {
  const FullScreenPage(
      {required this.child,
      super.key,
      this.backgroundColor = Colors.black,
      this.backgroundIsTransparent = true,
      this.disposeLevel = DisposeLevel.medium});

  final Widget child;
  final Color backgroundColor;
  final bool backgroundIsTransparent;
  final DisposeLevel disposeLevel;

  @override
  FullScreenPageState createState() => FullScreenPageState();
}

class FullScreenPageState extends State<FullScreenPage> {
  double initialPositionY = 0;

  double currentPositionY = 0;

  double positionYDelta = 0;

  double opacity = 1;

  double disposeLimit = 150;

  Duration animationDuration = Duration.zero;


  @override
  void initState() {
    super.initState();
    setDisposeLevel();
  }

  setDisposeLevel() {
    setState(() {
      if (widget.disposeLevel == DisposeLevel.high) {
        disposeLimit = 300;
      }
      else if (widget.disposeLevel == DisposeLevel.medium) {
        disposeLimit = 200;
      }
      else {
        disposeLimit = 100;
      }
    });
  }

  void _startVerticalDrag(details) {
    setState(() {
      initialPositionY = details.globalPosition.dy;
    });
  }

  void _whileVerticalDrag(details) {
    setState(() {
      currentPositionY = details.globalPosition.dy;
      positionYDelta = currentPositionY - initialPositionY;
      setOpacity();
    });
  }

  setOpacity() {
    double tmp = positionYDelta < 0
        ? 1 - ((positionYDelta / 1000) * -1)
        : 1 - (positionYDelta / 1000);

    if (tmp > 1) {
      opacity = 1;
    }
    else if (tmp < 0) {
      opacity = 0;
    }
    else {
      opacity = tmp;
    }
    if (positionYDelta > disposeLimit || positionYDelta < -disposeLimit) {
      opacity = 0.5;
    }
  }

  _endVerticalDrag(DragEndDetails details) {
    if (positionYDelta > disposeLimit || positionYDelta < -disposeLimit) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        animationDuration = const Duration(milliseconds: 300);
        opacity = 1;
        positionYDelta = 0;
      });

      Future.delayed(animationDuration).then((_){
        setState(() {
          animationDuration = Duration.zero;
        });
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundIsTransparent
          ? Colors.transparent
          : widget.backgroundColor,
      body: GestureDetector(
        onVerticalDragStart: (details) => _startVerticalDrag(details),
        onVerticalDragUpdate: (details) => _whileVerticalDrag(details),
        onVerticalDragEnd: (details) => _endVerticalDrag(details),
        child: Container(
          color: widget.backgroundColor.withOpacity(opacity),
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: animationDuration,
                curve: Curves.fastOutSlowIn,
                top: 0 + positionYDelta,
                bottom: 0 - positionYDelta,
                left: 0,
                right: 0,
                child: widget.child,
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, top: 30),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: WeightechThemes.weightechBlue,
                    iconSize: 30,
                    onPressed: () {
                      setState(() {
                        animationDuration = const Duration(milliseconds: 300);
                        opacity = 0.5;
                      });
                      Navigator.of(context).pop();
                    },
                  )
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}


@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeInQuint,
      reverseCurve: Curves.easeInQuint,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: 
      SizedBox.expand(
        child: Stack(
          alignment: Alignment.bottomRight,
          clipBehavior: Clip.none,
          children: [
            _buildTapToCloseFab(),
            ..._buildExpandingActionButtons(),
            _buildTapToOpenFab(),
          ],
        ),
      )
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 70.0 / (count - 1);
    for (var i = 0, angleInDegrees =  10.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToCloseFab() {
    return Container(
      padding: const EdgeInsets.all(25),
      width: 80,
      height: 80,
      child: Center(
        child: Material(
          color: const Color(0xFFA0A0A2),
          shape: const CircleBorder(),
          shadowColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(0),
              child: const Icon(
                Icons.close,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.8 : 1.0,
          _open ? 0.8 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child:  AnimatedRotation(
          turns: _open ? 0.875 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 80,
            height: 80,
            child: Center(
              child: Material(
                color: const Color(0xFFA0A0A2),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                child: InkWell(
                  onTap: _toggle,
                  child: Transform.rotate(
                    angle: 45*math.pi/180,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  )
                ),
              ),
            ),
          )
        ),
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF808082),
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: theme.colorScheme.onSecondary,
        mouseCursor: SystemMouseCursors.click,
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 20 + offset.dx,
          bottom: 20 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}


/// A form that prompts the user for the type of feedback they want to give,
/// free form text feedback, and a sentiment rating.
/// The submit button is disabled until the user provides the feedback type. All
/// other fields are optional.
class CustomFeedbackForm extends StatefulWidget {
  const CustomFeedbackForm({
    super.key,
    required this.onSubmit,
    required this.scrollController,
  });

  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  @override
  State<CustomFeedbackForm> createState() => _CustomFeedbackFormState();
}

class _CustomFeedbackFormState extends State<CustomFeedbackForm> {
  late TextEditingController controller;
  late bool _loading;
  late String _feedbackText;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    _feedbackText = '';
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    controller: widget.scrollController,
                    // Pad the top by 20 to match the corner radius if drag enabled.
                    padding: EdgeInsets.fromLTRB(
                        50, widget.scrollController != null ? 20 : 16, 50, 0),
                    children: <Widget>[
                      Text(
                        FeedbackLocalizations.of(context).feedbackDescriptionText,
                        maxLines: 2,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: 
                              TextField(
                                maxLines: null,
                                controller: controller,
                                onChanged: (value) {
                                  _feedbackText = value;
                                },
                              ),
                          ),
                          // Added the below as a quick fix for https://github.com/ueman/feedback/issues/281
                          InkWell(
                            child: const Icon(Icons.keyboard_backspace),
                            onTap: () {
                              if (controller.text != '') {
                                controller.text = controller.text.substring(0, controller.text.length-1);
                              }
                            }
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            child: const Icon(Icons.clear),
                            onTap: () => setState(() => controller.text = '')
                          )
                        ]
                      )
                    ],
                  ),
                  if (widget.scrollController != null)
                    const FeedbackSheetDragHandle(),
                ],
              ),
            ),
            _loading ?
              const CircularProgressIndicator()
              : TextButton(
                key: const Key('submit_feedback_button'),
                onPressed: _feedbackText.isNotEmpty ? 
                  () async {
                    setState(() => _loading = true);
                    await widget.onSubmit(controller.text);
                    setState(() => _loading = false);
                  }
                  : null,
                child: Text(
                  FeedbackLocalizations.of(context).submitButtonText,
                ),
              ),
            const SizedBox(height: 15),
          ],
        ),
      ]
    );
  }
}



// ///
// /// Below is taken from https://github.com/defuncart/feedback_github/
// /// Only copied to make asynchronous for progress indicator.
// ///

// /// This is an extension to make it easier to call
// /// [showAndUploadToGitHub].
// extension BetterFeedbackX on FeedbackController {
//   /// Example usage:
//   /// ```dart
//   /// import 'package:feedback_github/feedback_github.dart';
//   ///
//   /// RaisedButton(
//   ///   child: Text('Click me'),
//   ///   onPressed: (){
//   ///     BetterFeedback.of(context).showAndUploadToGitHub
//   ///       username: 'username',
//   ///       repository: 'repository',
//   ///       authToken: 'github_pat_token',
//   ///       labels: ['feedback'],
//   ///       assignees: ['dash'],
//   ///       customMarkdown: '**Hello World**',
//   ///       imageId: 'unique-id',
//   ///     );
//   ///   }
//   /// )
//   /// ```
//   ///
//   /// The API token (Personal Access Token) needs access to:
//   ///   - issues (write)
//   ///   - content (write)
//   ///   - metadata (read)
//   ///
//   /// It is assumed that the branch `issue_images` exists for [repository]
//   FutureOr<void> UploadToGitHub({
//     required String username,
//     required String repository,
//     required String authToken,
//     List<String>? labels,
//     List<String>? assignees,
//     String? customMarkdown,
//     required String imageId,
//     String? githubUrl,
//     http.Client? client,
//   }) async {uploadToGitLab(
//       username: username,
//       repository: repository,
//       authToken: authToken,
//       labels: labels,
//       assignees: assignees,
//       customMarkdown: customMarkdown,
//       imageId: imageId,
//       githubUrl: githubUrl,
//       client: client,
//     );
//   }
// }

// /// See [BetterFeedbackX.showAndUploadToGitHub].
// /// This is just [visibleForTesting].
// @visibleForTesting
// OnFeedbackCallback uploadToGitLab({
//   required String username,
//   required String repository,
//   required String authToken,
//   List<String>? labels,
//   List<String>? assignees,
//   String? customMarkdown,
//   required String imageId,
//   String? githubUrl,
//   http.Client? client,
// }) {
//   final httpClient = client ?? http.Client();
//   final baseUrl = githubUrl ?? 'api.github.com';

//   return (UserFeedback feedback) async {
//     var uri = Uri.https(
//       baseUrl,
//       'repos/$username/$repository/issues',
//     );

//     // upload image to /issue_images branch
//     var response = await httpClient.put(
//       Uri.https(
//         baseUrl,
//         'repos/$username/$repository/contents/issue_images/$imageId.png',
//       ),
//       headers: {
//         'Accept': 'application/vnd.github+json',
//         'Authorization': 'Bearer $authToken',
//       },
//       body: jsonEncode({
//         'message': imageId,
//         'content': base64Encode(feedback.screenshot),
//         'branch': 'issue_images',
//       }),
//     );

//     if (response.statusCode == 201) {
//       final imageUrl = jsonDecode(response.body)['content']['download_url'];

//       // title contains first 20 characters of message, with a default for empty feedback
//       final title = feedback.text.length > 20
//           ? '${feedback.text.substring(0, 20)}...'
//           : feedback.text.isEmpty
//               ? 'New Feedback'
//               : feedback.text;
//       // body contains message and optional logs
//       final body = '''${feedback.text}
//         ![]($imageUrl)
//         ${customMarkdown ?? ''}
//         ''';

//       uri = Uri.https(
//         baseUrl,
//         'repos/$username/$repository/issues',
//       );

//       // https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28#create-an-issue
//       response = await httpClient.post(
//         uri,
//         headers: {
//           'Accept': 'application/vnd.github+json',
//           'Authorization': 'Bearer $authToken',
//         },
//         body: jsonEncode({
//           'title': title,
//           'body': body,
//           if (labels != null && labels.isNotEmpty) 'labels': labels,
//           if (assignees != null && assignees.isNotEmpty) 'assignees': assignees,
//         }),
//       );

//     }
//   };
// }