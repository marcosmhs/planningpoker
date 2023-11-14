import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planningpoker/features/main/hive_controller.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/visualizations/landing_screen.dart';
import 'package:planningpoker/features/main/visualizations/main_screen.dart';
import 'package:planningpoker/features/main/visualizations/screen_not_found.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_data_form.dart';
import 'package:planningpoker/features/story/visualizations/story_form.dart';
import 'package:planningpoker/features/user/model/user.dart';

import 'package:json_theme/json_theme.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
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

  await Hive.initFlutter();
  Hive.registerAdapter(PlanningDataAdapter());
  Hive.registerAdapter(RoleAdapter());
  Hive.registerAdapter(UserAdapter());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setUrlStrategy(XDPathUrlStrategy());

  var darkThemeData = ThemeData();
  var lightThemeData = ThemeData();

  var dartThemeStr = await rootBundle.loadString('dark_theme.json');
  var darkThemeJson = json.decode(dartThemeStr);
  darkThemeData = ThemeDecoder.decodeThemeData(
        darkThemeJson,
        validate: true,
      ) ??
      ThemeData();

  var lightThemeStr = await rootBundle.loadString('light_theme.json');
  var lightThemeJson = json.decode(lightThemeStr);
  lightThemeData = ThemeDecoder.decodeThemeData(
        lightThemeJson,
        validate: true,
      ) ??
      ThemeData();

  var localThemeMode = await HiveController().getLocalThemeMode();

  runApp(PlanningPokerMain(
    darkThemeData: darkThemeData,
    lightThemeData: lightThemeData,
    localThemeMode: localThemeMode,
  ));
}

class PlanningPokerMain extends StatefulWidget {
  final ThemeData darkThemeData;
  final ThemeData lightThemeData;
  final ThemeMode? localThemeMode;
  const PlanningPokerMain({
    Key? key,
    required this.darkThemeData,
    required this.lightThemeData,
    this.localThemeMode,
  }) : super(key: key);

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
      HiveController().saveThemeMode(themeMode: localThemeMode);
      setState(() => _themeMode = localThemeMode);
      return;
    }

    if (_themeMode == ThemeMode.dark) {
      HiveController().saveThemeMode(themeMode: ThemeMode.light);
      setState(() => _themeMode = ThemeMode.light);
    } else {
      HiveController().saveThemeMode(themeMode: ThemeMode.dark);
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
        Routes.mainScreen: (ctx) => const MainScreen(),
        Routes.planningDataForm: (ctx) => const PlanningDataForm(),
        Routes.storyForm: (ctx) => const StoryForm(),
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
