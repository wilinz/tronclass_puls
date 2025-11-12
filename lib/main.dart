import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'data/changke_client.dart';
import 'data/get_storage.dart';
import 'path.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFilePath();
  await initGetStorage();
  final savedUsername = getStorage.read<String>(
    GetStorageKeys.lastLoginUsername,
  );
  // 初始化默认用户实例（同步），优先使用上次登录的用户
  if (savedUsername?.isNotEmpty ?? false) {
    ChangkeClient.getInstance(username: savedUsername);
  } else {
    ChangkeClient.getInstance();
  }
  runApp(const TronclassApp());
}

class TronclassApp extends StatelessWidget {
  const TronclassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: true,
      ),
      child: GetMaterialApp(
        navigatorKey: AppRoute.navigatorKey,
        title: 'Tronclass Sign-in',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DB6C2)),
        ),
        initialRoute: AppRoute.tronClassPage,
        builder: FToastBuilder(),
        getPages: AppRoute.routes,
      ),
    );
  }
}
