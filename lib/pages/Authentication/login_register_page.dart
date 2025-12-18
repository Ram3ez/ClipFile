import 'package:clipfile/components/custom_button.dart';
import 'package:clipfile/config.dart';
import 'package:clipfile/pages/Authentication/login_page.dart';
import 'package:clipfile/providers/isdev_provider.dart';
import 'package:clipfile/secrets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clipfile/providers/local_only_provider.dart';
import 'package:provider/provider.dart';

/// A page that allows the user to choose between Logging in or entering Developer Mode.
class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool _showLogin = false;

  final Box<String> settingsBox = Hive.box("settings");

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      _initializeLoginConfig();
      return LoginPage();
    }

    return _buildSelectionScreen(context);
  }

  void _initializeLoginConfig() {
    // Only set defaults if they are empty
    if ((settingsBox.get("endpoint") ?? "").isEmpty) {
      settingsBox.put("endpoint", Secrets.endpoint);
      Config.endpoint = Secrets.endpoint;
    }
    if ((settingsBox.get("projectID") ?? "").isEmpty) {
      settingsBox.put("projectID", Secrets.projectID);
      Config.projectID = Secrets.projectID;
    }
    if ((settingsBox.get("databaseID") ?? "").isEmpty) {
      settingsBox.put("databaseID", Secrets.databaseID);
      Config.databaseID = Secrets.databaseID;
    }
    if ((settingsBox.get("collectionID") ?? "").isEmpty) {
      settingsBox.put("collectionID", Secrets.collectionID);
      Config.collectionID = Secrets.collectionID;
    }
    if ((settingsBox.get("attributeName") ?? "").isEmpty) {
      settingsBox.put("attributeName", Secrets.attributeName);
      Config.attributeName = Secrets.attributeName;
    }

    settingsBox.put("documentID", "");
    settingsBox.put("bucketID", "");
    Config.documentID = "";
    Config.bucketID = "";

    Config().init(); // Initialize config instance
  }

  Widget _buildSelectionScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: CustomButton(
                onPress: () => setState(() => _showLogin = true),
                buttonText: "Login",
                long: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: CustomButton(
                onPress: () {
                  context.read<LocalOnlyProvider>().update(true);
                },
                buttonText: "Local Only Mode",
                long: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: CustomButton(
                onPress: () {
                  context.read<IsdevProvider>().update(true);
                },
                buttonText: "Developer Mode",
                long: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
