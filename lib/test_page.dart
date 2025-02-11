import "package:flutter/material.dart";
import 'package:appwrite/appwrite.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    Client client = Client().setProject("67ab3c22001a38fb2f43");
    Databases db = Databases(client);

    return Scaffold(
      appBar: AppBar(
        title: Text("Test"),
      ),
      body: Text("hello"),
    );
  }
}
