import "package:clipfile/config.dart";
import "package:clipfile/main.dart";
import "package:clipfile/pages/Authentication/login_register_page.dart";
import "package:clipfile/providers/auth_provider.dart";
import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:provider/provider.dart";

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  bool initial = false;
  final Box<String> settingsBox = Hive.box("settings");

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.watch<AuthProvider>().account.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          settingsBox.put("documentID", "doc_${snapshot.data?.$id}");
          settingsBox.put("bucketID", "user_${snapshot.data?.$id}");
          Config.documentID = "doc_${snapshot.data?.$id}";
          Config.bucketID = "user_${snapshot.data?.$id}";

          return MainApp();
        }

        return LoginRegisterPage();
      },
    );
  }
}
