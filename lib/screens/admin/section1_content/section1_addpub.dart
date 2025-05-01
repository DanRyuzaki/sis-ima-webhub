import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/models/pubModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class AddPubDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<PubModel> PubDataDeployed;

  AddPubDialog({required this.onRefresh, required this.PubDataDeployed});

  @override
  _AddPubDialogState createState() => _AddPubDialogState(
      onRefresh: onRefresh, userDataDeployed: PubDataDeployed);
}

class _AddPubDialogState extends State<AddPubDialog> {
  final VoidCallback onRefresh;
  final List<PubModel> userDataDeployed;
  final _formKey = GlobalKey<FormState>();

  final _pubTitleController = TextEditingController();
  final _pubContentController = TextEditingController();

  _AddPubDialogState({required this.onRefresh, required this.userDataDeployed});

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
                  Text("Create an Article",
                      style: TextStyle(
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.025),
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(200, 0, 0, 0))),
                  SizedBox(height: 16),
                  _buildTextField(_pubTitleController, 'Subject', 0),
                  SizedBox(height: 12),
                  _buildTextField(_pubContentController, 'Content', 1),
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
                        onPressed: () => pubSubmission(),
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

  Widget _buildTextField(
      TextEditingController controller, String label, int type,
      {TextInputType inputType = TextInputType.text}) {
    return Container(
      height: type == 1
          ? DynamicSizeService.calculateHeightSize(context, 0.40)
          : null,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 0.4,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SizedBox(
        height: type == 1
            ? DynamicSizeService.calculateHeightSize(context, 0.40)
            : null,
        child: TextFormField(
          controller: controller,
          keyboardType: type == 1 ? TextInputType.multiline : inputType,
          maxLines: null,
          style: GoogleFonts.montserrat(color: Colors.black),
          decoration: InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
            labelText: label,
            labelStyle:
                GoogleFonts.montserrat(color: Color.fromARGB(179, 3, 3, 3)),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Future<void> pubSubmission() async {
    if (_formKey.currentState!.validate()) {
      CollectionReference pubCollection =
          FirebaseFirestore.instance.collection("publication");
      String pubTitle = _pubTitleController.text.trim();
      String pubContent = _pubContentController.text.trim();
      final highestValueQS = await FirebaseFirestore.instance
          .collection('publication')
          .orderBy('pub_id', descending: true)
          .limit(1)
          .get();
      int pubID = highestValueQS.docs.first.get('pub_id') + 1;
      try {
        print('Form submitted');
        print('Pub ID: $pubID');
        print('Pub Title: $pubTitle');
        print('Pub Content: $pubContent');
        print('Pub Date: April 10, 2025 01:12 UTC +8');

        pubCollection.add({
          'pub_id': pubID,
          'pub_title': pubTitle,
          'pub_content': pubContent,
          'pub_date': Timestamp.fromDate(DateTime.now()),
          'pub_views': 0,
        });

        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(context, "Successful Posted",
            "The article is now officially posted!");
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        useToastify.showErrorToast(context, "Error",
            "Fail to post the entry. Please contact the developer for investigation.");
      }
    }
  }
}
