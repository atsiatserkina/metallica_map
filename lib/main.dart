import 'package:flutter/material.dart';
import 'package:metallica_map/widget/map_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metallica concerts map',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MapWidget(),
    );
  }
}
