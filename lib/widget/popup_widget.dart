import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/concert.dart';

class PopupWidget extends StatelessWidget {
  const PopupWidget(this.concert, {super.key});

  final Concert concert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Wrap(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                concert.date,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                concert.address,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(concert.place),
              const SizedBox(height: 13),
              OutlinedButton(
                onPressed: () => _launchUrl(Uri.parse(concert.link)),
                child: const Text(
                  'MORE INFO',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF000000),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }
}
