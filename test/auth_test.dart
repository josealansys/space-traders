
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('V2: AuthService', () {
    test('1. Register a new user', () async {
      final auth = AuthService();
      final result = await auth.register(
        username: 'captain',
        email: 'captain@galaxy.com',
        password: 'secret123',
        rememberMe: false,
      );
      expect(result.success, true);
      expect(result.username, 'captain');
      expect(result.token, isNotNull);
    });

    test('2. Register rejects duplicate username', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
      );
      final result = await auth.register(
        username: 'captain', email: 'b@x.com', password: 'secret123',
      );
      expect(result.success, false);
      expect(result.errorMessage, contains('Username'));
    });

    test('3. Register rejects duplicate email', () async {
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

    test('4. Login with correct credentials', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'cap@x.com', password: 'secret123',
      );
      await auth.logout();
      final result = await auth.login(
        username: 'captain', password: 'secret123',
      );
      expect(result.success, true);
    });

    test('5. Login with wrong password fails', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'cap@x.com', password: 'secret123',
      );
      await auth.logout();
      final result = await auth.login(
        username: 'captain', password: 'wrongpass',
      );
      expect(result.success, false);
    });

    test('6. Validation: username too short', () async {
      final auth = AuthService();
      final result = await auth.register(
        username: 'ab', email: 'a@x.com', password: 'secret123',
      );
      expect(result.success, false);
    });

    test('7. Validation: password too short', () async {
      final auth = AuthService();
      final result = await auth.register(
        username: 'captain', email: 'a@x.com', password: '123',
      );
      expect(result.success, false);
    });

    test('8. Validation: invalid email', () async {
      final auth = AuthService();
      final result = await auth.register(
        username: 'captain', email: 'notanemail', password: 'secret123',
      );
      expect(result.success, false);
    });

    test('9. Remember me: session persists across "restart"', () async {
      // First session
      final auth1 = AuthService();
      await auth1.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
        rememberMe: true,
      );
      // Simulate app restart - new auth instance reads from prefs
      final auth2 = AuthService();
      final current = await auth2.currentUser();
      expect(current.user, isNotNull);
      expect(current.user!.username, 'captain');
    });

    test('10. Without remember me: session does not persist', () async {
      final auth1 = AuthService();
      await auth1.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
        rememberMe: false,
      );
      final auth2 = AuthService();
      final current = await auth2.currentUser();
      expect(current.user, isNull); // no remember-me
    });

    test('11. Password is hashed (not stored as plaintext)', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
      );
      // Read raw prefs to verify password is hashed
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('space_traders_users');
      expect(raw, isNotNull);
      expect(raw!.contains('secret123'), false); // plaintext should NOT be stored
    });

    test('12. Logout clears session but keeps remember-me', () async {
      final auth1 = AuthService();
      await auth1.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
        rememberMe: true,
      );
      await auth1.logout();
      // New auth instance still has remember-me
      final auth2 = AuthService();
      final current = await auth2.currentUser();
      expect(current.user, isNotNull);
    });

    test('13. Delete account', () async {
      final auth = AuthService();
      await auth.register(
        username: 'captain', email: 'a@x.com', password: 'secret123',
      );
      final deleted = await auth.deleteAccount('captain');
      expect(deleted, true);
      final current = await auth.currentUser();
      expect(current.user, isNull);
    });
  });
}
