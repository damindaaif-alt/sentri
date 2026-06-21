import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({this.statusCode, String message = 'Server error.'})
      : super(message);

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error.']);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Required permission not granted.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Record not found.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
