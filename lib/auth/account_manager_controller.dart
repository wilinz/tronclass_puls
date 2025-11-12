import 'package:get/get.dart';

import 'package:tronclass/auth/saved_account_storage.dart';
import 'package:tronclass/data/get_storage.dart';
import 'package:tronclass/routes.dart';

class AccountManagerController extends GetxController {
  final accounts = <SavedAccount>[].obs;
  final isProcessing = false.obs;
  final currentUsername = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
    refreshCurrentUser();
  }

  void loadAccounts() {
    accounts.assignAll(SavedAccountStorage.loadAccounts());
    refreshCurrentUser();
  }

  void refreshCurrentUser() {
    final stored = getStorage.read<String>(GetStorageKeys.lastLoginUsername);
    currentUsername.value = stored ?? '';
  }

  Future<void> deleteAccount(String username) async {
    await SavedAccountStorage.removeAccount(username);
    loadAccounts();
  }

  Future<void> loginWithAccount(SavedAccount account) async {
    isProcessing.value = true;
    final password = SavedAccountStorage.decryptPassword(account);
    isProcessing.value = false;

    final args = {
      'username': account.username,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final result = await Get.toNamed(AppRoute.loginPage, arguments: args);
    refreshCurrentUser();
    if (result == true) {
      Get.back(result: true);
    }
  }
}
