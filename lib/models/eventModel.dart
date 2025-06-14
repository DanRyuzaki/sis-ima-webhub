import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final int event_id;
  final String event_title;
  final String event_description;
  final Timestamp event_date_start;
  final Timestamp event_date_end;
  final String event_time;
  final List<dynamic> recipient;

  EventModel(
      {required this.event_id,
      required this.event_title,
      required this.event_description,
      required this.event_date_start,
      required this.event_date_end,
      required this.event_time,
      required this.recipient});

  @override
  String toString() => event_title;
}
