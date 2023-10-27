import 'package:flutter/material.dart';
import 'package:teb_package/util/teb_url_manager.dart';

class BottonInfo extends StatelessWidget {
  const BottonInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return size.height <= 600
        ? Container(height: 0)
        : Stack(
            children: [
              Container(height: MediaQuery.of(context).size.height * 0.07),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Desenvolvido por ',
                              style:
                                  TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize, color: Colors.black54),
                            ),
                            InkWell(
                              onTap: () => TebUrlManager.launchUrl(url: 'https://www.marcosmhs.com.br'),
                              child: Text(
                                'Marcos H. Silva',
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => TebUrlManager.launchUrl(url: 'mailto:marcosmhs@live.com'),
                              child: const Text('marcosmhs@live.com', style: TextStyle(color: Colors.black54)),
                            ),
                            const SizedBox(width: 20),
                            InkWell(
                              onTap: () => TebUrlManager.launchUrl(url: 'https://github.com/marcosmhs/'),
                              child: const Text('https://github.com/marcosmhs/', style: TextStyle(color: Colors.black54)),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
