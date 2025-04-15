import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/analyticsModel.dart';
import 'package:sis_project/models/pubModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/screens/admin/section1_content/section1_addpub.dart';
import 'package:sis_project/screens/admin/section1_content/section1_viewpub.dart';
import 'package:sis_project/screens/welcome/widget_buildsectionheader.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_on_hover/animate_on_hover.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

class AdminFirstSection extends StatefulWidget {
  const AdminFirstSection({super.key});

  @override
  State<AdminFirstSection> createState() => _AdminFirstSectionState();
}

class _AdminFirstSectionState extends State<AdminFirstSection> {
  List<PubModel> PubDataFetch = [], PubDataDeployed = [];
  bool isPubListLoaded = false, isHeaderClicked = false;
  late AnalyticsModel AnalyticsData;
  late Timestamp timeNow;
  late String query = '';
  late int socialTraffic, sisTraffic;
  double sortBy = 0;

  @override
  void initState() {
    super.initState();
    timeNow = Timestamp.fromDate(DateTime.now());
    AnalyticsData = AnalyticsModel(
      studentsEnrolled: 0,
      educatorsEmployed: 0,
      systemTraffic: 0,
      socialTraffic: 0,
    );
    _loadTrafficLogs();
    _fetchAnalytics();
    _fetchPubList();
  }

  String formatTimestamp(Timestamp timestamp, String format) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate = DateFormat(format).format(dateTime);

    return formattedDate;
  }

  Future<void> _fetchAnalytics() async {
    try {
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final studentsTotalQS =
          await entityCollection.where('entity', isEqualTo: 2).get();
      final educatorsTotalQS =
          await entityCollection.where('entity', isEqualTo: 1).get();
      setState(() {
        AnalyticsData.studentsEnrolled = studentsTotalQS.size;
        AnalyticsData.educatorsEmployed = educatorsTotalQS.size;
      });

      useToastify.showLoadingToast(
          context, 'Loaded', 'Analytical data fetched successfully.');
    } catch (e) {
      useToastify.showErrorToast(context, 'Error', 'Failed to load analytics.');
      print(e);
    }
  }

  Future<void> _loadTrafficLogs() async {
    int social = await _fetchTrafficLog('social');
    int sis = await _fetchTrafficLog('sis');

    setState(() {
      socialTraffic = social;
      sisTraffic = sis;
      AnalyticsData.systemTraffic = sis;
      AnalyticsData.socialTraffic = social;
    });
  }

  Future<int> _fetchTrafficLog(String type) async {
    try {
      String formattedDate = DateFormat('MMMM d, y').format(DateTime.now());
      CollectionReference trafficCollection =
          FirebaseFirestore.instance.collection("trafficlog");

      QuerySnapshot querySnapshot = await trafficCollection
          .where("timestamp", isEqualTo: formattedDate)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var docData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        int sis = docData['sis-traffic'] ?? 0;
        int social = docData['social-traffic'] ?? 0;

        if (type == 'sis') {
          return sis;
        } else if (type == 'social') {
          return social;
        } else {
          return 0;
        }
      } else {
        return 0;
      }
    } catch (e) {
      print('Error fetching traffic log: $e');
      return 0;
    }
  }

  Future<void> _fetchPubList() async {
    try {
      final pubCollection =
          FirebaseFirestore.instance.collection("publication");
      final pubQS = await pubCollection.get();

      PubDataFetch = pubQS.docs.map((doc) {
        return PubModel(
          pub_id: doc.get("pub_id"),
          pub_title: doc.get("pub_title"),
          pub_content: doc.get("pub_content"),
          pub_date: doc.get("pub_date"),
          pub_views: doc.get("pub_views"),
          pub_reacts: doc.get("pub_reacts"),
        );
      }).toList();

      setState(() {
        PubDataDeployed = _filterUsers(query);
        isPubListLoaded = true;
      });

      useToastify.showLoadingToast(
          context, "Loaded", "Articles fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(context, "Error", "Failed to fetch articles.");
      print(e);
    }
  }

  List<PubModel> _filterUsers(String query) {
    final filteredUsers = query.isEmpty
        ? PubDataFetch
        : PubDataFetch.where((user) {
            return user.pub_title.toLowerCase().contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredUsers.sort((a, b) => a.pub_date.compareTo(b.pub_date));
      case 0.5:
        filteredUsers.sort((a, b) => b.pub_date.compareTo(a.pub_date));
      case 1:
        filteredUsers.sort((a, b) => a.pub_title.compareTo(b.pub_title));
      case 1.5:
        filteredUsers.sort((a, b) => b.pub_title.compareTo(a.pub_title));
      case 2:
        filteredUsers.sort((a, b) => a.pub_content.compareTo(b.pub_content));
      case 2.5:
        filteredUsers.sort((a, b) => b.pub_content.compareTo(a.pub_content));
      case 3:
        filteredUsers.sort((a, b) => a.pub_date.compareTo(b.pub_date));
      case 3.5:
        filteredUsers.sort((a, b) => b.pub_date.compareTo(a.pub_date));
      case 4:
        filteredUsers.sort((a, b) => a.pub_views.compareTo(b.pub_views));
      case 4.5:
        filteredUsers.sort((a, b) => b.pub_views.compareTo(a.pub_views));
      default:
        filteredUsers.sort((a, b) => a.pub_date.compareTo(b.pub_date));
    }
    return filteredUsers.take(10).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      PubDataDeployed = _filterUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 36, 66, 117),
        child:
            HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddPubDialog(
              onRefresh: _refreshUserList,
              PubDataDeployed: PubDataDeployed,
            ),
          );
        },
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshUserList,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DynamicSizeService.calculateWidthSize(context, 0.03),
              vertical: DynamicSizeService.calculateHeightSize(context, 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.03)),
                Row(children: [
                  Text("Dashboard",
                      style: TextStyle(
                        fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context, 0.035),
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(200, 0, 0, 0),
                      )),
                  Spacer(),
                  Text(
                      '${formatTimestamp(Timestamp.now(), "MMMM d, yyyy | EEEE | h:mm a")}',
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.013)))
                ]),
                Text(
                    'Welcome back, Admin ${Provider.of<GlobalState>(context, listen: false).userName00} ${Provider.of<GlobalState>(context, listen: false).userName01}!',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context, 0.013))),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.08)),
                WidgetSectionHeader(title: 'System Analytics'),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.05)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _buildAnalyticsCard(
                          HugeIcons.strokeRoundedBackpack01,
                          AnalyticsData.studentsEnrolled,
                          'STUDENTS ENROLLED',
                          'As of ${formatTimestamp(timeNow, "MMMM d, yyyy | EEEE | h:mm a 'UTC' Z")}',
                          context),
                      _buildAnalyticsCard(
                          HugeIcons.strokeRoundedSchoolTie,
                          AnalyticsData.educatorsEmployed,
                          'EDUCATORS EMPLOYED',
                          'As of ${formatTimestamp(timeNow, "MMMM d, yyyy | EEEE | h:mm a 'UTC' Z")}',
                          context),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _buildAnalyticsCard(
                          HugeIcons.strokeRoundedAnalytics03,
                          AnalyticsData.systemTraffic,
                          'SIS TRAFFIC (/day)',
                          'For ${formatTimestamp(timeNow, "MMMM d, yyyy | EEEE | h:mm a 'UTC' Z")}region',
                          context),
                      _buildAnalyticsCard(
                          HugeIcons.strokeRoundedTrafficJam02,
                          AnalyticsData.socialTraffic,
                          'SOCIALS TRAFFIC (/day)',
                          'For ${formatTimestamp(timeNow, "MMMM d, yyyy | EEEE | h:mm a 'UTC' Z")}cregion',
                          context)
                    ])
                  ],
                ),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.1)),
                WidgetSectionHeader(title: 'Institutional Articles'),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.05)),
                _buildSearchBar(),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.01)),
                _buildTableHeader(),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.02)),
                isPubListLoaded
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: PubDataDeployed.length,
                        itemBuilder: (context, index) {
                          final pub = PubDataDeployed[index];
                          return _buildTableRow(pub);
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text("Fetching users from the database..."),
                        ),
                      ),
                SizedBox(
                    height:
                        DynamicSizeService.calculateHeightSize(context, 0.1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDDD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Find articles through  PUB_ID, title, or date.",
          hintStyle: TextStyle(
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.015),
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: DynamicSizeService.calculateHeightSize(context, 0.02),
            horizontal: DynamicSizeService.calculateWidthSize(context, 0.05),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildTableHeader() {
    return Card(
      elevation: 0.5,
      color: Color.fromARGB(255, 253, 253, 253),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTableHeaderCell("PUB_ID"),
            _buildTableHeaderCell("TITLE"),
            _buildTableHeaderCell("DATE"),
            _buildTableHeaderCell("VIEWS"),
            _buildTableHeaderCell("REACTS"),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isHeaderClicked == false)
            switch (text) {
              case 'PUB_ID':
                sortBy = 0;
                isHeaderClicked = true;
                break;
              case 'TITLE':
                sortBy = 1;
                isHeaderClicked = true;
                break;
              case 'DATE':
                sortBy = 2;
                isHeaderClicked = true;
                break;
              case 'VIEWS':
                sortBy = 3;
                isHeaderClicked = true;
                break;
              case 'REACTS':
                sortBy = 4;
                isHeaderClicked = true;
                break;
            }
          else
            switch (text) {
              case 'PUB_ID':
                sortBy = 0.5;
                isHeaderClicked = false;
                break;
              case 'TITLE':
                sortBy = 1.5;
                isHeaderClicked = false;
                break;
              case 'DATE':
                sortBy = 2.5;
                isHeaderClicked = false;
                break;
              case 'VIEWS':
                sortBy = 3.5;
                isHeaderClicked = false;
                break;
              case 'REACTS':
                sortBy = 4.5;
                isHeaderClicked = false;
                break;
            }

          // 👇 ADD THIS
          PubDataDeployed = _filterUsers(query);
        });
      },
      child: SizedBox(
        width: DynamicSizeService.calculateWidthSize(context, 0.09),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.013),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(PubModel pub) {
    return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) =>
                ViewPubDialog(onRefresh: _refreshUserList, pubModel: pub),
          );
        },
        onDoubleTap: () {},
        child: Card(
            elevation: 0.5,
            color: Color.fromARGB(255, 253, 253, 253),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0)),
            child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTableRowCell('${pub.pub_id}', 0),
                      _buildTableRowCell(pub.pub_title, 1),
                      _buildTableRowCell(pub.pub_date.toDate().toString(), 2),
                      _buildTableRowCell('${pub.pub_views}', 3),
                      _buildTableRowCell('${pub.pub_reacts}', 4)
                    ]))));
  }

  Widget _buildTableRowCell(String text, int type) {
    return SizedBox(
        width: DynamicSizeService.calculateWidthSize(context, 0.09),
        child: SelectableText(text,
            style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: DynamicSizeService.calculateAspectRatioSize(
                    context, 0.013))));
  }

  Widget _buildAnalyticsCard(IconData icon, num data, String label,
      String description, BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(
            DynamicSizeService.calculateAspectRatioSize(context, 0.025)),
        child: InkWell(
            onTap: () {},
            child: Container(
                height: DynamicSizeService.calculateHeightSize(context, 0.25),
                width: DynamicSizeService.calculateWidthSize(context, 0.30),
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
                              AnimatedFlipCounter(
                                  value: data,
                                  duration: Duration(milliseconds: 1000),
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: DynamicSizeService
                                          .calculateAspectRatioSize(
                                              context, 0.038),
                                      color: Color.fromARGB(250, 13, 46, 102))),
                              Text(label,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: DynamicSizeService
                                          .calculateAspectRatioSize(
                                              context, 0.012),
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
                    ])))).increaseSizeOnHover(1.2));
  }

  Future<void> _refreshUserList() async {
    setState(() {
      isPubListLoaded = false;
      PubDataFetch.clear();
      PubDataDeployed.clear();
    });

    await _fetchPubList();
  }
}
