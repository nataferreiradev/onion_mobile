import 'package:flutter/material.dart';
import 'package:onion_mobile/core/supabase_config.dart';
import 'package:onion_mobile/modules/lista/lista.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListaController extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  List<Lista> listas = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<int?> _getUsuarioId(String userId) async {
    try {
      final response = await _supabase
          .from('usuario')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return response['id'] as int?;
    } catch (e) {
      debugPrint('Erro ao buscar usuario_id: $e');
      return null;
    }
  }

  Future<void> fetchListas() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final usuarioId = await _getUsuarioId(user.id);
        if (usuarioId != null) {
          final response = await _supabase
              .from('lista')
              .select()
              .eq('usuario_id', usuarioId)
              .order('id', ascending: false);

          debugPrint('Response from fetchListas: $response');

          listas = (response as List)
              .map<Lista>(
                (item) => Lista.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else {
          debugPrint('Usuario ID não encontrado');
          listas = [];
        }
      } else {
        debugPrint('Usuário não autenticado');
        listas = [];
      }
    } catch (e) {
      debugPrint('Erro ao buscar listas: $e');
      listas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createLista(String descricao, DateTime data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      await _supabase.from('lista').insert({
        'descricao': descricao,
        'data': data.toIso8601String(),
        'usuario_id': usuarioId,
      });

      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao criar lista: $e');
      rethrow;
    }
  }

  Future<void> updateLista(int id, String descricao, DateTime data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      await _supabase
          .from('lista')
          .update({'descricao': descricao, 'data': data.toIso8601String()})
          .eq('id', id)
          .eq('usuario_id', usuarioId);

      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao atualizar lista: $e');
      rethrow;
    }
  }

  Future<void> deleteLista(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      await _supabase
          .from('lista')
          .delete()
          .eq('id', id)
          .eq('usuario_id', usuarioId);

      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao excluir lista: $e');
      rethrow;
    }
  }

  Future<void> duplicateLista(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      final originalResponse = await _supabase
          .from('lista')
          .select()
          .eq('id', id)
          .single();

      await _supabase.from('lista').insert({
        'descricao': '${originalResponse['descricao']} (Cópia)',
        'data': originalResponse['data'],
        'usuario_id': usuarioId,
      });

      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao duplicar lista: $e');
      rethrow;
    }
  }
}
