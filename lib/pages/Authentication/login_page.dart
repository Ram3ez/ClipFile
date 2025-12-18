import "package:clipfile/components/custom_button.dart";
import "package:clipfile/components/custom_text_field.dart";
import "package:clipfile/pages/Authentication/register_page.dart";
import "package:clipfile/providers/auth_provider.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:provider/provider.dart";

/// The login screen for the application.
class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

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
          const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomTextField(
              controller: emailController,
              label: "Email",
              hint: "",
              isSetting: false,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 50),
          CustomButton(
            onPress: () => _handleLogin(context),
            buttonText: "Login",
            long: false,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Dont Have an Account?"),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: Text(
                  " Register here",
                  style: TextStyle(
                    color: Theme.of(context).secondaryHeaderColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!context.mounted) return;

    // Start login process
    var loginFuture = context
        .read<AuthProvider>()
        .login(emailController.text, passController.text, context);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Logging in. . ."),
      behavior: SnackBarBehavior.floating,
    ));

    await loginFuture;

    emailController.clear();
    passController.clear();
  }
}
