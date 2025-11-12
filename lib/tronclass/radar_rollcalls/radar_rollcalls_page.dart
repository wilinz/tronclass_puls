import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'radar_rollcalls_controller.dart';

class RadarRollcallsPageArgs {
  final int rollcallId;

  RadarRollcallsPageArgs({required this.rollcallId});
}

class RadarRollcallsPage extends StatefulWidget {
  const RadarRollcallsPage({super.key, required this.args});

  final RadarRollcallsPageArgs args;

  @override
  State<RadarRollcallsPage> createState() => _RadarRollcallsPageState();
}

class _RadarRollcallsPageState extends State<RadarRollcallsPage> {
  late RadarRollcallsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(RadarRollcallsController(rollcallId: widget.args.rollcallId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF01b9bb), // 顶部蓝色
              Color(0xFF29cbcd), // 底部浅蓝色
            ],
          ),
        ),
        child: Column(
          children: [
            // 上半部分：渐变背景 + SafeArea内容
            Expanded(
              child: Container(
                child: SafeArea(
                  child: Column(
                    children: [
                      // 顶部标题栏
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  '雷达点名',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // 平衡左侧按钮
                          ],
                        ),
                      ),

                      // 中间内容区域
                      Expanded(
                        child: Obx(() {
                          switch (controller.currentState.value) {
                            case RadarRollcallState.radar:
                              return _buildRadarContent();
                            case RadarRollcallState.success:
                              return Center(child: _buildSuccessContent());
                            case RadarRollcallState.failure:
                              return Center(child: _buildFailureContent());
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 底部卡片 - 不在SafeArea内
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 40,
                right: 40,
                top: 100,
                bottom: 100 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Obx(() => _buildBottomButton()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 状态文本
        Obx(() {
          return Text(
            controller.isScanning.value ? '正在签到...' : '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          );
        }),

        const SizedBox(height: 20),

        // 雷达图标 - 使用提供的SVG，紧贴底部
        Container(
          height: 240,
          child: SvgPicture.asset(
            'assets/images/rollcalls_icon-radar.svg',
            width: 240,
            height: 240,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 成功状态图标
        Container(
          height: 200,
          child: Image.asset(
            'assets/images/radar-rollcall-success.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 30),

        // 成功文字
        Text(
          '签到成功',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        // 时间信息
        Text(
          DateTime.now().toString().substring(0, 16),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFailureContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 失败状态图标
        Container(
          height: 200,
          child: Image.asset(
            'assets/images/radar-rollcall-failed.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 30),

        // 失败文字
        Text(
          '签到失败',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        // 错误信息
        Text(
          '签到失败，点名已结束',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    switch (controller.currentState.value) {
      case RadarRollcallState.radar:
        return Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: ElevatedButton(
              onPressed: controller.isScanning.value ? null : controller.openLocationPicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20bec8),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFF20bec8).withOpacity(0.8),
              ),
              child: Text(
                controller.isScanning.value ? '签到中' : '签到',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      case RadarRollcallState.success:
        return Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20bec8),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 0,
              ),
              child: const Text(
                '完成',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      case RadarRollcallState.failure:
        return Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: ElevatedButton(
              onPressed: () {
                controller.restartRadar();
                controller.openLocationPicker();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20bec8),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 0,
              ),
              child: const Text(
                '重试',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
    }
  }
}