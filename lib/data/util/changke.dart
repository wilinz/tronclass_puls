import 'dart:convert';

class _UrlAnalysis {
  // 定义特殊字符
  static final String ta = String.fromCharCode(30);
  static final String ea = String.fromCharCode(31);
  static final String na = String.fromCharCode(26);
  static final String ra = String.fromCharCode(16);
  static final String ia = na + "1";
  static final String oa = na + "0";

  // 假设 base_url 是全局变量
  static final String baseUrl = 'https://courses.guet.edu.cn';

  // 辅助函数：将整数转换为 base36 字符串
  static String toBase36(int num) {
    const String chars = "0123456789abcdefghijklmnopqrstuvwxyz";
    if (num < 0) {
      return "-" + toBase36(-num);
    } else if (num < 36) {
      return chars[num];
    } else {
      String result = "";
      while (num > 0) {
        int rem = num % 36;
        num = num ~/ 36;
        result = chars[rem] + result;
      }
      return result;
    }
  }

  // 定义 aa 对象：key 为各字段名，value 为 index 转换成 base36 后的字符串
  static const List<String> _aaKeys = [
    "courseId",
    "activityId",
    "activityType",
    "data",
    "rollcallId",
    "groupSetId",
    "accessCode",
    "action",
    "enableGroupRollcall",
    "createUser",
    "joinCourse",
  ];

  // 2) 用下标生成 aa，并设为只读
  static final Map<String, String> aa = Map.unmodifiable({
    for (final e in _aaKeys.asMap().entries) e.value: toBase36(e.key),
  });

  // 定义 ua 对象：key 为各字段名，value 为 na 加上 (index+2) 转换成 base36 的字符串
  static const List<String> _uaKeys = [
    "classroom-exam",
    "feedback",
    "vote",
  ];

  static final Map<String, String> ua = Map.unmodifiable({
    for (final e in _uaKeys.asMap().entries) e.value: na + toBase36(e.key + 2),
  });

  // ca 为 aa 的键值对反转后的 Map
  static final Map<String, String> ca = {
    for (var entry in aa.entries) entry.value: entry.key
  };

  // sa 为 ua 的键值对反转后的 Map
  static final Map<String, String> sa = {
    for (var entry in ua.entries) entry.value: entry.key
  };

  // 辅助函数：解析查询字符串
  static Map<String, List<String>> parseQueryParams(String query) {
    final uri = Uri.parse('?$query');
    return uri.queryParametersAll;
  }

  // 解析字符串 [t]，将其按照分隔符处理后，返回一个 Map 对象
  static Map<String, dynamic> parseSignQrCode(String t) {
    final Map<String, dynamic> result = {};

    if (t.isNotEmpty) {
      final parts = t.split("!").where((part) => part.isNotEmpty);
      for (var part in parts) {
        final splitted = part.split("~");
        if (splitted.length >= 2) {
          final r = splitted[0];
          final iValue = splitted.sublist(1).join("~");
          final key = ca.containsKey(r) ? ca[r]! : r;
          dynamic value;

          if (iValue.startsWith(na)) {
            if (iValue == ia) {
              value = true;
            } else if (iValue != oa) {
              value = sa.containsKey(iValue) ? sa[iValue] : iValue;
            } else {
              value = false;
            }
          } else if (iValue.startsWith(ra)) {
            final substr = iValue.substring(1);
            final parts_ = substr.split(".");
            List<int> nums = [];
            try {
              nums = parts_.map((p) => int.parse(p, radix: 36)).toList();
            } catch (e) {
              nums = [];
            }
            if (nums.length > 1) {
              value = double.tryParse("${nums[0]}.${nums[1]}") ??
                  "${nums[0]}.${nums[1]}";
            } else if (nums.isNotEmpty) {
              value = nums[0];
            } else {
              value = iValue;
            }
          } else {
            value = iValue.replaceAll(ea, "~").replaceAll(ta, "!");
          }
          result[key] = value;
        }
      }
    }

    return result;
  }

  // 公开函数：解析 URL 并返回处理后的结果
  static String scanUrlAnalysis(String e) {
    print("scanUrlAnalysis url: $e");

    // 如果 URL 包含 "/j?p=" 且不是以 "http" 开头，拼接基础 URL
    if (e.contains("/j?p=") && !e.startsWith("http")) {
      e = baseUrl + e;
    }

    // 如果仍然不是 HTTP 链接，直接返回
    if (!e.startsWith("http")) {
      return e;
    }

    Uri? n;
    try {
      n = Uri.parse(e);
    } catch (err) {
      return e;
    }

    // 处理特定路径
    if (n.path == "/j" || n.path == "/scanner-jumper") {
      Map<String, List<String>> o = parseQueryParams(n.query);
      dynamic r;
      try {
        var a = o["_p"]?.first;
        if (a != null) {
          r = jsonDecode(a);
        }
      } catch (e) {
        // 如果解析失败，继续
      }

      if (r == null) {
        String pValue = o["p"]?.first ?? '';
        r = parseSignQrCode(pValue);
      }

      // 如果 r 是非空字典对象，返回 JSON 字符串
      if (r != null && r is Map<String, dynamic> && r.isNotEmpty) {
        return jsonEncode(r);
      } else {
        return e;
      }
    }

    return e;
  }
}

// 示例：如何使用
dynamic parseChangkeScanUrl(String raw) {
  final result = _UrlAnalysis.scanUrlAnalysis(raw);
  if (result.startsWith("{") && result.endsWith("}")){
    return jsonDecode(result);
  }
  return result;
}