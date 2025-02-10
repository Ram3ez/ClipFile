import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:clipfile/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Config {
  static Box<String> settingsBox = Hive.box("settings");
  static var endpoint = settingsBox.get("endpoint") ?? "";
  static var projectID = settingsBox.get("projectID") ?? "";
  static var databaseID = settingsBox.get("databaseID") ?? "";
  static var documentID = settingsBox.get("documentID") ?? "";
  static var collectionID = settingsBox.get("collectionID") ?? "";
  static var attributeName = settingsBox.get("attributeName") ?? "";
  static var bucketID = settingsBox.get("bucketID") ?? "";

  static late Client client;
  static late Databases databases;
  static late Storage storage;

  Config._();

  factory Config() {
    Config.client = Client().setEndpoint(endpoint).setProject(projectID);
    Config.databases = Databases(client);
    Config.storage = Storage(client);
    return Config._();
  }

  Databases getDatabase() => databases;

  Storage getStorage() => storage;
  Client getClient() => client;

  Future<String> getData([BuildContext? context]) async {
    try {
      var result = await databases.getDocument(
          databaseId: databaseID,
          collectionId: collectionID,
          documentId: documentID);
      return result.data[attributeName] ?? "";
    } catch (e) {
      if (context!.mounted) {
        serverSettingErrorDialog(
          context,
          "Error in Server Details",
        );
      }

      return "";
    }
  }

  Future<String> updateData(String? data) async {
    try {
      var result = await databases.updateDocument(
        collectionId: collectionID,
        databaseId: databaseID,
        documentId: documentID,
        data: {attributeName: data ?? ""},
      );

      return result.data[attributeName];
    } on AppwriteException {
      rethrow;
    }
  }

  Future<FileList?>? listFiles([BuildContext? context]) async {
    try {
      await storage.listFiles(bucketId: bucketID);
      return storage.listFiles(bucketId: bucketID);
    } catch (e) {
      if (context!.mounted) {
        serverSettingErrorDialog(
          context,
          "Error in Server Details",
        );
      }
      return null;
    }
  }

  Future deleteData(String file) {
    return storage.deleteFile(bucketId: bucketID, fileId: file);
  }

  Stream<Uint8List> downloadData(String file) {
    var data = storage.getFileDownload(bucketId: bucketID, fileId: file);
    return data.asStream();
  }

  Future<File> insertData(
      {String? path, Uint8List? bytes, String? name}) async {
    try {
      var result = await storage.createFile(
          bucketId: bucketID,
          fileId: ID.unique(),
          file: path == null
              ? InputFile.fromBytes(bytes: bytes!.toList(), filename: name!)
              : InputFile.fromPath(path: path));
      return result;
    } on AppwriteException {
      rethrow;
    }
  }

  Future<Uint8List> getImage(String fileID) async {
    var data = Config().getStorage().getFilePreview(
          bucketId: Config.bucketID,
          fileId: fileID,
          output: ImageFormat.webp,
        );

    return data;
  }

  Future<dynamic> serverSettingErrorDialog(BuildContext context, String title) {
    return showDialog(
        context: context,
        barrierDismissible: false,
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
                  /* settingsBox.put("databaseID", "67a60bc1002f0f1f6ce8");
                    settingsBox.put("projectID", "67a60a050000bc893984");
                    settingsBox.put("documentID", "67a60cb600360cda06f2");
                    settingsBox.put("collectionID", "67a60c07002df8f2e9d8");
                    settingsBox.put("bucketID", "67a6e34a001ffa8c8949"); */
                  /* settingsBox.put("databaseID", "");
                    settingsBox.put("projectID", "");
                    settingsBox.put("documentID", "");
                    settingsBox.put("collectionID", "");
                    settingsBox.put("bucketID", ""); */
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
