import 'package:cloud_firestore/cloud_firestore.dart';

class PubModel {
  final int pub_id;
  final String pub_title;
  final String pub_content;
  final Timestamp pub_date;
  final int pub_views;

  PubModel(
      {required this.pub_id,
      required this.pub_title,
      required this.pub_content,
      required this.pub_date,
      required this.pub_views});
}
