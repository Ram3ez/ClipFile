import "package:clipfile/components/custom_button.dart";
import "package:clipfile/components/custom_text_field.dart";
import "package:clipfile/providers/auth_provider.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:provider/provider.dart";

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

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
                  /* Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LoginPage())); */
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
