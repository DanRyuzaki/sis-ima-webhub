import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/screens/admin/section2_content/section2_adduser.dart';
import 'package:sis_project/screens/admin/section2_content/section2_edituser.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSecondSection extends StatefulWidget {
  const AdminSecondSection({super.key});

  @override
  State<AdminSecondSection> createState() => _AdminSecondSectionState();
}

class _AdminSecondSectionState extends State<AdminSecondSection> {
  List<AuthenticationModel> userDataFetch = [], userDataDeployed = [];
  bool isUserListLoaded = false, isHeaderClicked = false;
  String query = '';
  double sortBy = 0;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;
  static const Color _adminAccent = Color.fromARGB(255, 220, 53, 69);
  static const Color _successColor = Color.fromARGB(255, 40, 167, 69);

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  Future<void> _fetchUserList() async {
    try {
      final userCollection = FirebaseFirestore.instance.collection("entity");
      final querySnapshot = await userCollection.get();

      userDataFetch = querySnapshot.docs.map((doc) {
        return AuthenticationModel(
          userID: doc.get("userID"),
          firstName: doc.get("userName00"),
          lastName: doc.get("userName01"),
          middleName: doc.get("userName02"),
          entityType: doc.get("entity"),
          userMail: doc.get("userMail"),
          userKey: doc.get("userKey"),
          lastSession: doc.get("lastSession"),
        );
      }).toList();

      if (mounted) {
        setState(() {
          userDataDeployed = _filterUsers(query);
          isUserListLoaded = true;
        });
      }

      useToastify.showLoadingToast(
          context, "Loaded", "Users fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(context, "Error", "Failed to fetch users.");
      if (mounted) {
        setState(() {
          isUserListLoaded = true;
        });
      }
    }
  }

  List<AuthenticationModel> _filterUsers(String query) {
    final filteredUsers = query.isEmpty
        ? userDataFetch
        : userDataFetch.where((user) {
            return user.userID.toLowerCase().contains(query.toLowerCase()) ||
                user.firstName.toLowerCase().contains(query.toLowerCase()) ||
                user.lastName.toLowerCase().contains(query.toLowerCase()) ||
                user.userMail.toLowerCase().contains(query.toLowerCase()) ||
                _getEntityName(user.entityType)
                    .toLowerCase()
                    .contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredUsers.sort((a, b) => a.userID.compareTo(b.userID));
      case 0.5:
        filteredUsers.sort((a, b) => b.userID.compareTo(a.userID));
      case 1:
        filteredUsers.sort((a, b) => a.firstName.compareTo(b.firstName));
      case 1.5:
        filteredUsers.sort((a, b) => b.firstName.compareTo(a.firstName));
      case 2:
        filteredUsers.sort((a, b) => a.entityType.compareTo(b.entityType));
      case 2.5:
        filteredUsers.sort((a, b) => b.entityType.compareTo(a.entityType));
      case 3:
        filteredUsers.sort((a, b) => a.userMail.compareTo(b.userMail));
      case 3.5:
        filteredUsers.sort((a, b) => b.userMail.compareTo(a.userMail));
      case 4:
        filteredUsers.sort((a, b) => a.lastSession.compareTo(b.lastSession));
      case 4.5:
        filteredUsers.sort((a, b) => b.lastSession.compareTo(a.lastSession));
      default:
        filteredUsers.sort((a, b) => a.entityType.compareTo(b.entityType));
    }
    return filteredUsers.take(50).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      userDataDeployed = _filterUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      floatingActionButton: _buildModernFAB(),
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
                _buildModernHeader(),
                const SizedBox(height: 32),
                _buildUserStatsCards(),
                const SizedBox(height: 24),
                _buildModernSearchBar(),
                const SizedBox(height: 16),
                _buildModernUserTable(),
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
          colors: [_adminAccent, _adminAccent.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _adminAccent.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddUserDialog(
              onRefresh: _refreshUserList,
              userDataDeployed: userDataDeployed,
            ),
          );
        },
        icon: const Icon(
          HugeIcons.strokeRoundedUserAdd01,
          color: Colors.white,
        ),
        label: Text(
          'Add User',
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
                  HugeIcons.strokeRoundedUserSettings01,
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
                      "User Management",
                      style: GoogleFonts.montserrat(
                        fontSize: DynamicSizeService.calculateAspectRatioSize(
                            context, 0.032),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage system users and their permissions.',
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
        ],
      ),
    );
  }

  Widget _buildUserStatsCards() {
    Map<String, int> userCounts = {};
    for (var user in userDataFetch) {
      String entityName = _getEntityName(user.entityType);
      userCounts[entityName] = (userCounts[entityName] ?? 0) + 1;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            'Total Users',
            userDataFetch.length.toString(),
            HugeIcons.strokeRoundedMale02,
            _primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            'Admins',
            (userCounts['Admin'] ?? 0).toString(),
            HugeIcons.strokeRoundedUserShield01,
            _adminAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            'Registrars',
            (userCounts['Registrar'] ?? 0).toString(),
            HugeIcons.strokeRoundedUserCheck01,
            _successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            'Faculty',
            (userCounts['Faculty'] ?? 0).toString(),
            HugeIcons.strokeRoundedTeacher,
            Colors.orange,
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
          hintText: "Search by ID, name, email, or user type...",
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

  Widget _buildModernUserTable() {
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
          isUserListLoaded ? _buildUserList() : _buildLoadingIndicator(),
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
            width: 120,
            child: _buildHeaderCell("USER ID"),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildHeaderCell("NAME"),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: _buildHeaderCell("ENTITY"),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: _buildHeaderCell("EMAIL"),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: _buildHeaderCell("LAST SESSION"),
          ),
          const SizedBox(width: 60),
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

  Widget _buildUserList() {
    if (userDataFetch.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userDataDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernUserRow(userDataDeployed[index]);
      },
    );
  }

  Widget _buildModernUserRow(AuthenticationModel user) {
    Color entityColor = _getEntityColor(user.entityType);

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
          // USER ID - Fixed width (matches header)
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.userID,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${user.userID}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // NAME - Flexible (matches header)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${user.firstName} ${user.lastName}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (user.middleName.isNotEmpty)
                  Text(
                    user.middleName,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ENTITY - Fixed width (matches header)
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: entityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getEntityName(user.entityType),
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

          // EMAIL - Flexible (matches header)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.userMail,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '••••••••••',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // LAST SESSION - Fixed width (matches header)
          SizedBox(
            width: 100,
            child: Text(
              _formatDate(user.lastSession.toDate()),
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Actions - Fixed width (matches header spacing)
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      if (user.entityType != 0) {
                        showDialog(
                          context: context,
                          builder: (context) => EditUserDialog(
                            onRefresh: _refreshUserList,
                            userDataDeployed: userDataDeployed,
                            user: user,
                          ),
                        );
                      } else {
                        useToastify.showErrorToast(
                          context,
                          'Restricted',
                          'Admin accounts can only be modified by the Hosting Engineer.',
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Edit User'),
                        ],
                      ),
                    ),
                  ],
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
            HugeIcons.strokeRoundedMale02,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or add new users.',
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'USER ID':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'NAME':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'ENTITY':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        case 'EMAIL':
          newSortBy = isHeaderClicked ? 3.5 : 3;
          break;
        case 'LAST SESSION':
          newSortBy = isHeaderClicked ? 4.5 : 4;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      userDataDeployed = _filterUsers(query);
    });
  }

  Future<void> _refreshUserList() async {
    setState(() {
      isUserListLoaded = false;
      userDataFetch.clear();
      userDataDeployed.clear();
    });

    await _fetchUserList();
  }
}
