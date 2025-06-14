import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/studentProfileModel.dart';
import 'package:sis_project/screens/student/section2_content/section2_editprofile.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentSecondSection extends StatefulWidget {
  const StudentSecondSection({super.key});

  @override
  State<StudentSecondSection> createState() => _StudentSecondSectionState();
}

class _StudentSecondSectionState extends State<StudentSecondSection> {
  List<studentProfileModel> studentProfileFetch = [];
  List<studentProfileModel> studentProfileDeployed = [];
  bool _isProfileLoaded = false;
  String _searchQuery = '';

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  // Map of display names to Firestore field names
  final Map<String, String> _firestoreFieldMap = {
    "Address": "address",
    "Date of Birth": "birthday",
    "Religion": "religion",
    "Contact Number": "contactNumber",
    "Father's Name": "fatherName",
    "Father's Occupation": "fatherOccupation",
    "Father's Contact": "fatherContact",
    "Mother's Name": "motherName",
    "Mother's Occupation": "motherOccupation",
    "Mother's Contact": "motherContact",
    "Guardian's Name": "guardianName",
    "Guardian's Occupation": "guardianOccupation",
    "Guardian's Contact": "guardianContact",
    "Guardian Relation": "guardianRelationship",
    "Birth Certificate": "birthCertificate",
    "Form 137": "form137",
  };

  // Map for name components
  final Map<String, Map<String, String>> _nameComponentMap = {
    "Father's Name": {
      "00": "fatherName00",
      "01": "fatherName01",
      "02": "fatherName02",
    },
    "Mother's Name": {
      "00": "motherName00",
      "01": "motherName01",
      "02": "motherName02",
    },
    "Guardian's Name": {
      "00": "guardianName00",
      "01": "guardianName01",
      "02": "guardianName02",
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _loadProfileInformation();
  }

  Future<void> _loadProfileInformation() async {
    try {
      final studentID = Provider.of<GlobalState>(context, listen: false).userID;

      final snapshot = await FirebaseFirestore.instance
          .collection('profile-information')
          .where('studentId', isEqualTo: studentID)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final profileData = snapshot.docs.first.data();
        final profile = studentProfileModel.fromMap(profileData);

        setState(() {
          studentProfileFetch = [profile];
          studentProfileDeployed = _filterProfile();
          _isProfileLoaded = true;
        });

        useToastify.showLoadingToast(
            context, "Loaded", "Profile loaded successfully.");
      } else {
        useToastify.showErrorToast(context, 'Not Found', 'Profile not found.');
        setState(() {
          _isProfileLoaded = true;
        });
      }
    } catch (e) {
      useToastify.showErrorToast(context, 'Error', 'Failed to load profile.');
      debugPrint('Error: $e');
      setState(() {
        _isProfileLoaded = true;
      });
    }
  }

  List<studentProfileModel> _filterProfile() {
    if (_searchQuery.isEmpty || studentProfileFetch.isEmpty) {
      return studentProfileFetch;
    }

    // For profile filtering, we can check if any field contains the search query
    final profile = studentProfileFetch.first;
    final searchLower = _searchQuery.toLowerCase();

    if (profile.address.toLowerCase().contains(searchLower) ||
        profile.religion.toLowerCase().contains(searchLower) ||
        profile.contactNumber.toLowerCase().contains(searchLower) ||
        profile.fatherName00.toLowerCase().contains(searchLower) ||
        profile.motherName00.toLowerCase().contains(searchLower) ||
        profile.guardianName00.toLowerCase().contains(searchLower)) {
      return studentProfileFetch;
    }

    return [];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      studentProfileDeployed = _filterProfile();
    });
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isProfileLoaded = false;
      studentProfileFetch.clear();
      studentProfileDeployed.clear();
    });
    await _loadProfileInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
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
                _buildProfileSection(),
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
                "Profile Management",
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
            'View and manage your personal information.',
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

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernSearchBar(),
        const SizedBox(height: 16),
        _buildModernProfileTable(),
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
          hintText: "Search profile information...",
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

  Widget _buildModernProfileTable() {
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
          _isProfileLoaded ? _buildProfileList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "FIELD",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "VALUE",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              "ACTION",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList() {
    if (studentProfileDeployed.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProfileRows(studentProfileDeployed.first);
  }

  Widget _buildProfileRows(studentProfileModel profile) {
    final globalState = Provider.of<GlobalState>(context, listen: false);

    Map<String, String> profileMap = {
      "Name":
          '${globalState.userName00} ${globalState.userName02} ${globalState.userName01}',
      "Student ID": profile.studentId,
      "Entry Year": profile.entryYear,
      "Enrolled Class": profile.enrolledClass,
      "Address": profile.address,
      "Date of Birth":
          DateFormat('MMMM dd, yyyy').format(profile.dateOfBirth.toDate()),
      "Religion": profile.religion,
      "Contact Number": profile.contactNumber,
      "Father's Name":
          '${profile.fatherName00} ${profile.fatherName02} ${profile.fatherName01}',
      "Father's Occupation": profile.fatherOccupation,
      "Father's Contact": profile.fatherContact,
      "Mother's Name":
          '${profile.motherName00} ${profile.motherName02} ${profile.motherName01}',
      "Mother's Occupation": profile.motherOccupation,
      "Mother's Contact": profile.motherContact,
      "Guardian's Name":
          '${profile.guardianName00} ${profile.guardianName02} ${profile.guardianName01}',
      "Guardian's Occupation": profile.guardianOccupation,
      "Guardian's Contact": profile.guardianContact,
      "Guardian Relation": profile.guardianRelation,
      "Birth Certificate":
          profile.birthCertificate ? "✔️ Submitted" : "❌ Not Submitted",
      "Form 137": profile.form137 ? "✔️ Submitted" : "❌ Not Submitted",
    };

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: profileMap.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = profileMap.entries.elementAt(index);
        return _buildModernProfileRow(entry, profile);
      },
    );
  }

  Widget _buildModernProfileRow(
      MapEntry<String, String> entry, studentProfileModel profile) {
    final nonEditableFields = [
      "Entry Year",
      "Enrolled Class",
      "Student ID",
      "Birth Certificate",
      "Form 137",
      "Name"
    ];

    final isEditable = !nonEditableFields.contains(entry.key);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.key,
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
            flex: 3,
            child: Text(
              entry.value,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: isEditable
                ? IconButton(
                    onPressed: () => _handleEntryTap(entry, profile),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: _primaryColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
          ),
        ],
      ),
    );
  }

  void _handleEntryTap(
      MapEntry<String, String> entry, studentProfileModel profile) {
    final nonEditableFields = [
      "Entry Year",
      "Enrolled Class",
      "Student ID",
      "Birth Certificate",
      "Form 137",
      "Name"
    ];

    if (nonEditableFields.contains(entry.key)) {
      useToastify.showErrorToast(
          context, "Error", "${entry.key} cannot be edited.");
      return;
    }

    final nameMap = {
      "fatherName00": profile.fatherName00,
      "fatherName01": profile.fatherName01,
      "fatherName02": profile.fatherName02,
      "motherName00": profile.motherName00,
      "motherName01": profile.motherName01,
      "motherName02": profile.motherName02,
      "guardianName00": profile.guardianName00,
      "guardianName01": profile.guardianName01,
      "guardianName02": profile.guardianName02,
    };

    // Handle name fields
    if (entry.key == "Father's Name" ||
        entry.key == "Mother's Name" ||
        entry.key == "Guardian's Name") {
      final who = entry.key == "Father's Name"
          ? 1
          : entry.key == "Mother's Name"
              ? 2
              : 3;
      showDialog(
        context: context,
        builder: (context) => EditProfileDialog(
          onRefresh: _refreshProfile,
          studentProfile: studentProfileDeployed,
          dateOfBirth: profile.dateOfBirth,
          familyMemberType: who,
          firestoreField: _nameComponentMap[entry.key]?.values.join(',') ?? '',
          nameMap: nameMap,
          title: 'Edit ${entry.key}',
          label: entry.key,
          editType: EditType.name,
          currentValue: entry.value,
        ),
      );
      return;
    }

    // Handle date of birth
    if (entry.key == "Date of Birth") {
      showDialog(
        context: context,
        builder: (context) => EditProfileDialog(
          onRefresh: _refreshProfile,
          studentProfile: studentProfileDeployed,
          dateOfBirth: profile.dateOfBirth,
          familyMemberType: 0,
          firestoreField: _firestoreFieldMap[entry.key] ?? '',
          nameMap: nameMap,
          title: 'Edit ${entry.key}',
          label: entry.key,
          editType: EditType.date,
          currentValue:
              profile.dateOfBirth.toDate().toString().substring(0, 10),
        ),
      );
      return;
    }

    // Handle all other editable fields
    if (_firestoreFieldMap.containsKey(entry.key)) {
      showDialog(
        context: context,
        builder: (context) => EditProfileDialog(
          onRefresh: _refreshProfile,
          studentProfile: studentProfileDeployed,
          dateOfBirth: profile.dateOfBirth,
          familyMemberType: 0,
          firestoreField: _firestoreFieldMap[entry.key] ?? '',
          nameMap: nameMap,
          title: 'Edit ${entry.key}',
          label: entry.key,
          editType: EditType.singleField,
          currentValue: entry.value,
        ),
      );
      return;
    }

    useToastify.showErrorToast(
        context, "Error", "There is an error when clicking this field.");
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.person_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No profile information found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact administrator',
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
