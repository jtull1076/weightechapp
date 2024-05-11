import 'dart:math' as math;
import 'package:feedback/feedback.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as fluent_icons;


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
                              TextBox(
                                maxLines: null,
                                controller: controller,
                                onChanged: (value) {
                                  _feedbackText = value;
                                },
                              ),
                          ),
                          // Added the below as a quick fix for https://github.com/ueman/feedback/issues/281
                          IconButton(
                            icon: const Icon(FluentIcons.delete),
                            onPressed: () {
                              if (controller.text != '') {
                                controller.text = controller.text.substring(0, controller.text.length-1);
                              }
                            }
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(FluentIcons.clear),
                            onPressed: () => setState(() => controller.text = '')
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
              const ProgressRing()
              : Button(
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