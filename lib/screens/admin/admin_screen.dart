import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/screens/admin/section1_content/section1_main.dart';
import 'package:sis_project/screens/admin/section2_content/section2_main.dart';
import 'package:sis_project/screens/admin/section3_content/section3_main.dart';
import 'package:sis_project/screens/admin/section4_content/section4_main.dart';
import 'package:sis_project/screens/admin/section5_content/section5_main.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import 'package:sis_project/services/global_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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
                          CircleAvatar(
                            radius: DynamicSizeService.calculateAspectRatioSize(
                                context, 0.03),
                            child: Icon(HugeIcons.strokeRoundedUserCircle,
                                size:
                                    DynamicSizeService.calculateAspectRatioSize(
                                        context, 0.04)),
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                              width: DynamicSizeService.calculateWidthSize(
                                  context, 0.095),
                              child: Text(
                                  textAlign: TextAlign.center,
                                  "${Provider.of<GlobalState>(context, listen: false).userName00} ${Provider.of<GlobalState>(context, listen: false).userName01}",
                                  style: TextStyle(
                                      fontSize: DynamicSizeService
                                          .calculateAspectRatioSize(
                                              context, 0.0138),
                                      fontWeight: FontWeight.bold),
                                  softWrap: true)),
                          Text('Admin',
                              style: TextStyle(
                                  fontSize: DynamicSizeService
                                      .calculateAspectRatioSize(
                                          context, 0.0125))),
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
                      destinations: <NavigationRailDestination>[
                        NavigationRailDestination(
                          padding: EdgeInsets.symmetric(
                              horizontal: DynamicSizeService.calculateWidthSize(
                                  context, 0.030)),
                          icon: Icon(HugeIcons.strokeRoundedDashboardSquare02,
                              size: DynamicSizeService.calculateAspectRatioSize(
                                  context, 0.023)),
                          label: Text('Dashboard',
                              style: TextStyle(
                                  fontSize: DynamicSizeService
                                      .calculateAspectRatioSize(
                                          context, 0.0125))),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedStudentCard,
                              size: DynamicSizeService.calculateAspectRatioSize(
                                  context, 0.023)),
                          label: Text('Users',
                              style: TextStyle(
                                  fontSize: DynamicSizeService
                                      .calculateAspectRatioSize(
                                          context, 0.0125))),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedCalendar03,
                              size: DynamicSizeService.calculateAspectRatioSize(
                                  context, 0.023)),
                          label: Text('Calendar',
                              style: TextStyle(
                                  fontSize: DynamicSizeService
                                      .calculateAspectRatioSize(
                                          context, 0.0125))),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedSecurityLock,
                              size: DynamicSizeService.calculateAspectRatioSize(
                                  context, 0.023)),
                          label: Text('Security',
                              style: TextStyle(
                                  fontSize: DynamicSizeService
                                      .calculateAspectRatioSize(
                                          context, 0.0125))),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedNodeEdit,
                              size: DynamicSizeService.calculateAspectRatioSize(
                                  context, 0.023)),
                          label: Text('Configuration',
                              style: TextStyle(
                                  fontSize: DynamicSizeService
                                      .calculateAspectRatioSize(
                                          context, 0.0125))),
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
                      context, 0.060))
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
        return AdminFirstSection();
      case 1:
        return AdminSecondSection();
      case 2:
        return AdminThirdSection();
      case 3:
        return AdminFourthSection();
      case 4:
        return AdminFifthSection();
      default:
        return const Text('Error loading content.');
    }
  }
}
