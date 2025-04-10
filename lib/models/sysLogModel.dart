import 'package:cloud_firestore/cloud_firestore.dart';

class SysLogModel {
  final int log_id; //id of the log
  final String log_user; //id of the user
  final double log_entity;
  final String log_activity;
  final String log_agent;
  final Timestamp log_date;

  SysLogModel(
      {required this.log_id,
      required this.log_user,
      required this.log_entity,
      required this.log_activity,
      required this.log_agent,
      required this.log_date});
}
