
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:weightechapp/models.dart';
import 'package:weightechapp/utils.dart';
import 'package:weightechapp/universal_routes.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:upgrader/upgrader.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> with TickerProviderStateMixin {
  late String _startupTaskMessage;
  late StreamController<String> _progressStreamController;
  late bool _updateReady;
  late bool _checkingForUpdate;

  @override
  void initState() {
    super.initState();
    _startupTaskMessage = '';
    _progressStreamController = StreamController<String>();
    _updateReady = false;
    _checkingForUpdate = false;
    _runStartupTasks();
  }

  Future<void> _runStartupTasks() async { 

    try {
      Log.logger.t('...Clearing existing cache');
      _progressStreamController.add('...Clearing cache...');
      await FileUtils.cacheManager.emptyCache();

      Log.logger.t('...Initializing Firebase...');
      _progressStreamController.add('...Initializing Firebase...');
      await FirebaseUtils().init();

      Log.logger.t('...Initializing Product Manager...');
      _progressStreamController.add('...Initializing Product Manager...');

      await ProductManager.create();

      Log.logger.t('...Precaching images...');
      _progressStreamController.add('...Caching images...');
      if (mounted) {
        await ProductManager.precacheImages(context);
      }

      Log.logger.t('...App Startup...');
      _progressStreamController.add('...App Startup...');
    } catch (e, stackTrace) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => ErrorPage(message: e.toString())));
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _progressStreamController.close();
      Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (BuildContext context, _, __) => const IdlePage()));
    });
  }

  @override
  void dispose() {
    _progressStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Image.asset('assets/icon/wt_icon.ico', height: 200),
            ),
            const SizedBox(height: 10), 
            Text("App Version: ${AppInfo.packageInfo.version}"),
            Text(_startupTaskMessage),
            StreamBuilder(
              stream: _progressStreamController.stream,
              initialData: '',
              builder:(context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const CircularProgressIndicator(); // Or any loading indicator
                  }
                }
                else if (snapshot.connectionState == ConnectionState.done) {
                  return UpgradeAlert(
                    child: const Center(child: Text("...Checking for updates...")),
                  );
                }
                else {
                  return const Text("Other");
                }
              }
            )
          ]
        )
      )
    );
  }
}
