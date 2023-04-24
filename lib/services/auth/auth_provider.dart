import 'package:mynotes/services/auth/auth_user.dart';

//Auth Provider should provide us with the current user
abstract class AuthProvider {
  AuthUser? get currentUser; //getter for the current user in session
  Future<AuthUser> logIn({required String email, required String password});
  Future<AuthUser> createUser(
      {required String email, required String password});
  Future<void> logOut();
  Future<void> sendEmailVerification();
}
