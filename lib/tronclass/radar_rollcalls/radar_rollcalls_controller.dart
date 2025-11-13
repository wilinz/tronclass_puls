import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:tronclass/data/changke_client.dart';
import 'package:tronclass/data/service/tronclass.dart';
import 'package:tronclass/routes.dart';
import 'package:tronclass/tronclass/common.dart';
import 'package:tronclass/utils/coord_transform.dart';

import 'location_picker_page.dart';
import 'location_selection.dart';

enum RadarRollcallState {
  radar, // 雷达扫描状态
  success, // 成功状态
  failure, // 失败状态
}

class RadarRollcallsController extends GetxController {
  final int rollcallId;

  var currentState = RadarRollcallState.radar.obs;
  var isScanning = false.obs;
  var successMessage = ''.obs;
  var errorMessage = ''.obs;

  RadarRollcallsController({required this.rollcallId});

  // 打开地图选择位置
  Future<void> openLocationPicker() async {
    try {
      final result = await Get.toNamed(
        AppRoute.mapLocationPickerPage,
        arguments: LocationPickerPageArgs(rollcallId: rollcallId),
      );

      if (result != null) {
        LocationSelectionResult? parsed;
        if (result is LocationSelectionResult) {
          parsed = result;
        } else if (result is Map<String, dynamic>) {
          parsed = LocationSelectionResult.fromMap(result);
        }

        if (parsed != null) {
          await _handleLocationResult(parsed);
        }
      }
    } catch (e) {
      print("Error opening location picker: $e");
      errorMessage.value = getMappingMessage("failed");
      currentState.value = RadarRollcallState.failure;
    }
  }

  Future<void> _handleLocationResult(LocationSelectionResult selection) async {
    var latitude = selection.latitude;
    var longitude = selection.longitude;
    final accuracy = selection.accuracy;

    if (selection.crs == CoordinateSystem.wgs84) {
      final converted = CoordTransform.wgs84ToGcj02(latitude, longitude);
      latitude = converted[0];
      longitude = converted[1];
    }

    await _performRollcallWithLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  // 使用位置进行签到
  Future<void> _performRollcallWithLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    if (isScanning.value) return;

    isScanning.value = true;

    try {
      final deviceId = Uuid().v4();

      // 调用雷达签到接口
      final response = await TronClassService.signRadar(
        ChangkeClient.instance.dio,
        rollcallId: rollcallId.toString(),
        deviceId: deviceId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );

      final responseData = response.data;
      final int? id = responseData?["id"];
      final String? status = responseData?["status"];
      final bool isSuccessful =
          response.statusCode == 200 && status == "on_call";

      if (isSuccessful) {
        successMessage.value = getMappingMessage("success");
        currentState.value = RadarRollcallState.success;
      } else {
        errorMessage.value = getMappingMessage(
          responseData?['message'] ?? "failed",
        );
        currentState.value = RadarRollcallState.failure;
      }
    } catch (e) {
      print("Error during rollcall: $e");
      errorMessage.value = getMappingMessage("retry");
      currentState.value = RadarRollcallState.failure;
    } finally {
      isScanning.value = false;
    }
  }

  // 重新开始雷达扫描
  void restartRadar() {
    currentState.value = RadarRollcallState.radar;
    errorMessage.value = '';
    successMessage.value = '';
  }
}
