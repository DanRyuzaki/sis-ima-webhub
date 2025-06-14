import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/facultyProfileModel.dart';
import 'package:sis_project/screens/registrar/section4_content/section4_addfaculty.dart';
import 'package:sis_project/screens/registrar/section4_content/section4_modifyfaculty.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_on_hover/animate_on_hover.dart';

class RegistrarFourthSection extends StatefulWidget {
  const RegistrarFourthSection({super.key});

  @override
  State<RegistrarFourthSection> createState() => _RegistrarFourthSectionState();
}

class _RegistrarFourthSectionState extends State<RegistrarFourthSection> {
  List<facultyProfileModel> userDataFetch = [];
  List<facultyProfileModel> userDataDeployed = [];

  bool isUserListLoaded = false;
  bool isHeaderClicked = false;
  String query = '';
  double sortBy = -1;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  static const Map<String, String> departmentMap = {
    'pre-dept': 'Pre-School',
    'pri-dept': 'Primary School',
    'jhs-dept': 'Junior High School',
    'abm-dept': 'ABM - Senior High School',
    'humms-dept': 'HUMMS - Senior High School',
    'gas-dept': 'GAS - Senior High School',
    'ict-dept': 'ICT - Senior High School',
    'he-dept': 'HE - Senior High School'
  };

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  Future<void> _fetchUserList({bool skipInitialClear = false}) async {
    try {
      if (!skipInitialClear) {
        setState(() {
          isUserListLoaded = false;
          userDataFetch.clear();
        });
      }

      final userCollection = FirebaseFirestore.instance.collection("entity");
      final querySnapshot =
          await userCollection.where("entity", isEqualTo: 2).get();

      final List<facultyProfileModel> fetchedUsers =
          querySnapshot.docs.map((doc) {
        final data = doc.data();

        // Handle department as List<String>
        List<String> departments = [];
        if (data['department'] != null) {
          if (data['department'] is List) {
            departments = List<String>.from(data['department']);
          } else if (data['department'] is String) {
            // Handle backward compatibility for old single department format
            departments = [data['department']];
          }
        }

        return facultyProfileModel(
          facultyId: data['userID'] ?? '',
          facultyName00: data['userName00'] ?? '',
          facultyName01: data['userName01'] ?? '',
          facultyName02: data['userName02'] ?? '',
          dateOfBirth: data['birthday'],
          contactNumber: data['contactNumber'] ?? '',
          advisoryClassId: data['advisoryClassId'] ?? [],
          subjectsList: data['subjectsList'] ?? [],
          facultyEmail: data['userMail'] ?? '',
          facultyKey: data['userKey'] ?? '',
          lastSession: data['lastSession'] ?? Timestamp.now(),
          department: departments,
        );
      }).toList();

      if (mounted) {
        useToastify.showLoadingToast(
            context, "Fetched", "Faculty profiles fetched successfully");

        if (fetchedUsers.length > 50) {
          useToastify.showLoadingToast(context, "Limiter",
              "Showing 50 out of ${fetchedUsers.length} faculty members");
        } else {
          useToastify.showLoadingToast(context, "Limiter",
              "Showing ${fetchedUsers.length} out of ${fetchedUsers.length} faculty members");
        }

        setState(() {
          isUserListLoaded = true;
          userDataFetch = fetchedUsers;
          userDataDeployed = _filterUsers(query);
        });
      }
    } catch (e) {
      if (mounted) {
        useToastify.showErrorToast(
            context, "Error", "Failed to fetch faculty data.");
      }
      debugPrint("Error fetching users: $e");
    }
  }

  Future<void> _refreshUserList() async {
    setState(() {
      isUserListLoaded = false;
      userDataFetch.clear();
      userDataDeployed.clear();
      sortBy = -1;
      query = '';
    });

    await _fetchUserList();
  }

  List<facultyProfileModel> _filterUsers(String query) {
    List<facultyProfileModel> filteredUsers;

    if (query.isEmpty) {
      filteredUsers = List.from(userDataFetch);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredUsers = userDataFetch.where((faculty) {
        // Check if any department matches the search query
        final departmentMatches = faculty.department.any((dept) {
          final departmentName = departmentMap[dept] ?? dept;
          return departmentName.toLowerCase().contains(lowerQuery);
        });

        return faculty.facultyId.toLowerCase().contains(lowerQuery) ||
            faculty.facultyName00.toLowerCase().contains(lowerQuery) ||
            faculty.facultyName01.toLowerCase().contains(lowerQuery) ||
            faculty.facultyEmail.toLowerCase().contains(lowerQuery) ||
            departmentMatches;
      }).toList();
    }

    _applySorting(filteredUsers);
    return filteredUsers.take(50).toList();
  }

  void _applySorting(List<facultyProfileModel> users) {
    switch (sortBy) {
      case -1:
        users.sort(_defaultSort);
        break;
      case 0:
        users.sort((a, b) => a.facultyId.compareTo(b.facultyId));
        break;
      case 0.5:
        users.sort((a, b) => b.facultyId.compareTo(a.facultyId));
        break;
      case 1:
        users.sort((a, b) => a.facultyName00.compareTo(b.facultyName00));
        break;
      case 1.5:
        users.sort((a, b) => b.facultyName00.compareTo(a.facultyName00));
        break;
      case 2:
        users.sort((a, b) => a.facultyEmail.compareTo(b.facultyEmail));
        break;
      case 2.5:
        users.sort((a, b) => b.facultyEmail.compareTo(a.facultyEmail));
        break;
      case 3:
        users.sort((a, b) {
          // Sort by first department for simplicity
          final deptA = a.department.isNotEmpty
              ? (departmentMap[a.department.first] ?? a.department.first)
              : '';
          final deptB = b.department.isNotEmpty
              ? (departmentMap[b.department.first] ?? b.department.first)
              : '';
          return deptA.compareTo(deptB);
        });
        break;
      case 3.5:
        users.sort((a, b) {
          // Sort by first department for simplicity
          final deptA = a.department.isNotEmpty
              ? (departmentMap[a.department.first] ?? a.department.first)
              : '';
          final deptB = b.department.isNotEmpty
              ? (departmentMap[b.department.first] ?? b.department.first)
              : '';
          return deptB.compareTo(deptA);
        });
        break;
      case 4:
        users.sort((a, b) => a.lastSession.compareTo(b.lastSession));
        break;
      case 4.5:
        users.sort((a, b) => b.lastSession.compareTo(a.lastSession));
        break;
      default:
        users.sort(_defaultSort);
    }
  }

  int _defaultSort(facultyProfileModel a, facultyProfileModel b) {
    return a.facultyId.compareTo(b.facultyId);
  }

  void _onSearchChanged(String searchQuery) {
    setState(() {
      query = searchQuery;
      userDataDeployed = _filterUsers(searchQuery);
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'USER_ID':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'NAME':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'EMAIL':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        case 'DEPARTMENT':
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

  String _getDepartmentDisplayName(String departmentCode) {
    return departmentMap[departmentCode] ?? departmentCode;
  }

  // Updated to handle multiple departments display
  Widget _buildDepartmentChips(List<String> departments) {
    if (departments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'No Department',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    if (departments.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getDepartmentColor(departments.first),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _getDepartmentDisplayName(departments.first),
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _getDepartmentTextColor(departments.first),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // For multiple departments, show first one with count
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDepartmentColor(departments.first),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _getDepartmentDisplayName(departments.first),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getDepartmentTextColor(departments.first),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (departments.length > 1) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${departments.length - 1} more',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getDepartmentColor(String departmentCode) {
    switch (departmentCode) {
      case 'pre-dept':
        return Colors.pink.shade100;
      case 'pri-dept':
        return Colors.blue.shade100;
      case 'jhs-dept':
        return Colors.green.shade100;
      case 'abm-dept':
        return Colors.orange.shade100;
      case 'humms-dept':
        return Colors.purple.shade100;
      case 'gas-dept':
        return Colors.red.shade100;
      case 'ict-dept':
        return Colors.blue.shade100;
      case 'he-dept':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getDepartmentTextColor(String departmentCode) {
    switch (departmentCode) {
      case 'pre-dept':
        return Colors.pink.shade700;
      case 'pri-dept':
        return Colors.blue.shade700;
      case 'jhs-dept':
        return Colors.green.shade700;
      case 'abm-dept':
        return Colors.orange.shade700;
      case 'humms-dept':
        return Colors.purple.shade700;
      case 'gas-dept':
        return Colors.red.shade700;
      case 'ict-dept':
        return Colors.blue.shade700;
      case 'he-dept':
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      floatingActionButton: _buildModernFloatingActionButton(),
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
                _buildFacultyManagementSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            children: [
              Icon(
                HugeIcons.strokeRoundedSchoolTie,
                color: Colors.white,
                size:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              ),
              const SizedBox(width: 12),
              Text(
                "Faculty Management",
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.032),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage faculty profiles and registrations across all departments',
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

  Widget _buildFacultyManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faculty Directory',
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
        _buildModernFacultyTable(),
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
          hintText: "Search by ID, name, email, or department...",
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

  Widget _buildModernFacultyTable() {
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
          isUserListLoaded ? _buildFacultyList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell("USER_ID")),
          Expanded(flex: 3, child: _buildHeaderCell("NAME")),
          Expanded(flex: 3, child: _buildHeaderCell("EMAIL")),
          Expanded(flex: 2, child: _buildHeaderCell("DEPARTMENT")),
          Expanded(flex: 2, child: _buildHeaderCell("LAST SESSION")),
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
              isHeaderClicked
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

  Widget _buildFacultyList() {
    if (userDataDeployed.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userDataDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernFacultyRow(userDataDeployed[index]);
      },
    );
  }

  Widget _buildModernFacultyRow(facultyProfileModel faculty) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => ModifyFacultyDialog(
              onRefresh: _refreshUserList, facultyDataDeployed: faculty),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  faculty.facultyId,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${faculty.facultyName01}, ${faculty.facultyName00}",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (faculty.facultyName02.isNotEmpty)
                    Text(
                      faculty.facultyName02,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                faculty.facultyEmail,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildDepartmentChips(faculty.department),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy')
                        .format(faculty.lastSession.toDate()),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(faculty.lastSession.toDate()),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.grey.shade500,
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
            HugeIcons.strokeRoundedSchoolTie,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No faculty members found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or add new faculty',
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

  Widget _buildModernFloatingActionButton() {
    return Container(
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
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUserAdd02,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddFacultyDialog(
                onRefresh: _refreshUserList,
                facultyDataDeployed: userDataDeployed),
          );
        },
      ),
    ).increaseSizeOnHover(1.1);
  }
}
