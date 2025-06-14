import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/models/eventModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class AddEventDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<EventModel> EventDataDeployed;

  AddEventDialog({required this.onRefresh, required this.EventDataDeployed});

  @override
  _AddEventDialogState createState() => _AddEventDialogState(
      onRefresh: onRefresh, eventDataDeployed: EventDataDeployed);
}

class _AddEventDialogState extends State<AddEventDialog> {
  final VoidCallback onRefresh;
  final List<EventModel> eventDataDeployed;
  final _formKey = GlobalKey<FormState>();

  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventDateStartController = TextEditingController();
  final _eventDateEndController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // Time fields
  String? _selectedStartHour;
  String? _selectedEndHour;

  // Recipients management
  Set<int> _selectedRecipients = {0}; // Admin is always included by default

  static const Map<int, String> _recipientTypes = {
    0: 'Admin',
    1: 'Registrar',
    2: 'Faculty',
    3: 'Student',
  };

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  // Generate 24-hour format options
  List<String> get _hourOptions {
    List<String> hours = [];
    for (int i = 0; i < 24; i++) {
      String hour = i.toString().padLeft(2, '0');
      hours.add('$hour:00');
    }
    return hours;
  }

  _AddEventDialogState(
      {required this.onRefresh, required this.eventDataDeployed});

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _eventDateStartController.dispose();
    _eventDateEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: DynamicSizeService.calculateWidthSize(context, 0.5),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                child: _buildContent(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Event',
                  style: GoogleFonts.montserrat(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                        context, 0.020),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add event details and recipients',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            _buildSectionContainer(
              title: 'Event Title',
              icon: Icons.title_outlined,
              child: _buildTextField(
                _eventTitleController,
                'Enter event title',
                0,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Event Description
            _buildSectionContainer(
              title: 'Event Description',
              icon: Icons.description_outlined,
              child: _buildTextField(
                _eventDescriptionController,
                'Enter event description',
                1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event description';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Date Range Section
            _buildSectionContainer(
              title: 'Event Duration',
              icon: Icons.date_range_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _eventDateStartController,
                          'Start Date',
                          2,
                          readOnly: true,
                          onTap: () => _selectDate(true),
                          validator: (value) {
                            if (_selectedStartDate == null) {
                              return 'Please select start date';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          _eventDateEndController,
                          'End Date',
                          2,
                          readOnly: true,
                          onTap: () => _selectDate(false),
                          validator: (value) {
                            if (_selectedEndDate == null) {
                              return 'Please select end date';
                            }
                            if (_selectedStartDate != null &&
                                _selectedEndDate != null &&
                                _selectedEndDate!
                                    .isBefore(_selectedStartDate!)) {
                              return 'End date must be after start date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Time Section
            _buildSectionContainer(
              title: 'Event Time',
              icon: Icons.access_time_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeDropdown(
                          label: 'Start Time',
                          value: _selectedStartHour,
                          onChanged: (value) {
                            setState(() {
                              _selectedStartHour = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select start time';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeDropdown(
                          label: 'End Time',
                          value: _selectedEndHour,
                          onChanged: (value) {
                            setState(() {
                              _selectedEndHour = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select end time';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recipients Section
            _buildSectionContainer(
              title: 'Event Recipients',
              icon: Icons.group_outlined,
              child: _buildRecipientsSelector(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0x66000000),
          width: 0.4,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          labelText: label,
          labelStyle:
              GoogleFonts.montserrat(color: const Color.fromARGB(179, 3, 3, 3)),
          prefixIcon: const Icon(Icons.access_time),
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 36, 66, 117),
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
        ),
        items: _hourOptions.map((String hour) {
          return DropdownMenuItem<String>(
            value: hour,
            child: Text(
              hour,
              style: GoogleFonts.montserrat(color: Colors.black),
            ),
          );
        }).toList(),
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 24,
        dropdownColor: Colors.white,
        style: GoogleFonts.montserrat(color: Colors.black),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRecipientsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select who will receive this event notification:',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _recipientTypes.entries.map((entry) {
            final recipientId = entry.key;
            final recipientName = entry.value;
            final isSelected = _selectedRecipients.contains(recipientId);
            final isAdmin = recipientId == 0;

            return GestureDetector(
              onTap: isAdmin
                  ? null
                  : () {
                      setState(() {
                        if (isSelected) {
                          _selectedRecipients.remove(recipientId);
                        } else {
                          _selectedRecipients.add(recipientId);
                        }
                      });
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _primaryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isSelected ? _primaryColor : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      recipientName,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? _primaryColor : Colors.grey.shade700,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Note: Admin is always included as a recipient',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: eventSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Event',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    // Set constraints based on the other selected date
    if (!isStartDate && _selectedStartDate != null) {
      // For end date, it should be at least the start date
      initialDate = _selectedStartDate!;
      firstDate = _selectedStartDate!;
    } else if (isStartDate && _selectedEndDate != null) {
      // For start date, it should be before the end date
      lastDate = _selectedEndDate!;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          _eventDateStartController.text =
              "${picked.day}/${picked.month}/${picked.year}";

          // If end date is before start date, clear it
          if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
            _selectedEndDate = null;
            _eventDateEndController.clear();
          }
        } else {
          _selectedEndDate = picked;
          _eventDateEndController.text =
              "${picked.day}/${picked.month}/${picked.year}";
        }
      });
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    int type, {
    TextInputType inputType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: type == 1
          ? DynamicSizeService.calculateHeightSize(context, 0.15)
          : null,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0x66000000),
          width: 0.4,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type == 1 ? TextInputType.multiline : inputType,
        maxLines: type == 1 ? null : 1,
        style: GoogleFonts.montserrat(color: Colors.black),
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          labelText: label,
          labelStyle:
              GoogleFonts.montserrat(color: const Color.fromARGB(179, 3, 3, 3)),
          prefixIcon: readOnly ? const Icon(Icons.calendar_today) : null,
          enabledBorder: InputBorder.none,
          focusedBorder: type == 0 || type == 2
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 36, 66, 117),
                  ),
                )
              : InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> eventSubmission() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStartDate == null || _selectedEndDate == null) {
        useToastify.showErrorToast(context, "Error",
            "Please select both start and end dates for the event.");
        return;
      }

      if (_selectedStartHour == null || _selectedEndHour == null) {
        useToastify.showErrorToast(context, "Error",
            "Please select both start and end times for the event.");
        return;
      }

      if (_selectedRecipients.isEmpty) {
        useToastify.showErrorToast(
            context, "Error", "Please select at least one recipient.");
        return;
      }

      CollectionReference eventCollection =
          FirebaseFirestore.instance.collection("events");
      String eventTitle = _eventTitleController.text.trim();
      String eventDescription = _eventDescriptionController.text.trim();
      String eventTime = '$_selectedStartHour - $_selectedEndHour';

      try {
        final highestValueQS = await FirebaseFirestore.instance
            .collection('events')
            .orderBy('event_id', descending: true)
            .limit(1)
            .get();

        int assignEventID = highestValueQS.docs.isEmpty
            ? 1
            : highestValueQS.docs.first.get('event_id') + 1;

        print('Form submitted');
        print('event_id: $assignEventID');
        print('event_title: $eventTitle');
        print('event_description: $eventDescription');
        print('event_date_start: $_selectedStartDate');
        print('event_date_end: $_selectedEndDate');
        print('event_time: $eventTime');
        print('recipients: ${_selectedRecipients.toList()}');

        await eventCollection.add({
          'event_id': assignEventID,
          'event_title': eventTitle,
          'event_description': eventDescription,
          'event_date_start': Timestamp.fromDate(_selectedStartDate!),
          'event_date_end': Timestamp.fromDate(_selectedEndDate!),
          'event_time': eventTime,
          'recipient': _selectedRecipients.toList(),
        });

        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(context, "Successfully Added",
            "The event has been created and assigned to selected recipients!");
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        print(e);
        useToastify.showErrorToast(context, "Error",
            "Failed to submit the entry. Please contact the developer for investigation.");
      }
    }
  }
}
