import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:core';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weightechapp/firebase_options.dart';
import 'package:shortid/shortid.dart';
import 'package:retry/retry.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:string_validator/string_validator.dart' as validator;
import 'package:path/path.dart' as p;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

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
      output: MultiOutput(
        [
          FileOutput(
            file: await File("${appDocsDir.path}/logs/app-${AppInfo.sessionId}.log").create(recursive: true)
          ),
          ConsoleOutput()
        ]
      )
    );
    debugPrint("Log location: ${appDocsDir.path}/logs/app-${AppInfo.sessionId}.log");
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


class FileUtils {
  static final DefaultCacheManager cacheManager = DefaultCacheManager();

  static Future<File> getSingleFile({required String url}) {
    return cacheManager.getSingleFile(url);
  }

  static Future<FileInfo> cacheFile({required String url}) {
    return cacheManager.downloadFile(url);
  }

  static Future<File> getLocalFile({required String path}) async {
    return File(path);
  }

  static bool isURL({required String path}) {
    return validator.isURL(path);
  }

  static bool isLocalPathAndExists({required String path}) {
    try {
      return File(path).existsSync() || Directory(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  static String extension(path) {
    return p.extension(path);
  }

  static bool isMP4(String path) {
    return extension(path) == '.mp4';
  }

  static bool isImage(String path) {
    return ['.jpg', '.png', '.jpeg'].contains(extension(path));
  }

  static String dirname(String path) {
    return p.dirname(path);
  }
}

class FirebaseUtils {
  static late FirebaseApp firebaseApp; // Initialize Firebase
  static late FirebaseFirestore database;
  static late FirebaseStorage storage;
  static late UserCredential userCredential;
  static late String githubToken;
  static late String apiVideoKey;
  FirebaseUtils();

  Future<void> init() async {
    firebaseApp = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    userCredential = await FirebaseAuth.instance.signInAnonymously();
    Log.logger.t("-> Signed in with temporary account.");

    Log.logger.t("-> Setting up Firestore Database...");
    database = FirebaseFirestore.instanceFor(app: firebaseApp);

    Log.logger.t("-> Setting up Firebase Storage...");
    storage = FirebaseStorage.instanceFor(app: firebaseApp, bucket: 'gs://weightechapp.appspot.com');
    
    Log.logger.t("-> Getting access tokens...");
    await database.collection("tokens").doc("github").get().then((DocumentSnapshot doc) {
      githubToken = (doc.data() as Map<String, dynamic>)['access_token']!;
    });
    await database.collection("tokens").doc("api-video").get().then((DocumentSnapshot doc){
      apiVideoKey = (doc.data() as Map<String, dynamic>)['api_key']!;
    });
  }

  static Future<void> postCatalogToFirestore(Map<String, dynamic> json) async {
    await database.collection("devCatalog").add(json)
      .then((DocumentReference doc) {
        Log.logger.i('Firestore DocumentSnapshot added with ID: ${doc.id}');
      });
  }

  static Future<Map<String,dynamic>> getCatalogFromFirestore() async {
    return await retry(
      () => database.collection("catalog").orderBy("timestamp", descending: true).limit(1).get()
        .timeout(const Duration(seconds: 5))
        .then((event) {
          if (event.docs.isEmpty) {
            throw("Empty get data.");
          }
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

  static Future<File> downloadFromFirebaseStorage({required String url, Directory? directory, bool returnFile = false}) async {
    directory ??= await getDownloadsDirectory();
    
    try {
      final imageRef = FirebaseUtils.storage.refFromURL(url);
      final file = File('${directory!.path}/${imageRef.name}');

      final task = await imageRef.writeToFile(file);

      return file;
      
    }
    catch (e, stackTrace) {
      Log.logger.e("Failed to download file at $url.", error: e, stackTrace: stackTrace);
      throw("Failed to download file at $url");
    }
  }
}


class ApiVideoService {
  static const String apiUrl = 'https://ws.api.video/videos';
  static final String apiKey = FirebaseUtils.apiVideoKey;

  static Future<Map<String, dynamic>> createVideo({required String title, String? source}) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'public': true,
        'panoramic': false,
        'mp4Support': true,
        'title': title,
        'source': source
      }),
    );

    final jsonResponse = jsonDecode(response.body);

    if ((response.statusCode == 201) || (response.statusCode == 202)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create video: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> uploadVideo(String videoId, String filePath) async {
    
    Log.logger.t("Uploading video to host...");
    
    final file = File(filePath);
    final fileStream = file.openRead();
    final length = await file.length();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/$videoId/source'),
    )
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Range'] = 'bytes 0-${length - 1}/$length'
      ..files.add(http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: file.uri.pathSegments.last,
      ));

    final response = await request.send();

    Log.logger.t("Response: ${response.statusCode} ${response.reasonPhrase}");

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(await response.stream.bytesToString());
      debugPrint('Video uploaded successfully');
      return {
        'downloadUrl' : responseBody['assets']['mp4'],
        'streamUrl' : responseBody['assets']['hls'],
        'thumbnailUrl' : responseBody['assets']['thumbnail'],
        'playerUrl' : responseBody['assets']['player']
      };
    } else {
      debugPrint('Failed to upload video: ${response.reasonPhrase}');
      debugPrint(await response.stream.bytesToString());
      throw('Failed to upload video.');
    }
  }

  static Future<File> downloadVideo(String url, String savePath) async {
    Log.logger.t("Downloading videos at $url");
    // Send the HTTP GET request to download the file
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Write the file to the specified path
      final file = File(savePath);
      return file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download video: ${response.reasonPhrase}');
    }
  
  }

  static Future<void> deleteExistingForId(String itemId) async {
    Log.logger.t("Deleting existing videos for $itemId");
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    var videoList = jsonDecode(response.body)['data'];

    for (var video in videoList) {
      if (video['title'].contains(itemId)) {
        final deleteResponse = await http.delete(
          Uri.parse('$apiUrl/${video['videoId']}'),
          body: jsonEncode({
            'videoId': video['videoId'],
          }),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        );
        Log.logger.i('HTTP Delete response: ${deleteResponse.statusCode} ${deleteResponse.reasonPhrase}');
      }
    }
  }
}

extension TreeMapping on TreeDragAndDropDetails<Object> {
  T mapDropPosition<T>({
    required T Function() whenAbove,
    required T Function() whenInside,
    required T Function() whenBelow,
  }) {
    final double oneThirdOfTotalHeight = targetBounds.height * 0.3;
    final double pointerVerticalOffset = dropPosition.dy;

    if (pointerVerticalOffset < oneThirdOfTotalHeight) {
       return whenAbove();
    } else if (pointerVerticalOffset < oneThirdOfTotalHeight * 2) {
      return whenInside();
    } else {
      return whenBelow();
    }
  }
}