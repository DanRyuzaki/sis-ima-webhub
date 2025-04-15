import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/configModel.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class EditConfigDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<ConfigModel> configDataDeployed;
  final ConfigModel config;
  EditConfigDialog(
      {required this.onRefresh,
      required this.configDataDeployed,
      required this.config});

  @override
  _EditConfigDialogState createState() => _EditConfigDialogState(
      onRefresh: onRefresh,
      configDataDeployed: configDataDeployed,
      config: config);
}

class _EditConfigDialogState extends State<EditConfigDialog> {
  final VoidCallback onRefresh;
  final List<ConfigModel> configDataDeployed;
  final ConfigModel config;

  _EditConfigDialogState(
      {required this.onRefresh,
      required this.configDataDeployed,
      required this.config});

  final _formKey = GlobalKey<FormState>();
  final _configController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _configController.text = config.value;
  }

  Future<void> _initializeConfig() async {
    if (_formKey.currentState!.validate()) {
      final configCollection = FirebaseFirestore.instance.collection("config");
      final configQS =
          await configCollection.where("id", isEqualTo: config.id).get();

      String configState = _configController.text.trim();
      try {
        configCollection.doc(configQS.docs.first.id).update({
          'id': config.id,
          'category': config.category,
          'name': config.name,
          'value': configState
        });
        Navigator.of(context).pop();
        onRefresh();
        useToastify.showLoadingToast(context, "Successful Configuration",
            "${config.name}'s value have been updated!");
      } catch (e) {
        Navigator.of(context).pop();
        onRefresh();
        useToastify.showErrorToast(context, "Error",
            "Failed to update the credentials. Please contact the developer.");
        print("Force Update Error: $e");
      }
    } else {}
  }

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
                  Text("Configure ${config.name}",
                      style: TextStyle(
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.025),
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(200, 0, 0, 0))),
                  SizedBox(height: 16),
                  _buildTextField(_configController,
                      '/${config.category.split('=')[1]}/${config.name}'),
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
                        onPressed: () => _initializeConfig(),
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
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Container(
      height: DynamicSizeService.calculateHeightSize(context, 0.40),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 0.4,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SizedBox(
        height: DynamicSizeService.calculateHeightSize(context, 0.40),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.multiline,
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
}
