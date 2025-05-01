import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/eventModel.dart';
import 'package:sis_project/screens/welcome/widget_buildsectionheader.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:table_calendar/table_calendar.dart';

class FacultyFifthSection extends StatefulWidget {
  const FacultyFifthSection({super.key});

  @override
  State<FacultyFifthSection> createState() => _ManageCalendarState();
}

class _ManageCalendarState extends State<FacultyFifthSection> {
  late ScrollController _scrollController;
  List<EventModel> EventDataFetch = [], EventDataDeployed = [];
  bool isEventListLoaded = false, isHeaderClicked = false;
  late Timestamp timeNow;
  late String query = '';
  double sortBy = 0;
  DateTime today = DateTime.now();
  late final LinkedHashMap<DateTime, List<EventModel>> events;
  late final ValueNotifier<List<EventModel>> selectedEvents;
  late Map<DateTime, List<EventModel>> eventSource;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    eventSource = {};
    events = LinkedHashMap(
      equals: isSameDay,
      hashCode: (d) => d.day * 1000000 + d.month * 10000 + d.year,
    )..addAll(eventSource);

    selectedEvents = ValueNotifier([]);
    timeNow = Timestamp.fromDate(DateTime.now());

    _fetchEventList();
  }

  String formatTimestamp(Timestamp timestamp, String format) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat(format).format(dateTime);
  }

  Future<void> _fetchEventList() async {
    try {
      final pubCollection = FirebaseFirestore.instance.collection("events");
      final pubQS = await pubCollection.get();

      EventDataFetch = pubQS.docs.map((doc) {
        return EventModel(
          event_id: doc.get("event_id"),
          event_title: doc.get("event_title"),
          event_description: doc.get("event_description"),
          event_date: doc.get("event_date"),
        );
      }).toList();

      _buildEventSource();

      setState(() {
        EventDataDeployed = _filterEvents(query);
        isEventListLoaded = true;
      });

      useToastify.showLoadingToast(
          context, "Loaded", "Events fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(context, "Error", "Failed to fetch events.");
      print(e);
    }
  }

  void _buildEventSource() {
    eventSource.clear();
    for (var event in EventDataFetch) {
      final eventDay = DateTime.utc(
        event.event_date.toDate().year,
        event.event_date.toDate().month,
        event.event_date.toDate().day,
      );

      if (eventSource[eventDay] == null) {
        eventSource[eventDay] = [event];
      } else {
        eventSource[eventDay]!.add(event);
      }
    }

    events
      ..clear()
      ..addAll(eventSource);
  }

  List<EventModel> _filterEvents(String query) {
    final filteredEvents = query.isEmpty
        ? EventDataFetch
        : EventDataFetch.where((event) =>
                event.event_title.toLowerCase().contains(query.toLowerCase()))
            .toList();

    switch (sortBy) {
      case 0:
        filteredEvents.sort((a, b) => a.event_id.compareTo(b.event_id));
        break;
      case 0.5:
        filteredEvents.sort((a, b) => b.event_id.compareTo(a.event_id));
        break;
      case 1:
        filteredEvents.sort((a, b) => a.event_title.compareTo(b.event_title));
        break;
      case 1.5:
        filteredEvents.sort((a, b) => b.event_title.compareTo(a.event_title));
        break;
      case 2:
        filteredEvents.sort((a, b) => a.event_date.compareTo(b.event_date));
        break;
      case 2.5:
        filteredEvents.sort((a, b) => b.event_date.compareTo(a.event_date));
        break;
      default:
        filteredEvents.sort((a, b) => a.event_id.compareTo(b.event_id));
    }
    return filteredEvents.take(10).toList();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      today = selectedDay;
      selectedEvents.value = _getEventsForDay(selectedDay);
    });

    if (selectedEvents.value.isNotEmpty) {
      _showEventModal(context, selectedEvents.value);
    }
  }

  void _showEventModal(BuildContext context, List<EventModel> eventsForDay) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Events on ${DateFormat('MMMM d, yyyy').format(today)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...eventsForDay.map((event) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    event.event_title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(event.event_description),
                  onTap: () {
                    Navigator.pop(context);
                    _scrollController.animateTo(
                      0,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                    _highlightEventDate(event.event_date.toDate());
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _highlightEventDate(DateTime eventDate) {
    setState(() {
      today = eventDate;
      selectedEvents.value = _getEventsForDay(eventDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshEventList,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DynamicSizeService.calculateWidthSize(context, 0.03),
              vertical: DynamicSizeService.calculateHeightSize(context, 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.03)),
                Text("Campus Calendar",
                    style: TextStyle(
                      fontSize: DynamicSizeService.calculateAspectRatioSize(
                          context, 0.035),
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(200, 0, 0, 0),
                    )),
                Text('View the calendar of events for your institution.',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context, 0.013))),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.03)),
                Container(child: _buildCalendar()),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.1)),
                WidgetSectionHeader(title: 'Campus Events Overview'),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.05)),
                _buildSearchBar(),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.05)),
                _buildTableHeader(),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.02)),
                isEventListLoaded
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: EventDataDeployed.length,
                        itemBuilder: (context, index) {
                          final event = EventDataDeployed[index];
                          return _buildTableRow(event);
                        },
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Fetching users from the database..."),
                        ),
                      ),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.01)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      locale: "en_US",
      rowHeight: DynamicSizeService.calculateHeightSize(context, 0.12),
      headerStyle:
          const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      availableGestures: AvailableGestures.all,
      selectedDayPredicate: (day) => isSameDay(day, today),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) {
          if (day.weekday == DateTime.sunday) {
            final text = DateFormat.E().format(day);
            return Center(
                child: Text(text, style: const TextStyle(color: Colors.red)));
          }
          return null;
        },
      ),
      focusedDay: today,
      firstDay: DateTime.utc(2024, 6, 16),
      lastDay: DateTime.utc(2025, 6, 16),
      onDaySelected: onDaySelected,
      eventLoader: _getEventsForDay,
    );
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDDD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Find events by title, date, or event ID",
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.grey,
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.015),
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: DynamicSizeService.calculateHeightSize(context, 0.02),
            horizontal: DynamicSizeService.calculateWidthSize(context, 0.05),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      EventDataDeployed = _filterEvents(query);
    });
  }

  Widget _buildTableHeader() {
    return Card(
      elevation: 0.5,
      color: const Color.fromARGB(255, 253, 253, 253),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTableHeaderCell("ID"),
            _buildTableHeaderCell("TITLE"),
            _buildTableHeaderCell("DATE"),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          if (!isHeaderClicked) {
            sortBy = text == 'TITLE'
                ? 1
                : text == 'DATE'
                    ? 2
                    : 0;
            isHeaderClicked = true;
          } else {
            sortBy = text == 'TITLE'
                ? 1.5
                : text == 'DATE'
                    ? 2.5
                    : 0.5;
            isHeaderClicked = false;
          }
          EventDataDeployed = _filterEvents(query);
        });
      },
      child: SizedBox(
        width: DynamicSizeService.calculateWidthSize(context, 0.12),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.013),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(EventModel event) {
    return InkWell(
        onTap: () {
          selectedEvents.value = _getEventsForDay(event.event_date.toDate());
          _showEventModal(context, selectedEvents.value);
        },
        onDoubleTap: () {},
        child: Card(
          elevation: 0.5,
          color: const Color.fromARGB(255, 253, 253, 253),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTableRowCell('${event.event_id}'),
                _buildTableRowCell(event.event_title),
                _buildTableRowCell(event.event_date.toDate().toString()),
              ],
            ),
          ),
        ));
  }

  Widget _buildTableRowCell(String text) {
    return SizedBox(
      width: DynamicSizeService.calculateWidthSize(context, 0.12),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: DynamicSizeService.calculateAspectRatioSize(context, 0.013),
        ),
      ),
    );
  }

  Future<void> _refreshEventList() async {
    setState(() {
      isEventListLoaded = false;
      EventDataFetch.clear();
      EventDataDeployed.clear();
    });
    await _fetchEventList();
  }

  @override
  void dispose() {
    selectedEvents.dispose();
    super.dispose();
  }
}
