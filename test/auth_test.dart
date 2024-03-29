import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    //We keep all mock authentication tests in this group
    final provider = MockAuthProvider();
    test('Should not be initialized to begin with', () {
      expect(
        provider.isInitialized,
        false,
      );
    });
    test('Cannot log out if not initialized', () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedExcpetion>()),
      );
    });

    test('Should be able to be initialized', () async {
      await provider.initialize();
      expect(
        provider.isInitialized,
        true,
      );
    });

    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    });

    test(
      'Should be able to initialize in less than 2 seconds',
      () async {
        await provider.initialize();
        expect(provider.isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );

    test('create user should delegate to Log In', () async {
      final badEmailUser =
          provider.createUser(email: 'foo@bar.com', password: 'anypassword');
      expect(
        badEmailUser,
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );
      final badPasswordUser =
          provider.createUser(email: 'someone@bar.com', password: 'foobar');
      expect(
        badPasswordUser,
        throwsA(const TypeMatcher<WrongPasswordAuthExcpetion>()),
      );
      final user = await provider.createUser(email: 'foo', password: 'bar');
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('Logged in user should be able to get verified', () async {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test('Should be able to log out and log in again', () async {
      await provider.logOut();
      await provider.logIn(email: 'email', password: 'password');
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedExcpetion implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false; //Tracks if our auth provider is initialized
  bool get isInitialized => _isInitialized;
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedExcpetion();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitializedExcpetion();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthExcpetion();
    const user = AuthUser(
      isEmailVerified: false,
      email: 'helo',
      id: 'my_id',
    );
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedExcpetion();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedExcpetion();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(
      isEmailVerified: true,
      email: 'helo',
      id: 'my_id',
    );
    _user = newUser;
  }

  @override
  Future<void> sendPasswordReset({required String toEmail}) {
    throw UnimplementedError();
  }
}
