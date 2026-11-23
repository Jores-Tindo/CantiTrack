import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'db/app_db.dart';
import 'screens/accueil_screen.dart';
import 'screens/login_screen.dart';
import 'screens/menus_screen.dart';
import 'screens/plus_screen.dart';
import 'screens/registre_screen.dart';
import 'screens/stock_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CantiTrackApp());
}

class CantiTrackApp extends StatelessWidget {
  const CantiTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CantiTrack',
      debugShowCheckedModeBanner: false,
      theme: construireTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Racine(),
    );
  }
}

/// Affiche la connexion tant que l'utilisateur n'a pas saisi son code.
class _Racine extends StatefulWidget {
  const _Racine();

  @override
  State<_Racine> createState() => _RacineState();
}

class _RacineState extends State<_Racine> {
  bool _ouvert = false;
  Future<String?> _pin = AppDb.instance.param('pin_hash');

  @override
  Widget build(BuildContext context) {
    if (_ouvert) {
      return HomePage(
        onVerrouiller: () => setState(() {
          _ouvert = false;
          _pin = AppDb.instance.param('pin_hash');
        }),
      );
    }
    return FutureBuilder<String?>(
      future: _pin,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return LoginScreen(
          premiereFois: snap.data == null,
          onSuccess: () => setState(() => _ouvert = true),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onVerrouiller;

  const HomePage({super.key, required this.onVerrouiller});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AccueilScreen(allerA: (i) => setState(() => _index = i)),
          const StockScreen(),
          const MenusScreen(),
          const RegistreScreen(),
          PlusScreen(onVerrouiller: widget.onVerrouiller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Stock'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menus'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Registre'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'Plus'),
        ],
      ),
    );
  }
}
