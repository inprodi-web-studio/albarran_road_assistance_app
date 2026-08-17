import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

enum AgentLocationTrackingStatus {
  stopped,
  starting,
  active,
  foregroundOnly,
  serviceDisabled,
  permissionDenied,
  error,
}

class AgentLocationService extends ChangeNotifier {
  AgentLocationService._();

  static final AgentLocationService instance = AgentLocationService._();

  static const _availableWriteInterval = Duration(seconds: 20);
  static const _navigationWriteInterval = Duration(seconds: 5);
  static const _heartbeatInterval = Duration(seconds: 45);

  final Location _location = Location();
  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _heartbeatTimer;
  Future<bool>? _startFuture;
  Future<void>? _activeWrite;
  String? _userId;
  int _sessionGeneration = 0;
  DateTime? _lastWriteAt;
  LocationData? _lastLocation;
  bool _writeInProgress = false;
  bool _navigationMode = false;
  bool _backgroundEnabled = false;
  String? _errorMessage;
  AgentLocationTrackingStatus _status = AgentLocationTrackingStatus.stopped;

  Stream<LocationData> get locationStream => _locationController.stream;
  LocationData? get lastLocation => _lastLocation;
  AgentLocationTrackingStatus get status => _status;
  bool get backgroundEnabled => _backgroundEnabled;
  bool get isTracking =>
      _status == AgentLocationTrackingStatus.active ||
      _status == AgentLocationTrackingStatus.foregroundOnly;

  String get statusMessage {
    switch (_status) {
      case AgentLocationTrackingStatus.active:
        return 'Ubicación activa, incluso en segundo plano.';
      case AgentLocationTrackingStatus.foregroundOnly:
        return 'Ubicación activa mientras la app está abierta. Para continuar en segundo plano, permite acceso a la ubicación siempre.';
      case AgentLocationTrackingStatus.serviceDisabled:
        return 'Activa la ubicación del dispositivo para aparecer disponible.';
      case AgentLocationTrackingStatus.permissionDenied:
        return 'Permite el acceso a la ubicación, incluyendo segundo plano, para aparecer disponible.';
      case AgentLocationTrackingStatus.error:
        return _errorMessage ??
            'No pudimos iniciar el seguimiento de ubicación.';
      case AgentLocationTrackingStatus.starting:
        return 'Iniciando seguimiento de ubicación...';
      case AgentLocationTrackingStatus.stopped:
        return 'El seguimiento de ubicación está detenido.';
    }
  }

  Future<bool> start(String userId) async {
    if (userId.isEmpty) {
      return false;
    }

    if (_userId == userId && _locationSubscription != null && isTracking) {
      return true;
    }

    if (_startFuture != null) {
      return _startFuture!;
    }

    final future = _startForUser(userId);
    _startFuture = future;

    try {
      return await future;
    } finally {
      _startFuture = null;
    }
  }

  Future<bool> _startForUser(String userId) async {
    if (_userId != null && _userId != userId) {
      await stop(markOffline: true);
    }

    final sessionGeneration = ++_sessionGeneration;
    _userId = userId;
    _setStatus(AgentLocationTrackingStatus.starting);

    try {
      var serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
      }

      if (!serviceEnabled) {
        if (_isCurrentSession(userId, sessionGeneration)) {
          await _markUnavailable(userId);
          if (_isCurrentSession(userId, sessionGeneration)) {
            _setStatus(AgentLocationTrackingStatus.serviceDisabled);
          }
        }
        return false;
      }

      var permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }

      if (permission == PermissionStatus.denied ||
          permission == PermissionStatus.deniedForever) {
        if (_isCurrentSession(userId, sessionGeneration)) {
          await _markUnavailable(userId);
          if (_isCurrentSession(userId, sessionGeneration)) {
            _setStatus(AgentLocationTrackingStatus.permissionDenied);
          }
        }
        return false;
      }

      await _applyLocationSettings();
      final backgroundEnabled = await _enableBackgroundTracking();
      if (!_isCurrentSession(userId, sessionGeneration)) {
        if (backgroundEnabled) {
          await _disableBackgroundTracking();
        }
        return false;
      }
      _backgroundEnabled = backgroundEnabled;

      final initialLocation = await _location.getLocation();
      if (!_isCurrentSession(userId, sessionGeneration)) {
        return false;
      }
      await _handleLocation(initialLocation, forceWrite: true);
      if (!_isCurrentSession(userId, sessionGeneration)) {
        return false;
      }

      await _locationSubscription?.cancel();
      _locationSubscription = _location.onLocationChanged.listen(
        (location) => unawaited(_handleLocation(location)),
        onError: (Object error) {
          _errorMessage = error.toString();
          _setStatus(AgentLocationTrackingStatus.error);
        },
      );

      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        _heartbeatInterval,
        (_) => unawaited(_publishHeartbeat()),
      );

      _setStatus(
        _backgroundEnabled
            ? AgentLocationTrackingStatus.active
            : AgentLocationTrackingStatus.foregroundOnly,
      );
      return true;
    } catch (error) {
      if (_isCurrentSession(userId, sessionGeneration)) {
        _errorMessage = error.toString();
        _setStatus(AgentLocationTrackingStatus.error);
      }
      return false;
    }
  }

  Future<void> setNavigationMode(bool enabled) async {
    if (_navigationMode == enabled) {
      return;
    }

    _navigationMode = enabled;
    if (_userId != null) {
      await _applyLocationSettings();
    }
  }

  Future<void> stop({bool markOffline = true}) async {
    final userId = _userId;
    _sessionGeneration += 1;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _activeWrite;

    if (markOffline && userId != null) {
      try {
        await _writePresence(userId, isOnline: false);
      } catch (error) {
        debugPrint('[agent-location] unable to mark offline: $error');
      }
    }

    if (_backgroundEnabled && !kIsWeb) {
      await _disableBackgroundTracking();
    }

    _backgroundEnabled = false;
    _navigationMode = false;
    _lastWriteAt = null;
    _lastLocation = null;
    _userId = null;
    _setStatus(AgentLocationTrackingStatus.stopped);
  }

  Future<void> _applyLocationSettings() => _location.changeSettings(
        accuracy: _navigationMode
            ? LocationAccuracy.navigation
            : LocationAccuracy.balanced,
        interval: _navigationMode ? 5000 : 30000,
        distanceFilter: 0,
      );

  Future<bool> _enableBackgroundTracking() async {
    if (kIsWeb) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _location.changeNotificationOptions(
          channelName: 'Disponibilidad de agentes',
          title: 'Auxiliar Vial activo',
          subtitle: 'Compartiendo ubicacion mientras estas disponible',
          description:
              'Tu ubicacion permite asignarte y monitorear servicios de auxilio.',
          onTapBringToFront: true,
        );
      } catch (error) {
        debugPrint(
          '[agent-location] unable to configure Android notification: $error',
        );
      }
    }

    try {
      return await _location.enableBackgroundMode(enable: true);
    } catch (error) {
      debugPrint('[agent-location] background mode unavailable: $error');
      return false;
    }
  }

  Future<void> _disableBackgroundTracking() async {
    try {
      await _location.enableBackgroundMode(enable: false);
    } catch (error) {
      debugPrint('[agent-location] unable to disable background mode: $error');
    }
  }

  Future<void> _handleLocation(
    LocationData location, {
    bool forceWrite = false,
  }) async {
    if (location.latitude == null || location.longitude == null) {
      return;
    }

    _lastLocation = location;
    if (!_locationController.isClosed) {
      _locationController.add(location);
    }

    final userId = _userId;
    if (userId == null || _writeInProgress) {
      return;
    }

    final minimumInterval =
        _navigationMode ? _navigationWriteInterval : _availableWriteInterval;
    if (!forceWrite &&
        _lastWriteAt != null &&
        DateTime.now().difference(_lastWriteAt!) < minimumInterval) {
      return;
    }

    _writeInProgress = true;
    final write =
        FirebaseFirestore.instance.collection('users').doc(userId).set({
      'currentLocation': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'heading': location.heading ?? 0,
        'accuracy': location.accuracy,
        'speed': location.speed,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'presence': {
        'isOnline': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'backgroundEnabled': _backgroundEnabled,
        'platform': defaultTargetPlatform.name,
      },
    }, SetOptions(merge: true));
    _activeWrite = write;
    try {
      await write;
      _lastWriteAt = DateTime.now();
    } catch (error) {
      debugPrint('[agent-location] Firestore write failed: $error');
    } finally {
      if (identical(_activeWrite, write)) {
        _activeWrite = null;
      }
      _writeInProgress = false;
    }
  }

  Future<void> _publishHeartbeat() async {
    final location = _lastLocation;
    if (location != null) {
      await _handleLocation(location, forceWrite: true);
      return;
    }

    try {
      await _handleLocation(await _location.getLocation(), forceWrite: true);
    } catch (error) {
      debugPrint('[agent-location] heartbeat failed: $error');
    }
  }

  Future<void> _markUnavailable(String userId) async {
    try {
      await _writePresence(userId, isOnline: false, isLogout: false);
    } catch (error) {
      debugPrint('[agent-location] unable to mark unavailable: $error');
    }
  }

  Future<void> _writePresence(
    String userId, {
    required bool isOnline,
    bool isLogout = true,
  }) =>
      FirebaseFirestore.instance.collection('users').doc(userId).set({
        'presence': {
          'isOnline': isOnline,
          'lastSeenAt': FieldValue.serverTimestamp(),
          'backgroundEnabled': isOnline && _backgroundEnabled,
          'platform': defaultTargetPlatform.name,
          if (!isOnline && isLogout)
            'loggedOutAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

  void _setStatus(AgentLocationTrackingStatus value) {
    _status = value;
    notifyListeners();
  }

  bool _isCurrentSession(String userId, int generation) =>
      _userId == userId && _sessionGeneration == generation;
}
