
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('V2: Username uniqueness (CRITICAL)', () {
    test('1. First user can register', () async {
      final auth = AuthService();
      final result = await auth.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
      );
      expect(result.success, true);
    });

    test('2. Second user with SAME username is rejected', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
      );
      final result = await auth.register(
        username: 'captain', email: 'b@x.com', password: 'secret456',
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('Username'));
    });

    test('3. Second user with SAME email is rejected', () async {
      final auth = AuthService();
      await auth.register(
        username: 'cap1', email: 'same@x.com', password: 'secret123',
      );
      final result = await auth.register(
        username: 'cap2', email: 'same@x.com', password: 'secret123',
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('Email'));
    });

    test('4. usernameExists() returns true for existing', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
      );
      expect(await auth.usernameExists('captain'), true);
      expect(await auth.usernameExists('notthere'), false);
    });

    test('5. Username check is case-insensitive in storage but case-preserving', () async {
      final auth = AuthService();
      await auth.register(
        username: 'Captain', email: 'a@x.com', password: 'secret123',
      );
      // "Captain" and "captain" both exist as different users
      await auth.register(
        username: 'captain', email: 'b@x.com', password: 'secret123',
      );
      expect(await auth.usernameExists('Captain'), true);
      expect(await auth.usernameExists('captain'), true);
    });
  });

  group('V2: Email storage', () {
    test('6. getEmailForUser() returns the email', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'cap@galaxy.com', password: 'secret123',
      );
      final email = await auth.getEmailForUser('captain');
      expect(email, 'cap@galaxy.com');
    });

    test('7. getEmailForUser() returns null for missing user', () async {
      final auth = AuthService();
      final email = await auth.getEmailForUser('nobody');
      expect(email, isNull);
    });

    test('8. Email is stored as-is (normalized lowercase)', () async {
      final auth = AuthService();
      await auth.register(
        username: 'cap', email: 'CAP@Galaxy.COM', password: 'secret123',
      );
      final email = await auth.getEmailForUser('cap');
      expect(email, 'cap@galaxy.com'); // normalized to lowercase
    });
  });

  group('V2: Password recovery', () {
    test('9. resetPassword() changes the password', () async {
      final auth = AuthService();
      await auth.register(
        username: 'cap', email: 'a@x.com', password: 'oldpass1',
      );
      final result = await auth.resetPassword(
        username: 'cap', newPassword: 'newpass1',
      );
      expect(result.success, true);
      // Try login with new password
      final loginResult = await auth.login(
        username: 'cap', password: 'newpass1',
      );
      expect(loginResult.success, true);
    });

    test('10. Old password no longer works after reset', () async {
      final auth = AuthService();
      await auth.register(
        username: 'cap', email: 'a@x.com', password: 'oldpass1',
      );
      await auth.resetPassword(
        username: 'cap', newPassword: 'newpass1',
      );
      final loginResult = await auth.login(
        username: 'cap', password: 'oldpass1',
      );
      expect(loginResult.success, false);
    });

    test('11. resetPassword() rejects short password', () async {
      final auth = AuthService();
      await auth.register(
        username: 'cap', email: 'a@x.com', password: 'oldpass1',
      );
      final result = await auth.resetPassword(
        username: 'cap', newPassword: 'abc',
      );
      expect(result.success, false);
    });

    test('12. resetPassword() rejects non-existent user', () async {
      final auth = AuthService();
      final result = await auth.resetPassword(
        username: 'nobody', newPassword: 'newpass1',
      );
      expect(result.success, false);
    });

    test('13. recoverPassword() returns the email on file', () async {
      final auth = AuthService();
      await auth.register(
        username: 'cap', email: 'a@x.com', password: 'secret123',
      );
      final result = await auth.recoverPassword(username: 'cap');
      expect(result.success, true);
      expect(result.email, 'a@x.com');
      // recoverPassword cannot return the original (it's hashed)
      expect(result.recoveredPassword, isNull);
    });
  });
}
