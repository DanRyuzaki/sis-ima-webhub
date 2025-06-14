import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/configModel.dart';
import 'package:sis_project/screens/admin/section5_content/section5_editconfig.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_browser_detect/web_browser_detect.dart';

class AdminFifthSection extends StatefulWidget {
  const AdminFifthSection({super.key});

  @override
  State<AdminFifthSection> createState() => _AdminFifthSectionState();
}

class _AdminFifthSectionState extends State<AdminFifthSection> {
  List<ConfigModel> configDataFetch = [], configDataDeployed = [];
  bool isConfigListLoaded = false, isHeaderClicked = false;
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
    _fetchConfigList();
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate =
        DateFormat("MMMM d, yyyy | EEEE | h:mm a 'UTC' Z").format(dateTime);
    return formattedDate;
  }

  Future<void> _fetchConfigList() async {
    try {
      final configCollection = FirebaseFirestore.instance.collection("config");
      final configQS = await configCollection.get();

      configDataFetch = configQS.docs.map((doc) {
        return ConfigModel(
            id: doc.get('id'),
            category: doc.get('category'),
            name: doc.get('name'),
            value: doc.get('value'));
      }).toList();

      if (mounted) {
        setState(() {
          configDataDeployed = _filterConfig(query);
          isConfigListLoaded = true;
        });
      }

      useToastify.showLoadingToast(
          context, "Loaded", "Configuration settings fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch configuration settings.");
      if (mounted) {
        setState(() {
          isConfigListLoaded = true;
        });
      }
    }
  }

  List<ConfigModel> _filterConfig(String query) {
    final filteredConfigs = query.isEmpty
        ? configDataFetch
        : configDataFetch.where((config) {
            return config.category
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                config.name.toLowerCase().contains(query.toLowerCase()) ||
                config.value.toLowerCase().contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredConfigs.sort((a, b) => a.category.compareTo(b.category));
      case 0.5:
        filteredConfigs.sort((a, b) => b.category.compareTo(a.category));
      case 1:
        filteredConfigs.sort((a, b) => a.name.compareTo(b.name));
      case 1.5:
        filteredConfigs.sort((a, b) => b.name.compareTo(a.name));
      case 2:
        filteredConfigs.sort((a, b) => a.value.compareTo(b.value));
      case 2.5:
        filteredConfigs.sort((a, b) => b.value.compareTo(a.value));
      default:
        filteredConfigs.sort((a, b) => a.category.compareTo(b.category));
    }
    return filteredConfigs.take(50).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      configDataDeployed = _filterConfig(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      floatingActionButton: _buildModernFAB(),
      body: RefreshIndicator(
        onRefresh: _refreshConfigList,
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
                const SizedBox(height: 24),
                _buildModernSearchBar(),
                const SizedBox(height: 16),
                _buildModernConfigTable(),
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
        onPressed: _refreshConfigList,
        icon: const Icon(
          HugeIcons.strokeRoundedRefresh,
          color: Colors.white,
        ),
        label: Text(
          'Refresh Settings',
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
                  HugeIcons.strokeRoundedSettings02,
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
                      "Configuration Settings",
                      style: GoogleFonts.montserrat(
                        fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context, 0.032),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage system configuration parameters and settings.',
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
          hintText: "Search by category, name, or value...",
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

  Widget _buildModernConfigTable() {
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
          isConfigListLoaded ? _buildConfigList() : _buildLoadingIndicator(),
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
            width: 150,
            child: _buildHeaderCell("CATEGORY"),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildHeaderCell("NAME"),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildHeaderCell("VALUE"),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: _buildHeaderCell("ACTIONS"),
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

  Widget _buildConfigList() {
    if (configDataFetch.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: configDataDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernConfigRow(configDataDeployed[index]);
      },
    );
  }

  Widget _buildModernConfigRow(ConfigModel config) {
    Color categoryColor = _getCategoryColor(config.category);

    return InkWell(
      onTap: () => useToastify.showLoadingToast(context, 'Edit?',
          'To edit \'${config.name}\', double-tap this segment.'),
      onDoubleTap: () => showDialog(
          context: context,
          builder: (context) => EditConfigDialog(
              onRefresh: _refreshConfigList,
              configDataDeployed: configDataDeployed,
              config: config)),
      child: Container(
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
            // CATEGORY - Fixed width
            SizedBox(
              width: 150,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getCategoryName(config.category),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // NAME - Flexible
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Configuration Parameter',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // VALUE - Flexible
            Expanded(
              flex: 3,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  config.value,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ACTIONS - Fixed width
            SizedBox(
              width: 100,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedEdit02,
                      size: 14,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
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
            HugeIcons.strokeRoundedSettings02,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No configuration settings found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or refresh the settings.',
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

  Color _getCategoryColor(String category) {
    String categoryName = _getCategoryName(category).toLowerCase();

    if (categoryName.contains('main')) {
      return _successColor;
    } else if (categoryName.contains('department')) {
      return _adminAccent;
    } else if (categoryName.contains('vmgo')) {
      return _warningColor;
    }
    return _primaryColor;
  }

  String _getCategoryName(String category) {
    if (category.contains('=')) {
      return category.trim().split('=')[1];
    }
    return category;
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'CATEGORY':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'NAME':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'VALUE':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      configDataDeployed = _filterConfig(query);
    });
  }

  Future<void> _refreshConfigList() async {
    setState(() {
      isConfigListLoaded = false;
      configDataFetch.clear();
      configDataDeployed.clear();
    });

    await _fetchConfigList();
  }
}
