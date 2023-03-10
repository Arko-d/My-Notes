import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

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
    return Column(
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
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email, password: password);
              } on FirebaseAuthException catch (e) {
                var err = e.code;
                switch (err) {
                  case 'weak-password':
                    print("WEAK PASSWORD");
                    break;
                  case 'email-already-in-use':
                    print("EMAIL ALREADY IN USE");
                    break;
                  case 'invalid-email':
                    print("Invalid Email");
                    break;
                  default:
                    print(e.code);
                    break;
                }
              }
            },
            child: const Text('Register')),
      ],
    );
  }
}
