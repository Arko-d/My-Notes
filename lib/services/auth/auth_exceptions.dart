//Exceptions being used in login
class UserNotFoundAuthException implements Exception {}

class WrongPasswordAuthExcpetion implements Exception {}

//Exceptions being used in registration
class EmailAlreadyInUseAuthException implements Exception {}

class WeakPasswordAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

//Generic Exceptions
class GenericAuthException implements Exception {}

class UserNotLoggedInAuthException implements Exception {}
