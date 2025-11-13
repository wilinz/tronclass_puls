import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tronclass/auth/auth_controller.dart';
import 'package:tronclass/auth/saved_account_storage.dart';
import 'package:tronclass/common/toast.dart';
import 'package:tronclass/data/changke_client.dart';
import 'package:tronclass/data/get_storage.dart';
import 'package:tronclass/data/service/login.dart';

class LoginController extends GetxController {
  LoginController({this.initialUsername, this.initialPassword});

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isSubmitting = false.obs;
  final passwordVisible = false.obs;
  final passwordErrorCount = 0.obs;
  final suppressPasswordError = true.obs;
  final isFirstLoginAttempt = true.obs;

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
    if (isSubmitting.value) {
      return;
    }
    isSubmitting.value = true;

    final username = usernameController.text.trim();
    final password = passwordController.text;
    final client = ChangkeClient.getInstance(username: username);

    final attemptLimit = isFirstLoginAttempt.value ? 3 : 1;
    isFirstLoginAttempt.value = false;

    Object? lastError;

    for (var attempt = 0; attempt < attemptLimit; attempt++) {
      try {
        await client.login(
          username: username,
          password: password,
          captchaRequester: _showCaptchaDialog,
        );
        await SavedAccountStorage.upsertAccount(
          username: username,
          password: password,
        );
        await getStorage.write(GetStorageKeys.lastLoginUsername, username);
        await getStorage.write(GetStorageKeys.isCleanWebSession, true);
        Get.find<AuthController>().refreshState();

        passwordErrorCount.value = 0;
        suppressPasswordError.value = true;

        toastSuccess0('登录成功');
        if (!isClosed) {
          isSubmitting.value = false;
        }
        Get.back(result: true);
        return;
      } on RequireLoginVerificationCodeException catch (e) {
        final handled = await _handleVerificationRequired(
          username: username,
          client: client,
        );
        if (handled) {
          if (!isClosed) {
            isSubmitting.value = false;
          }
          await submit();
          return;
        }
        lastError = e;
        break;
      } catch (e) {
        lastError = e;
        if (attempt < attemptLimit - 1) {
          continue;
        }
      }
    }

    if (lastError != null) {
      _handleLoginError(lastError);
    }

    if (!isClosed) {
      isSubmitting.value = false;
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

  void _handleLoginError(Object error) {
    final message = error.toString();
    final isPasswordError =
        message.contains('密码有误') || message.contains('密码错误');

    if (isPasswordError) {
      passwordErrorCount.value++;
      if (suppressPasswordError.value && passwordErrorCount.value <= 3) {
        toastFailure0('登录过程发生错误，请核对密码并重试');
      } else {
        suppressPasswordError.value = false;
        toastFailure0('登录失败，请检查密码并重试');
      }
      return;
    }

    toastFailure(message: '登录失败', error: error);
  }

  Future<bool> _handleVerificationRequired({
    required String username,
    required ChangkeClient client,
  }) async {
    try {
      return await _showVerificationCodeDialog(
        casDio: client.casDio,
        username: username,
      );
    } catch (e) {
      toastFailure(message: '验证码流程失败', error: e);
      return false;
    }
  }

  Future<bool> _showVerificationCodeDialog({
    required Dio casDio,
    required String username,
  }) async {
    final codeController = TextEditingController();
    Timer? countdownTimer;
    int? countdown;
    String? maskedMobile;
    bool sending = false;
    bool verifying = false;

    void stopTimer() {
      countdownTimer?.cancel();
      countdownTimer = null;
    }

    final result = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> startCountdown(int seconds) async {
            stopTimer();
            setState(() {
              countdown = seconds;
            });
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              setState(() {
                if (countdown != null && countdown! > 1) {
                  countdown = countdown! - 1;
                } else {
                  countdown = null;
                  stopTimer();
                }
              });
            });
          }

          Future<void> sendCode() async {
            if (sending) return;
            setState(() {
              sending = true;
            });
            try {
              final resp = await LoginService.sendDynamicCode(
                dio: casDio,
                username: username,
              );
              maskedMobile = resp.mobile;
              final seconds = resp.codeTime ?? 120;
              await startCountdown(seconds);
              final message = resp.returnMessage ?? '验证码已发送';
              toastSuccess0(message);
            } catch (e) {
              toastFailure(message: '发送验证码失败', error: e);
            } finally {
              setState(() {
                sending = false;
              });
            }
          }

          Future<void> verifyCode() async {
            if (verifying) return;
            final code = codeController.text.trim();
            if (code.isEmpty) {
              toastFailure0('请输入验证码');
              return;
            }
            setState(() {
              verifying = true;
            });
            try {
              final resp = await LoginService.reAuthCheck(
                dio: casDio,
                code: code,
              );
              if (resp.code == 'reAuth_success') {
                toastSuccess0('验证成功');
                Get.back(result: true);
              } else {
                toastFailure0(resp.msg ?? '验证失败，请重试');
              }
            } catch (e) {
              toastFailure(message: '验证失败', error: e);
            } finally {
              setState(() {
                verifying = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('短信验证'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('智慧校园要求短信二次验证，请先发送验证码并输入完成验证。'),
                if (maskedMobile != null) ...[
                  const SizedBox(height: 8),
                  Text('验证码已发送到：$maskedMobile'),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '短信验证码',
                    hintText: '请输入短信验证码',
                    prefixIcon: const Icon(Icons.message),
                    suffixIcon: countdown == null
                        ? IconButton(
                            onPressed: sending ? null : sendCode,
                            icon: sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Center(
                              child: Text('${countdown!}s'),
                            ),
                          ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: verifying
                    ? null
                    : () {
                        Get.back(result: false);
                      },
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: verifying ? null : verifyCode,
                child: verifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('验证并继续'),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );

    stopTimer();
    codeController.dispose();
    return result ?? false;
  }
}
