import 'dart:convert';
import 'package:get/get.dart';
import 'package:tronclass/data/changke_client.dart';
import 'package:tronclass/data/model/tron_class/rollcalls_response/rollcalls_response.dart';
import 'package:tronclass/data/service/tronclass.dart';

class RollcallController extends GetxController {
  var rollcalls = <Rollcalls>[].obs; // Observable list to hold rollcall data
  var isLoading = true.obs; // Loading state
  var clickCount = 0.obs; // 点击计数
  var showMockData = false.obs; // 是否显示mock数据

  // 处理隐藏按钮点击
  void onHiddenButtonTap() {
    clickCount++;
    if (clickCount.value >= 10) {
      showMockData.value = true;
      clickCount.value = 0; // 重置计数
      // 强制显示mock数据
      final response = jsonDecode(mockData);
      RollcallsResponse rollcallsResponse =
          RollcallsResponse.fromJson(response);
      rollcalls.value = rollcallsResponse.rollcalls;
    }
  }

  // Fetch rollcalls data
  Future<void> fetchRollcalls({bool isPullRefresh = false}) async {
    try {
      if (!isPullRefresh) {
        isLoading(true);
      }

      if (showMockData.value) {
        final response = jsonDecode(mockData);
        RollcallsResponse rollcallsResponse =
            RollcallsResponse.fromJson(response);
        rollcalls.value = rollcallsResponse.rollcalls;
        isLoading(false);
        return;
      }

      final rollcallsResp =
          await TronClassService.getRollcalls(ChangkeClient.instance.dio);
      this.rollcalls.value = rollcallsResp.rollcalls;
    } catch (e) {
      print("Error fetching data: $e");
      rollcalls.value = []; // 异常时也清空数据
    } finally {
      isLoading(false);
    }
  }

  final mockData = """
  {
  "rollcalls": [
    {
      "avatar_big_url": "",
      "class_name": "",
      "course_id": 12375,
      "course_title": "数据结构与算法",
      "created_by": 27581,
      "created_by_name": "Anita Riley",
      "department_name": "计算机学院",
      "grade_name": "",
      "group_set_id": 0,
      "is_expired": false,
      "is_number": true,
      "is_radar": false,
      "published_at": null,
      "rollcall_id": 4329,
      "rollcall_status": "in_progress",
      "rollcall_time": "2025-03-17T13:48:01",
      "scored": true,
      "source": "manual",
      "status": "late",
      "student_rollcall_id": 0,
      "title": "2025-03-13",
      "type": "self_registration_rollcall"
    },
    {
      "avatar_big_url": "",
      "class_name": "",
      "course_id": 12375,
      "course_title": "雷达点名",
      "created_by": 38797,
      "created_by_name": "Jeffrey Hayden",
      "department_name": "Clark-Gomez",
      "grade_name": "",
      "group_set_id": 0,
      "is_expired": false,
      "is_number": false,
      "is_radar": true,
      "published_at": null,
      "rollcall_id": 4329,
      "rollcall_status": "in_progress",
      "rollcall_time": "2025-04-09T16:08:21",
      "scored": true,
      "source": "qr",
      "status": "present",
      "student_rollcall_id": 0,
      "title": "2025-01-11",
      "type": "manual_rollcall"
    },
    {
      "avatar_big_url": "",
      "class_name": "",
      "course_id": 12375,
      "course_title": "二维码点名",
      "created_by": 48535,
      "created_by_name": "Kelly Miller",
      "department_name": "Ayala LLC",
      "grade_name": "",
      "group_set_id": 0,
      "is_expired": false,
      "is_number": false,
      "is_radar": false,
      "published_at": null,
      "rollcall_id": 4329,
      "rollcall_status": "in_progress",
      "rollcall_time": "2025-04-15T11:45:09",
      "scored": true,
      "source": "qr",
      "status": "excused",
      "student_rollcall_id": 0,
      "title": "2025-01-13",
      "type": "manual_rollcall"
    },
    {
      "avatar_big_url": "",
      "class_name": "",
      "course_id": 12375,
      "course_title": "模式识别(双语教学)",
      "created_by": 21234,
      "created_by_name": "张老师",
      "department_name": "人工智能学院",
      "grade_name": "",
      "group_set_id": 0,
      "is_expired": false,
      "is_number": false,
      "is_radar": false,
      "published_at": null,
      "rollcall_id": 4330,
      "rollcall_status": "in_progress",
      "rollcall_time": "2025-01-15T14:30:00",
      "scored": true,
      "source": "qr",
      "status": "on_call_fine",
      "student_rollcall_id": 0,
      "title": "2025-01-15",
      "type": "qr_rollcall"
    },
    {
      "avatar_big_url": "",
      "class_name": "",
      "course_id": 12376,
      "course_title": "机器学习基础",
      "created_by": 21235,
      "created_by_name": "李老师",
      "department_name": "人工智能学院",
      "grade_name": "",
      "group_set_id": 0,
      "is_expired": false,
      "is_number": false,
      "is_radar": false,
      "published_at": null,
      "rollcall_id": 4331,
      "rollcall_status": "in_progress",
      "rollcall_time": "2025-01-16T09:00:00",
      "scored": true,
      "source": "qr",
      "status": "absent",
      "student_rollcall_id": 0,
      "title": "2025-01-16",
      "type": "qr_rollcall"
    }
  ]
}

  """;
}
