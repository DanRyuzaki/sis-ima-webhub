import 'package:animate_on_hover/animate_on_hover.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/constants.dart';
import 'package:sis_project/screens/welcome/widget_buildsectionheader.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class Section2Content extends StatelessWidget {
  const Section2Content({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: DynamicSizeService.calculateHeightSize(context, 0.050)),
      WidgetSectionHeader(title: "Program Offerings"),
      Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildProgramCard(
              HugeIcons.strokeRoundedBackpack01,
              WELCOME_PROGRAM_OFFERINGS_TITLE[0],
              WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[0],
              context),
          _buildProgramCard(
              HugeIcons.strokeRoundedStudent,
              WELCOME_PROGRAM_OFFERINGS_TITLE[1],
              WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[1],
              context),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildProgramCard(
              HugeIcons.strokeRoundedSchoolTie,
              WELCOME_PROGRAM_OFFERINGS_TITLE[2],
              WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[2],
              context),
          _buildProgramCard(
              HugeIcons.strokeRoundedStudents,
              WELCOME_PROGRAM_OFFERINGS_TITLE[3],
              WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[3],
              context)
        ])
      ])),
      SizedBox(height: DynamicSizeService.calculateHeightSize(context, 0.10))
    ]);
  }

  Widget _buildProgramCard(
      IconData icon, String program, String description, BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(
            DynamicSizeService.calculateAspectRatioSize(context, 0.020)),
        child: InkWell(
            onTap: () {},
            child: Container(
                height: DynamicSizeService.calculateHeightSize(context, 0.24),
                width: DynamicSizeService.calculateWidthSize(context, 0.40),
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.6),
                        spreadRadius: 4,
                        blurRadius: 13,
                        offset: Offset(0, 3),
                      )
                    ]),
                child: Padding(
                    padding: EdgeInsets.all(
                        DynamicSizeService.calculateAspectRatioSize(
                            context, 0.016)),
                    child: Column(children: [
                      SizedBox(
                          height: DynamicSizeService.calculateHeightSize(
                              context, 0.010)),
                      Row(children: [
                        Icon(icon,
                            size: DynamicSizeService.calculateAspectRatioSize(
                                context, 0.045)),
                        SizedBox(
                            width: DynamicSizeService.calculateWidthSize(
                                context, 0.015)),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(program,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: DynamicSizeService
                                          .calculateAspectRatioSize(
                                              context, 0.018),
                                      color: Color.fromARGB(250, 13, 46, 102))),
                              SizedBox(
                                  height:
                                      DynamicSizeService.calculateHeightSize(
                                          context, 0.003)),
                              SizedBox(
                                  width: DynamicSizeService.calculateWidthSize(
                                      context, 0.030),
                                  child: Divider(
                                      thickness: 2.5,
                                      color: Color.fromARGB(250, 13, 46, 102))),
                              SizedBox(
                                  height:
                                      DynamicSizeService.calculateHeightSize(
                                          context, 0.005)),
                              Text(description,
                                  softWrap: true,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      color: Color.fromARGB(191, 0, 0, 0),
                                      fontSize: DynamicSizeService
                                          .calculateAspectRatioSize(
                                              context, 0.012))),
                              SizedBox(
                                  height:
                                      DynamicSizeService.calculateHeightSize(
                                          context, 0.010))
                            ]))
                      ])
                    ])))).increaseSizeOnHover(1.1));
  }
}
