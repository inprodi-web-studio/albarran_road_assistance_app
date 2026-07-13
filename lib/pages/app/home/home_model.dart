import '/backend/api_requests/api_calls.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'home_widget.dart' show HomeWidget;
import 'package:flutter/material.dart';

class HomeModel extends FlutterFlowModel<HomeWidget> {
  ///  State fields for stateful widgets in this page.

  Completer<ApiCallResponse>? apiRequestCompleter;
  Completer<ApiCallResponse>? queueRequestCompleter;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  /// Additional helper methods.
  Future<ApiCallResponse> findAssignedOrder() async {
    var token = currentJwtToken;

    if (token.isEmpty) {
      token = await refreshCurrentJwtToken();
    }

    final response = await OrdersGroup.findOrderCall.call(
      token: token,
    );

    if (!response.succeeded && kDebugMode) {
      debugPrint(
        'Find Order failed (${response.statusCode}): ${response.bodyText}',
      );
    }

    return response;
  }

  Future<ApiCallResponse> findQueuedOrders() async {
    var token = currentJwtToken;

    if (token.isEmpty) {
      token = await refreshCurrentJwtToken();
    }

    final response = await OrdersGroup.queuedOrdersCall.call(
      token: token,
    );

    if (!response.succeeded && kDebugMode) {
      debugPrint(
        'Queued orders failed (${response.statusCode}): ${response.bodyText}',
      );
    }

    return response;
  }

  Future waitForApiRequestCompleted({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = apiRequestCompleter?.isCompleted ?? false;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
