import 'package:hive_flutter/hive_flutter.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/visualizations/landing_screen.dart';
import 'package:planningpoker/features/main/visualizations/main_screen.dart';
import 'package:planningpoker/features/main/visualizations/screen_not_found.dart';
import 'package:planningpoker/features/planning_poker/planning_controller.dart';
import 'package:planningpoker/features/planning_poker/planning_poker.dart';
import 'package:planningpoker/features/planning_poker/planning_data_form.dart';
import 'package:planningpoker/features/story/story_controller.dart';
import 'package:planningpoker/features/story/story_form.dart';
import 'package:planningpoker/features/user/user.dart';
import 'package:planningpoker/features/user/user_controller.dart';
import 'package:provider/provider.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(PlanningDataAdapter());
  Hive.registerAdapter(RoleAdapter());
  Hive.registerAdapter(UserAdapter());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PlanningPoker(),
    supportedLocales: [
      Locale('en', ''),
      Locale('pt-br', ''),
    ],
  ));
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
          Routes.mainScreen: (ctx) => MainScreen(),
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
