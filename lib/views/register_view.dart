import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'dart:developer' as devtools show log;
import 'login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  //initialize the states
  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  //ALWAYS dispose your states
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Column(
        children: [
          TextField(
              keyboardType: TextInputType.emailAddress,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  const InputDecoration(hintText: 'Enter your email here'),
              controller: _email),
          TextField(
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  const InputDecoration(hintText: 'Enter your password here'),
              controller: _password),
          TextButton(
              onPressed: () async {
                final email = _email.text;
                final password = _password.text;
                try {
                  await AuthService.firebase()
                      .createUser(email: email, password: password);
                  final user = AuthService.firebase().currentUser;
                  await AuthService.firebase().sendEmailVerification();

                  if (context.mounted) {
                    Navigator.of(context).pushNamed(verifyEmailRoute);
                  }
                } on EmailAlreadyInUseAuthException {
                  await showErrorDialog(context, "Email already in use");
                } on WeakPasswordAuthException {
                  await showErrorDialog(context, "Weak Password");
                } on InvalidEmailAuthException {
                  await showErrorDialog(context, "Invalid Email");
                } on GenericAuthException {
                  await showErrorDialog(context, "Failed to register");
                }
              },
              child: const Text('Register')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (route) => false,
                );
              },
              child: const Text('Already registered? Login here!'))
        ],
      ),
    );
  }
}
