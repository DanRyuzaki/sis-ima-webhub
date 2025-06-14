import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sis_project/constants.dart';
import 'package:sis_project/screens/welcome/desktop_screen/section1_content.dart';
import 'package:sis_project/screens/welcome/desktop_screen/section2_content.dart';
import 'package:sis_project/screens/welcome/desktop_screen/section3_content.dart';
import 'package:sis_project/screens/welcome/widget_buildsocialsection.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:web/web.dart' as web;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

final section1key = GlobalKey();
final section2key = GlobalKey();
final section3key = GlobalKey();

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool isAuthToggled = false;

  Map<String, GlobalKey> searchableContent = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(updateActiveSection);
    _initializeSearchableContent();
  }

  void _initializeSearchableContent() {
    searchableContent = {
      'The Immaculate Mother Academy Inc': section1key,
      'Immaculate Mother Academy': section1key,
      'IMA': section1key,
      'home': section1key,
      'program offerings': section2key,
      'pre-school': section2key,
      'preschool': section2key,
      'primary school': section2key,
      'junior high school': section2key,
      'senior high school': section2key,
      'inquire': section2key,
      'about us': section3key,
      'mission': section3key,
      'vision': section3key,
      'objectives': section3key,
      'advocate': section3key,
      'education': section3key,
      'learning': section3key,
      'students': section3key,
    };
  }

  double getOffset(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return 0.0;
    final box = context.findRenderObject() as RenderBox;
    return box.localToGlobal(Offset.zero).dy;
  }

  void scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  void _performSearch(String searchTerm) {
    if (searchTerm.isEmpty) return;

    String normalizedSearch = searchTerm.toLowerCase().trim();

    GlobalKey? targetKey;

    // ignore: unused_local_variable
    String? matchedTerm;

    for (String key in searchableContent.keys) {
      if (key.toLowerCase() == normalizedSearch) {
        targetKey = searchableContent[key];
        matchedTerm = key;
        break;
      }
    }

    if (targetKey == null) {
      for (String key in searchableContent.keys) {
        if (key.toLowerCase().contains(normalizedSearch) ||
            normalizedSearch.contains(key.toLowerCase())) {
          targetKey = searchableContent[key];
          matchedTerm = key;
          break;
        }
      }
    }

    if (targetKey != null) {
      scrollToSection(targetKey);

      String sectionName = '';
      if (targetKey == section1key) {
        sectionName = 'HOME';
      } else if (targetKey == section2key) {
        sectionName = 'INQUIRE';
      } else if (targetKey == section3key) {
        sectionName = 'ABOUT US';
      }

      if (sectionName.isNotEmpty) {
        Provider.of<GlobalState>(context, listen: false)
            .toggleActiveSection(sectionName);
      }
    } else {}

    _searchController.clear();
  }

  void updateActiveSection() {
    final scrollPosition = _scrollController.offset;

    setState(() {
      final section1Top = getOffset(section1key);
      final section2Top = getOffset(section2key);
      final section3Top = getOffset(section3key);

      if (scrollPosition >= section1Top && scrollPosition < section2Top - 50) {
        Provider.of<GlobalState>(context, listen: false)
            .toggleActiveSection("HOME");
      } else if (scrollPosition >= section2Top &&
          scrollPosition < section3Top - 50) {
        Provider.of<GlobalState>(context, listen: false)
            .toggleActiveSection("INQUIRE");
      } else if (scrollPosition >= section3Top) {
        Provider.of<GlobalState>(context, listen: false)
            .toggleActiveSection("ABOUT US");
      }
    });
  }

  void onToggleAuthWidgetStatus(GlobalKey key) {
    Provider.of<GlobalState>(context, listen: false).toggleIsActive();
    scrollToSection(key);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle appBarTextStyle = TextStyle(
      fontSize: DynamicSizeService.calculateAspectRatioSize(context, 0.015),
      color: Color.fromARGB(255, 36, 66, 117),
      fontWeight: FontWeight.bold,
    );

    TextStyle activeAppBarTextStyle = TextStyle(
      fontSize: DynamicSizeService.calculateAspectRatioSize(context, 0.015),
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    );
    return Scaffold(
        appBar: _buildAppBar(appBarTextStyle, activeAppBarTextStyle),
        body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(children: [
              _buildSection1(context),
              WidgetSectionSocials(),
              _buildSection2(context),
              _buildSection3(context)
            ])));
  }

  AppBar _buildAppBar(
      TextStyle appBarTextStyle, TextStyle activeAppBarTextStyle) {
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
              Row(children: [
                SizedBox(
                    width:
                        DynamicSizeService.calculateWidthSize(context, 0.045)),
                _buildNavLink('HOME', appBarTextStyle, activeAppBarTextStyle,
                    section1key, context),
                SizedBox(
                    width:
                        DynamicSizeService.calculateWidthSize(context, 0.045)),
                _buildNavLink('INQUIRE', appBarTextStyle, activeAppBarTextStyle,
                    section2key, context),
                SizedBox(
                    width:
                        DynamicSizeService.calculateWidthSize(context, 0.045)),
                _buildNavLink('ABOUT US', appBarTextStyle,
                    activeAppBarTextStyle, section3key, context)
              ])
            ])),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0.0,
        toolbarHeight: DynamicSizeService.calculateHeightSize(context, 0.12),
        actions: [
          _buildSearchBar(),
          SizedBox(
              width: DynamicSizeService.calculateWidthSize(context, 0.035)),
          _buildNavLink(
              FirebaseAuth.instance.currentUser == null
                  ? 'SIGN IN'
                  : 'LOGGED IN',
              Provider.of<GlobalState>(context).isVisible
                  ? activeAppBarTextStyle
                  : appBarTextStyle,
              Provider.of<GlobalState>(context).isVisible
                  ? activeAppBarTextStyle
                  : appBarTextStyle,
              section1key,
              context),
          SizedBox(
              width: DynamicSizeService.calculateWidthSize(context, 0.025)),
        ]);
  }

  Widget _buildNavLink(String title, TextStyle textStyle,
      TextStyle activeTextStyle, GlobalKey key, BuildContext context) {
    String activeSection =
        Provider.of<GlobalState>(context, listen: false).activeSection;

    return InkWell(
      onTap: () => title == 'SIGN IN'
          ? onToggleAuthWidgetStatus(key)
          : title == 'LOGGED IN'
              ? web.window.open(
                  './?session=true&page=${Provider.of<GlobalState>(context, listen: false).entityType}',
                  '_self')
              : scrollToSection(key),
      child: Text(title,
          style: activeSection == title ? activeTextStyle : textStyle),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
        padding: EdgeInsets.symmetric(
            vertical: DynamicSizeService.calculateHeightSize(context, 0.005),
            horizontal: DynamicSizeService.calculateWidthSize(context, 0.005)),
        child: Container(
            width: DynamicSizeService.calculateWidthSize(context, 0.25),
            height: DynamicSizeService.calculateHeightSize(context, 0.07),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: WELCOME_NAVBAR[0],
                hintStyle: TextStyle(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                        context, 0.015)),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    vertical:
                        DynamicSizeService.calculateHeightSize(context, 0.010),
                    horizontal:
                        DynamicSizeService.calculateWidthSize(context, 0.015)),
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                print("Search input: $value");
              },
            )));
  }

  Widget _buildSection1(BuildContext context) {
    return Container(
        key: section1key,
        width: DynamicSizeService.calculateWidthSize(context, 1),
        height: DynamicSizeService.calculateHeightSize(context, 1) * 0.55,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
              (Colors.blue[900] ?? Colors.blue),
              (Colors.blue[900] ?? Colors.blue)
            ])),
        child: Stack(children: [
          ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ]).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/JPGs/IMABackgroundPhoto.jpg',
                fit: BoxFit.cover,
                width: DynamicSizeService.calculateWidthSize(context, 1),
                height:
                    DynamicSizeService.calculateHeightSize(context, 1) * 0.55,
              )),
          Section1Content(),
        ]));
  }

  Widget _buildSection2(BuildContext context) {
    return Container(
        key: section2key,
        width: DynamicSizeService.calculateWidthSize(context, 1),
        height: DynamicSizeService.calculateHeightSize(context, 1),
        color: Colors.white,
        child: Section2Content());
  }

  Widget _buildSection3(BuildContext context) {
    return SizedBox(
        key: section3key,
        width: DynamicSizeService.calculateWidthSize(context, 1),
        height: DynamicSizeService.calculateHeightSize(context, 1.0),
        child: Section3Content());
  }
}
