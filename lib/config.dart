import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/services.dart';

class Config {
  static const databaseID = String.fromEnvironment("databaseID");
  static const collectionID = String.fromEnvironment("collectionID");
  static const projectID = String.fromEnvironment("projectID");
  static const documentID = String.fromEnvironment("documentID");
  static const bucketID = String.fromEnvironment("bucketID");

  static late Client client;
  static late Databases databases;
  static late Storage storage;

  Config._();

  factory Config() {
    Config.client = Client().setProject(projectID);
    Config.databases = Databases(client);
    Config.storage = Storage(client);
    return Config._();
  }

  Databases getDatabase() => databases;

  Storage getStorage() => storage;
  Client getClient() => client;

  Future<String> getData() async {
    try {
      var result = await databases.getDocument(
          databaseId: databaseID,
          collectionId: collectionID,
          documentId: documentID);
      return result.data["clip"] ?? "";
    } on AppwriteException {
      return "";
    } catch (e) {
      return "";
    }
  }

  Future<String> updateData(String? data) async {
    try {
      var result = await databases.updateDocument(
        collectionId: collectionID,
        databaseId: databaseID,
        documentId: documentID,
        data: {"clip": data ?? ""},
      );

      return result.data["clip"];
    } on AppwriteException {
      rethrow;
    }
  }

  Future<FileList> listFiles() {
    return storage.listFiles(bucketId: bucketID);
  }

  Future deleteData(String file) {
    return storage.deleteFile(bucketId: bucketID, fileId: file);
  }

  Stream<Uint8List> downloadData(String file) {
    var data = storage.getFileDownload(bucketId: bucketID, fileId: file);
    return data.asStream();
  }

  Future<File> insertData(String path) async {
    try {
      var result = await storage.createFile(
          bucketId: bucketID,
          fileId: ID.unique(),
          file: InputFile.fromPath(path: path));
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
}
