import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/manageSubjectModel.dart';
import 'package:sis_project/screens/registrar/section3_content/section3_modifysubject.dart';
import 'package:sis_project/screens/registrar/section3_content/section3_registersubject.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_on_hover/animate_on_hover.dart';

class RegistrarThirdSection extends StatefulWidget {
  const RegistrarThirdSection({super.key});

  @override
  State<RegistrarThirdSection> createState() => _RegistrarThirdSectionState();
}

class _RegistrarThirdSectionState extends State<RegistrarThirdSection> {
  List<ManageSubjectModel> subjectsDeployed = [];
  List<ManageSubjectModel> subjectsFetch = [];

  bool isSubjectListLoaded = false;
  bool isHeaderClicked = false;
  String query = '';
  double sortBy = -1;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  static const Map<String, String> _departmentNameMap = {
    'pre-dept': 'Pre-School',
    'pri-dept': 'Primary School',
    'jhs-dept': 'Junior High School',
    'abm-dept': 'Senior High School',
    'humms-dept': 'Senior High School',
    'gas-dept': 'Senior High School',
    'ict-dept': 'Senior High School',
    'he-dept': 'Senior High School',
  };

  static const Map<String, int> _departmentOrderMap = {
    'Pre-School': 1,
    'Primary School': 2,
    'Junior High School': 3,
    'Senior High School': 4,
  };

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      setState(() {
        isSubjectListLoaded = false;
        subjectsFetch.clear();
      });

      final snapshot =
          await FirebaseFirestore.instance.collection('subjects').get();

      final List<ManageSubjectModel> fetchedSubjects = snapshot.docs.map((doc) {
        final data = doc.data();
        return ManageSubjectModel(
          subjectId: data['subjectId'] ?? '',
          subjectName: data['subjectName'] ?? '',
          subjectDepartment:
              _getDepartmentName(data['subjectDepartment'] ?? ''),
          subjectDescription: data['subjectDescription'] ?? '',
        );
      }).toList();

      if (mounted) {
        useToastify.showLoadingToast(
            context, "Fetched", "Subjects fetched successfully");

        if (fetchedSubjects.length > 50) {
          useToastify.showLoadingToast(context, "Limiter",
              "Showing 50 out of ${fetchedSubjects.length}");
        } else {
          useToastify.showLoadingToast(context, "Limiter",
              "Showing ${fetchedSubjects.length} out of ${fetchedSubjects.length}");
        }

        setState(() {
          isSubjectListLoaded = true;
          subjectsFetch = fetchedSubjects;
          subjectsDeployed = _filteredSubjects(query);
        });
      }
    } catch (e) {
      if (mounted) {
        useToastify.showErrorToast(
            context, "Error", "Failed to fetch subjects");
      }
      print('Error fetching data: $e');
    }
  }

  Future<void> _refreshSubjectList() async {
    setState(() {
      isSubjectListLoaded = false;
      subjectsFetch.clear();
      subjectsDeployed.clear();
      sortBy = -1;
    });
    await _fetchSubjects();
  }

  String _getDepartmentName(String departmentCode) {
    return _departmentNameMap[departmentCode] ?? 'N/A';
  }

  int _getSubjectLevel(String subjectId) {
    final regex = RegExp(r'-(\d+)$');
    final match = regex.firstMatch(subjectId);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  List<ManageSubjectModel> _filteredSubjects(String query) {
    List<ManageSubjectModel> filteredSubjects;

    if (query.isEmpty) {
      filteredSubjects = List.from(subjectsFetch);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredSubjects = subjectsFetch.where((subject) {
        return subject.subjectId.toLowerCase().contains(lowerQuery) ||
            subject.subjectName.toLowerCase().contains(lowerQuery) ||
            subject.subjectDepartment.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    _applySorting(filteredSubjects);
    return filteredSubjects.take(50).toList();
  }

  void _applySorting(List<ManageSubjectModel> subjects) {
    switch (sortBy) {
      case -1:
        subjects.sort(_defaultSort);
        break;
      case 0:
        subjects.sort((a, b) => a.subjectId.compareTo(b.subjectId));
        break;
      case 0.5:
        subjects.sort((a, b) => b.subjectId.compareTo(a.subjectId));
        break;
      case 1:
        subjects.sort((a, b) => a.subjectName.compareTo(b.subjectName));
        break;
      case 1.5:
        subjects.sort((a, b) => b.subjectName.compareTo(a.subjectName));
        break;
      case 2:
        subjects.sort(_departmentSort);
        break;
      case 2.5:
        subjects.sort(_departmentSortReverse);
        break;
      default:
        subjects.sort(_defaultSort);
    }
  }

  int _defaultSort(ManageSubjectModel a, ManageSubjectModel b) {
    int deptOrderA = _departmentOrderMap[a.subjectDepartment] ?? 999;
    int deptOrderB = _departmentOrderMap[b.subjectDepartment] ?? 999;

    if (deptOrderA != deptOrderB) {
      return deptOrderA.compareTo(deptOrderB);
    }

    int levelA = _getSubjectLevel(a.subjectId);
    int levelB = _getSubjectLevel(b.subjectId);

    if (levelA != levelB) {
      return levelA.compareTo(levelB);
    }

    return a.subjectId.compareTo(b.subjectId);
  }

  int _departmentSort(ManageSubjectModel a, ManageSubjectModel b) {
    int deptOrderA = _departmentOrderMap[a.subjectDepartment] ?? 999;
    int deptOrderB = _departmentOrderMap[b.subjectDepartment] ?? 999;

    if (deptOrderA != deptOrderB) {
      return deptOrderA.compareTo(deptOrderB);
    }

    int levelA = _getSubjectLevel(a.subjectId);
    int levelB = _getSubjectLevel(b.subjectId);
    return levelA.compareTo(levelB);
  }

  int _departmentSortReverse(ManageSubjectModel a, ManageSubjectModel b) {
    int deptOrderA = _departmentOrderMap[a.subjectDepartment] ?? 999;
    int deptOrderB = _departmentOrderMap[b.subjectDepartment] ?? 999;

    if (deptOrderA != deptOrderB) {
      return deptOrderB.compareTo(deptOrderA);
    }

    int levelA = _getSubjectLevel(a.subjectId);
    int levelB = _getSubjectLevel(b.subjectId);
    return levelB.compareTo(levelA);
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      subjectsDeployed = _filteredSubjects(query);
    });
  }

  void _onHeaderTap(String headerType) {
    setState(() {
      double newSortBy;
      switch (headerType) {
        case 'ID':
          newSortBy = isHeaderClicked ? 0.5 : 0;
          break;
        case 'SUBJECT NAME':
          newSortBy = isHeaderClicked ? 1.5 : 1;
          break;
        case 'DEPARTMENT':
          newSortBy = isHeaderClicked ? 2.5 : 2;
          break;
        default:
          newSortBy = 0;
      }

      sortBy = newSortBy;
      isHeaderClicked = !isHeaderClicked;
      subjectsDeployed = _filteredSubjects(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      floatingActionButton: _buildModernFloatingActionButton(),
      body: RefreshIndicator(
        onRefresh: _refreshSubjectList,
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
                _buildSubjectManagementSection(),
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
                HugeIcons.strokeRoundedBook02,
                color: Colors.white,
                size:
                    DynamicSizeService.calculateAspectRatioSize(context, 0.04),
              ),
              const SizedBox(width: 12),
              Text(
                "Subject Management",
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
            'Register, manage, and organize subjects across all departments',
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

  Widget _buildSubjectManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Overview',
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
        _buildModernSubjectTable(),
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
          hintText: "Search by ID, subject name, or department...",
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

  Widget _buildModernSubjectTable() {
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
          isSubjectListLoaded ? _buildSubjectsList() : _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell("ID")),
          Expanded(flex: 4, child: _buildHeaderCell("SUBJECT NAME")),
          Expanded(flex: 3, child: _buildHeaderCell("DEPARTMENT")),
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

  Widget _buildSubjectsList() {
    if (subjectsDeployed.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjectsDeployed.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildModernSubjectRow(subjectsDeployed[index]);
      },
    );
  }

  Widget _buildModernSubjectRow(ManageSubjectModel subjectModel) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => ModifySubjectDialog(
            subjectModel: subjectModel,
            onRefresh: _refreshSubjectList,
          ),
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
                  subjectModel.subjectId,
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
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectModel.subjectName,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subjectModel.subjectDescription.isNotEmpty)
                    Text(
                      subjectModel.subjectDescription,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDepartmentColor(subjectModel.subjectDepartment)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subjectModel.subjectDepartment,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _getDepartmentColor(subjectModel.subjectDepartment),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Pre-School':
        return Colors.purple;
      case 'Primary School':
        return Colors.green;
      case 'Junior High School':
        return Colors.orange;
      case 'Senior High School':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedBook02,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No subjects found',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or register a new subject',
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
          icon: HugeIcons.strokeRoundedAdd01,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                RegisterSubjectDialog(onRefresh: _refreshSubjectList),
          );
        },
      ),
    ).increaseSizeOnHover(1.1);
  }
}
