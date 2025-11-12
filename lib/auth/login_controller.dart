import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tronclass/auth/auth_controller.dart';
import 'package:tronclass/auth/saved_account_storage.dart';
import 'package:tronclass/common/toast.dart';
import 'package:tronclass/data/changke_client.dart';
import 'package:tronclass/data/get_storage.dart';

class LoginController extends GetxController {
  LoginController({this.initialUsername, this.initialPassword});

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isSubmitting = false.obs;
  final passwordVisible = false.obs;

  final String? initialUsername;
  final String? initialPassword;

  @override
  void onInit() {
    super.onInit();
    final savedUsername =
        initialUsername ??
        getStorage.read<String>(GetStorageKeys.lastLoginUsername);
    if (savedUsername?.isNotEmpty ?? false) {
      usernameController.text = savedUsername!;
      ChangkeClient.getInstance(username: savedUsername);
    }
    final prefPassword = initialPassword;
    if (prefPassword?.isNotEmpty ?? false) {
      passwordController.text = prefPassword!;
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    isSubmitting.value = true;

    try {
      final username = usernameController.text.trim();
      final client = ChangkeClient.getInstance(username: username);
      await client.login(
        username: username,
        password: passwordController.text,
        captchaRequester: _showCaptchaDialog,
      );
      await SavedAccountStorage.upsertAccount(
        username: username,
        password: passwordController.text,
      );
      await getStorage.write(GetStorageKeys.lastLoginUsername, username);
      await getStorage.write(GetStorageKeys.isCleanWebSession, true);
      Get.find<AuthController>().refreshState();
      toastSuccess0('登录成功');
      Get.back(result: true);
    } catch (e) {
      toastFailure(message: '登录失败', error: e);
    } finally {
      if (!isClosed) {
        isSubmitting.value = false;
      }
    }
  }

  void togglePasswordVisibility() {
    passwordVisible.value = !passwordVisible.value;
  }

  Future<String> _showCaptchaDialog(Uint8List image) async {
    final completer = Completer<String>();
    final controller = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('请输入验证码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(image, width: 160, height: 80, fit: BoxFit.contain),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '验证码'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              if (!completer.isCompleted) {
                completer.complete('');
              }
              Get.back();
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              controller.dispose();
              if (!completer.isCompleted) {
                completer.complete(value);
              }
              Get.back();
            },
            child: const Text('确定'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
