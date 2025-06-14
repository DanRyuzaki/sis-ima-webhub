import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/adminAnalyticsModel.dart';
import 'package:sis_project/models/pubModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/screens/admin/section1_content/section1_addpub.dart';
import 'package:sis_project/screens/admin/section1_content/section1_viewpub.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_on_hover/animate_on_hover.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminFirstSection extends StatefulWidget {
  const AdminFirstSection({super.key});

  @override
  State<AdminFirstSection> createState() => _AdminFirstSectionState();
}

class _AdminFirstSectionState extends State<AdminFirstSection> {
  List<PubModel> _pubDataFetch = [];
  List<PubModel> _pubDataDeployed = [];
  late AnalyticsModel _analyticsData;
  late Timestamp _timeNow;
  late int _socialTraffic, _sisTraffic;

  bool _isPubListLoaded = false;
  bool _isHeaderClicked = false;
  String _query = '';
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
    _analyticsData = AnalyticsModel(
      studentsEnrolled: 0,
      employeesRegistered: 0,
      systemTraffic: 0,
      socialTraffic: 0,
    );
    _loadTrafficLogs();
    _fetchAnalytics();
    _fetchPubList();
  }

  String _formatTimestamp(Timestamp timestamp, String format) {
    return DateFormat(format).format(timestamp.toDate());
  }

  Future<void> _fetchAnalytics() async {
    try {
      final entityCollection = FirebaseFirestore.instance.collection("entity");
      final results = await Future.wait([
        entityCollection.where('entity', isEqualTo: 3).get(),
        entityCollection.where('entity', isEqualTo: 2).get(),
        entityCollection.where('entity', isEqualTo: 1).get(),
      ]);

      setState(() {
        _analyticsData.studentsEnrolled = results[0].size;
        _analyticsData.employeesRegistered = results[1].size + results[2].size;
      });

      useToastify.showLoadingToast(
        context,
        'Loaded',
        'Analytical data fetched successfully.',
      );
    } catch (e) {
      useToastify.showErrorToast(context, 'Error', 'Failed to load analytics.');
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> _loadTrafficLogs() async {
    try {
      final results = await Future.wait([
        _fetchTrafficLog('social'),
        _fetchTrafficLog('sis'),
      ]);

      setState(() {
        _socialTraffic = results[0];
        _sisTraffic = results[1];
        _analyticsData.systemTraffic = _sisTraffic;
        _analyticsData.socialTraffic = _socialTraffic;
      });
    } catch (e) {
      debugPrint('Traffic logs error: $e');
    }
  }

  Future<int> _fetchTrafficLog(String type) async {
    try {
      String formattedDate = DateFormat('MMMM d, y').format(DateTime.now());
      CollectionReference trafficCollection = FirebaseFirestore.instance
          .collection("trafficlog");

      QuerySnapshot querySnapshot =
          await trafficCollection
              .where("timestamp", isEqualTo: formattedDate)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        var docData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        int sis = docData['sis-traffic'] ?? 0;
        int social = docData['social-traffic'] ?? 0;

        return type == 'sis' ? sis : (type == 'social' ? social : 0);
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching traffic log: $e');
      return 0;
    }
  }

  Future<void> _fetchPubList() async {
    try {
      final pubCollection = FirebaseFirestore.instance.collection(
        "publication",
      );
      final pubQS = await pubCollection.get();

      _pubDataFetch =
          pubQS.docs.map((doc) {
            return PubModel(
              pub_id: doc.get("pub_id"),
              pub_title: doc.get("pub_title"),
              pub_content: doc.get("pub_content"),
              pub_date: doc.get("pub_date"),
              pub_views: doc.get("pub_views"),
            );
          }).toList();

      setState(() {
        _pubDataDeployed = _filterAndSortPublications();
        _isPubListLoaded = true;
      });

      useToastify.showLoadingToast(
        context,
        "Loaded",
        "Articles fetched successfully.",
      );
    } catch (e) {
      useToastify.showErrorToast(context, "Error", "Failed to fetch articles.");
      debugPrint('Fetch publications error: $e');
    }
  }

  Future<void> _incrementPubViews(int pubId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
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
    final filteredUsers =
        _query.isEmpty
            ? _pubDataFetch
            : _pubDataFetch.where((user) {
              return user.pub_title.toLowerCase().contains(
                _query.toLowerCase(),
              );
            }).toList();

    switch (_sortBy) {
      case 0:
        filteredUsers.sort((a, b) => a.pub_date.compareTo(b.pub_date));
        break;
      case 0.5:
        filteredUsers.sort((a, b) => b.pub_date.compareTo(a.pub_date));
        break;
      case 1:
        filteredUsers.sort((a, b) => a.pub_title.compareTo(b.pub_title));
        break;
      case 1.5:
        filteredUsers.sort((a, b) => b.pub_title.compareTo(a.pub_title));
        break;
      case 2:
        filteredUsers.sort((a, b) => a.pub_content.compareTo(b.pub_content));
        break;
      case 2.5:
        filteredUsers.sort((a, b) => b.pub_content.compareTo(a.pub_content));
        break;
      case 3:
        filteredUsers.sort((a, b) => a.pub_date.compareTo(b.pub_date));
        break;
      case 3.5:
        filteredUsers.sort((a, b) => b.pub_date.compareTo(a.pub_date));
        break;
      case 4:
        filteredUsers.sort((a, b) => a.pub_views.compareTo(b.pub_views));
        break;
      case 4.5:
        filteredUsers.sort((a, b) => b.pub_views.compareTo(a.pub_views));
        break;
      default:
        filteredUsers.sort((a, b) => b.pub_date.compareTo(a.pub_date));
    }
    return filteredUsers.take(10).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _query = query;
      _pubDataDeployed = _filterAndSortPublications();
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'PUB_ID':
          newSortBy = _isHeaderClicked ? 0.5 : 0;
          break;
        case 'TITLE':
          newSortBy = _isHeaderClicked ? 1.5 : 1;
          break;
        case 'DATE':
          newSortBy = _isHeaderClicked ? 3.5 : 3;
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

  Future<void> _refreshUserList() async {
    setState(() {
      _isPubListLoaded = false;
      _pubDataFetch.clear();
      _pubDataDeployed.clear();
    });

    await Future.wait([_fetchAnalytics(), _loadTrafficLogs(), _fetchPubList()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 36, 66, 117),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Colors.white,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (context) => AddPubDialog(
                  onRefresh: _refreshUserList,
                  PubDataDeployed: _pubDataDeployed,
                ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUserList,
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
                "Admin Dashboard",
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                    context,
                    0.032,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
            'Welcome back, Admin ${globalState.userName00} ${globalState.userName01}!',
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                context,
                0.016,
              ),
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
          'System Summary',
          style: GoogleFonts.montserrat(
            fontSize: DynamicSizeService.calculateAspectRatioSize(
              context,
              0.024,
            ),
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnalyticsCard(
              HugeIcons.strokeRoundedBackpack01,
              _analyticsData.studentsEnrolled,
              'ENROLLED STUDENTS',
              'As of ${_formatTimestamp(_timeNow, "MMMM d, yyyy | EEEE")}',
              context,
            ),
            _buildAnalyticsCard(
              HugeIcons.strokeRoundedSchoolTie,
              _analyticsData.employeesRegistered,
              'REGISTERED EMPLOYEES',
              'As of ${_formatTimestamp(_timeNow, "MMMM d, yyyy | EEEE")}',
              context,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnalyticsCard(
              HugeIcons.strokeRoundedAnalytics03,
              _analyticsData.systemTraffic,
              'SIS TRAFFIC (/day)',
              'For ${_formatTimestamp(_timeNow, "MMMM d, yyyy | EEEE")}',
              context,
            ),
            _buildAnalyticsCard(
              HugeIcons.strokeRoundedTrafficJam02,
              _analyticsData.socialTraffic,
              'SOCIALS TRAFFIC (/day)',
              'For ${_formatTimestamp(_timeNow, "MMMM d, yyyy | EEEE")}',
              context,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    IconData icon,
    num data,
    String label,
    String description,
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.all(
        DynamicSizeService.calculateAspectRatioSize(context, 0.025),
      ),
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
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              DynamicSizeService.calculateAspectRatioSize(context, 0.016),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: DynamicSizeService.calculateHeightSize(
                    context,
                    0.010,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: DynamicSizeService.calculateAspectRatioSize(
                        context,
                        0.045,
                      ),
                    ),
                    SizedBox(
                      width: DynamicSizeService.calculateWidthSize(
                        context,
                        0.015,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedFlipCounter(
                            value: data,
                            duration: const Duration(milliseconds: 1000),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  DynamicSizeService.calculateAspectRatioSize(
                                    context,
                                    0.038,
                                  ),
                              color: const Color.fromARGB(250, 13, 46, 102),
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  DynamicSizeService.calculateAspectRatioSize(
                                    context,
                                    0.012,
                                  ),
                              color: const Color.fromARGB(250, 13, 46, 102),
                            ),
                          ),
                          SizedBox(
                            height: DynamicSizeService.calculateHeightSize(
                              context,
                              0.003,
                            ),
                          ),
                          SizedBox(
                            width: DynamicSizeService.calculateWidthSize(
                              context,
                              0.030,
                            ),
                            child: const Divider(
                              thickness: 2.5,
                              color: Color.fromARGB(250, 13, 46, 102),
                            ),
                          ),
                          SizedBox(
                            height: DynamicSizeService.calculateHeightSize(
                              context,
                              0.005,
                            ),
                          ),
                          Text(
                            description,
                            softWrap: true,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              color: const Color.fromARGB(191, 0, 0, 0),
                              fontSize:
                                  DynamicSizeService.calculateAspectRatioSize(
                                    context,
                                    0.012,
                                  ),
                            ),
                          ),
                          SizedBox(
                            height: DynamicSizeService.calculateHeightSize(
                              context,
                              0.010,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).increaseSizeOnHover(1.02),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Institutional Announcements',
          style: GoogleFonts.montserrat(
            fontSize: DynamicSizeService.calculateAspectRatioSize(
              context,
              0.024,
            ),
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
          hintText: "Search articles...",
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
          Expanded(flex: 1, child: _buildHeaderCell("PUB_ID")),
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
            builder:
                (context) =>
                    ViewPubDialog(onRefresh: _refreshUserList, pubModel: pub),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                '${pub.pub_id}',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
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
          Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No articles found',
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
        child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 2),
      ),
    );
  }
}
