import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:pure_dart_extensions/pure_dart_extensions.dart';
import 'package:tronclass/common/toast.dart';
import 'package:tronclass/data/changke_client.dart';
import 'package:tronclass/data/service/tronclass.dart';
import 'package:uuid/uuid.dart';

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
  var successCode = ''.obs;
  var isBruteForcing = false.obs;
  var bruteForceAttempts = 0.obs;
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

    try {
      final success = await _performSignRequest(inputCode);
      if (!success) {
        toastFailure0('签到失败，点名已结束');
        showFailureState('签到失败，点名已结束');
        return;
      }

      toastSuccess0("签到成功");
      showSuccessState(code: inputCode);
    } catch (e) {
      toastFailure0('签到失败，请稍后再试');
      showFailureState('签到失败，请稍后再试');
    }
  }

  Future<void> bruteForceSignCodes() async {
    if (isBruteForcing.value) return;

    resetToInputState();
    isBruteForcing.value = true;
    bruteForceAttempts.value = 0;

    const int maxCode = 10000; // 0000-9999
    const int windowSize = 100;
    int currentIndex = 0;
    var found = false;
    var abort = false;
    String? lastErrorMessage;
    final deviceId = Uuid().v4();

    Future<void> worker() async {
      while (true) {
        if (found || abort) break;
        final int index = currentIndex;
        if (index >= maxCode) break;
        currentIndex++;
        final candidate = index.toString().padLeft(4, '0');

        bool attemptSuccess = false;
        try {
          attemptSuccess = await _performSignRequest(candidate,
              deviceIdOverride: deviceId);
        } catch (e) {
          lastErrorMessage ??= e.toString();
          abort = true;
          break;
        } finally {
          bruteForceAttempts.value++;
        }

        if (attemptSuccess && !found) {
          found = true;
          toastSuccess0('已自动匹配签到码 $candidate');
          showSuccessState(code: candidate);
          break;
        }
      }
    }

    final workerCount = math.min(windowSize, maxCode);
    await Future.wait(List.generate(workerCount, (_) => worker()));

    isBruteForcing.value = false;

    if (!found) {
      final message = abort
          ? '一键签到失败，请稍后再试'
          : '一键签到失败，未匹配到正确签到码';
      toastFailure0(message);
      showFailureState(message);
    }
  }

  Future<bool> _performSignRequest(String inputCode,
      {String? deviceIdOverride}) async {
    final deviceId = deviceIdOverride ?? Uuid().v4();
    final response = await TronClassService.signNumber(
        ChangkeClient.instance.dio,
        rollcallId: rollcallId.toString(),
        numberCode: inputCode,
        deviceId: deviceId);

    final responseData = response.data;
    final String? status = responseData?["status"];
    final bool isSuccessful =
        response.statusCode == 200 && status == "on_call";

    return isSuccessful;
  }

  void showSuccessState({String? code}) {
    clearError();
    currentState.value = RollcallState.success;
    successCode.value = code ?? '';
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
    successCode.value = '';

    // 保持显示状态，不自动重置
  }

  void resetToInputState() {
    currentState.value = RollcallState.input;
    clearError();
    code.value = '';
    successTime.value = '';
    successCode.value = '';
  }

  void triggerPrinterAnimation() {
    // 这个方法可以被页面调用来重新启动打印机动画
  }
}
