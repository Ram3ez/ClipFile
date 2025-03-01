import "package:clipfile/components/custom_button.dart";
import "package:clipfile/components/custom_text_field.dart";
import "package:clipfile/config.dart";
import "package:clipfile/providers/auth_provider.dart";
import "package:clipfile/secrets.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:provider/provider.dart";

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final Box<String> settingsBox = Hive.box("settings");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Register",
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          CustomTextField(controller: nameController, label: "Name", hint: ""),
          SizedBox(
            height: 10,
          ),
          CustomTextField(
              controller: emailController, label: "Email", hint: ""),
          SizedBox(
            height: 10,
          ),
          CustomTextField(
            controller: passController,
            label: "Password",
            hint: "",
            isPassword: true,
          ),
          SizedBox(
            height: 50,
          ),
          CustomButton(
              onPress: () async {
                await settingsBox.put("endpoint", Secrets.endpoint);
                await settingsBox.put("projectID", Secrets.projectID);
                await settingsBox.put("databaseID", Secrets.databaseID);
                await settingsBox.put("collectionID", Secrets.collectionID);
                await settingsBox.put("attributeName", Secrets.attributeName);
                Config.endpoint = settingsBox.get("endpoint") ?? "";
                Config.projectID = settingsBox.get("projectID") ?? "";
                Config.databaseID = settingsBox.get("databaseID") ?? "";
                Config.collectionID = settingsBox.get("collectionID") ?? "";
                Config.attributeName = settingsBox.get("attributeName") ?? "";
                if (!context.mounted) return;
                var user = context.read<AuthProvider>().register(
                    nameController.text,
                    emailController.text,
                    passController.text,
                    context);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Registering. . ."),
                  behavior: SnackBarBehavior.floating,
                ));
                await user;
                passController.clear();
                emailController.clear();
                nameController.clear();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              buttonText: "Register",
              long: false),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Have an Account?"),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  " Login here",
                  style: TextStyle(
                      color: Theme.of(context).secondaryHeaderColor,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          Spacer(),
        ],
      ),
    );
  }
}
