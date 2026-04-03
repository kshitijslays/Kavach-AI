import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const String overpassApiUrl = 'https://overpass-api.de/api/interpreter';

class RouteBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  RouteBounds({
    required this.north,
    required this.south,
    required this.east,
    required this. west,
  });
}

class LightingData {
  final String id;
  final LatLng? position;
  final String type; // 'street_lamp' or 'road_segment'
  final List<LatLng>? geometry;
  final bool? isLit;
  final String? roadType;

  LightingData({
    required this.id,
    this.position,
    required this.type,
    this.geometry,
    this.isLit,
    this.roadType,
  });
}

class BusinessPopulationData {
  final List<LatLng> businessPoints;
  final List<List<LatLng>> populationWays;

  BusinessPopulationData(this.businessPoints, this.populationWays);
}

Future<List<LightingData>> fetchStreetLightsInArea(RouteBounds bounds) async {
  final north = bounds.north.clamp(-90.0, 90.0);
  final south = bounds.south.clamp(-90.0, 90.0);
  final east = bounds.east.clamp(-180.0, 180.0);
  final west = bounds.west.clamp(-180.0, 180.0);

  final query = """
[out:json][timeout:25];
(
  node[highway=street_lamp]($south,$west,$north,$east);
  way[highway][lit=yes]($south,$west,$north,$east);
  way[highway][lit=no]($south,$west,$north,$east);
);
out geom;
""";

  try {
    print('Fetching street lighting data for bounds: $north, $south, $east, $west');

    final response = await http.post(
      Uri.parse(overpassApiUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Kavach-App/1.0'
      },
      body: 'data=${Uri.encodeComponent(query)}',
    );

    if (response.statusCode != 200) {
      print('Overpass API responded with status: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    return _processStreetLightData(data);
  } catch (error) {
    print('Error fetching street lighting data: $error');
    return [];
  }
}

List<LightingData> _processStreetLightData(Map<String, dynamic> osmData) {
  if (!osmData.containsKey('elements')) return [];

  final List<LightingData> lights = [];
  try {
    for (var element in osmData['elements']) {
      final tags = element['tags'] as Map<String, dynamic>?;

      if (element['type'] == 'node' && tags?['highway'] == 'street_lamp') {
        lights.add(LightingData(
          id: element['id'].toString(),
          position: LatLng(element['lat'], element['lon']),
          type: 'street_lamp',
        ));
      }

      if (element['type'] == 'way' && tags != null && tags.containsKey('highway') && element['geometry'] != null) {
        final isLit = tags['lit'] == 'yes';
        final List<LatLng> geom = (element['geometry'] as List).map((p) {
          return LatLng(p['lat'], p['lon']);
        }).toList();

        lights.add(LightingData(
          id: element['id'].toString(),
          type: 'road_segment',
          geometry: geom,
          isLit: isLit,
          roadType: tags['highway'],
        ));
      }
    }
    print('Processed ${lights.length} lighting elements');
    return lights;
  } catch (error) {
    print('Error processing street light data: $error');
    return [];
  }
}

List<LightingData> generateFallbackLightingData(RouteBounds bounds) {
  print('Using fallback lighting data');
  final List<LightingData> lights = [];
  final double areaApprox = (bounds.north - bounds.south) * 100;
  final int numLamps = min(20, areaApprox.floor());
  final random = Random();

  for (int i = 0; i < numLamps; i++) {
    final lat = bounds.south + random.nextDouble() * (bounds.north - bounds.south);
    final lon = bounds.west + random.nextDouble() * (bounds.east - bounds.west);

    lights.add(LightingData(
      id: 'fallback_$i',
      position: LatLng(lat, lon),
      type: 'street_lamp',
    ));
  }
  return lights;
}

RouteBounds calculateRouteBounds(LatLng origin, LatLng destination) {
  const margin = 0.01; // ~1km buffer
  return RouteBounds(
    north: max(origin.latitude, destination.latitude) + margin,
    south: min(origin.latitude, destination.latitude) - margin,
    east: max(origin.longitude, destination.longitude) + margin,
    west: min(origin.longitude, destination.longitude) - margin,
  );
}

Future<BusinessPopulationData> fetchBusinessAndPopulationData(RouteBounds bounds) async {
  final north = bounds.north.clamp(-90.0, 90.0);
  final south = bounds.south.clamp(-90.0, 90.0);
  final east = bounds.east.clamp(-180.0, 180.0);
  final west = bounds.west.clamp(-180.0, 180.0);

  final query = """
[out:json][timeout:30];
(
  node[shop]($south,$west,$north,$east);
  node[amenity~"restaurant|cafe|bar|pub|bank|pharmacy|hotel|clinic|hospital|school|mall"]($south,$west,$north,$east);
  way[shop]($south,$west,$north,$east);
  way[amenity~"restaurant|cafe|bar|pub|bank|pharmacy|hotel|clinic|hospital|school|mall"]($south,$west,$north,$east);
  way[landuse=residential]($south,$west,$north,$east);
  way[landuse=urban]($south,$west,$north,$east);
);
out center;""";

  try {
    final response = await http.post(
      Uri.parse(overpassApiUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Kavach-App/1.0'
      },
      body: 'data=${Uri.encodeComponent(query)}',
    );

    if (response.statusCode != 200) {
      return BusinessPopulationData([], []);
    }

    final data = jsonDecode(response.body);
    final List<LatLng> businessPoints = [];
    final List<List<LatLng>> populationWays = [];

    for (var el in data['elements'] ?? []) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      
      if (el['type'] == 'node' && (tags.containsKey('shop') || tags.containsKey('amenity'))) {
        businessPoints.add(LatLng(el['lat'], el['lon']));
      }

      if (el['type'] == 'way' && el['geometry'] != null && (tags['landuse'] == 'residential' || tags['landuse'] == 'urban')) {
        final List<LatLng> geom = (el['geometry'] as List).map((p) => LatLng(p['lat'], p['lon'])).toList();
        populationWays.add(geom);
      }
    }

    return BusinessPopulationData(businessPoints, populationWays);
  } catch (error) {
    print('Error fetching business/population data: $error');
    return BusinessPopulationData([], []);
  }
}
