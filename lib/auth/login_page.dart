import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tronclass/auth/login_controller.dart';
import 'package:tronclass/routes.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    String? initialUsername;
    String? initialPassword;
    final args = Get.arguments;
    if (args is String) {
      initialUsername = args;
    } else if (args is Map) {
      final map = Map<String, dynamic>.from(args as Map);
      final user = map['username'];
      final pass = map['password'];
      if (user is String) initialUsername = user;
      if (pass is String) initialPassword = pass;
    }

    return GetBuilder<LoginController>(
      init: LoginController(
        initialUsername: initialUsername,
        initialPassword: initialPassword,
      ),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(title: const Text('登录')),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: controller.formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.qr_code_scanner,
                                      size: 24,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '登录 Tronclass',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '使用教务系统账户登录 Tronclass，进行扫码签到',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        TextFormField(
                          controller: controller.usernameController,
                          autofocus: false,
                          decoration: const InputDecoration(
                            labelText: '学号',
                            hintText: '您的学号',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                          validator: (v) {
                            return v!.trim().isNotEmpty ? null : '学号不能为空';
                          },
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => TextFormField(
                            controller: controller.passwordController,
                            obscureText: !controller.passwordVisible.value,
                            autofocus: false,
                            decoration: InputDecoration(
                              labelText: '智慧校园密码',
                              hintText: '初始为 Guet@身份证后六位',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.passwordVisible.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                              ),
                            ),
                            validator: (v) {
                              return v!.trim().isNotEmpty ? null : '密码不能为空';
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => ElevatedButton(
                            onPressed: controller.isSubmitting.value
                                ? null
                                : controller.submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: controller.isSubmitting.value
                                ? const Text('正在登录...')
                                : const Text('登录'),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await Get.toNamed(
                              AppRoute.accountManagerPage,
                            );
                            if (result == true) {
                              Get.back(result: true);
                            }
                          },
                          child: const Text('管理已保存账号'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
