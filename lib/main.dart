import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// BU FONKSIYON UYGULAMA BASLAMADAN ONCE FIREBASE'I HAZIRLAR
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase'i başlat
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Namer App',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
            ),
            // AuthGate: Giris yapilmis mi kontrol eden kapi
            home: AuthGate(),
          );
        },
      ),
    );
  }
}

// DURUM YONETIMI (VERITABANI GIBI CALISAN KISIM)
class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  
  // Favoriler Listesi
  var favorites = <WordPair>[];

  // AYARLAR (YENI EKLENDI)
  String language = 'TR'; // Varsayilan dil Turkce
  double textSize = 20.0; // Varsayilan yazi boyutu (M)

  // Kelime degistirme
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  // Favoriye ekleme/cikarma
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  // Favoriden SILME (YENI ISTENEN OZELLIK)
  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }

  // Dil Degistirme Ayari
  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  // Yazi Boyutu Ayari (S, M, L)
  void setTextSize(String size) {
    if (size == 'S') textSize = 14.0;
    if (size == 'M') textSize = 20.0;
    if (size == 'L') textSize = 30.0;
    notifyListeners();
  }
}

// ---------------------------------------------------------
// GIRIS KONTROL KAPISI (AUTH GATE)
// ---------------------------------------------------------
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Eger kullanici giris yapmissa -> Ana Uygulamayi Goster
        if (snapshot.hasData) {
          return MyHomePage();
        }
        // Giris yapmamissa -> Giris Ekranini Goster
        return LoginPage();
      },
    );
  }
}

// ---------------------------------------------------------
// GIRIS YAP / KAYIT OL EKRANI (LOGIN PAGE)
// ---------------------------------------------------------
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // Giris modunda miyiz? Yoksa Kayit mi?

  Future<void> _authenticate() async {
    try {
      if (_isLogin) {
        // GIRIS YAPMA ISLEMI
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // KAYIT OLMA ISLEMI
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      // Hata olursa ekrana yaz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-posta'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Şifre'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin; // Modu degistir (Giris <-> Kayit)
                      });
                    },
                    child: Text(_isLogin ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten üye misin? Giriş Yap'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ANA UYGULAMA EKRANI (MAIN SCREEN)
// ---------------------------------------------------------
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Uygulamanin durumuna (Settings) erisiyoruz
    var appState = context.watch<MyAppState>();

    // Dil Ayarina Gore Metinler
    var labels = appState.language == 'TR'
        ? ['Ana Sayfa', 'Favoriler', 'Ayarlar']
        : ['Home', 'Favorites', 'Settings'];

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = SettingsPage(); // YENI AYARLAR SAYFASI
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text(labels[0]),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text(labels[1]),
                  ),
                  NavigationRailDestination( // YENI AYARLAR BUTONU
                    icon: Icon(Icons.settings),
                    label: Text(labels[2]),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------
// KELIME URETME SAYFASI
// ---------------------------------------------------------
class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    // Dil Ayarina Gore Buton Yazilari
    String likeText = appState.language == 'TR' ? 'Beğen' : 'Like';
    String nextText = appState.language == 'TR' ? 'Sıradaki' : 'Next';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Yazi Boyutu Ayarina Gore Kart
          BigCard(pair: pair, textSize: appState.textSize),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text(likeText),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text(nextText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// KELIME KARTI
// ---------------------------------------------------------
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
    required this.textSize,
  });

  final WordPair pair;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Yazi stilini ayarlardan gelen boyuta gore ayarliyoruz
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontSize: textSize, // KULLANICININ SECTIGI BOYUT
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// FAVORILER SAYFASI (SILME OZELLIGI EKLENDI)
// ---------------------------------------------------------
class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var lang = appState.language;

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text(lang == 'TR' ? 'Henüz favori yok.' : 'No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(lang == 'TR' 
              ? '${appState.favorites.length} favorin var:' 
              : 'You have ${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase, style: TextStyle(fontSize: appState.textSize)),
            // YENI OZELLIK: SILME BUTONU
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                appState.removeFavorite(pair);
              },
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------
// AYARLAR SAYFASI (YENI)
// ---------------------------------------------------------
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var lang = appState.language;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. DIL AYARI
          Text(lang == 'TR' ? 'Dil Seçimi / Language' : 'Language Selection'),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => appState.setLanguage('TR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lang == 'TR' ? Colors.orange : Colors.grey[200]
                ),
                child: Text('Türkçe'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => appState.setLanguage('EN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lang == 'EN' ? Colors.orange : Colors.grey[200]
                ),
                child: Text('English'),
              ),
            ],
          ),
          
          Divider(height: 40, thickness: 2),

          // 2. METIN BOYUTU
          Text(lang == 'TR' ? 'Metin Boyutu' : 'Text Size'),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => appState.setTextSize('S'),
                child: Text('S'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => appState.setTextSize('M'),
                child: Text('M'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => appState.setTextSize('L'),
                child: Text('L'),
              ),
            ],
          ),
          
          Divider(height: 40, thickness: 2),

          // 3. CIKIS YAP BUTONU
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: Icon(Icons.logout),
            label: Text(lang == 'TR' ? 'Çıkış Yap' : 'Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}