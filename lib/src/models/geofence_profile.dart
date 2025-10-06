// lib/src/models/geofence_profile.dart

enum BandType { fixed, floating }

enum OutsidePolicy { block, allowAndFlag }

enum GeofenceSlot { checkIn, checkOut }

BandType? bandTypeFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'fixed':
      return BandType.fixed;
    case 'floating':
      return BandType.floating;
    default:
      return null;
  }
}

OutsidePolicy? outsidePolicyFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'block':
      return OutsidePolicy.block;
    case 'allowandflag':
    case 'allow_and_flag':
      return OutsidePolicy.allowAndFlag;
    default:
      return null;
  }
}

double? _parseDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class Geofence {
  const Geofence({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.campusSlug,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? campusSlug;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'lat': latitude,
    'lng': longitude,
    'radiusMeters': radiusMeters,
    if (campusSlug != null) 'campusSlug': campusSlug,
  };

  static Geofence? maybeFromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final lat = _parseDouble(data['lat']);
    final lng = _parseDouble(data['lng']);
    final radius = _parseDouble(data['radiusMeters']);
    if (lat == null || lng == null || radius == null) {
      return null;
    }
    return Geofence(
      latitude: lat,
      longitude: lng,
      radiusMeters: radius,
      campusSlug: data['campusSlug'] as String?,
    );
  }

  Geofence copyWith({
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? campusSlug,
  }) {
    return Geofence(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      campusSlug: campusSlug ?? this.campusSlug,
    );
  }
}

class EffectiveGeofence {
  const EffectiveGeofence({
    required this.checkIn,
    required this.checkOut,
    required this.bandType,
    this.outsidePolicy,
    this.outsideMessageText,
  });

  final Geofence checkIn;
  final Geofence checkOut;
  final BandType bandType;
  final OutsidePolicy? outsidePolicy;
  final String? outsideMessageText;
}

class GeofenceProfile {
  const GeofenceProfile({
    this.checkIn,
    this.checkOut,
    this.bandTypeOverride,
    this.outsidePolicy,
    this.outsideMessageText,
  });

  final Geofence? checkIn;
  final Geofence? checkOut;
  final BandType? bandTypeOverride;
  final OutsidePolicy? outsidePolicy;
  final String? outsideMessageText;

  factory GeofenceProfile.fromMap(Map<String, dynamic> data) {
    return GeofenceProfile(
      checkIn: Geofence.maybeFromMap(
        (data['checkIn'] as Map<String, dynamic>?) ??
            (data['check_in'] as Map<String, dynamic>?),
      ),
      checkOut: Geofence.maybeFromMap(
        (data['checkOut'] as Map<String, dynamic>?) ??
            (data['check_out'] as Map<String, dynamic>?),
      ),
      bandTypeOverride: bandTypeFromString(
        data['bandTypeOverride'] as String? ?? data['bandType'] as String?,
      ),
      outsidePolicy: outsidePolicyFromString(data['outsidePolicy'] as String?),
      outsideMessageText: data['outsideMessageText'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (checkIn != null) 'checkIn': checkIn!.toMap(),
      if (checkOut != null) 'checkOut': checkOut!.toMap(),
      if (bandTypeOverride != null) 'bandTypeOverride': bandTypeOverride!.name,
      if (outsidePolicy != null) 'outsidePolicy': outsidePolicy!.name,
      if (outsideMessageText != null && outsideMessageText!.isNotEmpty)
        'outsideMessageText': outsideMessageText,
    };
  }

  bool get hasOverrides =>
      checkIn != null ||
      checkOut != null ||
      bandTypeOverride != null ||
      outsidePolicy != null ||
      (outsideMessageText != null && outsideMessageText!.isNotEmpty);

  Geofence? slot(GeofenceSlot slot) =>
      slot == GeofenceSlot.checkIn ? checkIn : checkOut;
}

class OrgDefaults {
  const OrgDefaults({
    required this.dowDefaultCampus,
    required this.defaultRadiusMeters,
  });

  final Map<int, String> dowDefaultCampus;
  final double defaultRadiusMeters;

  factory OrgDefaults.fromMap(Map<String, dynamic> data) {
    final rawCampus = (data['dowDefaultCampus'] as Map?) ?? const {};
    final converted = <int, String>{};
    rawCampus.forEach((key, value) {
      final parsedKey = int.tryParse(key.toString());
      if (parsedKey != null && value is String && value.isNotEmpty) {
        converted[parsedKey] = value;
      }
    });
    final radius = _parseDouble(data['defaultRadiusMeters']) ?? 150.0;
    return OrgDefaults(
      dowDefaultCampus: converted,
      defaultRadiusMeters: radius,
    );
  }

  factory OrgDefaults.fallback() {
    return const OrgDefaults(
      dowDefaultCampus: <int, String>{
        0: 'up_park',
        1: 'up_park',
        2: 'up_park',
        3: 'stony_hill',
        4: 'stony_hill',
        5: 'up_park',
        6: 'up_park',
      },
      defaultRadiusMeters: 150.0,
    );
  }

  String campusSlugForDow(int dow) {
    final normalized = dow % 7;
    if (dowDefaultCampus.containsKey(normalized)) {
      return dowDefaultCampus[normalized]!;
    }
    if (dowDefaultCampus.isNotEmpty) {
      return dowDefaultCampus.values.first;
    }
    return 'up_park';
  }
}

class CampusLocation {
  const CampusLocation({
    required this.slug,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.defaultRadiusMeters,
  });

  final String slug;
  final String name;
  final double latitude;
  final double longitude;
  final double? defaultRadiusMeters;

  factory CampusLocation.fromMap(String slug, Map<String, dynamic>? data) {
    final lat = _parseDouble(data?['lat']) ?? 0;
    final lng = _parseDouble(data?['lng']) ?? 0;
    final radius = _parseDouble(data?['defaultRadiusMeters']);
    return CampusLocation(
      slug: slug,
      name: (data?['name'] as String?) ?? slug,
      latitude: lat,
      longitude: lng,
      defaultRadiusMeters: radius,
    );
  }
}

class GeofenceUserSettings {
  const GeofenceUserSettings({
    required this.uid,
    required this.bandType,
    required this.outsideMessageEnabled,
    this.outsideMessageText,
  });

  final String uid;
  final BandType bandType;
  final bool outsideMessageEnabled;
  final String? outsideMessageText;

  factory GeofenceUserSettings.fromMap(String uid, Map<String, dynamic>? data) {
    return GeofenceUserSettings(
      uid: uid,
      bandType:
          bandTypeFromString(data?['bandType'] as String?) ?? BandType.fixed,
      outsideMessageEnabled: data?['outsideMessageEnabled'] as bool? ?? false,
      outsideMessageText: data?['outsideMessageText'] as String?,
    );
  }

  String? get effectiveOutsideMessage {
    if (!outsideMessageEnabled) return null;
    final trimmed = outsideMessageText?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
