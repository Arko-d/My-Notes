import 'dart:developer' as devtools show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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
      appBar: AppBar(
        title: const Text("Login"),
      ),
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
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  if (mounted) {
                    //Handles the error for Don't use 'BuildContext across async gaps
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/notes/',
                      (route) => false,
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  var err = e.code;
                  switch (err) {
                    case 'user-not-found':
                      devtools.log("USER NOT FOUND");
                      break;
                    case 'wrong-password':
                      devtools.log("WRONG PASSWORD");
                      break;
                    default:
                      devtools.log(e.code);
                      break;
                  }
                }
              },
              child: const Text('Login')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/register/',
                  (route) => false,
                );
              },
              child: const Text('Not registered yet? Register here.'))
        ],
      ),
    );
  }
}
