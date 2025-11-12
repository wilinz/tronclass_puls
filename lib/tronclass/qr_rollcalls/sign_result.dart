import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangkeSignResult extends StatelessWidget {
  final bool successful;
  final String message;

  const ChangkeSignResult(
      {super.key, required this.successful, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("扫描结果"),
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
                      child: Image.asset(successful
                          ? "assets/images/qr_sign_ok.png"
                          : "assets/images/qr_sign_failed.png"),
                    ),
                    Text("签到结果",
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
                    offset: Offset(0, 0), // 可根据需要调整阴影偏移
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: () {
                  Get.back();
                },
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.all(
                      Color(successful ? 0xff1DB6C2 : 0xffff4853)),
                  elevation: WidgetStateProperty.all(0), // 关闭按钮自身的阴影
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text("返回", style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
