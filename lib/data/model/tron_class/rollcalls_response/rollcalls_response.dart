import 'package:json_annotation/json_annotation.dart';

part 'rollcalls_response.g.dart';

@JsonSerializable(explicitToJson: true)
class RollcallsResponse {

  RollcallsResponse(
      {required this.rollcalls});

  @JsonKey(name: "rollcalls", defaultValue: [])
  List<Rollcalls> rollcalls;


  factory RollcallsResponse.fromJson(Map<String, dynamic> json) => _$RollcallsResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$RollcallsResponseToJson(this);
  
  factory RollcallsResponse.emptyInstance() => RollcallsResponse(rollcalls: []);
}

@JsonSerializable(explicitToJson: true)
class Rollcalls {

  Rollcalls(
      {required this.avatarBigUrl,
      required this.className,
      required this.courseId,
      required this.courseTitle,
      required this.createdBy,
      required this.createdByName,
      required this.departmentName,
      required this.gradeName,
      required this.groupSetId,
      required this.isExpired,
      required this.isNumber,
      required this.isRadar,
      this.publishedAt,
      required this.rollcallId,
      required this.rollcallStatus,
      required this.rollcallTime,
      required this.scored,
      required this.source,
      required this.status,
      required this.studentRollcallId,
      required this.title,
      required this.type});

  @JsonKey(name: "avatar_big_url", defaultValue: "")
  String avatarBigUrl;

  @JsonKey(name: "class_name", defaultValue: "")
  String className;

  @JsonKey(name: "course_id", defaultValue: 0)
  int courseId;

  @JsonKey(name: "course_title", defaultValue: "")
  String courseTitle;

  @JsonKey(name: "created_by", defaultValue: 0)
  int createdBy;

  @JsonKey(name: "created_by_name", defaultValue: "")
  String createdByName;

  @JsonKey(name: "department_name", defaultValue: "")
  String departmentName;

  @JsonKey(name: "grade_name", defaultValue: "")
  String gradeName;

  @JsonKey(name: "group_set_id", defaultValue: 0)
  int groupSetId;

  @JsonKey(name: "is_expired", defaultValue: false)
  bool isExpired;

  @JsonKey(name: "is_number", defaultValue: false)
  bool isNumber;

  @JsonKey(name: "is_radar", defaultValue: false)
  bool isRadar;

  @JsonKey(name: "published_at")
  dynamic publishedAt;

  @JsonKey(name: "rollcall_id", defaultValue: 0)
  int rollcallId;

  @JsonKey(name: "rollcall_status", defaultValue: "")
  String rollcallStatus;

  @JsonKey(name: "rollcall_time", defaultValue: "")
  String rollcallTime;

  @JsonKey(name: "scored", defaultValue: false)
  bool scored;

  @JsonKey(name: "source", defaultValue: "")
  String source;

  @JsonKey(name: "status", defaultValue: "")
  String status;

  @JsonKey(name: "student_rollcall_id", defaultValue: 0)
  int studentRollcallId;

  @JsonKey(name: "title", defaultValue: "")
  String title;

  @JsonKey(name: "type", defaultValue: "")
  String type;


  factory Rollcalls.fromJson(Map<String, dynamic> json) => _$RollcallsFromJson(json);
  
  Map<String, dynamic> toJson() => _$RollcallsToJson(this);
  
  factory Rollcalls.emptyInstance() => Rollcalls(avatarBigUrl: "", className: "", courseId: 0, courseTitle: "", createdBy: 0, createdByName: "", departmentName: "", gradeName: "", groupSetId: 0, isExpired: false, isNumber: false, isRadar: false, rollcallId: 0, rollcallStatus: "", rollcallTime: "", scored: false, source: "", status: "", studentRollcallId: 0, title: "", type: "");
}


