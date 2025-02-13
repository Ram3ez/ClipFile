import 'dart:developer';

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
  static var alwaysOnTop = settingsBox.get("onTop") ?? "true";
  static var fixedSize = settingsBox.get("fixedSize") ?? "false";

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
    } on AppwriteException catch (e) {
      if (context!.mounted &&
          !e.message!.contains(
              "ClientException with SocketException: Failed host lookup")) {
        serverSettingErrorDialog(
          context,
          "Please Set Server Details",
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
    } on AppwriteException catch (e) {
      if (context!.mounted &&
          !e.message!.contains(
              "ClientException with SocketException: Failed host lookup")) {
        serverSettingErrorDialog(
          context,
          "Please Set Server Details",
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

  Future<Uint8List> downloadDataFuture(String file) async {
    var data = await storage.getFileDownload(bucketId: bucketID, fileId: file);

    return data;
  }

  Future<File?> insertData(
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
    } catch (e) {
      log(e.toString());
      return null;
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
