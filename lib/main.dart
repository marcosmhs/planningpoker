import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/visualizations/landing_screen.dart';
import 'package:planningpoker/features/main/visualizations/main_screen.dart';
import 'package:planningpoker/features/main/visualizations/screen_not_found.dart';
import 'package:planningpoker/features/planning_poker/models/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/planning_poker/planning_data_form.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/story/visualizations/story_form.dart';
import 'package:planningpoker/features/user/visualizations/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:provider/provider.dart';

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

  runApp(const PlanningPoker());
}

class PlanningPoker extends StatefulWidget {
  const PlanningPoker({
    Key? key,
  }) : super(key: key);

  @override
  State<PlanningPoker> createState() => _Home();
}

class _Home extends State<PlanningPoker> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanningPokerController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => StoryController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}
