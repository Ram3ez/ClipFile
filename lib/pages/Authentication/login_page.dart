import "package:clipfile/components/custom_button.dart";
import "package:clipfile/components/custom_text_field.dart";
import "package:clipfile/pages/Authentication/register_page.dart";
import "package:clipfile/providers/auth_provider.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:hive_flutter/adapters.dart";
import "package:provider/provider.dart";

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final Box<String> settingsBox = Hive.box("settings");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Login",
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
          Spacer(
            flex: 2,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomTextField(
              controller: emailController,
              label: "Email",
              hint: "",
              isSetting: false,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomTextField(
              controller: passController,
              label: "Password",
              hint: "",
              isPassword: true,
              isSetting: false,
            ),
          ),
          SizedBox(
            height: 50,
          ),
          CustomButton(
              onPress: () async {
                if (!context.mounted) return;
                var user = context
                    .read<AuthProvider>()
                    .login(emailController.text, passController.text, context);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Logging in. . ."),
                  behavior: SnackBarBehavior.floating,
                ));
                await user;
                emailController.clear();
                passController.clear();
              },
              buttonText: "Login",
              long: false),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Dont Have an Account?"),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => RegisterPage()));
                },
                child: Text(
                  " Register here",
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
