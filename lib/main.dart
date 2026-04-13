import 'package:aullet/viewmodels/auth_view_model.dart';
import 'package:aullet/viewmodels/profile_view_model.dart';
import 'package:aullet/views/auth/login_view.dart';
import 'package:aullet/views/auth/signup_view.dart';
import 'package:aullet/views/home_view.dart';
import 'package:aullet/views/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnnonKey == null) {
    throw Exception(
      'errore nel file .env: manca SUPABASE_URL o SUPABASE_ANON_KEY',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Aullet',
            theme: ThemeData(useMaterial3: true),
            
            home: authVM.isLoggedIn 
                ? const HomeView() 
                : const LoginPage(),
                
            routes: {
              '/login': (_) => const LoginPage(),
              '/signup': (_) => const SignUpPage(),
              '/home': (_) => const HomeView(),
              '/profile': (_) => const ProfilePage(),
            },
          );
        },
      ),
    );
  }
}
