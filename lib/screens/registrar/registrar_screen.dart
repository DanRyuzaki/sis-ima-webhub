import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/screens/registrar/section1_content/section1_main.dart';
import 'package:sis_project/screens/registrar/section2_content/section2_main.dart';
import 'package:sis_project/screens/registrar/section3_content/section3_main.dart';
import 'package:sis_project/screens/registrar/section4_content/section4_main.dart';
import 'package:sis_project/screens/registrar/section5_content/section5_main.dart';
import 'package:sis_project/screens/registrar/section6_content/section6_main.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:web/web.dart' as web;
import 'package:provider/provider.dart';
import 'package:sis_project/services/global_state.dart';

class RegistrarScreen extends StatefulWidget {
  const RegistrarScreen({super.key});

  @override
  State<RegistrarScreen> createState() => _RegistrarScreenState();
}

class _RegistrarScreenState extends State<RegistrarScreen> {
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
                          icon: Icon(HugeIcons.strokeRoundedHome01),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedSchool01),
                          label: Text('Classes'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedBook01),
                          label: Text('Subjects'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedTeacher),
                          label: Text('Faculty'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(HugeIcons.strokeRoundedStudent),
                          label: Text('Students'),
                        ),
                        NavigationRailDestination(
                            icon: Icon(HugeIcons.strokeRoundedCalendar01),
                            label: Text('Calendar')),
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
                  Text('Registrar',
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
    final queryParams = Uri.base.queryParameters;
    final sessionUser = int.parse(queryParams['page'].toString());

    switch (index) {
      case 0:
        return RegistrarFirstSection();
      case 1:
        return RegistrarSecondSection();
      case 2:
        return RegistrarThirdSection();
      case 3:
        return RegistrarFourthSection();
      case 4:
        return RegistrarFifthSection();
      case 5:
        return RegistrarSixthSection(userType: sessionUser);
      default:
        return const Text('Error loading content.');
    }
  }
}
