import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:tronclass/routes.dart';

final FToast fToast = FToast();
bool _isInit = false;

final _customPositionMapping = (child, gravity) {
  switch (gravity) {
    case ToastGravity.BOTTOM:
      return Positioned(bottom: 130, left: 24.0, right: 24.0, child: child);
    default:
      return null;
  }
};

void toast(dynamic message, {Duration? duration, ToastGravity? gravity}) {
  if (!initFToast()) return;

  final toast = ToastWidget(child: Builder(builder: (context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
            child: Text(message.toString(),
                style: TextStyle(color: Colors.black))),
      ],
    );
  }));

  fToast.showToast(
    child: toast,
    gravity: gravity ?? ToastGravity.BOTTOM,
    toastDuration: duration ?? Duration(seconds: 2),
    customPositionMapping: _customPositionMapping,
    ignorePointer: true,
  );
}

bool initFToast() {
  if (!_isInit) {
    final context = AppRoute.navigatorKey.currentContext;
    if (context == null) {
      return false;
    }
    fToast.init(context);
    _isInit = true;
  }
  return true;
}

void toastSuccess0(dynamic message,
    {Duration? duration, ToastGravity? gravity}) {
  toastSuccess(message: message, duration: duration, gravity: gravity);
}

void toastSuccess(
    {dynamic message, Duration? duration, ToastGravity? gravity}) {
  if (!initFToast()) return;

  message ??= "成功";

  final toast = ToastWidget(
      child: Builder(
          builder: (context) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 12.0),
                  Flexible(
                      child: Text(message.toString(),
                          style: TextStyle(color: Colors.black))),
                ],
              )));

  fToast.showToast(
    child: toast,
    gravity: gravity ?? ToastGravity.BOTTOM,
    toastDuration: duration ?? Duration(seconds: 2),
    customPositionMapping: _customPositionMapping,
    ignorePointer: true,
  );
}

void toastFailure0(dynamic message,
    {error, Duration? duration, ToastGravity? gravity}) {
  toastFailure(
      message: message, error: error, duration: duration, gravity: gravity);
}

void toastFailure(
    {dynamic message, error, Duration? duration, ToastGravity? gravity}) {
  if (!initFToast()) return;

  message ??= "失败";

  final toast = ToastWidget(child: Builder(builder: (context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.clear, color: Colors.red),
        SizedBox(width: 12.0),
        Flexible(
            child: Text("${message}${error != null ? ": ${error}" : ""}",
                style: TextStyle(color: Colors.black))),
      ],
    );
  }));

  fToast.showToast(
    child: toast,
    gravity: gravity ?? ToastGravity.BOTTOM,
    toastDuration: duration ?? Duration(seconds: 2),
    customPositionMapping: _customPositionMapping,
    ignorePointer: true,
  );
}

class ToastWidget extends StatelessWidget {
  final Widget child;

  const ToastWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }
}
