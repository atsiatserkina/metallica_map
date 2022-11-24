import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:metallica_map/constants.dart';
import 'package:metallica_map/widget/popup_concert_widget.dart';

import '../model/style_info.dart';
import '../model/concert.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  MapboxMapController? controller;
  final pageController = PageController();
  int selectedStyleId = 0;
  List<Concert> _concerts = [];
  List<Concert> selectedConcerts = [];

  static const _stylesAndLoaders = [
    StyleInfo(
      name: "Geojson cluster",
      baseStyle: MapboxStyles.DARK,
      addDetails: addGeojsonCluster,
      position: CameraPosition(target: LatLng(30, 0), zoom: 2),
    ),
    // StyleInfo(
    //   name: "Geojson heatmap",
    //   baseStyle: MapboxStyles.DARK,
    //   addDetails: addGeojsonHeatmap,
    //   position: CameraPosition(target: LatLng(30, 0), zoom: 2),
    // )
  ];

  @override
  void initState() {
    super.initState();
    readJson();
  }

  @override
  Widget build(BuildContext context) {
    final styleInfo = _stylesAndLoaders[selectedStyleId];
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            minMaxZoomPreference: const MinMaxZoomPreference(2, 17),
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            styleString: styleInfo.baseStyle,
            accessToken: MapConstants.mapBoxToken,
            onMapCreated: _onMapCreated,
            initialCameraPosition: styleInfo.position,
            onStyleLoadedCallback: _onStyleLoadedCallback,
          ),
          Positioned(
            bottom: 30,
            right: 0,
            left: 0,
            child: Builder(
              builder: (BuildContext context) {
                if (selectedConcerts.isEmpty) {
                  return Container();
                } else {
                  return PopupConcertWidget(
                    selectedConcerts,
                    () {
                      setState(() {
                        selectedConcerts.clear();
                      });
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }

  // Fetch content from the json file
  Future<void> readJson() async {
    final String response = await rootBundle.loadString(MapConstants.jsonData);
    final data = await json.decode(response);
    List items = data["concerts"];
    List<Concert> concerts = items
        .map((item) => Concert(item["id"], item["address"], item["place"],
            item["date"], item["link"], item["lng"], item["lat"]))
        .toList();
    setState(() {
      _concerts = concerts;
    });
  }

  _onStyleLoadedCallback() async {
    final styleInfo = _stylesAndLoaders[selectedStyleId];
    styleInfo.addDetails(controller!);
    controller!
        .animateCamera(CameraUpdate.newCameraPosition(styleInfo.position));
  }

  static Future<void> addGeojsonCluster(MapboxMapController controller) async {
    await controller.addSource(
        MapConstants.concertSourceId,
        const GeojsonSourceProperties(
          data: MapConstants.geoJsonData,
          cluster: true,
          clusterMaxZoom: 17,
          clusterRadius: 40,
          clusterProperties: {
            "concert_ids": [
              "concat",
              [
                "concat",
                ["get", "id"],
                ","
              ],
            ],
          },
        ));
    await controller.addLayer(
      MapConstants.concertSourceId,
      MapConstants.concertClusterLayerID,
      const CircleLayerProperties(
        circleColor: [
          Expressions.step,
          [Expressions.get, 'point_count'],
          '#51bbd6',
          100,
          '#f1f075',
          750,
          '#f28cb1'
        ],
        circleRadius: [
          Expressions.step,
          [Expressions.get, 'point_count'],
          20,
          100,
          30,
          750,
          40
        ],
      ),
    );
    await controller.addLayer(
        MapConstants.concertSourceId,
        MapConstants.concertCountLayerID,
        const SymbolLayerProperties(
          textField: [Expressions.get, 'point_count_abbreviated'],
          textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          textSize: 12,
        ));
  }

  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
    controller.onFeatureTapped.add(onFeatureTap);
  }

  void onFeatureTap(
    dynamic featureId,
    Point<double> point,
    LatLng latLng,
  ) async {
    List features = await controller!.queryRenderedFeatures(
        point,
        [MapConstants.concertClusterLayerID, MapConstants.concertCountLayerID],
        null);

    for (var feature in features) {
      if (feature["properties"]["cluster"] == true) {
        List<String> ids = feature["properties"]["concert_ids"].split(",");
        List<Concert> concerts =
            _concerts.where((element) => ids.contains(element.id)).toList();
        setState(() {
          selectedConcerts = concerts;
        });
      } else {
        String id = feature["properties"]["id"];
        Concert concert = _concerts.firstWhere((element) => element.id == id);
        setState(() {
          selectedConcerts.clear();
          selectedConcerts.add(concert);
        });
      }
    }
  }
}
