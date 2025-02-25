import "package:clipfile/main.dart";
import "package:clipfile/pages/Authentication/login_register_page.dart";
import "package:clipfile/providers/auth_provider.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: context.watch<AuthProvider>().user,
        builder: (context, snapshot) {
          if (snapshot.data?.name != null) {
            return MainApp(
              isDev: false,
            );
          } else {
            return LoginRegisterPage();
          }
        });
  }
}
