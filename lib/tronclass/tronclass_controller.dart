import 'package:get/get.dart';

import 'package:tronclass/common/toast.dart';

// import 'qr_rollcalls/scan_qr.dart';

class ChangkeController extends GetxController {
  // 示例状态：夜间提示
  var greeting = "夜深了，请注意休息".obs;

  // 最近访问的示例数据
  var recentItems = <String>[
    "模式识别（双语教学）",
    "计算机视觉（双语教学）",
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      greeting.value = "早上好，今天也是充满活力的一天！";
    } else if (hour >= 12 && hour < 18) {
      greeting.value = "下午好，保持充实的一天！";
    } else if (hour >= 18 && hour < 24) {
      greeting.value = "晚上好，放松一下吧！";
    } else {
      greeting.value = "夜深了，请注意休息";
    }
  }

  Future<void> scanQr() async {
    toastFailure0('扫码签到功能暂未开放，请使用下面的入口');
  }

}
