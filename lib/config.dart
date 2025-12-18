import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' hide Theme;
import 'package:appwrite/models.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'package:clipfile/secrets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A singleton configuration class for managing Appwrite client functionality.
///
/// This class handles database, storage, and account interactions, as well as
/// managing application settings stored in Hive.
class Config {
  // Hive Box for storing settings locally
  static Box<String> settingsBox = Hive.box("settings");

  // Appwrite Configuration Properties
  static var endpoint = settingsBox.get("endpoint") ?? Secrets.endpoint;
  static var projectID = settingsBox.get("projectID") ?? Secrets.projectID;
  static var databaseID = settingsBox.get("databaseID") ?? Secrets.databaseID;
  static var documentID = settingsBox.get("documentID") ?? Secrets.documentID;
  static var collectionID =
      settingsBox.get("collectionID") ?? Secrets.collectionID;
  static var attributeName =
      settingsBox.get("attributeName") ?? Secrets.attributeName;
  static var bucketID = settingsBox.get("bucketID") ?? Secrets.bucketID;

  // App Settings
  static var alwaysOnTop = settingsBox.get("onTop") ?? "true";
  static var fixedSize = settingsBox.get("fixedSize") ?? "false";
  static var isDev = settingsBox.get("isDev") ?? "false";
  static var isLocal = settingsBox.get("isLocal") == "true";

  // Appwrite Services
  static late Client client;
  static late Realtime realtime;
  static late Databases databases;
  static late TablesDB tables;
  static late Storage storage;
  static late Account account;

  // Private constructor for Singleton pattern
  Config._();

  factory Config() {
    return Config._();
  }

  static bool _isInitialized = false;

  void init() {
    if (isLocal) {
      _isInitialized = true;
      return;
    }

    if (endpoint.isNotEmpty) {
      Config.client = Client().setEndpoint(endpoint).setProject(projectID);
    } else {
      Config.client = Client();
    }
    Config.databases = Databases(client);
    Config.tables = TablesDB(client);
    Config.storage = Storage(client);
    Config.account = Account(client);

    _isInitialized = true;

    if (userUpdateCallback != null) {
      userUpdateCallback!();
    }
  }

  static VoidCallback? userUpdateCallback;

  void _ensureInitialized() {
    if (!_isInitialized) {
      init();
    }
  }

  /// Returns the initialized Database service.
  Databases getDatabase() {
    _ensureInitialized();
    return databases;
  }

  /// Returns the initialized Storage service.
  Storage getStorage() {
    _ensureInitialized();
    return storage;
  }

  /// Returns the initialized Client.
  Client getClient() {
    _ensureInitialized();
    return client;
  }

  /// Returns the initialized Account service.
  Account getAccount() {
    _ensureInitialized();
    return account;
  }

  /// Fetches the configured attribute data from the Appwrite database.
  ///
  /// Returns the data as a String, or an empty string if an error occurs.
  /// Fetches the configured attribute data from the Appwrite database.
  ///
  /// Returns the data as a String, or an empty string if an error occurs.
  Future<String> getData([BuildContext? context, bool isDev = false]) async {
    try {
      var result = await tables.getRow(
          databaseId: databaseID, tableId: collectionID, rowId: documentID);
      return result.data[attributeName] ?? "";
    } on AppwriteException catch (e) {
      if (context != null && context.mounted) {
        _handleConnectionError(context, e, isDev);
      }
      return "";
    }
  }

  /// Updates the configured attribute data in the Appwrite database.
  ///
  /// Returns the updated data.
  Future<String> updateData(String? data) async {
    try {
      var result = await tables.updateRow(
        tableId: collectionID,
        databaseId: databaseID,
        rowId: documentID,
        data: {attributeName: data ?? ""},
      );

      return result.data[attributeName];
    } on AppwriteException {
      rethrow;
    }
  }

  /// Lists files from the configured Appwrite storage bucket.
  ///
  /// Returns a [FileList] or null if an error occurs.
  Future<FileList?>? listFiles(
      [BuildContext? context, bool isDev = false]) async {
    try {
      return await getStorage().listFiles(bucketId: bucketID);
    } on AppwriteException catch (e) {
      if (context != null && context.mounted) {
        _handleConnectionError(context, e, isDev);
      }
      return null;
    }
  }

  /// Deletes a file from the Appwrite storage bucket.
  Future deleteData(String file) async {
    return await getStorage().deleteFile(bucketId: bucketID, fileId: file);
  }

  /// Returns a stream of file data for downloading.
  Stream<Uint8List> downloadData(String file) {
    var data = getStorage().getFileDownload(bucketId: bucketID, fileId: file);
    return data.asStream();
  }

  /// Future based download of file data.
  Future<Uint8List> downloadDataFuture(String file) async {
    var data =
        await getStorage().getFileDownload(bucketId: bucketID, fileId: file);
    return data;
  }

  /// Uploads a file to the Appwrite storage bucket.
  ///
  /// Can upload from bytes or a file path.
  Future<File?> insertData({
    String? path,
    Uint8List? bytes,
    String? name,
    BuildContext? context,
  }) async {
    try {
      // Determine input file type
      final inputFile = path == null
          ? InputFile.fromBytes(bytes: bytes!.toList(), filename: name!)
          : InputFile.fromPath(path: path);

      var result = await getStorage().createFile(
          bucketId: bucketID,
          fileId: ID.unique(),
          file: inputFile,
          onProgress: (UploadProgress progress) {});
      return result;
    } on AppwriteException catch (e) {
      if (context != null && context.mounted) {
        await _showUploadErrorDialog(context, e.message.toString());
      }
      return null;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  /// Fetches a preview image of a file from storage.
  Future<Uint8List> getImage(String fileID) async {
    var data = Config().getStorage().getFilePreview(
          bucketId: Config.bucketID,
          fileId: fileID,
          output: ImageFormat.webp,
        );

    return data;
  }

  /// Shows a dialog prompting the user to set server details if a connection error occurs.
  void _handleConnectionError(
      BuildContext context, AppwriteException e, bool isDev) {
    if (!e.message!
        .contains("ClientException with SocketException: Failed host lookup")) {
      serverSettingErrorDialog(
        context,
        "Please Set Server Details",
        isDev,
      );
    }
  }

  /// Helper method to show upload error dialogs.
  Future<dynamic> _showUploadErrorDialog(BuildContext context, String message) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Upload Error",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            actions: [
              MaterialButton(
                color: Theme.of(context).secondaryHeaderColor,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Ok",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          );
        });
  }

  /// Helper method to show server setting error dialog.
  Future<dynamic> serverSettingErrorDialog(
      BuildContext context, String title, bool isDev) {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Server details not initialized",
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            actions: [
              MaterialButton(
                color: Theme.of(context).secondaryHeaderColor,
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SettingsPage()));
                },
                child: Text(
                  "Settings",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          );
        });
  }
}
