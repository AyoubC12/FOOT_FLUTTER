/// Authentication contract. Tokens are stored on device; API keys are not.
abstract interface class AuthGateway {
  Future<void> login({required String email, required String password});

  Future<void> register({
    required String username,
    required String email,
    required String password,
  });
}
