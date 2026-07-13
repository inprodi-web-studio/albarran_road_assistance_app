import 'dart:convert';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start Auth Group Code

class AuthGroup {
  static String getBaseUrl() =>
      'https://road-assistance-api-eyflz.ondigitalocean.app/api';
  static Map<String, String> headers = {};
  static LoginCall loginCall = LoginCall();
}

class LoginCall {
  Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
  }) async {
    final baseUrl = AuthGroup.getBaseUrl();

    final ffApiRequestBody = '''
{
  "email": "${escapeStringForJson(email)}",
  "password": "${escapeStringForJson(password)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Login',
      apiUrl: '${baseUrl}/agent/auth/login',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? errorCode(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.error.status''',
      ));
}

/// End Auth Group Code

/// Start Orders Group Code

class OrdersGroup {
  static String getBaseUrl({
    String? token = '',
  }) =>
      'https://road-assistance-api-eyflz.ondigitalocean.app/api';
  static Map<String, String> headers = {};
  static FindOrderCall findOrderCall = FindOrderCall();
  static QueuedOrdersCall queuedOrdersCall = QueuedOrdersCall();
  static CompleteOrderCall completeOrderCall = CompleteOrderCall();
}

class FindOrderCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = OrdersGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Find Order',
      apiUrl: '${baseUrl}/orders',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        'token': token,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  OrderStruct? order(dynamic response) => OrderStruct.maybeFromMap(getJsonField(
        response,
        r'''$''',
      ));
}

class QueuedOrdersCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = OrdersGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Queued Orders',
      apiUrl: '${baseUrl}/orders/queue',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'token': token,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List<OrderStruct> orders(dynamic response) {
    final responseOrders = getJsonField(response, r'''$.data''', true);

    if (responseOrders is! List) {
      return [];
    }

    return responseOrders
        .map(OrderStruct.maybeFromMap)
        .whereType<OrderStruct>()
        .toList();
  }
}

class CompleteOrderCall {
  Future<ApiCallResponse> call({
    String? token = '',
    int? orderId,
    double? latitude,
    double? longitude,
    double? heading,
    double? accuracy,
    bool? confirmedOutsideRadius = false,
  }) async {
    final baseUrl = OrdersGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "latitude": $latitude,
  "longitude": $longitude,
  "heading": $heading,
  "accuracy": $accuracy,
  "confirmedOutsideRadius": $confirmedOutsideRadius
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Complete Order',
      apiUrl: '${baseUrl}/orders/$orderId/complete',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'token': token,
      },
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End Orders Group Code

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
