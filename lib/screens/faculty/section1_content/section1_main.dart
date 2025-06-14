import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/facultyAnalyticsModel.dart';
import 'package:sis_project/models/pubModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/screens/faculty/section1_content/section1_viewpub.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_on_hover/animate_on_hover.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultyFirstSection extends StatefulWidget {
  const FacultyFirstSection({super.key});

  @override
  State<FacultyFirstSection> createState() => _FacultyFirstSectionState();
}

class _FacultyFirstSectionState extends State<FacultyFirstSection> {
  List<PubModel> _pubDataFetch = [];
  List<PubModel> _pubDataDeployed = [];
  late facultyAnalyticsModel _facultyAnalyticsData;
  late Timestamp _timeNow;

  bool _isPubListLoaded = false;
  bool _isHeaderClicked = false;
  String _searchQuery = '';
  double _sortBy = 0;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _timeNow = Timestamp.fromDate(DateTime.now());
    _facultyAnalyticsData = facultyAnalyticsModel(
      totalStudents: 0,
      totalClasses: 0,
    );
    _fetchStudentsAnalytics();
    _fetchPubList();
  }

  String _formatTimestamp(Timestamp timestamp, String format) {
    return DateFormat(format).format(timestamp.toDate());
  }

  Future<void> _fetchStudentsAnalytics() async {
    try {
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final userID = Provider.of<GlobalState>(context, listen: false).userID;

      final entityDoc = await _getEntityDocument(entityCollection, userID);
      if (entityDoc == null) {
        debugPrint('No data found for the given userID.');
        return;
      }

      final Map<String, String> subjectToDepartmentMap =
          await _getSubjectDepartmentMap(entityDoc);

      final analytics = await _computeAnalytics(subjectToDepartmentMap);

      setState(() {
        _facultyAnalyticsData = facultyAnalyticsModel(
          totalStudents: analytics['totalStudents']!,
          totalClasses: analytics['totalClasses']!,
        );
      });

      useToastify.showLoadingToast(
          context, 'Loaded', 'Analytical data fetched successfully.');
    } catch (e) {
      useToastify.showErrorToast(context, 'Error', 'Failed to load analytics.');
      debugPrint('Analytics error: $e');
    }
  }

  Future<Map<String, dynamic>?> _getEntityDocument(
      CollectionReference entityCollection, String userID) async {
    final analyticsQS =
        await entityCollection.where('userID', isEqualTo: userID).get();

    if (analyticsQS.docs.isNotEmpty) {
      return analyticsQS.docs.first.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, String>> _getSubjectDepartmentMap(
      Map<String, dynamic> docData) async {
    final List<dynamic> advisoryClassId = docData['advisoryClassId'] ?? [];
    final List<dynamic> subjectsListDynamic = docData['subjectsList'] ?? [];
    final List<String> subjectsList = List<String>.from(subjectsListDynamic);

    for (String classSubjectCode in advisoryClassId) {
      if (!subjectsList.contains(classSubjectCode)) {
        subjectsList.add(classSubjectCode);
      }
    }

    final Map<String, String> subjectToDepartmentMap = {};
    for (String classSubjectCode in subjectsList) {
      final department = await _fetchClassDepartment(classSubjectCode);
      subjectToDepartmentMap[classSubjectCode] = department;
    }

    return subjectToDepartmentMap;
  }

  Future<Map<String, int>> _computeAnalytics(
      Map<String, String> subjectToDepartmentMap) async {
    Set<String> uniqueStudents = {};
    int totalClasses = subjectToDepartmentMap.length;

    for (final entry in subjectToDepartmentMap.entries) {
      final subjectCode = entry.key;
      final department = entry.value;

      final deptCollection = FirebaseFirestore.instance.collection(department);
      final deptQS = await deptCollection
          .where('class-code', isEqualTo: subjectCode.split(':')[0])
          .get();

      if (deptQS.docs.isNotEmpty) {
        final classList =
            List<String>.from(deptQS.docs.first.data()['class-list'] ?? []);
        uniqueStudents.addAll(classList);
      }
    }

    return {
      'totalStudents': uniqueStudents.length,
      'totalClasses': totalClasses,
    };
  }

  Future<String> _fetchClassDepartment(String classSubjectCode) async {
    final classSubjectsCollection =
        FirebaseFirestore.instance.collection("class-subjects");

    final classSubjectsQS = await classSubjectsCollection
        .where('classSubjectCode', isEqualTo: classSubjectCode)
        .get();

    if (classSubjectsQS.docs.isNotEmpty) {
      final docData = classSubjectsQS.docs.first.data();
      return docData['subjectDepartment'] ?? 'Unknown Department';
    }

    return 'Unknown Department';
  }

  Future<void> _fetchPubList() async {
    try {
      final pubCollection =
          FirebaseFirestore.instance.collection("publication");
      final pubQS = await pubCollection.get();

      _pubDataFetch = pubQS.docs.map((doc) {
        return PubModel(
            pub_id: doc.get("pub_id"),
            pub_title: doc.get("pub_title"),
            pub_content: doc.get("pub_content"),
            pub_date: doc.get("pub_date"),
            pub_views: doc.get("pub_views"));
      }).toList();

      setState(() {
        _pubDataDeployed = _filterAndSortPublications();
        _isPubListLoaded = true;
      });

      useToastify.showLoadingToast(
          context, "Loaded", "Articles fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(context, "Error", "Failed to fetch articles.");
      debugPrint('Fetch publications error: $e');
    }
  }

  Future<void> _incrementPubViews(int pubId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("publication")
          .where("pub_id", isEqualTo: pubId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final currentViews = (doc.data()['pub_views'] ?? 0) as int;

        await doc.reference.update({'pub_views': currentViews + 1});
        debugPrint('Views updated for publication $pubId');
      }
    } catch (e) {
      debugPrint('Error updating views: $e');
    }
  }

  List<PubModel> _filterAndSortPublications() {
    var filtered = _searchQuery.isEmpty
        ? _pubDataFetch
        : _pubDataFetch
            .where((pub) => pub.pub_title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    switch (_sortBy) {
      case 0:
        filtered.sort((a, b) => a.pub_date.compareTo(b.pub_date));
        break;
      case 0.5:
        filtered.sort((a, b) => b.pub_date.compareTo(a.pub_date));
        break;
      case 1:
        filtered.sort((a, b) => a.pub_title.compareTo(b.pub_title));
        break;
      case 1.5:
        filtered.sort((a, b) => b.pub_title.compareTo(a.pub_title));
        break;
      case 2:
        filtered.sort((a, b) => a.pub_content.compareTo(b.pub_content));
        break;
      case 2.5:
        filtered.sort((a, b) => b.pub_content.compareTo(a.pub_content));
        break;
      case 3:
        filtered.sort((a, b) => a.pub_date.compareTo(b.pub_date));
        break;
      case 3.5:
        filtered.sort((a, b) => b.pub_date.compareTo(a.pub_date));
        break;
      case 4:
        filtered.sort((a, b) => a.pub_views.compareTo(b.pub_views));
        break;
      case 4.5:
        filtered.sort((a, b) => b.pub_views.compareTo(a.pub_views));
        break;
      default:
        filtered.sort((a, b) => b.pub_date.compareTo(a.pub_date));
    }
    return filtered.take(10).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _pubDataDeployed = _filterAndSortPublications();
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'TITLE':
          newSortBy = _isHeaderClicked ? 1.5 : 1;
          break;
        case 'DATE':
          newSortBy = _isHeaderClicked ? 0.5 : 0;
          break;
        case 'VIEWS':
          newSortBy = _isHeaderClicked ? 4.5 : 4;
          break;
        default:
          newSortBy = 0;
      }

      _sortBy = newSortBy;
      _isHeaderClicked = !_isHeaderClicked;
      _pubDataDeployed = _filterAndSortPublications();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isPubListLoaded = false;
      _pubDataFetch.clear();
      _pubDataDeployed.clear();
    });
    await _fetchPubList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(
              DynamicSizeService.calculateAspectRatioSize(context, 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildDashboardSection(),
                const SizedBox(height: 40),
                _buildAnnouncementsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final globalState = Provider.of<GlobalState>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Educator Dashboard",
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.032),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatTimestamp(Timestamp.now(), "MMM d, yyyy | h:mm a"),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome back, Faculty ${globalState.userName00} ${globalState.userName01}!',
            style: GoogleFonts.montserrat(
              fontSize:
                  DynamicSizeService.calculateAspectRatioSize(context, 0.016),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teaching Overview',
          style: GoogleFonts.montserrat(
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.024),
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildAnalyticsCard(
              HugeIcons.strokeRoundedChild,
              _facultyAnalyticsData.totalStudents,
              'STUDENTS',
              'As of ${_formatTimestamp(_timeNow, "MMMM d, yyyy | EEEE")}',
              context),
          _buildAnalyticsCard(
              HugeIcons.strokeRoundedBook02,
              _facultyAnalyticsData.totalClasses,
              'CLASSES',
              'As of ${_formatTimestamp(_timeNow, "MMMM d, yyyy | EEEE")}',
              context),
        ]),
      ],
    );
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

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institutional Announcements',
          style: GoogleFonts.montserrat(
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.024),
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildModernSearchBar(),
        const SizedBox(height: 16),
        _buildModernPublicationsTable(),
      ],
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search announcements...",
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search_outlined,
            color: Colors.grey.shade500,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        style: GoogleFonts.montserrat(fontSize: 14),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildModernPublicationsTable() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernTableHeader(),
          const Divider(height: 1),
          _isPubListLoaded
              ? _buildPublicationsList()
              : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell("TITLE")),
          Expanded(flex: 2, child: _buildHeaderCell("DATE")),
          Expanded(flex: 1, child: _buildHeaderCell("VIEWS")),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return InkWell(
      onTap: () => _onHeaderTap(text),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Text(
              text,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isHeaderClicked
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 16,
              color: _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicationsList() {
    if (_pubDataDeployed.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pubDataDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernPublicationRow(_pubDataDeployed[index]);
      },
    );
  }

  Widget _buildModernPublicationRow(PubModel pub) {
    return InkWell(
      onTap: () async {
        await _incrementPubViews(pub.pub_id);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ViewPubDialog(
              onRefresh: _refreshData,
              pubModel: pub,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                pub.pub_title,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM d, yyyy').format(pub.pub_date.toDate()),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${pub.pub_views}',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No announcements found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
