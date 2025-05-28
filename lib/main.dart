import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zing_mp3_clone/themes/theme_provider.dart';
import 'package:zing_mp3_clone/themes/light_mode.dart';
import 'package:zing_mp3_clone/themes/dark_mode.dart';

import 'screens/explorer/all_playlists_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/admin/music_manager_screen.dart';
import 'screens/admin/playlist_manager_screen.dart';
import 'providers/recent_search_provider.dart';
import './screens/common/account_screen.dart';
import './screens/auth/forgot_screen.dart';
import './screens/auth/login_screen.dart';
import './screens/auth/signup_screen.dart';
import './screens/common/playing_screen.dart';
import './screens/common/playlist_screen.dart';
import './screens/common/search_screen.dart';
import './screens/common/welcome_screen.dart';
import 'utils/config.dart';
import 'screens/common/home_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await MusicProvider.instance.fetchAndSetData();
  // await PlaylistProvider.instance.fetchAndSetData();
  // await PlayingLogProvider.instance.fetchAndSetData();
  // await RankedMusicProvider.instance.countAndSort();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<void> loadPreferences() async {
      if (FirebaseAuth.instance.currentUser != null) {
        await Config.instance.loadAccountData();
      }
      await RecentSearchProvider.instance.load();
    }

    return FutureBuilder(
        future: loadPreferences(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'Zing MP3',
                theme: lightMode,
                darkTheme: darkMode,
                themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  return Directionality(
                    textDirection: TextDirection.ltr,
                    child: child!,
                  );
                },
                initialRoute: Config.instance.myAccount == null
                    ? WelcomeScreen.routeName
                    : HomeScreen.routeName,
                routes: {
                  WelcomeScreen.routeName: (ctx) => const WelcomeScreen(),
                  LoginScreen.routeName: (ctx) => const LoginScreen(),
                  SignUpScreen.routeName: (ctx) => const SignUpScreen(),
                  ForgotScreen.routeName: (ctx) => const ForgotScreen(),
                  HomeScreen.routeName: (ctx) => const HomeScreen(),
                  AccountScreen.routeName: (ctx) => const AccountScreen(),
                  SearchScreen.routeName: (ctx) => const SearchScreen(),
                  PlayingScreen.routeName: (ctx) => const PlayingScreen(),
                  PlaylistScreen.routeName: (ctx) => const PlaylistScreen(),
                  AllPlaylistsScreen.routeName: (ctx) => const AllPlaylistsScreen(),
                  AdminScreen.routeName: (ctx) => const AdminScreen(),
                  MusicManagerScreen.routeName: (ctx) => MusicManagerScreen(),
                  PlaylistManagerScreen.routeName: (ctx) => const PlaylistManagerScreen(),
                },
              );
            },
          );
        });
  }
}
