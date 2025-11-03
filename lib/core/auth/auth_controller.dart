import 'package:flutter/material.dart';
import 'package:onion_mobile/core/supabase_config.dart';
import 'package:onion_mobile/modules/usuario/usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Usuario? _currentUser;

  Usuario? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthController() {
    _checkCurrentSession();
  }

  Future<void> _checkCurrentSession() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        await _loadOrCreateUser(session.user);
      }
    } catch (e) {
      debugPrint('Error checking session: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadOrCreateUser(response.user!);
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrCreateUser(User supabaseUser) async {
    try {
      final response = await SupabaseConfig.client
          .from('usuario')
          .select()
          .eq('user_id', supabaseUser.id)
          .single();

      _currentUser = Usuario.fromJson(response);
    } catch (e) {
      // User doesn't exist, create new one
      final response = await SupabaseConfig.client
          .from('usuario')
          .insert({'descricao': supabaseUser.email, 'user_id': supabaseUser.id})
          .select()
          .single();

      _currentUser = Usuario.fromJson(response);
    }
  }

  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
