import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'concert.dart';

class MarkerPopup extends StatelessWidget {
  const MarkerPopup(this.concert, {super.key});

  final Concert concert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: 300,
      height: 150,
      color: Colors.white,
      child: GestureDetector(
        onTap: () => _launchUrl(Uri.parse(concert.link)),
        child: Column(
          children: [
            Text(concert.date),
            Text(concert.address),
            Text(concert.place),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }
}
