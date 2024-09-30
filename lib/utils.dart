import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'package:shortid/shortid.dart';
import 'package:retry/retry.dart';
import 'package:path/path.dart' as p;
import 'package:string_validator/string_validator.dart' as validator;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// A class to manage application information and session data.
class AppInfo {
  /// Holds the package information of the app, initialized through [init].
  static late PackageInfo packageInfo;

  /// A unique session identifier, generated upon initialization.
  static late String sessionId;

  /// A flag that indicates whether the device has internet access, set during initialization.
  static late bool hasInternet;

  /// Constructor for [AppInfo]. Typically followed by a call to [init].
  AppInfo();

  /// Initializes the [AppInfo] by:
  /// - Fetching platform-specific package information.
  /// - Generating a session ID using `shortid`.
  /// - Checking if the device has an active internet connection.
  /// 
  /// This method is asynchronous and should be awaited.
  Future<void> init() async {
    packageInfo = await PackageInfo.fromPlatform();
    sessionId = shortid.generate();
    hasInternet = await InternetConnection().hasInternetAccess;
  }

  /// Compares two version strings [newVersion] and [currentVersion].
  ///
  /// - Returns `1` if [newVersion] is higher than [currentVersion] (deprecated).
  /// - Returns `2` if [newVersion] is lower than [currentVersion] (development).
  /// - Returns `0` if both versions are equal.
  ///
  /// The version strings should follow the format `major.minor.patch`.
  ///
  /// The comparison is done by breaking down the version strings into their components
  /// (i.e., major, minor, patch) and comparing them numerically.
  static int versionCompare(String newVersion, String currentVersion) {
    List<String> currentV = currentVersion.split(".");
    List<String> newV = newVersion.split(".");
    bool deprecated = false;
    bool development = false;
    for (var i = 0; i <= 2; i++) {
      deprecated = int.parse(newV[i]) > int.parse(currentV[i]);
      development = int.parse(newV[i]) < int.parse(currentV[i]);
      if (int.parse(newV[i]) != int.parse(currentV[i])) break;
    }
    if (deprecated) {
      return 1;
    } else if (development) {
      return 2;
    } else {
      return 0;
    }
  }
}

/// A class that manages logging for the application.
class Log {
  /// The logger instance used to log events in the app.
  static late Logger logger;

  /// Constructor for [Log]. Initializes the logging mechanism.
  Log();

  /// Initializes the [Log] system by:
  /// - Setting up a directory to store log files.
  /// - Creating a logger that logs to both a file and the console.
  /// - Logs the location of the log file and a timestamp.
  ///
  /// This method is asynchronous and should be awaited.
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

/// A custom log filter that determines which log events should be recorded.
class AppLogFilter extends LogFilter {
  /// Determines if a log event should be logged.
  ///
  /// Logs all events with a level of [Level.debug] or higher, 
  /// as well as events at the "trace" level.
  ///
  /// Returns `true` if the event should be logged, otherwise `false`.
  @override
  bool shouldLog(LogEvent event) {
    if (event.level.value >= Level.debug.value || event.level.name == "trace") {
      return true;
    } else {
      return false;
    }
  }
}

/// A custom log printer that formats the log output.
class AppLogPrinter extends PrettyPrinter {
  /// Creates an instance of [AppLogPrinter] with custom configurations:
  /// - Excludes boxes for [Level.info] and [Level.trace].
  /// - Prints no method calls for regular logs, but up to 10 for errors.
  /// - Sets the line length to 120 characters.
  /// - Enables color and emoji support in the log output.
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

/// A utility class for handling file-related operations such as downloading,
/// caching, checking file types, and retrieving file paths.
class FileUtils {
  /// The cache manager used for downloading and caching files.
  static final DefaultCacheManager cacheManager = DefaultCacheManager();

  /// Downloads and returns a single file from the given [url] by using the cache manager.
  ///
  /// If the file is already cached, it retrieves it from the cache, otherwise, it downloads the file.
  ///
  /// - [url]: The URL of the file to be downloaded.
  /// - Returns a [Future] that resolves to the downloaded [File].
  static Future<File> getSingleFile({required String url}) {
    return cacheManager.getSingleFile(url);
  }

  /// Downloads a file from the provided [url] and caches it using the cache manager.
  ///
  /// - [url]: The URL of the file to be downloaded and cached.
  /// - Returns a [Future] that resolves to a [FileInfo] object containing details about the cached file.
  static Future<FileInfo> cacheFile({required String url}) {
    return cacheManager.downloadFile(url);
  }

  /// Retrieves a local file from the provided [path].
  ///
  /// - [path]: The local path to the file.
  /// - Returns a [Future] that resolves to the [File] object at the given path.
  static Future<File> getLocalFile({required String path}) async {
    return File(path);
  }

  /// Checks if the given [path] is a valid URL.
  ///
  /// - [path]: The string to be checked.
  /// - Returns `true` if the path is a valid URL, otherwise `false`.
  static bool isURL({required String path}) {
    return validator.isURL(path);
  }

  /// Checks if the given [path] is a local path and whether the file or directory exists.
  ///
  /// - [path]: The local path to check.
  /// - Returns `true` if the file or directory exists at the path, otherwise `false`.
  static bool isLocalPathAndExists({required String path}) {
    try {
      return File(path).existsSync() || Directory(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Returns the file extension from the given [path].
  ///
  /// - [path]: The path of the file.
  /// - Returns a string representing the file extension (e.g., `.jpg`, `.mp4`).
  static String extension(String path) {
    return p.extension(path);
  }

  /// Checks if the file at the given [path] has an `.mp4` extension.
  ///
  /// - [path]: The path of the file.
  /// - Returns `true` if the file is an MP4, otherwise `false`.
  static bool isMP4(String path) {
    return extension(path) == '.mp4';
  }

  /// Checks if the file at the given [path] is an image file (i.e., `.jpg`, `.png`, or `.jpeg`).
  ///
  /// - [path]: The path of the file.
  /// - Returns `true` if the file is an image, otherwise `false`.
  static bool isImage(String path) {
    return ['.jpg', '.png', '.jpeg'].contains(extension(path));
  }

  /// Returns the directory name for the given [path].
  ///
  /// - [path]: The full path to the file.
  /// - Returns a string representing the directory containing the file.
  static String dirname(String path) {
    return p.dirname(path);
  }

  /// Returns the file name without the extension for the given [path].
  ///
  /// - [path]: The full path to the file.
  /// - Returns a string representing the file name without the extension.
  static String filename(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// Returns the file name with the extension for the given [path].
  ///
  /// - [path]: The full path to the file.
  /// - Returns a string representing the file name with the extension.
  static String filenameWithExtension(String path) {
    return p.basename(path);
  }
}

/// A utility class for interacting with Firebase services such as Firestore,
/// Firebase Storage, and Firebase Authentication.
class FirebaseUtils {
  /// The Firebase application instance, initialized in [init].
  static late FirebaseApp firebaseApp;

  /// The Firestore database instance used for accessing Firestore collections.
  static late FirebaseFirestore database;

  /// The Firebase Storage instance used for accessing and storing files in Firebase Storage.
  static late FirebaseStorage storage;

  /// The credential for the current anonymous user, set during initialization.
  static late UserCredential userCredential;

  /// A GitHub access token retrieved from Firestore.
  static late String githubToken;

  /// An API key for the api.video service retrieved from Firestore.
  static late String apiVideoKey;

  /// Whether a connection was made to Firebase
  static bool connectionMade = false;

  /// The reference Id of the catalog retrieved. Used to compare with backup catalog. 
  static late String? catalogReferenceId;

  FirebaseUtils();

  /// Initializes Firebase services, including:
  /// - Firebase app initialization.
  /// - Signing in anonymously with Firebase Authentication.
  /// - Setting up Firestore and Firebase Storage.
  /// - Fetching access tokens for GitHub and api.video from Firestore.
  ///
  /// This method is asynchronous and should be awaited.
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
    await database.collection("tokens").doc("api-video").get().then((DocumentSnapshot doc) {
      apiVideoKey = (doc.data() as Map<String, dynamic>)['api_key']!;
    });
  }


  /// Uploads a catalog to Firestore by adding a document to the `catalog` collection.
  ///
  /// - [json]: The JSON map containing catalog data to be uploaded.
  ///
  /// Logs the document ID of the uploaded catalog on success.
  static Future<void> postCatalogToFirestore(Map<String, dynamic> json) async {
    await database.collection("catalog").add(json)
      .then((DocumentReference doc) {
        Log.logger.i('Firestore DocumentSnapshot added with ID: ${doc.id}');
      });
  }


  /// Retrieves the most recent catalog document from the `catalog` collection in Firestore.
  ///
  /// The query retrieves the latest document ordered by the `timestamp` field.
  ///
  /// - Returns a [Future] that resolves to a [Map] containing the catalog data.
  /// - Retries the operation up to two times in case of failure.
  static Future<Map<String,dynamic>> getCatalogFromFirestore() async {
    return await retry(
      () => database.collection("catalog").orderBy("timestamp", descending: true).limit(1).get()
        .timeout(const Duration(seconds: 5))
        .then((event) {
          if (event.docs.isEmpty) {
            throw("Empty get data.");
          }
          else if (event.metadata.isFromCache) {
            throw("Retrieved cached database version");
          }
          else {
            Log.logger.i('Firebase DocumentSnapshot retrieved with ID: ${event.docs[0].id}');
            connectionMade = true;
            catalogReferenceId = event.docs[0].id;
            return event.docs[0].data();
          }
        }),
      onRetry: (Exception exception) {
        debugPrint("Retrying.");
        Log.logger.w("Encountered exception when retrieving catalog. Trying again.", error: exception);
      },
      maxAttempts: 2,
    );
  }


  /// Downloads a file from Firebase Storage and saves it locally.
  ///
  /// - [url]: The URL of the file to download.
  /// - [directory]: An optional directory to save the file in. Defaults to the downloads directory.
  ///
  /// - Returns a [Future] that resolves to the downloaded file path [String].
  ///
  /// Throws an error if the download fails and logs the failure.
  static Future<String?> downloadFromFirebaseStorage({required String url, Directory? directory}) async {
    
    directory ??= await getDownloadsDirectory();
    
    try {
      final imageRef = FirebaseUtils.storage.refFromURL(url);
      final file = File('${directory!.path}/${imageRef.name}');

      imageRef.writeToFile(file);

      Log.logger.t("Downloaded image at $url to ${directory.path}");
      return '${directory.path}/${imageRef.name}';
    }
    catch (e, stackTrace) {
      Log.logger.e("Failed to download file at $url.", error: e, stackTrace: stackTrace);
      throw();
    }
  }
}


/// A service class for interacting with the api.video platform, handling video
/// creation, uploading, downloading, and deletion.
class ApiVideoService {
  /// The base URL for api.video.
  static const String apiUrl = 'https://ws.api.video/videos';

  /// The API key for authenticating requests to the api.video service.
  static final String apiKey = FirebaseUtils.apiVideoKey;

  /// Creates a new video on api.video.
  ///
  /// - [title]: The title of the video to be created.
  /// - [source]: An optional source URL for the video.
  ///
  /// - Returns a [Future] that resolves to a [Map] containing details of the created video.
  ///
  /// Throws an [Exception] if the video creation fails.
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
        'source': source,
      }),
    );

    if ((response.statusCode == 201) || (response.statusCode == 202)) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create video: ${response.body}');
    }
  }

  /// Uploads a video file to api.video.
  ///
  /// - [videoId]: The ID of the video to which the file will be uploaded.
  /// - [filePath]: The local path to the video file to be uploaded.
  ///
  /// - Returns a [Future] that resolves to a [Map] containing URLs for downloading,
  ///   streaming, and accessing the thumbnail of the uploaded video.
  ///
  /// Throws an [Exception] if the upload fails.
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
        'downloadUrl': responseBody['assets']['mp4'],
        'streamUrl': responseBody['assets']['hls'],
        'thumbnailUrl': responseBody['assets']['thumbnail'],
        'playerUrl': responseBody['assets']['player']
      };
    } else {
      debugPrint('Failed to upload video: ${response.reasonPhrase}');
      debugPrint(await response.stream.bytesToString());
      throw('Failed to upload video.');
    }
  }

  /// Downloads a video from the provided [url] and saves it to the specified [savePath].
  ///
  /// - [url]: The URL of the video to download.
  /// - [savePath]: The local path where the downloaded video will be saved.
  ///
  /// - Returns a [Future] that resolves to the [File] object of the downloaded video.
  ///
  /// Throws an [Exception] if the video download fails.
  static Future<File> downloadVideo(String url, String savePath) async {
    Log.logger.t("Downloading video from $url");
    
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

  /// Deletes all videos with titles containing [itemId] from api.video.
  ///
  /// - [itemId]: The identifier used to match and delete videos.
  ///
  /// Sends an HTTP DELETE request for each matching video.
  ///
  /// Logs the response from each delete operation.
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