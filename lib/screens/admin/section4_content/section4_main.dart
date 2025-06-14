import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/SysLogModel.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_browser_detect/web_browser_detect.dart';

class AdminFourthSection extends StatefulWidget {
  const AdminFourthSection({super.key});

  @override
  State<AdminFourthSection> createState() => _AdminFourthSectionState();
}

class _AdminFourthSectionState extends State<AdminFourthSection> {
  List<SysLogModel> logDataFetch = [], LogDataDeployed = [];
  bool isLogListLoaded = false, isHeaderClicked = false;
  double sortBy = 0;
  String query = '';

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;
  static const Color _adminAccent = Color.fromARGB(255, 220, 53, 69);
  static const Color _successColor = Color.fromARGB(255, 40, 167, 69);
  static const Color _warningColor = Color.fromARGB(255, 255, 193, 7);
  static const Color _infoColor = Color.fromARGB(255, 13, 202, 240);

  @override
  void initState() {
    super.initState();
    _fetchLogList();
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate =
        DateFormat("MMMM d, yyyy | EEEE | h:mm a 'UTC' Z").format(dateTime);
    return formattedDate;
  }

  String formatDateShort(DateTime date) {
    return DateFormat("MMM d, yyyy\nh:mm a").format(date);
  }

  Future<void> _fetchLogList() async {
    try {
      final logCollection =
          FirebaseFirestore.instance.collection("sysactivity");
      final syslogQS = await logCollection.get();

      logDataFetch = syslogQS.docs.map((doc) {
        return SysLogModel(
          log_id: doc.get("log_id"),
          log_user: doc.get("log_user"),
          log_entity: doc.get("log_entity"),
          log_activity: doc.get("log_activity"),
          log_agent: doc.get("log_agent"),
          log_date: doc.get("log_date"),
        );
      }).toList();

      if (mounted) {
        setState(() {
          LogDataDeployed = _filterLog(query);
          isLogListLoaded = true;
        });
      }

      useToastify.showLoadingToast(
          context, "Loaded", "System logs fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch system logs.");
      if (mounted) {
        setState(() {
          isLogListLoaded = true;
        });
      }
    }
  }

  List<SysLogModel> _filterLog(String query) {
    final filteredLogs = query.isEmpty
        ? logDataFetch
        : logDataFetch.where((log) {
            return log.log_user.toLowerCase().contains(query.toLowerCase()) ||
                log.log_activity.toLowerCase().contains(query.toLowerCase()) ||
                log.log_agent.toLowerCase().contains(query.toLowerCase()) ||
                _getEntityName(log.log_entity)
                    .toLowerCase()
                    .contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredLogs.sort((a, b) => a.log_id.compareTo(b.log_id));
      case 0.5:
        filteredLogs.sort((a, b) => b.log_id.compareTo(a.log_id));
      case 1:
        filteredLogs.sort((a, b) => a.log_user.compareTo(b.log_user));
      case 1.5:
        filteredLogs.sort((a, b) => b.log_user.compareTo(a.log_user));
      case 2:
        filteredLogs.sort((a, b) => a.log_entity.compareTo(b.log_entity));
      case 2.5:
        filteredLogs.sort((a, b) => b.log_entity.compareTo(a.log_entity));
      case 3:
        filteredLogs.sort((a, b) => a.log_activity.compareTo(b.log_activity));
      case 3.5:
        filteredLogs.sort((a, b) => b.log_activity.compareTo(a.log_activity));
      case 4:
        filteredLogs.sort((a, b) => a.log_date.compareTo(b.log_date));
      case 4.5:
        filteredLogs.sort((a, b) => b.log_date.compareTo(a.log_date));
      default:
        filteredLogs.sort((a, b) => b.log_date.compareTo(a.log_date));
    }
    return filteredLogs.take(50).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      LogDataDeployed = _filterLog(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      floatingActionButton: _buildModernFAB(),
      body: RefreshIndicator(
        onRefresh: _refreshLogList,
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
                _buildModernHeader(),
                const SizedBox(height: 32),
                _buildLogStatsCards(),
                const SizedBox(height: 24),
                _buildModernSearchBar(),
                const SizedBox(height: 16),
                _buildModernLogTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 36, 66, 117),
            Color.fromARGB(255, 43, 75, 131).withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _infoColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _refreshLogList,
        icon: const Icon(
          HugeIcons.strokeRoundedRefresh,
          color: Colors.white,
        ),
        label: Text(
          'Refresh Logs',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedAnalytics02,
                  color: Colors.white,
                  size: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.035),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "System Monitor",
                      style: GoogleFonts.montserrat(
                        fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context, 0.032),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor system activities and user interactions.',
                      style: GoogleFonts.montserrat(
                        fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context, 0.016),
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${formatTimestamp(Timestamp.now())} | ${Browser().browser} ${Browser().version}',
              style: GoogleFonts.montserrat(
                fontSize:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.013),
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogStatsCards() {
    Map<String, int> activityCounts = {};
    Map<String, int> entityCounts = {};

    for (var log in logDataFetch) {
      String entityName = _getEntityName(log.log_entity);
      entityCounts[entityName] = (entityCounts[entityName] ?? 0) + 1;

      // Categorize activities
      String activity = log.log_activity.toLowerCase();
      if (activity.contains('login') || activity.contains('signin')) {
        activityCounts['Logins'] = (activityCounts['Logins'] ?? 0) + 1;
      } else if (activity.contains('create') || activity.contains('add')) {
        activityCounts['Creates'] = (activityCounts['Creates'] ?? 0) + 1;
      } else if (activity.contains('update') || activity.contains('edit')) {
        activityCounts['Updates'] = (activityCounts['Updates'] ?? 0) + 1;
      } else {
        activityCounts['Others'] = (activityCounts['Others'] ?? 0) + 1;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            'Total Logs',
            logDataFetch.length.toString(),
            HugeIcons.strokeRoundedTask01,
            _primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            'User Logins',
            (activityCounts['Logins'] ?? 0).toString(),
            HugeIcons.strokeRoundedLogin01,
            _successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            'System Updates',
            (activityCounts['Updates'] ?? 0).toString(),
            HugeIcons.strokeRoundedSettings02,
            _warningColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            'Admin Actions',
            (entityCounts['Admin'] ?? 0).toString(),
            HugeIcons.strokeRoundedUserShield01,
            _adminAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                count,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
          hintText: "Search by user, activity, entity, or user agent...",
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

  Widget _buildModernLogTable() {
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
          isLogListLoaded ? _buildLogList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: _buildHeaderCell("LOG ID"),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: _buildHeaderCell("USER ID"),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: _buildHeaderCell("ENTITY"),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildHeaderCell("ACTIVITY"),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildHeaderCell("USER AGENT"),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: _buildHeaderCell("TIMESTAMP"),
          ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: _primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isHeaderClicked
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 14,
              color: _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList() {
    if (logDataFetch.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: LogDataDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernLogRow(LogDataDeployed[index]);
      },
    );
  }

  Widget _buildModernLogRow(SysLogModel log) {
    Color entityColor = _getEntityColor(log.log_entity);
    Color activityColor = _getActivityColor(log.log_activity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // LOG ID - Fixed width
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${log.log_id}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // USER ID - Fixed width
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  log.log_user,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'User ID',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ENTITY - Fixed width
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: entityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getEntityName(log.log_entity),
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: entityColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ACTIVITY - Flexible
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: activityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: activityColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                log.log_activity,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: activityColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // USER AGENT - Flexible
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  log.log_agent,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Browser Info',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // TIMESTAMP - Fixed width
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDateShort(log.log_date.toDate()),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedTask01,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No logs found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or refresh the logs.',
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

  Color _getEntityColor(double entityType) {
    switch (entityType) {
      case 0:
        return _adminAccent;
      case 1:
        return _successColor;
      case 2:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color _getActivityColor(String activity) {
    String activityLower = activity.toLowerCase();
    if (activityLower.contains('login') || activityLower.contains('signin')) {
      return _successColor;
    } else if (activityLower.contains('create') ||
        activityLower.contains('add')) {
      return _infoColor;
    } else if (activityLower.contains('update') ||
        activityLower.contains('edit')) {
      return _warningColor;
    } else if (activityLower.contains('delete') ||
        activityLower.contains('remove')) {
      return _adminAccent;
    }
    return _primaryColor;
  }

  String _getEntityName(double entityType) {
    switch (entityType) {
      case 0:
        return "Admin";
      case 1:
        return "Registrar";
      case 2:
        return "Faculty";
      default:
        return "Student";
    }
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'LOG ID':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'USER ID':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'ENTITY':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        case 'ACTIVITY':
          newSortBy = isHeaderClicked ? 3.5 : 3;
          break;
        case 'TIMESTAMP':
          newSortBy = isHeaderClicked ? 4.5 : 4;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      LogDataDeployed = _filterLog(query);
    });
  }

  Future<void> _refreshLogList() async {
    setState(() {
      isLogListLoaded = false;
      logDataFetch.clear();
      LogDataDeployed.clear();
    });

    await _fetchLogList();
  }
}
