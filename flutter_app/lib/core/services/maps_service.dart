import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';

class MapsService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: AppConstants.httpTimeout,
    receiveTimeout: AppConstants.httpTimeout,
  ));

  /// Fetch route between two points from Google Directions API.
  /// Returns [DirectionsResult] with distance, duration, and encoded polyline.
  Future<DirectionsResult> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final response = await _dio.get(
      AppConstants.directionsBaseUrl,
      queryParameters: {
        'origin':      '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode':        'driving',
        'language':    'en',
        'key':         AppConstants.googleMapsApiKey,
      },
    );

    final data = response.data;
    if (data['status'] != 'OK') {
      throw Exception('Directions API error: ${data['status']}');
    }

    final leg = data['routes'][0]['legs'][0];

    final distanceM  = (leg['distance']['value'] as num).toDouble();
    final durationS  = (leg['duration']['value']  as num).toInt();
    final polyline   = data['routes'][0]['overview_polyline']['points'] as String;

    final polylinePoints = PolylinePoints()
      .decodePolyline(polyline)
      .map((p) => LatLng(p.latitude, p.longitude))
      .toList();

    return DirectionsResult(
      distanceKm:      distanceM / 1000,
      durationMinutes: (durationS / 60).round(),
      polylinePoints:  polylinePoints,
      distanceText:    leg['distance']['text'],
      durationText:    leg['duration']['text'],
      startAddress:    leg['start_address'],
      endAddress:      leg['end_address'],
    );
  }

  /// Reverse-geocode a coordinate to a readable address.
  Future<String> reverseGeocode(LatLng point) async {
    final response = await _dio.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {
        'latlng':   '${point.latitude},${point.longitude}',
        'language': 'en',
        'key':      AppConstants.googleMapsApiKey,
      },
    );
    final results = response.data['results'] as List;
    if (results.isEmpty) return '${point.latitude}, ${point.longitude}';
    return results[0]['formatted_address'] as String;
  }
}

class DirectionsResult {
  final double       distanceKm;
  final int          durationMinutes;
  final List<LatLng> polylinePoints;
  final String       distanceText;
  final String       durationText;
  final String       startAddress;
  final String       endAddress;

  const DirectionsResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.startAddress,
    required this.endAddress,
  });
}
