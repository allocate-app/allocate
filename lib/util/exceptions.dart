class FailureToCreateException implements Exception {
  String cause;
  FailureToCreateException(this.cause);
}
class FailureToUploadException implements Exception{
  String cause;
  FailureToUploadException(this.cause);
}
class FailureToDeleteException implements Exception{
  String cause;
  FailureToDeleteException(this.cause);
}

class FailureToUpdateException implements Exception {
  String cause;
  FailureToUpdateException(this.cause);
}

class ListLimitExceededException implements Exception {
  String cause;
  ListLimitExceededException(this.cause);
}