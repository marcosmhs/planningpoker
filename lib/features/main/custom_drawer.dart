import 'package:flutter/material.dart';
import 'package:planningpoker/features/main/routes.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
    buildSignature: '',
    installerStore: '',
  );

  Column _option({
    required BuildContext context,
    required Icon icon,
    required String text,
    String route = '',
    Object? args,
    Function()? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: icon,
          title: Text(text),
          onTap: route == ''
              ? onTap
              : () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, route, arguments: args);
                },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Menu'),
            // remove o botão do drawer quando ele está aberto
            automaticallyImplyLeading: true,
          ),
          //const Spacer(),
          //_option(
          //  context: context,
          //  icon: const Icon(Icons.settings),
          //  text: 'Configurações',
          //  route: Routes.institutionConfigForm,
          //),
          _option(
            context: context,
            icon: const Icon(Icons.exit_to_app_sharp),
            text: 'Sair',
            onTap: () {
              Navigator.restorablePushNamedAndRemoveUntil(
                context,
                Routes.landingScreen,
                (route) => false,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Versão: ${_packageInfo.version}.${_packageInfo.buildNumber}'),
          )
        ],
      ),
    );
  }
}
