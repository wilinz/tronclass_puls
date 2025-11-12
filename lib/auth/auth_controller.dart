import 'package:get/get.dart';

import 'package:tronclass/data/changke_client.dart';

class AuthController extends GetxController {
  final isLoggedIn = ChangkeClient.instance.isLoggedIn.obs;

  void refreshState() {
    isLoggedIn.value = ChangkeClient.instance.isLoggedIn;
  }

  void logout() {
    ChangkeClient.instance.logout();
    refreshState();
  }
}
