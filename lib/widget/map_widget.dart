import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:metallica_map/constants.dart';
import 'package:metallica_map/widget/popup_concert_widget.dart';

import '../link_ext.dart';
import '../model/concert.dart';
import '../model/style_info.dart';

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
      baseStyle: MapConstants.baseStyle,
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
            compassEnabled: false,
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
          ),
          Positioned(
            top: 3,
            left: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => openUrl("https://www.kontur.io/"),
                    child: const Image(
                      image: AssetImage('assets/kontur_map_logo.png'),
                      height: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => openUrl("https://www.metallica.com/tour/past/"),
                    child: const Image(
                      image: AssetImage('assets/metallica_logo.png'),
                      height: 30,
                    ),
                  )
                ],
              ),
            ),
          ),
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

  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
    controller.onFeatureTapped.add(onFeatureTap);
  }

  _onStyleLoadedCallback() async {
    final styleInfo = _stylesAndLoaders[selectedStyleId];
    styleInfo.addDetails(controller!);
    controller!
        .animateCamera(CameraUpdate.newCameraPosition(styleInfo.position));

    // Add icon from assets
    final ByteData bytes = await rootBundle.load(MapConstants.guitarPickPath);
    final Uint8List list = bytes.buffer.asUint8List();
    await controller!.addImage(MapConstants.guitarPickIcon, list);
    controller!.addSymbol(
      const SymbolOptions(
        geometry: LatLng(0, 0),
        iconImage: "assetImage",
      ),
    );
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
      MapConstants.concertClusterCircleLayerID,
      const CircleLayerProperties(circleColor: '#1d758a', circleRadius: 20),
      filter: ['has', 'point_count'],
    );
    await controller.addLayer(
        MapConstants.concertSourceId,
        MapConstants.concertClusterCountLayerID,
        const SymbolLayerProperties(
            textField: [Expressions.get, 'point_count_abbreviated'],
            textFont: ['Noto Sans Regular'],
            textColor: '#ffffff',
            textSize: 12));
    await controller.addLayer(
      MapConstants.concertSourceId,
      MapConstants.concertLayerID,
      const SymbolLayerProperties(
          iconImage: MapConstants.guitarPickIcon,
          textSize: 12,
          iconIgnorePlacement: true,
          iconAnchor: "bottom"),
      filter: ['!has', 'point_count'],
    );
  }

  void onFeatureTap(
    dynamic featureId,
    Point<double> point,
    LatLng latLng,
  ) async {
    List features = await controller!.queryRenderedFeatures(
      point,
      [
        MapConstants.concertClusterCircleLayerID,
        MapConstants.concertClusterCountLayerID,
        MapConstants.concertLayerID
      ],
      null,
    );

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
