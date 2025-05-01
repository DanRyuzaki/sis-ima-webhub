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
  final _eventDateTimeController = TextEditingController();

  DateTime? _selectedDate;

  _AddEventDialogState(
      {required this.onRefresh, required this.eventDataDeployed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Container(
              width: DynamicSizeService.calculateWidthSize(context, 0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Create an Event",
                      style: TextStyle(
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.025),
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(200, 0, 0, 0))),
                  SizedBox(height: 16),
                  _buildTextField(_eventTitleController, 'Title', 0),
                  SizedBox(height: 12),
                  _buildTextField(
                      _eventDescriptionController, 'Description', 1),
                  SizedBox(height: 12),
                  _buildTextField(
                    _eventDateTimeController,
                    'Date',
                    2,
                    readOnly: true,
                    onTap: _selectDate,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel',
                            style: GoogleFonts.montserrat(color: Colors.black)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => eventSubmission(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 36, 66, 117),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('Submit',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? _picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));

    if (_picked != null) {
      setState(() {
        _selectedDate = _picked;
        _eventDateTimeController.text =
            "${_picked.day}/${_picked.month}/${_picked.year}";
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
  }) {
    return Container(
      height: type == 1
          ? DynamicSizeService.calculateHeightSize(context, 0.40)
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
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          labelText: label,
          labelStyle:
              GoogleFonts.montserrat(color: const Color.fromARGB(179, 3, 3, 3)),
          prefixIcon: readOnly ? const Icon(Icons.calendar_today) : null,
          enabledBorder: InputBorder.none,
          focusedBorder: type == 0
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 36, 66, 117),
                  ),
                )
              : InputBorder.none,
        ),
      ),
    );
  }

  Future<void> eventSubmission() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        useToastify.showErrorToast(
            context, "Error", "Please select a date for the event.");
        return;
      }
      CollectionReference eventCollection =
          FirebaseFirestore.instance.collection("events");
      String eventTitle = _eventTitleController.text.trim();
      String eventDescription = _eventDescriptionController.text.trim();
      final highestValueQS = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('event_id', descending: true)
          .limit(1)
          .get();

      int assignEventID = highestValueQS.docs.first.get('event_id') + 1;
      try {
        print('Form submitted');
        print('event_id: $assignEventID');
        print('event_title: $eventTitle');
        print('event_description: $eventDescription');
        print('event_date: $_selectedDate');

        eventCollection.add({
          'event_id': assignEventID,
          'event_title': eventTitle,
          'event_description': eventDescription,
          'event_date': Timestamp.fromDate(_selectedDate!),
        });

        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(
            context, "Successful Added", "The event is now officially added!");
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        print(e);
        useToastify.showErrorToast(context, "Error",
            "Fail to submit the entry. Please contact the developer for investigation.");
      }
    }
  }
}
