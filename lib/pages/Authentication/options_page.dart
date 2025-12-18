import "package:clipfile/config.dart";
import "package:clipfile/main.dart";
import "package:clipfile/pages/Authentication/login_register_page.dart";
import "package:clipfile/providers/auth_provider.dart";
import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:provider/provider.dart";

/// The initial route wrapper that decides whether to show the MainApp or Login screen
/// based on authentication status.
class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  final Box<String> settingsBox = Hive.box("settings");

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.watch<AuthProvider>().account.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in
        if (snapshot.hasData) {
          final userId = snapshot.data?.$id;
          settingsBox.put("documentID", "doc_$userId");
          settingsBox.put("bucketID", "user_$userId");
          Config.documentID = "doc_$userId";
          Config.bucketID = "user_$userId";

          return const MainApp();
        }

        return const LoginRegisterPage();
      },
    );
  }
}
