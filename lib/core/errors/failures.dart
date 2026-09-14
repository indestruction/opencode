sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ProviderFailure extends Failure {
  const ProviderFailure(super.message);
}

final class ConfigFailure extends Failure {
  const ConfigFailure(super.message);
}
