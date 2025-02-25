import 'package:clipfile/components/custom_button.dart';
import 'package:clipfile/main.dart';
import 'package:clipfile/pages/Authentication/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool login = false;
  bool devMode = false;
  bool noOp = true;

  @override
  Widget build(BuildContext context) {
    if (noOp) {
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
                    onPress: () {
                      setState(() {
                        noOp = false;
                        login = true;
                      });
                    },
                    buttonText: "Login",
                    long: true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: CustomButton(
                    onPress: () {
                      setState(() {
                        noOp = false;
                        devMode = true;
                      });
                    },
                    buttonText: "Developer Mode",
                    long: true),
              ),
            ],
          ),
        ),
      );
    } else if (login) {
      return LoginPage();
    } else if (devMode) {
      return MainApp(isDev: true);
    } else {
      setState(() {
        noOp = true;
      });
    }
    return Scaffold();
  }
}
