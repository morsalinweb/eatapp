// path: lib/providers/auth_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/navigation.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/socket_service.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/customer/customer_shell.dart';
import '../screens/vendor/vendor_shell.dart';
import '../screens/vendor/application/application_pending_screen.dart';
import '../screens/vendor/application/vendor_application_screen.dart';

class AuthProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  AppUser? _currentUser;
  VendorStatus? _vendorApplicationStatus;
  bool _loading = false;
  String? _error;

  bool _suppressAutoRoute = false;

  StreamSubscription<AuthState>? _authStateSubscription;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  VendorStatus? get vendorApplicationStatus => _vendorApplicationStatus;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _authStateSubscription = _client.auth.onAuthStateChange.listen((data) {
      final isFreshSignIn = data.event == AuthChangeEvent.signedIn;
      if (isFreshSignIn && !_suppressAutoRoute && _currentUser == null) {
        _autoRouteAfterDeepLinkSignIn();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<bool> tryRestoreSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return false;
    try {
      await _loadProfile();
      SocketService.instance.connect();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadProfile() async {
    final json = await ApiClient.instance.get('/auth/me');
    _currentUser = AppUser.fromJson(json['profile']);
    if (_currentUser!.role == UserRole.vendor) {
      await refreshVendorApplicationStatus();
    }
    notifyListeners();
  }

  Future<void> refreshVendorApplicationStatus() async {
    try {
      final json = await ApiClient.instance.get('/vendors/apply/status');
      final app = json['application'];
      _vendorApplicationStatus = app != null ? vendorStatusFromApi(app['status']) : null;
    } catch (_) {
      _vendorApplicationStatus = null;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    _suppressAutoRoute = true;
    notifyListeners();
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      await _loadProfile();
      SocketService.instance.connect();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Could not log in. Please try again.';
      return false;
    } finally {
      _loading = false;
      _suppressAutoRoute = false;
      notifyListeners();
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    _loading = true;
    _error = null;
    _suppressAutoRoute = true;
    notifyListeners();
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': userRoleToApi(role)},
        emailRedirectTo: 'com.eatapp.eat://login-callback',
      );
      if (_client.auth.currentSession != null) {
        await _loadProfile();
        SocketService.instance.connect();
      }
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Could not create your account. Please try again.';
      return false;
    } finally {
      _loading = false;
      _suppressAutoRoute = false;
      notifyListeners();
    }
  }

  Future<bool> submitVendorApplication({
    required String businessName,
    required VendorCategory category,
    required String description,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient.instance.post('/vendors/apply', body: {
        'business_name': businessName,
        'category': _categoryToApi(category),
        'description': description,
      });
      _vendorApplicationStatus = VendorStatus.pending;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({required String fullName, String? phone, String? avatarUrl}) async {
    try {
      final json = await ApiClient.instance.patch('/auth/me', body: {
        'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      _currentUser = AppUser.fromJson(json['profile']);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    SocketService.instance.disconnect();
    await _client.auth.signOut();
    _currentUser = null;
    _vendorApplicationStatus = null;
    notifyListeners();
  }

  /// DELETE /auth/me — permanently deletes the account and everything tied
  /// to it server-side (see auth.controller.js's deleteMe). Afterward, the
  /// local Supabase session is cleared too, since the account it belonged
  /// to no longer exists to validate any future request against.
  Future<bool> deleteAccount() async {
    try {
      await ApiClient.instance.delete('/auth/me');
      SocketService.instance.disconnect();
      await _client.auth.signOut();
      _currentUser = null;
      _vendorApplicationStatus = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> _autoRouteAfterDeepLinkSignIn() async {
    try {
      await _loadProfile();
      SocketService.instance.connect();
    } catch (_) {
      return;
    }

    final user = _currentUser;
    final navigator = rootNavigatorKey.currentState;
    if (user == null || navigator == null) return;

    Widget destination;
    switch (user.role) {
      case UserRole.admin:
        destination = const AdminShell();
        break;
      case UserRole.vendor:
        final status = _vendorApplicationStatus;
        if (status == VendorStatus.approved) {
          destination = const VendorShell();
        } else if (status == VendorStatus.pending) {
          destination = const ApplicationPendingScreen();
        } else {
          destination = const VendorApplicationScreen();
        }
        break;
      case UserRole.customer:
        destination = const CustomerShell();
        break;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  String _categoryToApi(VendorCategory c) {
    const map = {
      VendorCategory.tacos: 'tacos',
      VendorCategory.tamales: 'tamales',
      VendorCategory.iceCream: 'ice_cream',
      VendorCategory.bbq: 'bbq',
      VendorCategory.foodTruck: 'food_truck',
      VendorCategory.dessert: 'dessert',
      VendorCategory.drinks: 'drinks',
      VendorCategory.more: 'more',
    };
    return map[c] ?? 'more';
  }
}