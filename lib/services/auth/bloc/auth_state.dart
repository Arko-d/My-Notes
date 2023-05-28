import 'package:flutter/material.dart' show immutable;
import 'package:mynotes/services/auth/auth_user.dart';

//States are usually immutable. It is a class with no logic at all.
@immutable
abstract class AuthState {
  const AuthState();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateLoggedIn extends AuthState {
  //We added user since our user is logged in and we have a user. We can use the user data in the state.
  final AuthUser user;
  const AuthStateLoggedIn(this.user);
}

class AuthStateNeedsVerification extends AuthState {
  const AuthStateNeedsVerification();
}

class AuthStateLoggedOut extends AuthState {
  final Exception?
      exception; //Handles this type of case:: Fresh install -> State is logged out -> Enter wrong creds -> State is still logged out, but now we have an exception
  const AuthStateLoggedOut(this.exception);
}

class AuthStateLogoutFailure extends AuthState {
  final Exception exception;
  const AuthStateLogoutFailure(this.exception);
}
