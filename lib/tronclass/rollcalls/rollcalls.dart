import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:tronclass/data/model/tron_class/rollcalls_response/rollcalls_response.dart'
    show Rollcalls;
import 'package:tronclass/routes.dart';
import 'package:tronclass/tronclass/number_rollcalls/number_rollcalls_page.dart';
import 'package:tronclass/tronclass/radar_rollcalls/radar_rollcalls_page.dart';

import 'rollcalls_controller.dart';

class RollcallListPage extends StatelessWidget {
  const RollcallListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final RollcallController controller = Get.put(RollcallController());
    controller.fetchRollcalls();

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择签到课程'),
        actions: [
          HiddenClickButton(controller: controller),
        ],
      ),
      body: SafeArea(
        child: Obx(() => Column(
              children: [
                MockDataBanner(showMockData: controller.showMockData.value),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        controller.fetchRollcalls(isPullRefresh: true),
                    child: RollcallContent(controller: controller),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class HiddenClickButton extends StatelessWidget {
  final RollcallController controller;

  const HiddenClickButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: controller.onHiddenButtonTap,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            color: Colors.transparent,
            child: controller.clickCount.value > 0
                ? Center(
                    child: Text(
                      '${controller.clickCount.value}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
          ),
        ));
  }
}

class MockDataBanner extends StatelessWidget {
  final bool showMockData;

  const MockDataBanner({
    super.key,
    required this.showMockData,
  });

  @override
  Widget build(BuildContext context) {
    if (!showMockData) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.orange.withOpacity(0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science, size: 16, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            "Mock数据模式已激活",
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class RollcallContent extends StatelessWidget {
  final RollcallController controller;

  const RollcallContent({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.rollcalls.isEmpty) {
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child:
                    RollcallsEmpty(showMockData: controller.showMockData.value),
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        separatorBuilder: (_, __) => Divider(
          thickness: 0.5,
          color: Colors.black.withValues(alpha: 0.1),
        ),
        itemCount: controller.rollcalls.length,
        itemBuilder: (context, index) {
          return RollcallItem(rollcall: controller.rollcalls[index]);
        },
      );
    });
  }
}

class RollcallItem extends StatelessWidget {
  final Rollcalls rollcall;

  const RollcallItem({
    super.key,
    required this.rollcall,
  });

  @override
  Widget build(BuildContext context) {
    final rollcallInfo = _getRollcallInfo();

    return InkWell(
      onTap: () => _handleNavigation(rollcallInfo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RollcallImage(),
            const SizedBox(width: 16),
            Expanded(
              child: RollcallDetails(
                rollcall: rollcall,
                rollcallInfo: rollcallInfo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  RollcallInfo _getRollcallInfo() {
    if (rollcall.isNumber && !rollcall.isRadar) {
      return RollcallInfo(
        buttonText: "数字点名",
        buttonIconPath: "assets/images/number_rollcalls.svg",
        buttonColor: const Color(0xFF5ABBC6),
        route: AppRoute.numberRollcallsPage,
      );
    } else if (rollcall.isRadar && !rollcall.isNumber) {
      return RollcallInfo(
        buttonText: "雷达点名",
        buttonIconPath: "assets/images/rollcalls_icon-radar.svg",
        buttonColor: const Color(0xFF5B90EF),
        route: AppRoute.radarRollcallsPage,
      );
    } else {
      return RollcallInfo(
        buttonText: "二维码点名",
        buttonIconPath: "assets/images/qr_rollcalls.svg",
        buttonColor: const Color(0xFF74BC49),
        route: AppRoute.qrRollcallsPage,
      );
    }
  }

  void _handleNavigation(RollcallInfo info) {
    if (info.route == AppRoute.radarRollcallsPage) {
      Get.toNamed(info.route,
          arguments: RadarRollcallsPageArgs(rollcallId: rollcall.rollcallId));
    } else if (info.route == AppRoute.numberRollcallsPage) {
      Get.toNamed(info.route,
          arguments: NumberRollcallsPageArgs(rollcallId: rollcall.rollcallId));
    } else {
      Get.toNamed(info.route);
    }
  }
}

class RollcallImage extends StatelessWidget {
  const RollcallImage({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        "assets/images/rollcalls_item.png",
        fit: BoxFit.fitHeight,
        height: 80,
      ),
    );
  }
}

class RollcallDetails extends StatelessWidget {
  final Rollcalls rollcall;
  final RollcallInfo rollcallInfo;

  const RollcallDetails({
    super.key,
    required this.rollcall,
    required this.rollcallInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rollcall.courseTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rollcall.createdByName,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          rollcall.departmentName,
          style: const TextStyle(color: Colors.grey),
        ),
        if (rollcall.className.isNotEmpty)
          Text(
            rollcall.className,
            style: const TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            RollcallButton(
              text: rollcallInfo.buttonText,
              color: rollcallInfo.buttonColor,
              iconPath: rollcallInfo.buttonIconPath,
            ),
            RollcallStatusTag(status: rollcall.status),
          ],
        ),
      ],
    );
  }
}

class RollcallButton extends StatelessWidget {
  final String text;
  final Color color;
  final String iconPath;

  const RollcallButton({
    super.key,
    required this.text,
    required this.color,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            width: 10,
            height: 10,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class RollcallStatusTag extends StatelessWidget {
  final String status;

  const RollcallStatusTag({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status != "on_call_fine") return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFeceef2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case "on_call_fine":
        return '已签到';
      case "present":
        return '出席';
      case "late":
        return '迟到';
      case "excused":
        return '请假';
      case "absent":
        return '缺席';
      default:
        return '未知';
    }
  }
}

class RollcallsEmpty extends StatelessWidget {
  final bool showMockData;

  const RollcallsEmpty({
    super.key,
    this.showMockData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Image.asset("assets/images/rollcalls_empty.png"),
          ),
          Text(
            "目前尚未开放签到",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            showMockData ? "Mock数据已激活！下拉刷新查看模拟数据" : "老师说要签到？下拉刷新试试吧",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// 数据类
class RollcallInfo {
  final String buttonText;
  final String buttonIconPath;
  final Color buttonColor;
  final String route;

  const RollcallInfo({
    required this.buttonText,
    required this.buttonIconPath,
    required this.buttonColor,
    required this.route,
  });
}

// 保持向后兼容，移除旧的CustomButton
@Deprecated('Use RollcallButton instead')
class CustomButton extends StatelessWidget {
  final String text;
  final Color color;
  final Widget? prefixIcon;

  const CustomButton({
    super.key,
    required this.text,
    this.color = Colors.teal,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefixIcon != null) ...[
            prefixIcon!,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
