import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:sis_project/constants.dart';
import 'package:provider/provider.dart';

class MobileWelcomeScreen extends StatefulWidget {
  const MobileWelcomeScreen({Key? key}) : super(key: key);

  @override
  _MobileWelcomeScreenState createState() => _MobileWelcomeScreenState();
}

class _MobileWelcomeScreenState extends State<MobileWelcomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final Color _primaryColor = const Color.fromARGB(255, 36, 66, 117);
  // ignore: unused_field
  final Color _secondaryColor = const Color(0xFF2570ff);
  final Color _lightGray = const Color(0xFFF8F9FA);

  bool _isConfigLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkConfigLoaded();
  }

  void _checkConfigLoaded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalState = Provider.of<GlobalState>(context, listen: false);

      if (globalState.configAddr.value.isNotEmpty ||
          globalState.configCont.value.isNotEmpty) {
        setState(() {
          _isConfigLoaded = true;
        });
      } else {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) _checkConfigLoaded();
        });
      }
    });
  }

  void _showDesktopRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Desktop Required',
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.04,
              ),
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          content: Text(
            'Please switch to a desktop to access the WebHub portal.',
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.03,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConfigLoaded) {
      return Scaffold(
        backgroundColor: _lightGray,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: _primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _lightGray,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildSocialSection(),
            _buildProgramSection(),
            _buildAboutSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Consumer<GlobalState>(
      builder: (context, globalState, child) {
        return Container(
          height: DynamicSizeService.calculateHeightSize(context, 0.9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
            ),
          ),
          child: Stack(
            children: [
              Container(
                height: DynamicSizeService.calculateHeightSize(context, 0.9),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                  child: Image.asset(
                    'assets/JPGs/IMABackgroundPhoto.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset(
                            'assets/SVGs/VectorizedLogo_IMA.svg',
                            height: DynamicSizeService.calculateAspectRatioSize(
                              context,
                              0.1,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showDesktopRequiredDialog,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    DynamicSizeService.calculateWidthSize(
                                  context,
                                  0.04,
                                ),
                                vertical:
                                    DynamicSizeService.calculateHeightSize(
                                  context,
                                  0.012,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'WEBHUB PORTAL',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: DynamicSizeService
                                      .calculateAspectRatioSize(
                                    context,
                                    0.03,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: DynamicSizeService.calculateHeightSize(
                          context,
                          0.1,
                        ),
                      ),
                      Text(
                        "The Immaculate\nMother Academy Inc.",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context,
                            0.06,
                          ),
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.all(
                          DynamicSizeService.calculateAspectRatioSize(
                            context,
                            0.03,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${globalState.configAddr.value}\n${globalState.configCont.value}",
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize:
                                DynamicSizeService.calculateAspectRatioSize(
                              context,
                              0.025,
                            ),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgramSection() {
    return Consumer<GlobalState>(
      builder: (context, globalState, child) {
        return Container(
          padding: EdgeInsets.all(
            DynamicSizeService.calculateAspectRatioSize(context, 0.04),
          ),
          color: _lightGray,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Program Offerings',
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                    context,
                    0.04,
                  ),
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.01),
              ),
              Text(
                'Explore our academic programs',
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                    context,
                    0.025,
                  ),
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.03),
              ),
              _buildProgramCard(
                HugeIcons.strokeRoundedBackpack01,
                WELCOME_PROGRAM_OFFERINGS_TITLE[0],
                globalState.configDept1.value.isNotEmpty
                    ? globalState.configDept1.value
                    : WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[0],
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.02),
              ),
              _buildProgramCard(
                HugeIcons.strokeRoundedStudent,
                WELCOME_PROGRAM_OFFERINGS_TITLE[1],
                globalState.configDept2.value.isNotEmpty
                    ? globalState.configDept2.value
                    : WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[1],
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.02),
              ),
              _buildProgramCard(
                HugeIcons.strokeRoundedSchoolTie,
                WELCOME_PROGRAM_OFFERINGS_TITLE[2],
                globalState.configDept3.value.isNotEmpty
                    ? globalState.configDept3.value
                    : WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[2],
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.02),
              ),
              _buildProgramCard(
                HugeIcons.strokeRoundedStudents,
                WELCOME_PROGRAM_OFFERINGS_TITLE[3],
                globalState.configDept4.value.isNotEmpty
                    ? globalState.configDept4.value
                    : WELCOME_PROGRAM_OFFERINGS_DESCRIPTION[3],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Consumer<GlobalState>(
      builder: (context, globalState, child) {
        return Container(
          padding: EdgeInsets.all(
            DynamicSizeService.calculateAspectRatioSize(context, 0.04),
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Us',
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                    context,
                    0.04,
                  ),
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.01),
              ),
              Text(
                'Our vision, mission, and goals',
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                    context,
                    0.025,
                  ),
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.03),
              ),
              _buildAboutCard(
                WELCOME_INSTITUTION_INFO[0],
                globalState.configVmgo1.value.isNotEmpty
                    ? globalState.configVmgo1.value
                    : WELCOME_INSTITUTION_INFO[3],
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.02),
              ),
              _buildAboutCard(
                WELCOME_INSTITUTION_INFO[1],
                globalState.configVmgo2.value.isNotEmpty
                    ? globalState.configVmgo2.value
                    : WELCOME_INSTITUTION_INFO[4],
              ),
              SizedBox(
                height: DynamicSizeService.calculateHeightSize(context, 0.02),
              ),
              _buildAboutCard(
                WELCOME_INSTITUTION_INFO[2],
                globalState.configVmgo3.value.isNotEmpty
                    ? globalState.configVmgo3.value
                    : WELCOME_INSTITUTION_INFO[5],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: DynamicSizeService.calculateHeightSize(context, 0.08),
        horizontal: DynamicSizeService.calculateWidthSize(context, 0.05),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow Us',
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.04,
              ),
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(
            height: DynamicSizeService.calculateHeightSize(context, 0.03),
          ),
          Text(
            'Connect with us on social media',
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.025,
              ),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(
            height: DynamicSizeService.calculateHeightSize(context, 0.03),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialCard(
                HugeIcons.strokeRoundedFacebook01,
                'Facebook',
                'https://www.facebook.com/imacaloocan',
              ),
              _buildSocialCard(
                HugeIcons.strokeRoundedInstagram,
                'Instagram',
                'https://www.instagram.com/imacaloocan',
              ),
              _buildSocialCard(
                HugeIcons.strokeRoundedTwitter,
                'Twitter/X',
                'https://www.x.com/imacaloocan',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard(IconData icon, String platform, String url) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: DynamicSizeService.calculateWidthSize(context, 0.25),
        padding: EdgeInsets.symmetric(
          vertical: DynamicSizeService.calculateHeightSize(context, 0.02),
        ),
        decoration: BoxDecoration(
          color: _lightGray,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: DynamicSizeService.calculateAspectRatioSize(context, 0.05),
              color: _primaryColor,
            ),
            SizedBox(
              height: DynamicSizeService.calculateHeightSize(context, 0.01),
            ),
            Text(
              platform,
              style: GoogleFonts.montserrat(
                fontSize: DynamicSizeService.calculateAspectRatioSize(
                  context,
                  0.022,
                ),
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        DynamicSizeService.calculateAspectRatioSize(context, 0.03),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(
              DynamicSizeService.calculateAspectRatioSize(context, 0.02),
            ),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              color: _primaryColor,
            ),
          ),
          SizedBox(width: DynamicSizeService.calculateWidthSize(context, 0.03)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context,
                      0.03,
                    ),
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(
                  height: DynamicSizeService.calculateHeightSize(context, 0.01),
                ),
                Container(
                  width: DynamicSizeService.calculateWidthSize(context, 0.1),
                  height: 2,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  height: DynamicSizeService.calculateHeightSize(
                    context,
                    0.015,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context,
                      0.025,
                    ),
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(String title, String description) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        DynamicSizeService.calculateAspectRatioSize(context, 0.03),
      ),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.03,
              ),
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(
            height: DynamicSizeService.calculateHeightSize(context, 0.01),
          ),
          Container(
            width: DynamicSizeService.calculateWidthSize(context, 0.1),
            height: 2,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(
            height: DynamicSizeService.calculateHeightSize(context, 0.015),
          ),
          Text(
            description,
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.025,
              ),
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: _primaryColor,
      padding: EdgeInsets.symmetric(
        vertical: DynamicSizeService.calculateHeightSize(context, 0.03),
        horizontal: DynamicSizeService.calculateWidthSize(context, 0.05),
      ),
      child: Column(
        children: [
          Text(
            "© Copyright 2024. The Immaculate Mother Academy Incorporated.",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.8),
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.022,
              ),
              height: 1.4,
            ),
          ),
          SizedBox(
            height: DynamicSizeService.calculateHeightSize(context, 0.01),
          ),
          Text(
            "All Rights Reserved.",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.8),
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.022,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
