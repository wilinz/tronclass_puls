import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_dart/kt.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';

import 'package:tronclass/data/changke_client.dart';
import 'package:tronclass/data/service/tronclass.dart';
import 'package:tronclass/data/util/changke.dart';

import 'package:tronclass/tronclass/common.dart';
import 'package:tronclass/tronclass/qr_rollcalls/sign_result.dart';

class QrRollcallsPage extends StatefulWidget {
  const QrRollcallsPage({super.key});

  @override
  State<QrRollcallsPage> createState() => _QrRollcallsPageState();
}

class _QrRollcallsPageState extends State<QrRollcallsPage>
    with WidgetsBindingObserver {
  // 扫描相关状态
  bool hasCustomVibrationsSupport = false;
  bool isFlash = false;
  MobileScannerController? controller;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  final double _scaleThreshold = 0.15;
  double _lastScaleUpdate = 1.0;
  final double _zoomFactor = 2.0;

  // 简化状态管理
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initAsync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用重新显示时，检查相机状态
      if (mounted && !isProcessing) {
        _ensureCameraRunning();
      }
    }
  }

  // 确保相机运行
  void _ensureCameraRunning() {
    if (controller != null && mounted) {
      controller?.start();
    }
  }

  initAsync() async {
    try {
      // 检查振动支持
      (await Vibration.hasCustomVibrationsSupport())?.let((it) {
        if (mounted) {
          setState(() {
            hasCustomVibrationsSupport = it;
          });
        }
      });

      // 检查相机权限
      if (GetPlatform.isMobile) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          if (mounted) {
            Get.to(() => const ChangkeSignResult(
                  successful: false,
                  message: "请允许相机权限才能进行扫描二维码",
                ))?.then((_) {
              // 返回后退出页面
              if (mounted) Get.back();
            });
          }
          return;
        }
      }
    } catch (e) {
      print("初始化错误: $e");
      if (mounted) {
        Get.to(() => const ChangkeSignResult(
              successful: false,
              message: "初始化失败，请重试",
            ))?.then((_) {
          if (mounted) Get.back();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (controller == null) {
        final mediaQuery = MediaQuery.of(context);
        final devicePixelRatio = mediaQuery.devicePixelRatio;
        final size = Size(constraints.maxWidth, constraints.maxHeight) *
            devicePixelRatio;
        print("相机大小：${size}, 像素密度: ${devicePixelRatio}");
        controller =
            MobileScannerController(cameraResolution: Size(1080, 1920));
      }

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
          actions: [
            IconButton(
                onPressed: () {
                  controller?.toggleTorch();
                  setState(() {
                    isFlash = !isFlash;
                  });
                },
                icon: Icon(isFlash
                    ? Icons.flash_off_outlined
                    : Icons.flash_on_outlined))
          ],
          title: Text("二维码签到"),
        ),
        body: GestureDetector(
          onScaleStart: (details) {
            _baseScale = _currentScale;
          },
          onScaleUpdate: (details) {
            double newScale =
                (_baseScale * pow(details.scale, _zoomFactor)).clamp(1.0, 10.0);
            if ((newScale - _lastScaleUpdate).abs() > _scaleThreshold) {
              setState(() {
                _currentScale = newScale;
                double normalizedScale = log(_currentScale) / log(10.0);
                controller?.setZoomScale(normalizedScale);
                _lastScaleUpdate = newScale;
              });
            }
          },
          child: MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (isProcessing) return; // 防止重复处理

              controller?.stop();
              setState(() {
                isProcessing = true;
              });

              if (hasCustomVibrationsSupport) {
                Vibration.vibrate(duration: 100);
              } else {
                Vibration.vibrate();
              }

              await Future.delayed(Duration(milliseconds: 100));

              // 处理扫描结果
              _handleScanResult(capture);
            },
            overlayBuilder:
                (BuildContext context, BoxConstraints constraints) =>
                    Positioned(
              child: ScannerBox(width: 300, height: 300),
            ),
          ),
        ),
      );
    });
  }

  // 处理扫描结果
  void _handleScanResult(BarcodeCapture capture) {
    try {
      final code = capture.barcodes.firstOrNull?.rawValue;
      if (code == null) {
        if (mounted) {
          Get.to(() => const ChangkeSignResult(
                successful: false,
                message: "未识别到二维码",
              ))?.then((_) {
            if (mounted) _restartScan();
          });
        }
        return;
      }

      final codeData = parseChangkeScanUrl(code);

      if (!(codeData is Map)) {
        if (mounted) {
          Get.to(() => const ChangkeSignResult(
                successful: false,
                message: "二维码格式错误",
              ))?.then((_) {
            if (mounted) _restartScan();
          });
        }
        return;
      }

      final rollcallId = codeData['rollcallId']?.toString();
      final data = codeData['data'];

      if (rollcallId == null || data == null) {
        if (mounted) {
          Get.to(() => const ChangkeSignResult(
                successful: false,
                message: "二维码格式错误",
              ))?.then((_) {
            if (mounted) _restartScan();
          });
        }
        return;
      }

      // 立即导航到签到结果页面，显示"正在签到中"
      if (mounted) {
        Get.to(() => QrSignResultPage(
              rollcallId: rollcallId,
              data: data,
              onBack: () {
                Get.back(); // 返回到扫描页面
                _restartScan(); // 重新开始扫描
              },
            ))?.then((_) {
          // 无论如何返回都确保相机重启
          if (mounted) _restartScan();
        });
      }
    } catch (e) {
      print("扫描处理错误: $e");
      if (mounted) {
        Get.to(() => const ChangkeSignResult(
              successful: false,
              message: "处理扫描结果时出错",
            ))?.then((_) {
          if (mounted) _restartScan();
        });
      }
    }
  }

  // 重新开始扫描
  void _restartScan() {
    if (mounted) {
      setState(() {
        isProcessing = false;
      });
      controller?.start();
    }
  }
}

// 扫描框组件（保持原有样式）
class ScannerBox extends StatefulWidget {
  final double width;
  final double height;

  const ScannerBox({Key? key, required this.width, required this.height})
      : super(key: key);

  @override
  State<ScannerBox> createState() => _ScannerBoxState();
}

class _ScannerBoxState extends State<ScannerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: widget.height)
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: ScannerBoxPainter(_animation.value),
          );
        },
      ),
    );
  }
}

class ScannerBoxPainter extends CustomPainter {
  final double position;
  final double borderRadius;
  final List<Color> gradientColors;

  ScannerBoxPainter(this.position,
      {this.borderRadius = 8.0,
      this.gradientColors = const [Colors.blue, Colors.lightBlueAccent]});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: gradientColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(rrect, borderPaint);

    final linePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(
        Offset(0, position), Offset(size.width, position), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// 二维码签到结果页面
enum QrSignState { loading, success, failure }

class QrSignResultPage extends StatefulWidget {
  final String rollcallId;
  final String data;
  final VoidCallback? onBack;

  const QrSignResultPage({
    super.key,
    required this.rollcallId,
    required this.data,
    this.onBack,
  });

  @override
  State<QrSignResultPage> createState() => _QrSignResultPageState();
}

class _QrSignResultPageState extends State<QrSignResultPage> {
  QrSignState currentState = QrSignState.loading;
  String message = "正在签到中...";

  @override
  void initState() {
    super.initState();
    _performSignIn();
  }

  Future<void> _performSignIn() async {
    try {
      final deviceId = Uuid().v4();

      // 真实的API调用
      final response = await TronClassService.signQr(
        ChangkeClient.instance.dio,
        rollcallId: widget.rollcallId,
        data: widget.data,
        deviceId: deviceId,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception("网络请求超时");
        },
      );

      final responseData = response.data;
      final int? id = responseData?["id"];
      final String? status = responseData?["status"];
      final bool isSuccessful =
          response.statusCode == 200 && status == "on_call";

      if (mounted) {
        setState(() {
          currentState =
              isSuccessful ? QrSignState.success : QrSignState.failure;
          message = isSuccessful
              ? getMappingMessage("success")
              : getMappingMessage(responseData?['message'] ?? "failed");
        });
      }
    } catch (e) {
      print("签到错误: $e");
      if (mounted) {
        setState(() {
          currentState = QrSignState.failure;
          message = e.toString().contains("超时")
              ? "网络连接超时，请检查网络"
              : getMappingMessage("retry");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading状态使用渐变背景
    if (currentState == QrSignState.loading) {
      return WillPopScope(
        onWillPop: () async {
          // Loading状态下如果用户返回，调用onBack回调
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Get.back();
          }
          return false; // 阻止默认返回行为
        },
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF01b9bb),
                  Color(0xFF29cbcd),
                ],
              ),
            ),
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
                          onPressed: () {
                            // Loading状态下返回按钮调用onBack
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              Get.back();
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 20),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              '二维码签到',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // 中间内容区域
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Loading图标
                          Container(
                            height: 200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // 标题
                          const Text(
                            '正在签到',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // 消息
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
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
      );
    }

    // 成功失败状态保持原有样式
    return Scaffold(
      appBar: AppBar(
        title: Text("二维码签到"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 64.0, vertical: 32),
                      child: _buildStateWidget(),
                    ),
                    Text(_getStateTitle(),
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 12),
                    Text(message)
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: () {
                  if (currentState == QrSignState.success) {
                    // 成功时直接退出到上一级页面
                    Get.back();
                  } else {
                    // 失败时调用onBack回调（返回扫描页面）
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Get.back();
                    }
                  }
                },
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.all(Color(
                      currentState == QrSignState.success
                          ? 0xff1DB6C2
                          : 0xffff4853)),
                  elevation: WidgetStateProperty.all(0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(currentState == QrSignState.success ? '完成' : '重试',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStateWidget() {
    switch (currentState) {
      case QrSignState.loading:
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        );
      case QrSignState.success:
        return Image.asset(
          "assets/images/qr_sign_ok.png",
          fit: BoxFit.contain,
        );
      case QrSignState.failure:
        return Image.asset(
          "assets/images/qr_sign_failed.png",
          fit: BoxFit.contain,
        );
    }
  }

  String _getStateTitle() {
    switch (currentState) {
      case QrSignState.loading:
        return "正在签到";
      case QrSignState.success:
        return "签到结果";
      case QrSignState.failure:
        return "签到结果";
    }
  }
}
