import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/street_lighting_service.dart';

const String orsApiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjBiYjM1NDViZDViNzQ3YjhhNTdhMzNiNWNjMDQ4ZWI0IiwiaCI6Im11cm11cjY0In0=";

class Suggestion {
  final String label;
  final LatLng point;

  Suggestion(this.label, this.point);
}

class RouteSegment {
  final List<LatLng> points;
  final String lighting; // 'well_lit', 'lit', 'unlit'
  final Color color;

  RouteSegment(this.points, this.lighting, this.color);
}

class SafeRouteResult {
  final List<RouteSegment> segments;
  final int score;
  final int lightingScore;
  final int businessScore;
  final int populationScore;
  final List<LatLng> allPoints;
  final double distance;
  final double duration;
  final String distanceText;
  final String durationText;
  final String summary;
  final LatLng destCoord;

  SafeRouteResult({
    required this.segments,
    required this.score,
    required this.lightingScore,
    required this.businessScore,
    required this.populationScore,
    required this.allPoints,
    required this.distance,
    required this.duration,
    required this.distanceText,
    required this.durationText,
    required this.summary,
    required this.destCoord,
  });
}

class SafeRouteMapScreen extends StatefulWidget {
  const SafeRouteMapScreen({Key? key}) : super(key: key);

  @override
  State<SafeRouteMapScreen> createState() => _SafeRouteMapScreenState();
}

class _SafeRouteMapScreenState extends State<SafeRouteMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  String _locationLabel = "Current Location";
  bool _usingCurrentLocation = true;

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  List<Suggestion> _sourceSuggestions = [];
  List<Suggestion> _destSuggestions = [];
  bool _showSourceSuggestions = false;
  bool _showDestSuggestions = false;

  List<SafeRouteResult> _routes = [];
  int _selectedRouteIndex = 0;

  bool _loading = false;
  bool _locationLoading = true;
  bool _lightingLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fallbackLocation();
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _fallbackLocation();
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _fallbackLocation();
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _locationLabel = "Current GPS Location"; 
      _locationLoading = false;
    });
    
    // Move map if map is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController.move(_userLocation!, 15.0);
    });
  }

  void _fallbackLocation() {
    setState(() {
      _userLocation = const LatLng(26.9124, 75.7873); // Jaipur fallback
      _locationLabel = "Jaipur (Fallback)";
      _locationLoading = false;
    });
  }

  Future<List<Suggestion>> _fetchSuggestions(String text) async {
    if (text.length < 3) return [];
    final url = "https://api.openrouteservice.org/geocode/autocomplete?api_key=$orsApiKey&text=${Uri.encodeComponent(text)}&size=5";
    try {
      debugPrint("Fetching suggestions for: $text");
      final res = await http.get(Uri.parse(url));
      debugPrint("Autocomplete Response: ${res.statusCode}");
      
      final data = jsonDecode(res.body);
      if (data['features'] == null) {
        debugPrint("No features in autocomplete response");
        return [];
      }
      
      final List<Suggestion> suggestions = (data['features'] as List).map((f) {
        final coords = f['geometry']['coordinates'];
        final label = f['properties']['label'] ?? f['properties']['name'] ?? text;
        return Suggestion(label, LatLng(coords[1], coords[0]));
      }).toList();
      
      debugPrint("Generated ${suggestions.length} suggestions");
      return suggestions;
    } catch (e) {
      debugPrint("Autocomplete Error: $e");
      return [];
    }
  }

  Future<Suggestion?> _geocodePlace(String text) async {
    final url = "https://api.openrouteservice.org/geocode/search?api_key=$orsApiKey&text=${Uri.encodeComponent(text)}&size=1";
    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      if (data['features'] == null || (data['features'] as List).isEmpty) return null;
      
      final feature = data['features'][0];
      final coords = feature['geometry']['coordinates'];
      final label = feature['properties']['label'] ?? text;
      return Suggestion(label, LatLng(coords[1], coords[0]));
    } catch (_) {
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  double _getDistance(LatLng p1, LatLng p2) {
    const double R = 6371e3; // metres
    final double phi1 = p1.latitude * math.pi / 180; // φ, λ in radians
    final double phi2 = p2.latitude * math.pi / 180;
    final double deltaPhi = (p2.latitude - p1.latitude) * math.pi / 180;
    final double deltaLambda = (p2.longitude - p1.longitude) * math.pi / 180;

    final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
            math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c; 
  }

  double _pointToLineDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final A = point.longitude - lineStart.longitude;
    final B = point.latitude - lineStart.latitude;
    final C = lineEnd.longitude - lineStart.longitude;
    final D = lineEnd.latitude - lineStart.latitude;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    if (lenSq == 0) return _getDistance(point, lineStart);
    final param = dot / lenSq;

    double xx, yy;
    if (param < 0) {
      xx = lineStart.longitude;
      yy = lineStart.latitude;
    } else if (param > 1) {
      xx = lineEnd.longitude;
      yy = lineEnd.latitude;
    } else {
      xx = lineStart.longitude + param * C;
      yy = lineStart.latitude + param * D;
    }

    return _getDistance(point, LatLng(yy, xx));
  }

  bool _isPointOnWay(LatLng point, List<LatLng> wayGeometry) {
    if (wayGeometry.length < 2) return false;
    for (int i = 0; i < wayGeometry.length - 1; i++) {
      if (_pointToLineDistance(point, wayGeometry[i], wayGeometry[i+1]) <= 20) {
        return true;
      }
    }
    return false;
  }

  String _determineLightingAtPoint(LatLng point, List<LightingData> lightingData) {
    final nearbyLamps = lightingData.where((l) => l.type == 'street_lamp' && l.position != null && _getDistance(point, l.position!) <= 50).toList();
    if (nearbyLamps.isNotEmpty) return "well_lit";

    final litRoads = lightingData.where((l) => l.type == 'road_segment' && l.isLit == true && l.geometry != null && _isPointOnWay(point, l.geometry!)).toList();
    if (litRoads.isNotEmpty) return "lit";

    return "unlit";
  }

  Color _getLightingColor(String lighting) {
    switch (lighting) {
      case "well_lit": return Colors.green;
      case "lit": return Colors.yellow;
      case "unlit": return Colors.red;
      default: return Colors.grey;
    }
  }

  List<RouteSegment> _segmentRoute(List<LatLng> points, List<LightingData> lightingData) {
    if (points.isEmpty) return [];

    List<RouteSegment> segments = [];
    List<LatLng> currentSegment = [];
    String currentLighting = "unknown";

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final pointLighting = _determineLightingAtPoint(pt, lightingData);

      if (currentSegment.isEmpty) {
        currentSegment.add(pt);
        currentLighting = pointLighting;
      } else if (pointLighting == currentLighting) {
        currentSegment.add(pt);
      } else {
        currentSegment.add(pt);
        segments.add(RouteSegment(List.from(currentSegment), currentLighting, _getLightingColor(currentLighting)));
        currentSegment = [pt];
        currentLighting = pointLighting;
      }
    }

    if (currentSegment.isNotEmpty) {
      segments.add(RouteSegment(currentSegment, currentLighting, _getLightingColor(currentLighting)));
    }

    return segments;
  }

  int _scoreRouteByLighting(List<RouteSegment> segments) {
    int wellLit = 0, lit = 0, unlit = 0;
    for (var seg in segments) {
      if (seg.lighting == "well_lit") wellLit += seg.points.length;
      else if (seg.lighting == "lit") lit += seg.points.length;
      else if (seg.lighting == "unlit") unlit += seg.points.length;
    }
    int total = wellLit + lit + unlit;
    if (total == 0) return 50;

    double score = (wellLit / total * 100) + (lit / total * 70) - (unlit / total * 50);
    return math.max(0, math.min(100, score.round()));
  }

  int _scoreBusinessDensity(List<LatLng> points, BusinessPopulationData businessData) {
    if (points.isEmpty || businessData.businessPoints.isEmpty) return 0;
    int matched = 0;
    for (var pt in points) {
      bool hits = businessData.businessPoints.any((b) => _getDistance(pt, b) <= 70);
      if (hits) matched++;
    }
    return ((matched / points.length) * 100).round();
  }

  int _scorePopulationDensity(List<LatLng> points, BusinessPopulationData businessData) {
    if (points.isEmpty || businessData.populationWays.isEmpty) return 0;
    int matched = 0;
    for (var pt in points) {
      bool hits = businessData.populationWays.any((way) => _isPointOnWay(pt, way));
      if (hits) matched++;
    }
    return ((matched / points.length) * 100).round();
  }

  int _combineScores(int lighting, int business, int population) {
    return math.max(0, math.min(100, (lighting * 0.55 + business * 0.30 + population * 0.15).round()));
  }

  Future<void> _fetchRoutes() async {
    final destInput = _destController.text.trim();
    if (destInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a destination.")));
      return;
    }
    final sourceInput = _sourceController.text.trim();
    if (!_usingCurrentLocation && sourceInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a source.")));
      return;
    }

    setState(() {
      _loading = true;
      _showSourceSuggestions = false;
      _showDestSuggestions = false;
    });

    try {
      Suggestion? originSuggestion;
      if (_usingCurrentLocation) {
        if (_userLocation == null) throw Exception("GPS mapping not ready");
        originSuggestion = Suggestion(_locationLabel, _userLocation!);
      } else {
        originSuggestion = await _geocodePlace(sourceInput);
        if (originSuggestion == null) throw Exception("Source not found");
      }

      final destSuggestion = await _geocodePlace(destInput);
      if (destSuggestion == null) throw Exception("Destination not found");

      setState(() => _lightingLoading = true);
      final bounds = calculateRouteBounds(originSuggestion.point, destSuggestion.point);
      
      List<LightingData> lightingData = await fetchStreetLightsInArea(bounds);
      if (lightingData.isEmpty) {
        debugPrint("No lighting data from API, using fallback generator");
        lightingData = generateFallbackLightingData(bounds);
      }
      
      BusinessPopulationData bPData = await fetchBusinessAndPopulationData(bounds);
      setState(() => _lightingLoading = false);

      final body = {
        "coordinates": [
          [originSuggestion.point.longitude, originSuggestion.point.latitude],
          [destSuggestion.point.longitude, destSuggestion.point.latitude]
        ],
        "alternative_routes": {
          "target_count": 3,
          "weight_factor": 1.6,
          "share_factor": 0.6
        }
      };

      final response = await http.post(
        Uri.parse("https://api.openrouteservice.org/v2/directions/driving-car"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": orsApiKey,
        },
        body: jsonEncode(body),
      );

      debugPrint("ORS Directions Response: ${response.statusCode}");
      final data = jsonDecode(response.body);
      
      if (response.statusCode != 200) {
        debugPrint("ORS Error Body: ${response.body}");
        throw Exception("Routing API error: ${response.statusCode}");
      }

      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        debugPrint("No routes found in ORS response");
        throw Exception("No routes found");
      }

      List<SafeRouteResult> parsedRoutes = [];
      int idx = 1;
      for (var r in data['routes']) {
        debugPrint("Processing Route $idx...");
        final rawPoints = _decodePolyline(r['geometry']);
        final segments = _segmentRoute(rawPoints, lightingData);
        final lightingScore = _scoreRouteByLighting(segments);
        final bScore = _scoreBusinessDensity(rawPoints, bPData);
        final pScore = _scorePopulationDensity(rawPoints, bPData);
        final combined = _combineScores(lightingScore, bScore, pScore);

        parsedRoutes.add(SafeRouteResult(
          segments: segments,
          score: combined,
          lightingScore: lightingScore,
          businessScore: bScore,
          populationScore: pScore,
          allPoints: rawPoints,
          distance: r['summary']['distance'].toDouble(),
          duration: r['summary']['duration'].toDouble(),
          distanceText: "${(r['summary']['distance'] / 1000).toStringAsFixed(1)} km",
          durationText: "${(r['summary']['duration'] / 60).round()} mins",
          summary: "Route $idx",
          destCoord: destSuggestion.point,
        ));
        idx++;
      }

      // NOVEL: Uniqueness check to filter out redundant routes (matching JSX line 548)
      final Map<String, SafeRouteResult> uniqueMap = {};
      for (var route in parsedRoutes) {
        final key = route.allPoints.map((pt) => 
          "${pt.latitude.toStringAsFixed(5)}_${pt.longitude.toStringAsFixed(5)}"
        ).join('|');
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = route;
        }
      }
      final uniqueRoutes = uniqueMap.values.toList();

      uniqueRoutes.sort((a, b) => b.score.compareTo(a.score));
      final finalRoutes = uniqueRoutes.length > 3 ? uniqueRoutes.sublist(0, 3) : uniqueRoutes;

      setState(() {
        _routes = finalRoutes;
        _selectedRouteIndex = 0;
        debugPrint("Calculated ${finalRoutes.length} unique safe routes");
      });

      if (_routes.isNotEmpty) {
        final allP = _routes.expand((r) => r.allPoints).toList();
        final mapBounds = LatLngBounds.fromPoints(allP);
        _mapController.fitCamera(CameraFit.bounds(
            bounds: mapBounds, padding: const EdgeInsets.all(50)));
        debugPrint("Map adjusted to show all suggestions");
      }

    } catch (e) {
      debugPrint("SafeRoute Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _loading = false;
        _lightingLoading = false;
      });
    }
  }

  Widget _buildTopCard() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                     Navigator.of(context).pop();
                  } else {
                     context.go('/main');
                  }
                },
              ),
              const Expanded(
                child: Text("Safe Route", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const Icon(Icons.security, color: Colors.blue),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // START LOCATION FIELD
                if (_usingCurrentLocation)
                  InkWell(
                    onTap: () => setState(() { _usingCurrentLocation = false; _routes = []; _sourceController.text = ""; debugPrint("Manual location enabled"); }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_locationLabel, style: const TextStyle(fontWeight: FontWeight.w500))),
                          const Icon(Icons.close, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  )
                else 
                  Column(
                    children: [
                      TextField(
                        controller: _sourceController,
                        decoration: InputDecoration(
                          labelText: "Start Location", 
                          prefixIcon: const Icon(Icons.circle, color: Colors.green, size: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.blue, size: 20),
                            onPressed: () => setState(() { _usingCurrentLocation = true; _sourceController.clear(); _fetchUserLocation(); }),
                            tooltip: "Use GPS Location",
                          )
                        ),
                        onChanged: (val) async {
                          if (val.length > 2) {
                            final res = await _fetchSuggestions(val);
                            setState(() { _sourceSuggestions = res; _showSourceSuggestions = true; _showDestSuggestions = false; });
                          } else {
                            setState(() => _showSourceSuggestions = false);
                          }
                        },
                      ),
                      if (_showSourceSuggestions && _sourceSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _sourceSuggestions.length,
                            itemBuilder: (context, i) => ListTile(
                              dense: true,
                              title: Text(_sourceSuggestions[i].label, style: const TextStyle(fontSize: 13)),
                              onTap: () {
                                setState(() {
                                  _sourceController.text = _sourceSuggestions[i].label;
                                  _showSourceSuggestions = false;
                                  debugPrint("Source selected: ${_sourceSuggestions[i].label}");
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                
                const SizedBox(height: 8),
                
                // DESTINATION FIELD
                Column(
                  children: [
                    TextField(
                      controller: _destController,
                      decoration: const InputDecoration(
                        labelText: "Where to?", 
                        prefixIcon: Icon(Icons.circle, color: Colors.red, size: 12),
                        suffixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                      ),
                      onChanged: (val) async {
                        if (val.length > 2) {
                          final res = await _fetchSuggestions(val);
                          setState(() { _destSuggestions = res; _showDestSuggestions = true; _showSourceSuggestions = false; });
                        } else {
                          setState(() => _showDestSuggestions = false);
                        }
                      },
                    ),
                    if (_showDestSuggestions && _destSuggestions.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _destSuggestions.length,
                          itemBuilder: (context, i) => ListTile(
                            dense: true,
                            title: Text(_destSuggestions[i].label, style: const TextStyle(fontSize: 13)),
                            onTap: () {
                              setState(() {
                                _destController.text = _destSuggestions[i].label;
                                _showDestSuggestions = false;
                                debugPrint("Destination selected: ${_destSuggestions[i].label}");
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () {
                      _fetchRoutes();
                      debugPrint("Find Safe Routes clicked");
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Find Safe Routes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    if (_routes.isEmpty) return const SizedBox.shrink();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _routes.length + 2, // +2 for header and handle
            itemBuilder: (context, idx) {
              if (idx == 0) {
                return Center(
                  child: Container(
                    width: 40, 
                    height: 4, 
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
                  )
                );
              }
              if (idx == 1) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Suggested Routes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() { _routes = []; _destController.clear(); }),
                      child: const Text("Clear", style: TextStyle(color: Colors.red)),
                    )
                  ],
                );
              }

              final routeIdx = idx - 2;
              final route = _routes[routeIdx];
              final isSelected = routeIdx == _selectedRouteIndex;
              
              // Respective colors according to ranking (matching the map exactly)
              final List<Color> cardColors = [
                const Color(0xFF27AE60), // Green
                const Color(0xFFF39C12), // Yellow
                const Color(0xFFE74C3C), // Red
              ];
              Color cardThemeColor = routeIdx < cardColors.length ? cardColors[routeIdx] : Colors.grey;

              return GestureDetector(
                onTap: () => setState(() => _selectedRouteIndex = routeIdx),
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: isSelected ? cardThemeColor : Colors.grey[300]!, width: isSelected ? 3 : 1),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? cardThemeColor.withOpacity(0.08) : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(route.summary, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? cardThemeColor : Colors.black)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: cardThemeColor,
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: const Icon(Icons.shield, color: Colors.white, size: 14),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("${route.durationText} • ${route.distanceText}", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Polyline> lines = [];
    
    // Rank-based colors (matching UX request for Green/Yellow/Red rankings)
    final List<Color> routeColors = [
      const Color(0xFF27AE60), // Safest: Vibrant Green
      const Color(0xFFF39C12), // Medium: Vivid Yellow/Orange
      const Color(0xFFE74C3C), // Danger: Solid Red
    ];
    
    // Draw all routes (alternatives first, so selected is on top)
    for (int i = 0; i < _routes.length; i++) {
      if (i == _selectedRouteIndex) continue;
      final alt = _routes[i];
      final color = i < routeColors.length ? routeColors[i] : Colors.grey;
      
      for (var seg in alt.segments) {
        lines.add(Polyline(
          points: seg.points,
          color: color.withOpacity(0.6), // Solid visibility for alternatives
          strokeWidth: 4.5,
        ));
      }
    }
    
    // Draw selected route on top with an outline effect for maximum clarity
    if (_routes.isNotEmpty) {
      final selected = _routes[_selectedRouteIndex];
      final color = _selectedRouteIndex < routeColors.length ? routeColors[_selectedRouteIndex] : Colors.blue;
      
      for (var seg in selected.segments) {
        // Outline
        lines.add(Polyline(
          points: seg.points,
          color: Colors.white.withOpacity(0.8),
          strokeWidth: 12.0,
        ));
        // Core
        lines.add(Polyline(
          points: seg.points,
          color: color,
          strokeWidth: 8.0,
        ));
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(26.9124, 75.7873),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.kavach',
              ),
              PolylineLayer(polylines: lines),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Color(0xFF3182CE), size: 30),
                    ),
                  if (_routes.isNotEmpty)
                    Marker(
                      point: _routes[_selectedRouteIndex].destCoord,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Color(0xFF0F172A), size: 30),
                    )
                ]
              )
            ],
          ),
          _buildBottomSheet(),
          _buildTopCard(),
          if (_locationLoading)
            const Center(child: Card(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))),
        ],
      ),
    );
  }
}
