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
    final response = await _supabase
        .from('usuario')
        .select('id') // Assuming 'id' is the primary key in the 'usuario' table
        .eq(
          'user_id',
          userId,
        ) // Use the UUID to find the user in the 'usuario' table
        .single();

    return response['id']; // Return the ID from the 'usuario' table
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
              .eq(
                'usuario_id',
                usuarioId,
              ) // Use the ID from the 'usuario' table
              ;

          listas = response.map<Lista>((item) => Lista.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar listas: $e');
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

      // Get the usuario ID from the 'usuario' table
      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      // Now create the list
      await _supabase.from('lista').insert({
        'descricao': descricao,
        'data': data.toIso8601String(),
        'usuario_id': usuarioId, // Use the ID from the 'usuario' table
      });

      // Refresh the list of lists
      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao criar lista: $e');
      rethrow; // Rethrow the error for further handling
    }
  }

  Future<void> updateLista(int id, String descricao, DateTime data) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Get the usuario ID from the 'usuario' table
      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      // Update the list
      await _supabase
          .from('lista')
          .update({'descricao': descricao, 'data': data.toIso8601String()})
          .eq('id', id);

      // Refresh the list of lists
      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao atualizar lista: $e');
      rethrow; // Rethrow the error for further handling
    }
  }

  Future<void> deleteLista(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Get the usuario ID from the 'usuario' table
      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      // Delete the list
      await _supabase.from('lista').delete().eq('id', id);

      // Refresh the list of lists
      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao excluir lista: $e');
      rethrow; // Rethrow the error for further handling
    }
  }

  Future<void> duplicateLista(int id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Get the usuario ID from the 'usuario' table
      final usuarioId = await _getUsuarioId(user.id);
      if (usuarioId == null) {
        throw Exception('Usuário não encontrado na tabela usuario.');
      }

      // Fetch the original list
      final originalResponse = await _supabase
          .from('lista')
          .select()
          .eq('id', id)
          .single();

      // Create a duplicate of the list
      await _supabase.from('lista').insert({
        'descricao': '${originalResponse['descricao']} (Cópia)',
        'data': originalResponse['data'],
        'usuario_id': usuarioId, // Use the ID from the 'usuario' table
      });

      // Refresh the list of lists
      await fetchListas();
    } catch (e) {
      debugPrint('Erro ao duplicar lista: $e');
      rethrow; // Rethrow the error for further handling
    }
  }
}
