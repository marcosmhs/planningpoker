import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/visualizations/landing_screen.dart';
import 'package:planningpoker/features/planning_poker/visualizations/planning_poker_screen.dart';
import 'package:planningpoker/features/main/visualizations/screen_not_found.dart';
import 'package:planningpoker/features/planning_data/visualizations/planning_form.dart';
import 'package:planningpoker/features/story/visualizations/story_form.dart';
import 'package:planningpoker/features/user/model/user.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:planningpoker/features/user/widgets/user_form.dart';
import 'package:planningpoker/local_data_controller.dart';
import 'package:teb_package/teb_package.dart';
import 'firebase_options.dart';

class XDPathUrlStrategy extends HashUrlStrategy {
  // Creates an instance of [PathUrlStrategy].
  // The [PlatformLocation] parameter is useful for testing to mock out browser interactions.
  XDPathUrlStrategy([
    super.platformLocation,
  ]) : _basePath = stripTrailingSlash(extractPathname(checkBaseHref(
          platformLocation.getBaseHref(),
        )));

  final String _basePath;

  @override
  String prepareExternalUrl(String internalUrl) {
    if (internalUrl.isNotEmpty && !internalUrl.startsWith('/')) {
      internalUrl = '/$internalUrl';
    }
    return '$_basePath/';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setUrlStrategy(XDPathUrlStrategy());

  var tebThemeController = TebThemeController(
    lightThemeAssetPath: 'assets/light_theme.json',
    darkThemeAssetPath: 'assets/dark_theme.json',
    useMaterial3: false,
    useDebugLog: true,
    fireStoreInstance: FirebaseFirestore.instance,
  );

  await tebThemeController.loadThemeData;

  var localThemeMode = await LocalDataController().getLocalThemeMode();

  runApp(PlanningPokerMain(
    darkThemeData: tebThemeController.darkThemeData,
    lightThemeData: tebThemeController.lightThemeData,
    localThemeMode: localThemeMode,
  ));
}

class PlanningPokerMain extends StatefulWidget {
  final ThemeData darkThemeData;
  final ThemeData lightThemeData;
  final ThemeMode? localThemeMode;
  const PlanningPokerMain({
    super.key,
    required this.darkThemeData,
    required this.lightThemeData,
    this.localThemeMode,
  });

  @override
  State<PlanningPokerMain> createState() => _PlanningPokerMainState();

  // ignore: library_private_types_in_public_api
  static _PlanningPokerMainState? of(BuildContext context) => context.findAncestorStateOfType<_PlanningPokerMainState>();
}

class _PlanningPokerMainState extends State<PlanningPokerMain> {
  late ThemeMode _themeMode;
  @override
  void initState() {
    super.initState();
    _themeMode = widget.localThemeMode ?? ThemeMode.light;
  }

  void changeTheme({ThemeMode? localThemeMode}) {
    if (localThemeMode != null) {
      LocalDataController().saveUserThemeMode(userThemeMode: UserThemeMode(themeName: localThemeMode.name));
      setState(() => _themeMode = localThemeMode);
      return;
    }

    if (_themeMode == ThemeMode.dark) {
      LocalDataController().saveUserThemeMode(userThemeMode: UserThemeMode(themeName: ThemeMode.light.name));
      setState(() => _themeMode = ThemeMode.light);
    } else {
      LocalDataController().saveUserThemeMode(userThemeMode: UserThemeMode(themeName: ThemeMode.dark.name));
      setState(() => _themeMode = ThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: widget.darkThemeData,
      theme: widget.lightThemeData,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pt-br', ''),
      ],
      title: 'Planning Poker',
      routes: {
        Routes.landingScreen: (ctx) => const LandingScreen(),
        Routes.mainScreen: (ctx) => const PlanningPokerScreen(),
        Routes.planningDataForm: (ctx) => const PlanningForm(),
        Routes.storyForm: (ctx) => const StoryForm(),
        Routes.userForm: (ctx) => const UserForm(),
      },
      initialRoute: Routes.landingScreen,
      // Executado quando uma tela não é encontrada
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) {
          return ScreenNotFound(settings.name.toString());
        });
      },
    );
  }
}
