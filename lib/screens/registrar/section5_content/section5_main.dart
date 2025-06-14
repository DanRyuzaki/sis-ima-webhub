import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/models/studentProfileModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/screens/registrar/section5_content/section5_enrollstudent.dart';
import 'package:sis_project/screens/registrar/section5_content/section5_modifystudent.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_on_hover/animate_on_hover.dart';

class RegistrarFifthSection extends StatefulWidget {
  const RegistrarFifthSection({super.key});

  @override
  State<RegistrarFifthSection> createState() => _RegistrarFifthSectionState();
}

class _RegistrarFifthSectionState extends State<RegistrarFifthSection> {
  List<AuthenticationModel> userDataFetch = [], userDataDeployed = [];
  List<studentProfileModel> studentDataFetch = [], studentDataDeployed = [];

  bool isUserListLoaded = false;
  bool isHeaderClicked = false;
  String query = '';
  double sortBy = -1;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchUserList();
    _fetchStudentProfiles();
  }

  Future<void> _fetchUserList() async {
    try {
      setState(() {
        isUserListLoaded = false;
        userDataFetch.clear();
      });

      final userCollection = FirebaseFirestore.instance.collection("entity");
      final querySnapshot =
          await userCollection.where("entity", isEqualTo: 3).get();

      final List<AuthenticationModel> fetchedUsers =
          querySnapshot.docs.map((doc) {
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
        useToastify.showLoadingToast(
            context, "Fetched", "Student profiles fetched successfully");

        if (fetchedUsers.length > 50) {
          useToastify.showLoadingToast(context, "Limiter",
              "Showing 50 out of ${fetchedUsers.length} students");
        } else {
          useToastify.showLoadingToast(context, "Limiter",
              "Showing ${fetchedUsers.length} out of ${fetchedUsers.length} students");
        }

        setState(() {
          userDataFetch = fetchedUsers;
          userDataDeployed = _filterUsers(query);
          isUserListLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        useToastify.showErrorToast(
            context, "Error", "Failed to fetch student data.");
      }
      debugPrint("Error fetching users: $e");
    }
  }

  Future<void> _fetchStudentProfiles() async {
    try {
      final profileCollection =
          FirebaseFirestore.instance.collection("profile-information");
      final querySnapshot = await profileCollection.get();

      studentDataFetch = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return studentProfileModel(
          studentId: data['studentId'] ?? 'N/A',
          dateOfBirth: data['birthday'] ?? 'N/A',
          address: data['address'] ?? 'N/A',
          religion: data['religion'],
          contactNumber: data['contactNumber'] ?? 'N/A',
          entryYear: data['entryYear'],
          enrolledClass: _parseEnrolledClass(data['enrolledClass']),
          fatherName00: data['fatherName00'],
          fatherName01: data['fatherName01'],
          fatherName02: data['fatherName02'],
          fatherOccupation: data['fatherOccupation'],
          fatherContact: data['fatherContact'],
          motherName00: data['motherName00'],
          motherName01: data['motherName01'],
          motherName02: data['motherName02'],
          motherOccupation: data['motherOccupation'],
          motherContact: data['motherContact'],
          guardianName00: data['guardianName00'],
          guardianName01: data['guardianName01'],
          guardianName02: data['guardianName02'],
          guardianOccupation: data['guardianOccupation'],
          guardianContact: data['guardianContact'],
          guardianRelation: data['guardianRelationship'],
          birthCertificate: data['birthCertificate'],
          form137: data['form137'],
        );
      }).toList();

      setState(() {
        studentDataDeployed = _filterStudentProfiles(query);
      });
    } catch (e) {
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch student profiles. $e");
      debugPrint("Error fetching student profiles: $e");
    }
  }

  String _parseEnrolledClass(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'N/A';
    }
    return value.toString();
  }

  Future<void> _refreshUserList() async {
    setState(() {
      isUserListLoaded = false;
      userDataFetch.clear();
      userDataDeployed.clear();
      studentDataFetch.clear();
      studentDataDeployed.clear();
      sortBy = -1;
    });
    await _fetchUserList();
    await _fetchStudentProfiles();
  }

  List<AuthenticationModel> _filterUsers(String query) {
    List<AuthenticationModel> filteredUsers;

    if (query.isEmpty) {
      filteredUsers = List.from(userDataFetch);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredUsers = userDataFetch.where((user) {
        return user.userID.toLowerCase().contains(lowerQuery) ||
            user.firstName.toLowerCase().contains(lowerQuery) ||
            user.lastName.toLowerCase().contains(lowerQuery) ||
            user.userMail.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    _applySorting(filteredUsers);
    return filteredUsers.take(50).toList();
  }

  void _applySorting(List<AuthenticationModel> users) {
    switch (sortBy) {
      case -1:
        users.sort(_defaultSort);
        break;
      case 0:
        users.sort((a, b) => a.userID.compareTo(b.userID));
        break;
      case 0.5:
        users.sort((a, b) => b.userID.compareTo(a.userID));
        break;
      case 1:
        users.sort((a, b) => a.firstName.compareTo(b.firstName));
        break;
      case 1.5:
        users.sort((a, b) => b.firstName.compareTo(a.firstName));
        break;
      case 2:
        users.sort((a, b) => a.userMail.compareTo(b.userMail));
        break;
      case 2.5:
        users.sort((a, b) => b.userMail.compareTo(a.userMail));
        break;
      case 3:
        users.sort((a, b) => a.lastSession.compareTo(b.lastSession));
        break;
      case 3.5:
        users.sort((a, b) => b.lastSession.compareTo(a.lastSession));
        break;
      default:
        users.sort(_defaultSort);
    }
  }

  int _defaultSort(AuthenticationModel a, AuthenticationModel b) {
    return a.userID.compareTo(b.userID);
  }

  List<studentProfileModel> _filterStudentProfiles(String query) {
    final filteredProfiles = query.isEmpty
        ? studentDataFetch
        : studentDataFetch.where((profile) {
            return profile.studentId
                .toUpperCase()
                .contains(query.toUpperCase());
          }).toList();

    return filteredProfiles.take(10).toList();
  }

  void _onSearchChanged(String searchQuery) {
    setState(() {
      query = searchQuery;
      userDataDeployed = _filterUsers(searchQuery);
      studentDataDeployed = _filterStudentProfiles(searchQuery);
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'STUDENT_ID':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'NAME':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'EMAIL':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        case 'LAST SESSION':
          newSortBy = isHeaderClicked ? 3.5 : 3;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      userDataDeployed = _filterUsers(query);
    });
  }

  Future<void> _onRowTapped(AuthenticationModel user) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
          ),
        ),
      );

      studentProfileModel? studentProfile = studentDataFetch
          .where((profile) => profile.studentId == user.userID)
          .firstOrNull;

      Navigator.of(context).pop();

      if (studentProfile != null) {
        showDialog(
          context: context,
          builder: (context) => ModifyStudentDialog(
            onRefresh: _refreshUserList,
            studentDataDeployed: studentDataDeployed,
            authDataDeployed: userDataDeployed,
            studentToModify: studentProfile,
            authDataToModify: user,
          ),
        );
      } else {
        useToastify.showErrorToast(
          context,
          "Profile Not Found",
          "Student profile for ${user.userID} could not be found.",
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      useToastify.showErrorToast(
        context,
        "Error",
        "Failed to load student details. Please try again.",
      );
      debugPrint("Error loading student details: $e");
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
                _buildStudentManagementSection(),
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
                HugeIcons.strokeRoundedStudentCard,
                color: Colors.white,
                size:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              ),
              const SizedBox(width: 12),
              Text(
                "Student Management",
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
            'Manage student enrollment and profiles across all grade levels',
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

  Widget _buildStudentManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Directory',
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
        _buildModernStudentTable(),
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
          hintText: "Search by ID, name, or email...",
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

  Widget _buildModernStudentTable() {
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
          isUserListLoaded ? _buildStudentList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell("STUDENT_ID")),
          Expanded(flex: 3, child: _buildHeaderCell("NAME")),
          Expanded(flex: 3, child: _buildHeaderCell("EMAIL")),
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
              text.replaceAll('_', ' '),
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

  Widget _buildStudentList() {
    if (userDataDeployed.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userDataDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernStudentRow(userDataDeployed[index]);
      },
    );
  }

  Widget _buildModernStudentRow(AuthenticationModel student) {
    return InkWell(
      onTap: () => _onRowTapped(student),
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
                  student.userID,
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
                    "${student.lastName}, ${student.firstName}",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (student.middleName.isNotEmpty)
                    Text(
                      student.middleName,
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
                student.userMail,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy')
                        .format(student.lastSession.toDate()),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(student.lastSession.toDate()),
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
            HugeIcons.strokeRoundedStudentCard,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or enroll new students',
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
            builder: (context) => EnrollStudentDialog(
                onRefresh: _refreshUserList,
                existingStudents: userDataDeployed),
          );
        },
      ),
    ).increaseSizeOnHover(1.1);
  }
}
