import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/core/network/api_exception.dart';

void main() {
  test('ApiException marks 401 as unauthorized', () {
    const error = ApiException('Sign in required', statusCode: 401);
    expect(error.isUnauthorized, isTrue);
    expect(error.toString(), contains('401'));
  });

  test('ApiException without status is not unauthorized', () {
    const error = ApiException('Network request failed');
    expect(error.isUnauthorized, isFalse);
    expect(error.toString(), 'Network request failed');
  });
}
