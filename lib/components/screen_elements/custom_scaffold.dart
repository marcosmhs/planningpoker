import 'package:flutter/material.dart';

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
      bottomNavigationBar: bottomNavigationBar,
      drawer: showAppDrawer ? drawer : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
