import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onion_mobile/core/auth/auth_controller.dart';
import 'package:onion_mobile/core/supabase_config.dart';
import 'package:onion_mobile/login/login_page.dart';
import 'package:onion_mobile/modules/home/pages/funcionario_home.dart';
import 'package:onion_mobile/modules/home/pages/lista_detalhe_page.dart';
import 'package:onion_mobile/modules/lista/lista.dart';
import 'package:onion_mobile/modules/lista/lista_controller.dart';
import 'package:onion_mobile/modules/produto/produto_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseClient>.value(value: SupabaseConfig.client),
        ChangeNotifierProvider(create: (_) => AuthController(), lazy: false),
        ChangeNotifierProvider(create: (_) => ListaController()),
        ChangeNotifierProvider(create: (_) => ProdutoController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Onion App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const FuncionarioHome(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/lista_detalhes') {
            final lista = settings.arguments as Lista;
            return MaterialPageRoute(
              builder: (context) => ListaDetalhesPage(lista: lista),
            );
          }
          return null;
        },
        home: Consumer<AuthController>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return auth.isAuthenticated
                ? const FuncionarioHome()
                : const LoginPage();
          },
        ),
      ),
    );
  }
}
