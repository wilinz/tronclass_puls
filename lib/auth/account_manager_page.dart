import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tronclass/auth/account_manager_controller.dart';
import 'package:tronclass/routes.dart';

class AccountManagerPage extends StatelessWidget {
  const AccountManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountManagerController>(
      init: AccountManagerController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('管理账号'),
            actions: [
              IconButton(
                onPressed: controller.loadAccounts,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Obx(() {
            final accounts = controller.accounts;
            final isProcessing = controller.isProcessing.value;
            final currentUser = controller.currentUsername.value;
            if (accounts.isEmpty) {
              return const Center(child: Text('暂无保存的账号，登录后可自动保存'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final account = accounts[index];
                final isCurrent = account.username == currentUser;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Row(
                      children: [
                        Expanded(child: Text(account.username)),
                        // Expanded(child: Text('示意账号')),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '当前',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '最近更新：${account.updatedAt.toLocal().toString().split('.').first}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: isProcessing
                              ? null
                              : () => controller.loginWithAccount(account),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final confirmed = await _confirmDeletion(
                                    context,
                                    account.username,
                                  );
                                  if (confirmed == true) {
                                    controller.deleteAccount(account.username);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: accounts.length,
            );
          }),
          bottomNavigationBar: Obx(
            () => controller.isProcessing.value
                ? const LinearProgressIndicator()
                : const SizedBox.shrink(),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Get.toNamed(AppRoute.loginPage);
              if (result == true) {
                controller.loadAccounts();
                Get.back(result: true);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('添加账号'),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context, String username) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除账号'),
          content: Text('确定要删除账号 $username 吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
