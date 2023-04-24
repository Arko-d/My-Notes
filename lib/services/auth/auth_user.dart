//Handles the user in session
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

@immutable //import from foundation.dart, not material.dart. This class and all subclasses have to be immutable. It can't have fields that can change.
class AuthUser {
  final bool isEmailVerified;
  const AuthUser(this.isEmailVerified);

  factory AuthUser.fromFirebase(User user) => AuthUser(user
      .emailVerified); //if fromFirebase of AuthUser class is called, then AuthUser's isEmailVerified field will initialize with the boolean value of the user's email verification status.
}