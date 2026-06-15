import 'package:cloud_firestore/cloud_firestore.dart';

class VillageModel {
  final String villageId;
  final String villageName;
  final String serverType;
  final String? apiBaseUrl;
  final String? localIpAddress;
  final String? port;
  final bool requiresVpn;
  final bool isActive;

  VillageModel({
    required this.villageId,
    required this.villageName,
    this.serverType = 'firebase_shared',
    this.apiBaseUrl,
    this.localIpAddress,
    this.port,
    this.requiresVpn = false,
    this.isActive = true,
  });

  factory VillageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VillageModel(
      villageId: doc.id,
      villageName: data['villageName'] as String? ?? '',
      serverType: data['serverType'] as String? ?? 'firebase_shared',
      apiBaseUrl: data['apiBaseUrl'] as String?,
      localIpAddress: data['localIpAddress'] as String?,
      port: data['port']?.toString(),
      requiresVpn: data['requiresVpn'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'villageName': villageName,
      'serverType': serverType,
      'apiBaseUrl': apiBaseUrl,
      'localIpAddress': localIpAddress,
      'port': port,
      'requiresVpn': requiresVpn,
      'isActive': isActive,
    };
  }
}
