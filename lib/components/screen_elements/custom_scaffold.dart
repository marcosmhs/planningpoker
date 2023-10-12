import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final Widget? title;
  final bool showAppDrawer;
  final bool showAppBar;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;

  const CustomScaffold(
      {Key? key,
      this.title,
      this.drawer,
      this.showAppBar = true,
      required this.body,
      this.floatingActionButton,
      this.showAppDrawer = true,
      this.appBarActions,
      this.bottomNavigationBar,
      this.backgroundColor,
      this.appBar})
      : super(key: key);

  void _launchUrl({required String url}) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Não consegui abrir o link $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar ??
          (showAppBar
              ? AppBar(
                  title: title,
                  actions: appBarActions,
                )
              : null),
      bottomNavigationBar: Stack(
        children: [
          //bottomNavigationBar,
          Container(
            height: MediaQuery.of(context).size.height * 0.08,
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            bottom: 0.0,
            child: Card(
              //color: Theme.of(context).primaryColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Desenvolvido por Marcos H. Silva',
                      style: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize, color: Colors.black54),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _launchUrl(url: 'mailto:marcosmhs@live.com'),
                          child: const Text(
                            'marcosmhs@live.com',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _launchUrl(url: 'https://github.com/marcosmhs/'),
                          child: const Text(
                            'https://github.com/marcosmhs/',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: showAppDrawer ? drawer : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
