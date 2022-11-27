import 'package:flutter/material.dart';
import 'package:metallica_map/link_ext.dart';

import '../model/concert.dart';

class PopupConcertWidget extends StatefulWidget {
  const PopupConcertWidget(this.concerts, this.onCloseClick, {super.key});

  final List<Concert> concerts;
  final Function() onCloseClick;

  @override
  State<PopupConcertWidget> createState() => _PopupConcertWidgetState();
}

class _PopupConcertWidgetState extends State<PopupConcertWidget> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 400,
          height: 220,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF282828),
          ),
          child: Wrap(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Concert info",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onCloseClick,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.concerts[current].date),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(widget.concerts[current].address),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(widget.concerts[current].place),
                        )
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.launch_outlined),
                      onPressed: () => openUrl(widget.concerts[current].link),
                      color: Colors.white,
                    ),
                    contentPadding: EdgeInsets.symmetric(),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.navigate_before),
                        onPressed: () {
                          setState(() {
                            if (current > 0) {
                              current = current - 1;
                            }
                          });
                        },
                        color: current > 0 ? Colors.white : Colors.white30,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "${current + 1}/${widget.concerts.length}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next),
                        onPressed: () {
                          setState(() {
                            if (current < widget.concerts.length - 1) {
                              current = current + 1;
                            }
                          });
                        },
                        color: current + 1 < widget.concerts.length
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
