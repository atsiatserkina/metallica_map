import 'package:mapbox_gl/mapbox_gl.dart';

class StyleInfo {
  final String name;
  final String baseStyle;
  final Future<void> Function(MapboxMapController) addDetails;
  final CameraPosition position;

  const StyleInfo(
      {required this.name,
      required this.baseStyle,
      required this.addDetails,
      required this.position});
}
