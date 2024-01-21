class FailureToCreateException implements Exception {
  String cause;

  FailureToCreateException(this.cause);

  @override
  toString() => cause;
}

class FailureToUploadException implements Exception {
  String cause;

  FailureToUploadException(this.cause);

  @override
  toString() => cause;
}

class FailureToDeleteException implements Exception {
  String cause;

  FailureToDeleteException(this.cause);

  @override
  toString() => cause;
}

class FailureToUpdateException implements Exception {
  String cause;

  FailureToUpdateException(this.cause);

  @override
  toString() => cause;
}

class InvalidRepeatingException implements Exception {
  String cause;

  InvalidRepeatingException(this.cause);

  @override
  toString() => cause;
}

class FailureToScheduleException implements Exception {
  String cause;
  FailureToScheduleException(this.cause);
  @override
  toString() => cause;
}

class GroupNotFoundException implements Exception {
  String cause;

  GroupNotFoundException(this.cause);

  @override
  toString() => cause;
}

class InvalidEventItemException implements Exception {
  String cause;

  InvalidEventItemException(this.cause);

  @override
  toString() => cause;
}

class LoginFailedException implements Exception {
  String cause;

  LoginFailedException(this.cause);

  @override
  toString() => cause;
}

class SignUpFailedException implements Exception {
  String cause;

  SignUpFailedException(this.cause);

  @override
  toString() => cause;
}

class UserExistsException implements Exception {
  String cause;

  UserExistsException(this.cause);

  @override
  toString() => cause;
}

class UserSyncException implements Exception {
  String cause;

  UserSyncException(this.cause);

  @override
  toString() => cause;
}

class UserException implements Exception {
  String cause;

  UserException(this.cause);

  @override
  toString() => cause;
}

class NoUserException implements Exception {
  String cause;

  NoUserException(this.cause);

  @override
  toString() => cause;
}

class ObjectNotFoundException implements Exception {
  String cause;

  ObjectNotFoundException(this.cause);

  @override
  toString() => cause;
}
