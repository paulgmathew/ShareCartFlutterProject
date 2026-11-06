import 'package:flutter_test/flutter_test.dart';
import 'package:share_cart/models/register_response_model.dart';
import 'package:share_cart/models/verify_email_response_model.dart';

void main() {
  group('email verification models', () {
    test('RegisterResponseModel parses registration payload', () {
      final model = RegisterResponseModel.fromJson({
        'message':
            'Registration successful. Please check your email to verify your account.',
        'email': 'user@example.com',
        'emailVerified': false,
      });

      expect(
        model.message,
        'Registration successful. Please check your email to verify your account.',
      );
      expect(model.email, 'user@example.com');
      expect(model.emailVerified, isFalse);
    });

    test('VerifyEmailResponseModel parses verification payload', () {
      final model = VerifyEmailResponseModel.fromJson({
        'message': 'Email verified successfully. You can now log in.',
        'email': 'user@example.com',
        'emailVerified': true,
      });

      expect(model.message, 'Email verified successfully. You can now log in.');
      expect(model.email, 'user@example.com');
      expect(model.emailVerified, isTrue);
    });
  });
}
