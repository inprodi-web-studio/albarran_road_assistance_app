import 'package:rxdart/rxdart.dart';

import '/backend/schema/structs/index.dart';
import 'custom_auth_manager.dart';

class AlbarranRoadAssistantAuthUser {
  AlbarranRoadAssistantAuthUser({
    required this.loggedIn,
    this.uid,
    this.userData,
  });

  bool loggedIn;
  String? uid;
  UserStruct? userData;
}

/// Generates a stream of the authenticated user.
BehaviorSubject<AlbarranRoadAssistantAuthUser>
    albarranRoadAssistantAuthUserSubject =
    BehaviorSubject.seeded(AlbarranRoadAssistantAuthUser(loggedIn: false));
Stream<AlbarranRoadAssistantAuthUser> albarranRoadAssistantAuthUserStream() =>
    albarranRoadAssistantAuthUserSubject
        .asBroadcastStream()
        .map((user) => currentUser = user);
