import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final int event_id;
  final String event_title;
  final String event_description;
  final Timestamp event_date;

  EventModel(
      {required this.event_id,
      required this.event_title,
      required this.event_description,
      required this.event_date});

  @override
  String toString() => event_title;
}
