import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:metallica_map/constants.dart';

import '../model/StyleInfo.dart';
import '../model/concert.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  MapboxMapController? controller;
  int selectedStyleId = 0;
  List<Concert> _concerts = [];

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

  @override
  void initState() {
    super.initState();
    readJson();
  }

  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
    controller.onFeatureTapped.add(onFeatureTap);
  }

  void onFeatureTap(
      dynamic featureId, Point<double> point, LatLng latLng) async {
    print(
        "Map click: ${point.x},${point.y}   ${latLng.latitude}/${latLng.longitude}, featureId=$featureId");
    List features = await controller!.queryRenderedFeatures(
        point,
        [MapConstants.concertClusterLayerID, MapConstants.concertCountLayerID],
        null);
    features.forEach((feature) {
      if (feature["properties"]["cluster"] == true) {
        print(feature["properties"]["concert_ids"]);
      } else {
        print(feature["properties"]["id"]);
      }
    });

    // Concert concert =
    //     _concerts.firstWhere((element) => element.id == featureId.toString());
  }

  static Future<void> addGeojsonCluster(MapboxMapController controller) async {
    await controller.addSource(
        MapConstants.concertSourceId,
        const GeojsonSourceProperties(
          data: MapConstants.geoJsonData,
          cluster: true,
          clusterMaxZoom: 14,
          clusterRadius: 50,
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

  static const _stylesAndLoaders = [
    StyleInfo(
      name: "Geojson cluster",
      baseStyle: MapboxStyles.LIGHT,
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

  _onStyleLoadedCallback() async {
    final styleInfo = _stylesAndLoaders[selectedStyleId];
    styleInfo.addDetails(controller!);
    controller!
        .animateCamera(CameraUpdate.newCameraPosition(styleInfo.position));
  }

  @override
  Widget build(BuildContext context) {
    final styleInfo = _stylesAndLoaders[selectedStyleId];
    final nextName =
        _stylesAndLoaders[(selectedStyleId + 1) % _stylesAndLoaders.length]
            .name;
    return Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(32.0),
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.swap_horiz),
            label: SizedBox(
                width: 120, child: Center(child: Text("To $nextName"))),
            onPressed: () => setState(
              () => selectedStyleId =
                  (selectedStyleId + 1) % _stylesAndLoaders.length,
            ),
          ),
        ),
        body: MapboxMap(
          styleString: styleInfo.baseStyle,
          accessToken: MapConstants.mapBoxToken,
          onMapCreated: _onMapCreated,
          initialCameraPosition: styleInfo.position,
          onStyleLoadedCallback: _onStyleLoadedCallback,
        ));
  }
}
