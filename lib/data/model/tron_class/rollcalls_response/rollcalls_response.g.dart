// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rollcalls_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RollcallsResponse _$RollcallsResponseFromJson(Map<String, dynamic> json) =>
    RollcallsResponse(
      rollcalls: (json['rollcalls'] as List<dynamic>?)
              ?.map((e) => Rollcalls.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RollcallsResponseToJson(RollcallsResponse instance) =>
    <String, dynamic>{
      'rollcalls': instance.rollcalls.map((e) => e.toJson()).toList(),
    };

Rollcalls _$RollcallsFromJson(Map<String, dynamic> json) => Rollcalls(
      avatarBigUrl: json['avatar_big_url'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      courseId: (json['course_id'] as num?)?.toInt() ?? 0,
      courseTitle: json['course_title'] as String? ?? '',
      createdBy: (json['created_by'] as num?)?.toInt() ?? 0,
      createdByName: json['created_by_name'] as String? ?? '',
      departmentName: json['department_name'] as String? ?? '',
      gradeName: json['grade_name'] as String? ?? '',
      groupSetId: (json['group_set_id'] as num?)?.toInt() ?? 0,
      isExpired: json['is_expired'] as bool? ?? false,
      isNumber: json['is_number'] as bool? ?? false,
      isRadar: json['is_radar'] as bool? ?? false,
      publishedAt: json['published_at'],
      rollcallId: (json['rollcall_id'] as num?)?.toInt() ?? 0,
      rollcallStatus: json['rollcall_status'] as String? ?? '',
      rollcallTime: json['rollcall_time'] as String? ?? '',
      scored: json['scored'] as bool? ?? false,
      source: json['source'] as String? ?? '',
      status: json['status'] as String? ?? '',
      studentRollcallId: (json['student_rollcall_id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );

Map<String, dynamic> _$RollcallsToJson(Rollcalls instance) => <String, dynamic>{
      'avatar_big_url': instance.avatarBigUrl,
      'class_name': instance.className,
      'course_id': instance.courseId,
      'course_title': instance.courseTitle,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'department_name': instance.departmentName,
      'grade_name': instance.gradeName,
      'group_set_id': instance.groupSetId,
      'is_expired': instance.isExpired,
      'is_number': instance.isNumber,
      'is_radar': instance.isRadar,
      'published_at': instance.publishedAt,
      'rollcall_id': instance.rollcallId,
      'rollcall_status': instance.rollcallStatus,
      'rollcall_time': instance.rollcallTime,
      'scored': instance.scored,
      'source': instance.source,
      'status': instance.status,
      'student_rollcall_id': instance.studentRollcallId,
      'title': instance.title,
      'type': instance.type,
    };
