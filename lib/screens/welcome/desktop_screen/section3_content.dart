import 'package:animate_on_hover/animate_on_hover.dart';
import 'package:flutter/material.dart';
import 'package:sis_project/constants.dart';
import 'package:sis_project/screens/welcome/widget_buildsectionheader.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/services/global_state.dart';

class Section3Content extends StatelessWidget {
  const Section3Content({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: Column(children: [
          SizedBox(
              height: DynamicSizeService.calculateHeightSize(context, 0.050)),
          WidgetSectionHeader(title: "About Us"),
          Expanded(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildInstitutionInfo(
                WELCOME_INSTITUTION_INFO[0],
                Provider.of<GlobalState>(context, listen: false)
                    .configVmgo1
                    .value,
                context),
            _buildInstitutionInfo(
                WELCOME_INSTITUTION_INFO[1],
                Provider.of<GlobalState>(context, listen: false)
                    .configVmgo2
                    .value,
                context),
            _buildInstitutionInfo(
                WELCOME_INSTITUTION_INFO[2],
                Provider.of<GlobalState>(context, listen: false)
                    .configVmgo3
                    .value,
                context)
          ])),
          SizedBox(
              height: DynamicSizeService.calculateHeightSize(context, 0.05)),
          SelectableText(
              "© Copyright 2024. The Immaculate Mother Academy Incorporated. All Rights reserved.",
              style: TextStyle(
                  color: Color.fromARGB(191, 0, 0, 0),
                  fontFamily: 'Montserrat',
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.015))),
          SizedBox(
              height: DynamicSizeService.calculateHeightSize(context, 0.03)),
        ]));
  }

  Widget _buildInstitutionInfo(
    String title,
    String description,
    BuildContext context,
  ) {
    return Padding(
        padding: EdgeInsets.fromLTRB(
            DynamicSizeService.calculateWidthSize(context, 0.01),
            DynamicSizeService.calculateHeightSize(context, 0.02),
            DynamicSizeService.calculateWidthSize(context, 0.01),
            DynamicSizeService.calculateHeightSize(context, 0.02)),
        child: Container(
            width: DynamicSizeService.calculateWidthSize(context, 0.30),
            height: DynamicSizeService.calculateHeightSize(context, 0.60),
            child: Card(
                elevation: 9.0,
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                    padding: EdgeInsets.all(
                        DynamicSizeService.calculateAspectRatioSize(
                            context, 0.016)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  DynamicSizeService.calculateAspectRatioSize(
                                      context, 0.018),
                              color: Color.fromARGB(250, 13, 46, 102),
                            ),
                          ),
                          SizedBox(
                              height: DynamicSizeService.calculateHeightSize(
                                  context, 0.01)),
                          SizedBox(
                              width: DynamicSizeService.calculateWidthSize(
                                  context, 0.030),
                              child: Divider(
                                thickness: 2.5,
                                color: Color.fromARGB(250, 13, 46, 102),
                              )),
                          SizedBox(
                              height: DynamicSizeService.calculateHeightSize(
                                  context, 0.03)),
                          Expanded(
                              child: SingleChildScrollView(
                                  child: SelectableText(
                            description,
                            style: TextStyle(
                                overflow: TextOverflow.clip,
                                color: Color.fromARGB(191, 0, 0, 0),
                                fontSize:
                                    DynamicSizeService.calculateAspectRatioSize(
                                        context, 0.018),
                                fontFamily: 'Montserrat'),
                          ))),
                          SizedBox(
                              height: DynamicSizeService.calculateHeightSize(
                                  context, 0.010)),
                        ])))).increaseSizeOnHover(1.1));
  }
}
