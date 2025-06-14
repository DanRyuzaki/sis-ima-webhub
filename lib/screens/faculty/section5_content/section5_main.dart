import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/eventModel.dart';
import 'package:sis_project/screens/admin/section3_content/section3_addevent.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class FacultyFifthSection extends StatefulWidget {
  final int userType;

  const FacultyFifthSection({
    super.key,
    this.userType = 0,
  });

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

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

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

  bool _isValidRecipient(List<dynamic> recipients) {
    if (widget.userType == 0) return true;

    return recipients.contains(widget.userType);
  }

  List<EventModel> _filterEventsByRecipient(List<EventModel> events) {
    return events.where((event) => _isValidRecipient(event.recipient)).toList();
  }

  Future<void> _fetchEventList() async {
    try {
      final pubCollection = FirebaseFirestore.instance.collection("events");
      final pubQS = await pubCollection.get();

      List<EventModel> allEvents = pubQS.docs.map((doc) {
        return EventModel(
            event_id: doc.get("event_id"),
            event_title: doc.get("event_title"),
            event_description: doc.get("event_description"),
            event_date_start: doc.get("event_date_start"),
            event_date_end: doc.get("event_date_end"),
            event_time: doc.get("event_time"),
            recipient: doc.get("recipient"));
      }).toList();

      EventDataFetch = _filterEventsByRecipient(allEvents);

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
        event.event_date_start.toDate().year,
        event.event_date_start.toDate().month,
        event.event_date_start.toDate().day,
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
      case 0.5:
        filteredEvents.sort((a, b) => b.event_id.compareTo(a.event_id));
      case 1:
        filteredEvents.sort((a, b) => a.event_title.compareTo(b.event_title));
        break;
      case 1.5:
        filteredEvents.sort((a, b) => b.event_title.compareTo(a.event_title));
        break;
      case 2:
        filteredEvents
            .sort((a, b) => a.event_date_start.compareTo(b.event_date_start));
        break;
      case 2.5:
        filteredEvents
            .sort((a, b) => b.event_date_start.compareTo(a.event_date_start));
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedCalendar03,
                      color: _primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Events on ${DateFormat('MMMM d, yyyy').format(today)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...eventsForDay.map((event) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          HugeIcons.strokeRoundedCalendarAdd01,
                          color: _primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        event.event_title,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            event.event_description,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.event_time,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getEventDuration(event),
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                        _highlightEventDate(event.event_date_start.toDate());
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getEventDuration(EventModel event) {
    DateTime startDate = event.event_date_start.toDate();
    DateTime endDate = event.event_date_end.toDate();

    if (isSameDay(startDate, endDate)) {
      return DateFormat('MMM d, yyyy').format(startDate);
    } else {
      return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}';
    }
  }

  void _highlightEventDate(DateTime eventDate) {
    setState(() {
      today = eventDate;
      selectedEvents.value = _getEventsForDay(eventDate);
    });
  }

  String _getUserTypeDisplayName() {
    switch (widget.userType) {
      case 0:
        return 'Admin';
      case 1:
        return 'Registrar';
      case 2:
        return 'Faculty';
      case 3:
        return 'Student';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.userType == 0
          ? FloatingActionButton(
              backgroundColor: Color.fromARGB(255, 36, 66, 117),
              child: HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01, color: Colors.white),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => AddEventDialog(
                        onRefresh: _refreshEventList,
                        EventDataDeployed: EventDataDeployed));
              },
            )
          : null,
      backgroundColor: _lightGray,
      body: RefreshIndicator(
        onRefresh: _refreshEventList,
        color: _primaryColor,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(
              DynamicSizeService.calculateAspectRatioSize(context, 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildCalendarSection(),
                const SizedBox(height: 40),
                _buildEventsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedCalendar03,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Campus Calendar",
                    style: GoogleFonts.montserrat(
                      fontSize: DynamicSizeService.calculateAspectRatioSize(
                          context, 0.032),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatTimestamp(Timestamp.now(), "MMM d, yyyy | h:mm a"),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'View institutional and manage class calendar events',
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.016),
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getUserTypeDisplayName(),
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Calendar',
          style: GoogleFonts.montserrat(
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.024),
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildCalendar(),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      locale: "en_US",
      rowHeight: DynamicSizeService.calculateHeightSize(context, 0.08),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: _primaryColor,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: _primaryColor,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: GoogleFonts.montserrat(
          color: Colors.red.shade400,
        ),
        holidayTextStyle: GoogleFonts.montserrat(
          color: Colors.red.shade400,
        ),
        selectedDecoration: BoxDecoration(
          color: _primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: GoogleFonts.montserrat(),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
        weekendStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          color: Colors.red.shade400,
        ),
      ),
      availableGestures: AvailableGestures.all,
      selectedDayPredicate: (day) => isSameDay(day, today),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) {
          if (day.weekday == DateTime.sunday) {
            final text = DateFormat.E().format(day);
            return Center(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return null;
        },
      ),
      focusedDay: today,
      firstDay: DateTime.utc(1992, 12, 8),
      lastDay: DateTime.utc(
          DateTime.now().year + 1, DateTime.now().month, DateTime.now().day),
      onDaySelected: onDaySelected,
      eventLoader: _getEventsForDay,
    );
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campus Events Overview',
          style: GoogleFonts.montserrat(
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.024),
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 32),
        _buildModernSearchBar(),
        const SizedBox(height: 16),
        _buildModernEventsTable(),
      ],
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search events...",
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search_outlined,
            color: Colors.grey.shade500,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        style: GoogleFonts.montserrat(fontSize: 14),
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

  Widget _buildModernEventsTable() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernTableHeader(),
          const Divider(height: 1),
          isEventListLoaded ? _buildEventsList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 1, child: _buildHeaderCell("ID")),
          Expanded(flex: 3, child: _buildHeaderCell("TITLE")),
          Expanded(flex: 2, child: _buildHeaderCell("DATE")),
          Expanded(flex: 1, child: _buildHeaderCell("TIME")),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return InkWell(
      onTap: () => _onHeaderTap(text),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Text(
              text,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isHeaderClicked
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 16,
              color: _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'ID':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'TITLE':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'DATE':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      EventDataDeployed = _filterEvents(query);
    });
  }

  Widget _buildEventsList() {
    if (EventDataDeployed.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: EventDataDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernEventRow(EventDataDeployed[index]);
      },
    );
  }

  Widget _buildModernEventRow(EventModel event) {
    return InkWell(
      onTap: () {
        selectedEvents.value =
            _getEventsForDay(event.event_date_start.toDate());
        _showEventModal(context, [event]);
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                ' ${event.event_id}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.event_title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.event_description,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _getEventDuration(event),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.event_time,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedCalendar03,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or check back later',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2,
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
    _scrollController.dispose();
    super.dispose();
  }
}
