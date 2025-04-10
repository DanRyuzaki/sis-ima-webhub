import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/pubModel.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class ViewPubDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final PubModel pubModel;
  ViewPubDialog({required this.onRefresh, required this.pubModel});

  @override
  _ViewPubDialogState createState() =>
      _ViewPubDialogState(onRefresh: onRefresh, pubModel: pubModel);
}

class _ViewPubDialogState extends State<ViewPubDialog> {
  VoidCallback onRefresh;
  PubModel pubModel;
  _ViewPubDialogState({required this.onRefresh, required this.pubModel});

  bool _delPub = false;
  final _pubIDController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _delPub
        ? AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
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
                        Text("Delete Article",
                            style: TextStyle(
                                fontSize:
                                    DynamicSizeService.calculateAspectRatioSize(
                                        context, 0.025),
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(200, 0, 0, 0))),
                        SizedBox(height: 16),
                        _buildTextField(_pubIDController, 'Re-type the Pub ID'),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.black)),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _handleDelete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 117, 36, 36),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Text('Delete',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            content: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Container(
                  width: DynamicSizeService.calculateWidthSize(context, 0.3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(pubModel.pub_title,
                          style: TextStyle(
                              fontSize:
                                  DynamicSizeService.calculateAspectRatioSize(
                                      context, 0.025),
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(200, 0, 0, 0))),
                      SizedBox(height: 6),
                      SelectableText(formatTimestamp(pubModel.pub_date),
                          style: TextStyle(
                              color: Color.fromARGB(191, 0, 0, 0),
                              fontSize:
                                  DynamicSizeService.calculateAspectRatioSize(
                                      context, 0.012))),
                      SizedBox(height: 12),
                      SelectableText(pubModel.pub_content,
                          style: TextStyle(
                              color: Color.fromARGB(191, 0, 0, 0),
                              fontSize:
                                  DynamicSizeService.calculateAspectRatioSize(
                                      context, 0.012))),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          TextButton(
                              onPressed: () => setState(() {
                                    _delPub = true;
                                  }),
                              child: Text('Delete',
                                  style: GoogleFonts.montserrat(
                                      color: Color.fromARGB(255, 117, 36, 36),
                                      fontWeight: FontWeight.bold))),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Close',
                                style: GoogleFonts.montserrat(
                                    color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: GoogleFonts.montserrat(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Color.fromARGB(179, 3, 3, 3)),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Color.fromARGB(255, 26, 26, 26), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label cannot be empty';
        }
        return null;
      },
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate =
        DateFormat("MMMM d, yyyy | EEEE | h:mm a 'UTC' Z").format(dateTime);

    return formattedDate;
  }

  void _handleDelete() async {
    if (_formKey.currentState!.validate()) {
      final retypedId = _pubIDController.text.trim();
      final originalId = pubModel.pub_id;

      if (retypedId != '$originalId') {
        useToastify.showErrorToast(context, "Delete Failed",
            "Re-typed Pub ID does not match the original Pub ID.");
        return;
      }

      try {
        CollectionReference entityCollection =
            FirebaseFirestore.instance.collection("publication");

        QuerySnapshot querySnapshot =
            await entityCollection.where("pub_id", isEqualTo: originalId).get();

        if (querySnapshot.docs.isNotEmpty) {
          await entityCollection.doc(querySnapshot.docs.first.id).delete();

          Navigator.of(context).pop();
          onRefresh();
          useToastify.showLoadingToast(context, "Deleted Successfully",
              "Article '$originalId' has been removed from the database.");
        } else {
          Navigator.of(context).pop();
          useToastify.showErrorToast(context, "Pub Not Found",
              "No article found with Pub ID: $originalId");
        }
      } catch (e) {
        Navigator.of(context).pop();
        useToastify.showErrorToast(context, "Error",
            "Failed to delete the article. Please contact the developer.");
        print("Delete Error: $e");
      }
    }
  }
}
