import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'input.dart';
import 'number_rollcalls_controller.dart';

class NumberRollcallsPageArgs {
  final int rollcallId;

  NumberRollcallsPageArgs({required this.rollcallId});
}

class NumberRollcallsPage extends StatefulWidget {
  const NumberRollcallsPage({super.key, required this.args});

  final NumberRollcallsPageArgs args;

  @override
  State<NumberRollcallsPage> createState() => _NumberRollcallsPageState();
}

class _NumberRollcallsPageState extends State<NumberRollcallsPage>
    with TickerProviderStateMixin {
  late NumberRollcallsController controller =
      Get.put(NumberRollcallsController(rollcallId: widget.args.rollcallId));

  final FocusNode _codeFocus = FocusNode();
  
  late AnimationController _printerAnimationController;
  late Animation<double> _printerPaperAnimation;
  
  // 纸张槽的位置和尺寸
  static const double _slotTopPosition = 40.0;
  static const double _slotHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _printerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // 打印机打印纸张的动画 - 从30%打印到完整纸张
    _printerPaperAnimation = Tween<double>(
      begin: 0.3,  // 初始状态显示底部30%
      end: 1.0,    // 完成状态显示完整纸张
    ).animate(CurvedAnimation(
      parent: _printerAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // 初始状态显示底部30%
    _printerAnimationController.value = 0.0;  // 0.0对应30%

    // 监听状态变化，只有在状态转换时才播放打印动画
    ever(controller.currentState, (state) {
      if (state == RollcallState.success || state == RollcallState.failure) {
        // 从当前状态开始打印完整纸条
        _printerAnimationController.forward();
      } else if (state == RollcallState.input && _printerAnimationController.value > 0.0) {
        // 只在首次加载时重置为30%，其他时候不自动收回
        // 这里不做任何操作，保持展开状态
      }
    });
  }

  @override
  void dispose() {
    _printerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("数字点名", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00A9C0),
        iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.white),
        actionsIconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF00A9C0),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00A9C0),
              Color(0xFF0086A3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(
              children: [
                // 固定的验证码输入界面
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                                         // 打印机纸张槽 - 固定在上方
                     Container(
                       width: double.infinity,
                       height: _slotHeight,
                       constraints: const BoxConstraints(maxWidth: 400),
                       child: Image.asset(
                         'assets/images/number_rollcall_paper_slot.png',
                         width: double.infinity,
                         fit: BoxFit.cover,
                       ),
                     ),
                    const SizedBox(height: 10),
                    const Text("请输入签到密码", style: TextStyle(fontSize: 14, color: Colors.white)),
                    const SizedBox(height: 8),
                                         // 验证码输入框
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
                       child: Obx(() => AdvancedCodeInput(
                         codeLength: 4,
                         focusNode: _codeFocus,
                         autofocus: true,
                         hasError: controller.hasError.value,
                         // errorMessage: controller.errorMessage.value,
                         backgroundColor: Colors.white,
                         activeColor: const Color(0xFF00A9C0),
                         errorColor: Colors.red,
                         margin: EdgeInsets.only(left: 3, right: 3),
                         boxWidth: 90*0.618,
                         boxHeight: 80,
                         textStyle: TextStyle(fontSize: 48),
                         onChanged: (code) {
                           controller.updateCode(code);
                           if (controller.hasError.value) {
                             controller.clearError();
                           }
                         },
                         onCompleted: (code) {
                           controller.submitCode(code);
                         },
                       )),
                     ),
                    // const SizedBox(height: 20),
                    // const Text(
                    //   "长按输入框可以粘贴或清空",
                    //   style: TextStyle(fontSize: 14, color: Colors.white70),
                    // ),
                  ],
                ),
                // 打印出来的纸张 - 覆盖在上方
                Obx(() {
                  if (controller.currentState.value == RollcallState.success) {
                    return _buildPrintedPaper(true);
                  } else if (controller.currentState.value == RollcallState.failure) {
                    return _buildPrintedPaper(false);
                  } else {
                    // 初始状态也显示纸张底部30%
                    return _buildEmptyPaper();
                  }
                }),

              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildPrintedPaper(bool isSuccess) {
    return Positioned(
      top: _slotTopPosition + _slotHeight / 2, // 纸张顶部从slot center开始
      left: 20,
      right: 20,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: AnimatedBuilder(
          animation: _printerPaperAnimation,
          builder: (context, child) {
            return ClipRect(
              child: SizedBox(
                width: double.infinity,
                height: 180, // 减少容器高度，让纸张不要延伸太远
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Transform.translate(
                        offset: Offset(0, -180 * (1 - _printerPaperAnimation.value)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Stack(
                            children: [
                              // 纸张背景
                              Image.asset(
                                'assets/images/number_rollcall_paper.png',
                                width: double.infinity,
                                fit: BoxFit.fitWidth,
                              ),
                              // 纸张内容
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 图标
                                      SvgPicture.asset(
                                        isSuccess 
                                          ? 'assets/images/number_rollcall_paper_icon_success.svg'
                                          : 'assets/images/number_rollcall_paper_icon_fail.svg',
                                        width: 48,
                                        height: 48,
                                      ),
                                      const SizedBox(height: 4),
                                      // 文本
                                      Text(
                                        isSuccess ? '签到成功' : '签到失败',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      // 时间或错误信息
                                      Text(
                                        isSuccess 
                                          ? controller.successTime.value 
                                          : controller.errorMessage.value,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyPaper() {
    return Positioned(
      top: _slotTopPosition + _slotHeight / 2, // 纸张顶部从slot center开始
      left: 20,
      right: 20,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: AnimatedBuilder(
          animation: _printerPaperAnimation,
          builder: (context, child) {
            return ClipRect(
              child: SizedBox(
                width: double.infinity,
                height: 180, // 减少容器高度，让纸张不要延伸太远
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Transform.translate(
                        offset: Offset(0, -180 * (1 - _printerPaperAnimation.value)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Image.asset(
                            'assets/images/number_rollcall_paper.png',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }




}
