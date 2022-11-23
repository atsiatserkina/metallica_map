import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'AppConstants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PopupController _popupController = PopupController();
  List<Marker> markers = [];
  List concerts = [];

  // Fetch content from the json file
  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('assets/metallica_concerts.json');
    final data = await json.decode(response);

    List items = data["concerts"];
    List<Marker> m = items
        .map((i) => Marker(
              height: 30,
              width: 30,
              point: LatLng(i["lat"], i["lng"]),
              builder: (ctx) => const Icon(
                Icons.music_note_rounded,
                color: Colors.amber,
              ),
            ))
        .toList();

    setState(() {
      concerts = items;
      markers = m;
    });
  }

  @override
  void initState() {
    super.initState();
    readJson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          minZoom: 2,
          maxZoom: 18,
          zoom: 4,
          center: LatLng(38, -87),
          maxBounds: LatLngBounds(
            LatLng(-90, -180.0),
            LatLng(90.0, 180.0),
          ),
          onTap: (_, __) => _popupController.hideAllPopups(),
        ),
        children: <Widget>[
          TileLayer(
              urlTemplate:
                  "https://api.mapbox.com/styles/v1/alexmo/{mapStyleId}/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
              additionalOptions: const {
                'mapStyleId': AppConstants.mapBoxStyleId,
                'accessToken': AppConstants.mapBoxAccessToken,
              }),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 400,
              size: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              fitBoundsOptions: const FitBoundsOptions(
                padding: EdgeInsets.all(50),
                maxZoom: 15,
              ),
              markers: markers,
              popupOptions: PopupOptions(
                  popupState: PopupState(),
                  popupSnap: PopupSnap.markerTop,
                  popupController: _popupController,
                  popupBuilder: (_, marker) => Container(
                    width: 200,
                    height: 100,
                    color: Colors.white,
                    child: GestureDetector(
                      onTap: () => debugPrint('Popup tap!'),
                      child: Text(
                        'Container popup for marker at ${marker.point}',
                      ),
                    ),
                  )),
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.orange),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
