import 'package:feedback/feedback.dart';
import 'dart:async';
import 'package:weightechapp/themes.dart';
import 'package:updat/updat.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return DefaultTextEditingShortcuts(
      child: Stack(
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
                                  highlightColor: Colors.white,
                                  onChanged: (value) {
                                    _feedbackText = value;
                                  },
                                ),
                            ),
                            // // Added the below as a quick fix for https://github.com/ueman/feedback/issues/281
                            // InkWell(
                            //   child: const Icon(Icons.keyboard_backspace),
                            //   onTap: () {
                            //     if (controller.text != '') {
                            //       controller.text = controller.text.substring(0, controller.text.length-1);
                            //     }
                            //   }
                            // ),
                            // const SizedBox(width: 4),
                            // InkWell(
                            //   child: const Icon(Icons.clear),
                            //   onTap: () => setState(() => controller.text = '')
                            // )
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
                : FilledButton(
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
      )
    );
  }
}


Widget fluentChip({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {

  if (UpdatStatus.checking == status) {
    return const Text("Checking for update...");
  }

  if (UpdatStatus.upToDate == status) {
    return const Text("Up to date!");
  }

  if (UpdatStatus.error == status) {
    return const Text("Error downloading update!");
  }

  if (UpdatStatus.downloading == status) {
    return Card(
      child: Container(
        height: 200,
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Downloading Update",
              style: FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 8),
            Text("The newest app version is downloading...",
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 10),
            const Center(child: ProgressBar()),
          ]
        )
      )
    );
  }

  if (UpdatStatus.readyToInstall == status) {
    return Card(
      child: Container(
        height: 200,
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Installer Running",
              style: FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 8),
            Text("The installer should be open on your device.\nFollow the instructions to install the newest version.",
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 8),
            Button(
              onPressed: dismissUpdate,
              child: const Text('Skip update'),
            )
          ]
        )
      )
    );
  }

  if (UpdatStatus.available == status || UpdatStatus.availableWithChangelog == status) {
    return Card(
      child: Container(
        height: 200,
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update Ready",
              style: FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 8),
            Text(
              "Version ${latestVersion.toString()} is now ready to be installed!",
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 8),
            Text(
              "You are currently running version $appVersion.",
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 8),
            Text(
              "Update now to get the latest features and fixes.",
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Button(
                  onPressed: dismissUpdate,
                  child: const Text('Later'),
                ),
                const SizedBox(width: 10),
                if (UpdatStatus.availableWithChangelog == status)
                  ... [
                    Button(
                      onPressed: openDialog,
                      child: const Text('View Changelog')
                    ),
                    const SizedBox(width: 10),
                  ],
                FilledButton(
                  onPressed: startUpdate,
                  child: const Row(
                    children: [
                      Icon(FluentIcons.arrow_download_20_regular),
                      SizedBox(width: 2),
                      Text('Download Now')
                    ]
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return Container();
}

void fluentUpdateDialog({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required String? changelog,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {

  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: (latestVersion != null) ? Text('Version $latestVersion available') : const Text('Update available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current version: $appVersion'),
          const SizedBox(height: 10),
          Text('New Version: ${latestVersion!.toString()}'),
          const SizedBox(height: 10),
          if (status == UpdatStatus.availableWithChangelog) ...[
            Text(
              'Changelog:',
              style: FluentTheme.of(context).typography.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(changelog!,),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        Button(
          child: const Text('Close'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            startUpdate();
          },
          child: const Text('Update Now'),
        ),
      ],
    ),
  );
}