import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:onion_mobile/core/auth/auth_controller.dart';
import 'package:onion_mobile/modules/lista/lista.dart';
import 'package:onion_mobile/modules/lista/lista_controller.dart';
import 'package:provider/provider.dart';

class FuncionarioHome extends StatefulWidget {
  const FuncionarioHome({super.key});

  @override
  State<FuncionarioHome> createState() => _FuncionarioHomeState();
}

class _FuncionarioHomeState extends State<FuncionarioHome> {
  @override
  void initState() {
    super.initState();
    // Carregar listas ao iniciar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListaController>().fetchListas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Listas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthController>().signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Consumer<ListaController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.listas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma lista encontrada',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque no + para criar sua primeira lista',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchListas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.listas.length,
              itemBuilder: (context, index) {
                final lista = controller.listas[index];
                return _ListaCard(lista: lista);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNovaListaDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showNovaListaDialog(BuildContext context) async {
    final nomeController = TextEditingController();
    final dateController = TextEditingController();
    DateTime? selectedDate;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                hintText: 'Ex: Compras do mês',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data',
                hintText: 'Selecione uma data',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  selectedDate = date;
                  dateController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty) {
                try {
                  await context.read<ListaController>().createLista(
                    nomeController.text,
                    selectedDate ?? DateTime.now(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lista criada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao criar lista: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _ListaCard extends StatelessWidget {
  final Lista lista;

  const _ListaCard({required this.lista});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _confirmarExclusao(context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Excluir',
          ),
          SlidableAction(
            onPressed: (_) => _duplicarLista(context),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.copy,
            label: 'Duplicar',
          ),
        ],
      ),
      child: Card(
        child: ListTile(
          title: Text(lista.descricao),
          subtitle: Text(
            lista.data != null
                ? DateFormat('dd/MM/yyyy').format(lista.data!)
                : 'Sem data',
          ),
          leading: const CircleAvatar(child: Icon(Icons.list_alt)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/lista_detalhes', arguments: lista);
          },
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir esta lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<ListaController>().deleteLista(lista.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lista excluída com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir lista: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicarLista(BuildContext context) async {
    final nomeController = TextEditingController(
      text: '${lista.descricao} (Cópia)',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar Lista'),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(labelText: 'Nome da nova lista'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty) {
                try {
                  await context.read<ListaController>().duplicateLista(
                    lista.id,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lista duplicada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao duplicar lista: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );
  }
}
