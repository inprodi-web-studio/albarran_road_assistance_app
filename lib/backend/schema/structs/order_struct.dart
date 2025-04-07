// ignore_for_file: unnecessary_getters_setters


import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrderStruct extends BaseStruct {
  OrderStruct({
    String? serice,
    String? subService,
    String? autoInfo,
    String? stage,
    CustomerStruct? customer,
    LocationStruct? location,
    int? id,
  })  : _serice = serice,
        _subService = subService,
        _autoInfo = autoInfo,
        _stage = stage,
        _customer = customer,
        _location = location,
        _id = id;

  // "serice" field.
  String? _serice;
  String get serice => _serice ?? '';
  set serice(String? val) => _serice = val;

  bool hasSerice() => _serice != null;

  // "subService" field.
  String? _subService;
  String get subService => _subService ?? '';
  set subService(String? val) => _subService = val;

  bool hasSubService() => _subService != null;

  // "autoInfo" field.
  String? _autoInfo;
  String get autoInfo => _autoInfo ?? '';
  set autoInfo(String? val) => _autoInfo = val;

  bool hasAutoInfo() => _autoInfo != null;

  // "stage" field.
  String? _stage;
  String get stage => _stage ?? '';
  set stage(String? val) => _stage = val;

  bool hasStage() => _stage != null;

  // "customer" field.
  CustomerStruct? _customer;
  CustomerStruct get customer => _customer ?? CustomerStruct();
  set customer(CustomerStruct? val) => _customer = val;

  void updateCustomer(Function(CustomerStruct) updateFn) {
    updateFn(_customer ??= CustomerStruct());
  }

  bool hasCustomer() => _customer != null;

  // "location" field.
  LocationStruct? _location;
  LocationStruct get location => _location ?? LocationStruct();
  set location(LocationStruct? val) => _location = val;

  void updateLocation(Function(LocationStruct) updateFn) {
    updateFn(_location ??= LocationStruct());
  }

  bool hasLocation() => _location != null;

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  set id(int? val) => _id = val;

  void incrementId(int amount) => id = id + amount;

  bool hasId() => _id != null;

  static OrderStruct fromMap(Map<String, dynamic> data) => OrderStruct(
        serice: data['serice'] as String?,
        subService: data['subService'] as String?,
        autoInfo: data['autoInfo'] as String?,
        stage: data['stage'] as String?,
        customer: data['customer'] is CustomerStruct
            ? data['customer']
            : CustomerStruct.maybeFromMap(data['customer']),
        location: data['location'] is LocationStruct
            ? data['location']
            : LocationStruct.maybeFromMap(data['location']),
        id: castToType<int>(data['id']),
      );

  static OrderStruct? maybeFromMap(dynamic data) =>
      data is Map ? OrderStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'serice': _serice,
        'subService': _subService,
        'autoInfo': _autoInfo,
        'stage': _stage,
        'customer': _customer?.toMap(),
        'location': _location?.toMap(),
        'id': _id,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'serice': serializeParam(
          _serice,
          ParamType.String,
        ),
        'subService': serializeParam(
          _subService,
          ParamType.String,
        ),
        'autoInfo': serializeParam(
          _autoInfo,
          ParamType.String,
        ),
        'stage': serializeParam(
          _stage,
          ParamType.String,
        ),
        'customer': serializeParam(
          _customer,
          ParamType.DataStruct,
        ),
        'location': serializeParam(
          _location,
          ParamType.DataStruct,
        ),
        'id': serializeParam(
          _id,
          ParamType.int,
        ),
      }.withoutNulls;

  static OrderStruct fromSerializableMap(Map<String, dynamic> data) =>
      OrderStruct(
        serice: deserializeParam(
          data['serice'],
          ParamType.String,
          false,
        ),
        subService: deserializeParam(
          data['subService'],
          ParamType.String,
          false,
        ),
        autoInfo: deserializeParam(
          data['autoInfo'],
          ParamType.String,
          false,
        ),
        stage: deserializeParam(
          data['stage'],
          ParamType.String,
          false,
        ),
        customer: deserializeStructParam(
          data['customer'],
          ParamType.DataStruct,
          false,
          structBuilder: CustomerStruct.fromSerializableMap,
        ),
        location: deserializeStructParam(
          data['location'],
          ParamType.DataStruct,
          false,
          structBuilder: LocationStruct.fromSerializableMap,
        ),
        id: deserializeParam(
          data['id'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'OrderStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is OrderStruct &&
        serice == other.serice &&
        subService == other.subService &&
        autoInfo == other.autoInfo &&
        stage == other.stage &&
        customer == other.customer &&
        location == other.location &&
        id == other.id;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([serice, subService, autoInfo, stage, customer, location, id]);
}

OrderStruct createOrderStruct({
  String? serice,
  String? subService,
  String? autoInfo,
  String? stage,
  CustomerStruct? customer,
  LocationStruct? location,
  int? id,
}) =>
    OrderStruct(
      serice: serice,
      subService: subService,
      autoInfo: autoInfo,
      stage: stage,
      customer: customer ?? CustomerStruct(),
      location: location ?? LocationStruct(),
      id: id,
    );
