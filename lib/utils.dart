import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:core';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weightechapp/firebase_options.dart';
import 'package:shortid/shortid.dart';
import 'package:retry/retry.dart';

class AppInfo {
  static late PackageInfo packageInfo;
  static late String sessionId;
  AppInfo();
  
  Future<void> init() async {
    packageInfo = await PackageInfo.fromPlatform();
    sessionId = shortid.generate();
  }

  static int versionCompare(String newVersion, String currentVersion){
    List<String> currentV = currentVersion.split(".");
    List<String> newV = newVersion.split(".");
    bool deprecated = false;
    bool development = false;
    for (var i = 0 ; i <= 2; i++){
      deprecated = int.parse(newV[i]) > int.parse(currentV[i]);
      development = int.parse(newV[i]) < int.parse(currentV[i]);
      if(int.parse(newV[i]) != int.parse(currentV[i])) break;
    }
    if (deprecated) {
      return 1;
    }
    else if (development) {
      return 2;
    }
    else {
      return 0;
    }
  }
}

class Log {
  static late Logger logger;
  Log();

  Future<void> init() async {
    Directory appDocsDir = await getApplicationSupportDirectory();
    logger = Logger(
      filter: AppLogFilter(),
      printer: AppLogPrinter(),
      output: FileOutput(
        file: await File("${appDocsDir.path}/logs/app-${AppInfo.sessionId}.log").create(recursive: true))
    );
    Log.logger.t("...Logger initialized...");
    Log.logger.t(DateTime.now().toString());
  }
}

class AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (event.level.value >= Level.debug.value || event.level.name == "trace") {
      return true;
    }
    else {
      return false;
    }
  }
}

class AppLogPrinter extends PrettyPrinter {
  AppLogPrinter() 
  : super(
    excludeBox: {Level.info : true, Level.trace: true},
    methodCount: 0,
    errorMethodCount: 10,
    lineLength: 120,
    colors: true, 
    printEmojis: true
  );
}

class FirebaseUtils {
  static late FirebaseApp firebaseApp; // Initialize Firebase
  static late FirebaseFirestore database;
  static late FirebaseStorage storage;
  static late UserCredential userCredential;
  static late String githubToken;
  FirebaseUtils();

  Future<void> init() async {
    firebaseApp = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    try {
      userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      Log.logger.t("-> Signed in with temporary account.");
    } on FirebaseAuthException catch (error, stackTrace) {
      switch (error.code) {
        case "operation-not-allowed":
          Log.logger.e("Anonymous auth hasn't been enabled for this project.");
          break;
        default:
          Log.logger.e("Unknown error.", error: error, stackTrace: stackTrace);
      }
    }

    Log.logger.t("-> Setting up Firestore Database...");
    database = FirebaseFirestore.instanceFor(app: firebaseApp);

    Log.logger.t("-> Setting up Firebase Storage...");
    storage = FirebaseStorage.instanceFor(app: firebaseApp, bucket: 'gs://weightechapp.appspot.com');
    
    Log.logger.t("-> Getting access tokens...");
    await database.collection("tokens").doc("github").get().then((DocumentSnapshot doc) {
      githubToken = (doc.data() as Map<String, dynamic>)['access_token']!;
    });
  }

  static Future<void> postCatalogToFirestore(Map<String, dynamic> json) async {
    await retry(
      () => database.collection("catalog").add(json)
        .timeout(const Duration(seconds: 5))
        .then((DocumentReference doc) => Log.logger.i('Firestore DocumentSnapshot added with ID: ${doc.id}')),
      onRetry: (Exception exception) {
        Log.logger.w("Problem encountered when retrieving catalog. Trying again.", error: exception);
      },
      maxAttempts: 2,
    );
  }

  static Future<Map<String,dynamic>> getCatalogFromFirestore() async {

    return await retry(
      () => database.collection("catalog").orderBy("timestamp", descending: true).limit(1).get()
        .timeout(const Duration(seconds: 5))
        .then((event) {
          Log.logger.i('Firebase DocumentSnapshot retrieved with ID: ${event.docs[0].id}');
          return event.docs[0].data();
        }),
      onRetry: (Exception exception) {
        debugPrint("Retrying.");
        Log.logger.w("Encountered exception when retrieving catalog. Trying again.", error: exception);
      },
      maxAttempts: 2,
    );
  }

  static Future<void> downloadFromFirebaseStorage({required String url}) async {
    final downloadsDirectory = await getDownloadsDirectory();
    
    try {
      final imageRef = FirebaseUtils.storage.refFromURL(url);
      final file = File('${downloadsDirectory!.path}/${imageRef.name}');

      imageRef.writeToFile(file);

      Log.logger.t("Downloaded image at $url to ${downloadsDirectory.path}");
    }
    catch (e, stackTrace) {
      Log.logger.e("Failed to download file at $url.", error: e, stackTrace: stackTrace);
    }
  }
}
