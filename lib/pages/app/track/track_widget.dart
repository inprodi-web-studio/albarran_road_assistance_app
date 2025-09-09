import 'dart:async';
import 'dart:convert';
import 'package:albarran_road_assistant/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'track_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
export 'track_model.dart';

class TrackWidget extends StatefulWidget {
  const TrackWidget({super.key});

  static String routeName = 'Track';
  static String routePath = '/track';

  @override
  State<TrackWidget> createState() => _TrackWidgetState();
}

class _TrackWidgetState extends State<TrackWidget> {
  late TrackModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<gmaps.GoogleMapController> _googleMapController = Completer();

  // Para el marcador de origen y destino.
  gmaps.LatLng sourceLocation = gmaps.LatLng(20.6637689, -103.4333339);
  gmaps.LatLng destinationLocation = gmaps.LatLng(20.6737465, -103.4059306);

  gmaps.BitmapDescriptor sourceIcon = gmaps.BitmapDescriptor.defaultMarker;
  gmaps.BitmapDescriptor destinationIcon = gmaps.BitmapDescriptor.defaultMarker;
  gmaps.BitmapDescriptor currentIcon = gmaps.BitmapDescriptor.defaultMarker;

  // Para dibujar la ruta.
  final PolylinePoints polylinePoints = PolylinePoints();
  List<gmaps.LatLng> polyPoints = [];

  // Para la ubicación actual.
  final Location _location = Location();
  LocationData? locationData;
  String? estimatedTime;
  Timer? _debounceTimer;

  // Variable para controlar si se debe centrar la cámara en la ubicación actual.
  // Inicialmente se sigue al usuario.
  bool _shouldFollowUser = true;

  Future<void> setCustomMapPin() async {
    sourceIcon = await gmaps.BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/images/3d-hangar.png',
    );

    destinationIcon = await gmaps.BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/images/3d-cab.png',
    );

    currentIcon = await gmaps.BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
      'assets/images/3d-moto.png',
    );

    setState(() {});
  }

  // Obtiene los puntos de la ruta (polyline) desde sourceLocation hasta destinationLocation.
  Future<void> getPolyPoints() async {
    try {
      PolylineResult polylineResult =
          await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey:
            "AIzaSyDuOcrqLivIznod8kOB2ouHWwGSnYjJbFU", // Asegúrate de que esta API key tenga habilitada la Directions API.
        request: PolylineRequest(
          origin:
              PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
          destination: PointLatLng(
              destinationLocation.latitude, destinationLocation.longitude),
          mode: TravelMode.driving,
          optimizeWaypoints: true,
        ),
      );

      print("Número de puntos recibidos: ${polylineResult.points.length}");

      if (polylineResult.points.isNotEmpty) {
        setState(() {
          polyPoints = polylineResult.points
              .map((point) => gmaps.LatLng(point.latitude, point.longitude))
              .toList();
        });
      } else {
        print(
            "No se encontraron puntos para la ruta. Revisa la API key o los parámetros.");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

 Future<void> updateUserLocationInFirestore(LocationData loc, String? newEstimatedTime) async {
    Map<String, dynamic> dataToUpdate = {
      "currentLocation": {
        "latitude": loc.latitude,
        "longitude": loc.longitude,
        "heading": loc.heading ?? 0,
        "updatedAt": FieldValue.serverTimestamp(),
      },
    };

    if (newEstimatedTime != null) {
      dataToUpdate["estimatedTime"] = newEstimatedTime;
    }
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserUid)
        .update(dataToUpdate);
  }

  // Obtiene la ubicación actual y actualiza la cámara y marcadores.
  // La primera vez se fija la fuente (sourceLocation) con la ubicación actual.
  void getCurrentLocation() async {
    try {
      LocationData currentLoc = await _location.getLocation();
      setState(() {
        locationData = currentLoc;
        // Fijamos la ubicación de origen solo la primera vez.
        sourceLocation =
            gmaps.LatLng(currentLoc.latitude!, currentLoc.longitude!);
      });

      final gmaps.GoogleMapController controller =
          await _googleMapController.future;

      // Mueve la cámara a la ubicación actual (origen fija) si se está siguiendo al usuario.
      if (_shouldFollowUser) {
        double currentBearing = currentLoc.heading ?? 0;
        await controller.animateCamera(gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
              target: sourceLocation,
              zoom: 18,
              tilt: 59,
              bearing: currentBearing),
        ));
      }

      await updateEstimatedTime(sourceLocation);
      await getPolyPoints();
      await updateUserLocationInFirestore(currentLoc, estimatedTime);

      // Escucha los cambios de ubicación.
      _location.onLocationChanged.listen((LocationData newLocation) async {
        await updateUserLocationInFirestore(newLocation, null);
        // Si se está siguiendo al usuario, mueve la cámara a la nueva ubicación.
        if (_shouldFollowUser) {
          double currentBearing = newLocation.heading ?? 0;

          await controller.animateCamera(gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target:
                  gmaps.LatLng(newLocation.latitude!, newLocation.longitude!),
              zoom: 18,
              tilt: 59,
              bearing: currentBearing,
            ),
          ));
        }

        // Usa debounce para actualizar la ETA.
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 15), () async {
          await updateEstimatedTime(
              sourceLocation); // Se calcula desde el origen fijo.
        });

        setState(() {
          locationData = newLocation;
        });
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateEstimatedTime(gmaps.LatLng currentLocation) async {
    final String origin =
        '${currentLocation.latitude},${currentLocation.longitude}';
    final String destination =
        '${destinationLocation.latitude},${destinationLocation.longitude}';
    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=$origin&destinations=$destination&mode=driving&key=AIzaSyDuOcrqLivIznod8kOB2ouHWwGSnYjJbFU";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rows'] != null &&
            data['rows'][0]['elements'] != null &&
            data['rows'][0]['elements'][0]['duration'] != null) {
          final durationText =
              data['rows'][0]['elements'][0]['duration']['text'];
          setState(() {
            estimatedTime = durationText;
          });

          if (locationData != null) {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(currentUserUid)
                .update({
              "estimatedTime": durationText,
            });
          }
        } else {
          print("Estructura de datos inesperada: $data");
        }
      } else {
        debugPrint('Error en la solicitud HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Excepción al obtener la ETA: " + e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrackModel());
    setCustomMapPin();
    getCurrentLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (locationData == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        body: Center(child: CircularProgressIndicator()),
      );
    }

// Dentro del build(), en la sección del Stack:
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primary,
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: sourceLocation, // Se usa la ubicación de origen fija
              zoom: 18,
            ),
            onMapCreated: (controller) {
              _googleMapController.complete(controller);
            },
            myLocationButtonEnabled: false,
            compassEnabled: false,
            // Detecta cuando el usuario empieza a mover la cámara.
            onCameraMoveStarted: () {
              // Si el usuario interactúa, desactiva el seguimiento automático.
              setState(() {
                _shouldFollowUser = false;
              });
            },
            markers: {
              // Marcador de origen fijo
              gmaps.Marker(
                markerId: gmaps.MarkerId('source'),
                position: sourceLocation,
                icon: sourceIcon,
              ),
              // Marcador de destino fijo
              gmaps.Marker(
                markerId: gmaps.MarkerId('destination'),
                position: destinationLocation,
                icon: destinationIcon,
              ),
              // Marcador de la ubicación actual (se actualiza en cada cambio, pero la cámara no se centra automáticamente)
              gmaps.Marker(
                markerId: gmaps.MarkerId('currentLocation'),
                position: gmaps.LatLng(
                    locationData!.latitude!, locationData!.longitude!),
                icon: currentIcon,
              ),
            },
            polylines: {
              // La ruta se dibuja desde el origen fijo hasta el destino.
              gmaps.Polyline(
                polylineId: gmaps.PolylineId("route"),
                points: polyPoints,
                width: 6,
                color: FlutterFlowTheme.of(context).secondary,
              ),
            },
          ),
          // Ubica un Row en la parte inferior del mapa con un padding inferior de 10px.
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Contenedor para el texto con la ETA.
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Tiempo estimado: $estimatedTime",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Espacio entre ambos widgets.
                ElevatedButton(
                  onPressed: () async {
                    // Reactivar seguimiento y centrar la cámara en la ubicación actual del usuario.
                    setState(() {
                      _shouldFollowUser = true;
                    });
                    final controller = await _googleMapController.future;
                    double currentBearing = locationData!.heading ?? 0;
                    await controller.animateCamera(
                      gmaps.CameraUpdate.newCameraPosition(
                        gmaps.CameraPosition(
                          target: gmaps.LatLng(
                              locationData!.latitude!,
                              locationData!
                                  .longitude!), // Ubicación actual del usuario.
                          zoom: 18,
                          tilt: 59,
                          bearing: currentBearing,
                        ),
                      ),
                    );
                  },
                  child: Text("Centrar"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
