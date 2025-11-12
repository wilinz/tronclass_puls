import 'package:pure_dart_extensions/pure_dart_extensions.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:tronclass/data/changke_client.dart';
import 'package:tronclass/data/service/tronclass.dart';

import 'package:tronclass/common/toast.dart';

enum RollcallState {
  input, // 输入状态
  success, // 成功状态
  failure, // 失败状态
}

class NumberRollcallsController extends GetxController {
  final int rollcallId;

  var code = ''.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var currentState = RollcallState.input.obs;
  var successTime = ''.obs;
  final maxLength = 4;

  NumberRollcallsController({required this.rollcallId});

  void updateCode(String value) {
    code.value = value;
  }

  void pasteCode(String clipboardText) {
    final filtered = clipboardText.replaceAll(RegExp(r'[^0-9]'), '');
    if (filtered.isNotEmpty) {
      code.value = filtered.substring(
          0, filtered.length > maxLength ? maxLength : filtered.length);
    }
  }

  void clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }

  void setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
  }

  Future<void> submitCode(String inputCode) async {
    // 模拟验证逻辑
    if (inputCode.length != maxLength || inputCode.toIntOrNull() == null) {
      setError('请输入完整的签到密码');
      return;
    }

    final deviceId = Uuid().v4();
    final response = await TronClassService.signNumber(
        ChangkeClient.instance.dio,
        rollcallId: rollcallId.toString(),
        numberCode: inputCode,
        deviceId: deviceId);

    final responseData = response.data;
    final int? id = responseData?["id"];
    final String? status = responseData?["status"];
    final bool isSuccessful =
        response.statusCode == 200 && id != null && status == "on_call";

    // String message = isSuccessful
    // ? "签到成功"
    //     : getMappingMessage(responseData?['message'] ??
    // JsonEncoder.withIndent("  ").convert(responseData));

    if (!isSuccessful) {
      toastFailure0('签到失败，点名已结束');
      showFailureState('签到失败，点名已结束');
      return;
    }

    toastSuccess0("签到成功");
    // 验证成功
    showSuccessState();
  }

  void showSuccessState() {
    clearError();
    currentState.value = RollcallState.success;
    // 设置成功时间
    final now = DateTime.now();
    successTime.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 保持显示状态，不自动重置
  }

  void showFailureState(String message) {
    // hasError.value = true;
    errorMessage.value = message;
    currentState.value = RollcallState.failure;

    // 保持显示状态，不自动重置
  }

  void resetToInputState() {
    currentState.value = RollcallState.input;
    clearError();
    code.value = '';
    successTime.value = '';
  }

  void triggerPrinterAnimation() {
    // 这个方法可以被页面调用来重新启动打印机动画
  }
}
