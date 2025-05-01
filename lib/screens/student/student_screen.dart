import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/screens/student/section5_content/section5_main.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import 'package:sis_project/services/global_state.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 1.0) -
                    DynamicSizeService.calculateHeightSize(context, 0.11),
                width: DynamicSizeService.calculateWidthSize(context, 1.0),
                child: Row(children: <Widget>[
                  NavigationRail(
                      backgroundColor: Colors.white,
                      leading: Column(
                        children: [
                          SizedBox(
                              width: DynamicSizeService.calculateWidthSize(
                                  context, 0.095)),
                          Divider(
                            height: 20,
                            thickness: 1,
                            indent: 10,
                            endIndent: 10,
                            color: Colors.grey[300],
                          )
                        ],
                      ),
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: const <NavigationRailDestination>[
                        NavigationRailDestination(
                          padding: EdgeInsets.symmetric(horizontal: 35),
                          icon: Icon(HugeIcons.strokeRoundedDashboardSquare02),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedAccountSetting02),
                          label: Text('Profile'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedSchoolReportCard),
                          label: Text('Grades'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedCourse),
                          label: Text('Subjects'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedCalendar03),
                          label: Text('Calendar'),
                        )
                      ]),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: Center(child: _buildContent(_selectedIndex)))
                ]))));
  }

  AppBar _buildAppBar() {
    return AppBar(
        title: Padding(
            padding: EdgeInsets.only(
                left: DynamicSizeService.calculateWidthSize(context, 0.02)),
            child: Row(children: [
              SvgPicture.asset('assets/SVGs/VectorizedLogo_IMA.svg',
                  semanticsLabel: 'Vectorized IMA Logo',
                  height: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.060),
                  width: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.060)),
              SizedBox(
                  width: DynamicSizeService.calculateWidthSize(context, 0.025)),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      textAlign: TextAlign.center,
                      "${Provider.of<GlobalState>(context, listen: false).userName00} ${Provider.of<GlobalState>(context, listen: false).userName01}",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.0168),
                          fontWeight: FontWeight.bold),
                      softWrap: true),
                  Text('Student',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.0125))),
                ],
              )
            ])),
        backgroundColor: Color.fromARGB(255, 36, 66, 117),
        scrolledUnderElevation: 0.0,
        toolbarHeight: DynamicSizeService.calculateHeightSize(context, 0.11),
        actions: [
          SizedBox(
              width: DynamicSizeService.calculateWidthSize(context, 0.045)),
          InkWell(
              onTap: () {
                FirebaseAuth.instance.signOut();
                web.window.open('./?session=false', '_self');
              },
              child: Text("SIGN OUT",
                  style: TextStyle(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                        context, 0.016),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ))),
          const SizedBox(width: 30)
        ]);
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return const Text('Student home content.');
      case 1:
        return const Text('Edit your student profile.');
      case 2:
        return const Text('View your grades status.');
      case 3:
        return const Text('View your enrolled subjects.');

      case 4:
        return StudentFifthSection();
      default:
        return const Text('Error loading content.');
    }
  }
}
