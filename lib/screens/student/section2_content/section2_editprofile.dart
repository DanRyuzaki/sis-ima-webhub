import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/studentProfileModel.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';

enum EditType { name, date, singleField }

class EditProfileDialog extends StatefulWidget {
  final VoidCallback onRefresh;
  final List<studentProfileModel> studentProfile;
  final Timestamp dateOfBirth;
  final int familyMemberType;
  final String firestoreField;
  final Map<String, String> nameMap;
  final String title;
  final String label;
  final String currentValue;
  final EditType editType;

  const EditProfileDialog({
    super.key,
    required this.onRefresh,
    required this.studentProfile,
    required this.dateOfBirth,
    required this.familyMemberType,
    required this.firestoreField,
    required this.nameMap,
    required this.title,
    required this.label,
    required this.currentValue,
    required this.editType,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _singleFieldController;

  DateTime? _selectedDate;
  bool _isUpdating = false;

  static const Color _primaryColor = Color.fromARGB(255, 36, 66, 117);
  static const Color _lightGray = Color(0xFFF8F9FA);
  static const Color _cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFieldValues();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _singleFieldController = TextEditingController();
  }

  void _disposeControllers() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _singleFieldController.dispose();
  }

  void _initializeFieldValues() {
    switch (widget.editType) {
      case EditType.name:
        final prefix = _getFamilyMemberPrefix();
        _firstNameController.text = widget.nameMap['${prefix}Name00'] ?? '';
        _middleNameController.text = widget.nameMap['${prefix}Name02'] ?? '';
        _lastNameController.text = widget.nameMap['${prefix}Name01'] ?? '';
        break;
      case EditType.date:
        _dateOfBirthController.text =
            DateFormat('MM/dd/yyyy').format(widget.dateOfBirth.toDate());
        break;
      case EditType.singleField:
        _singleFieldController.text = widget.currentValue;
        break;
    }
  }

  String _getFamilyMemberPrefix() {
    switch (widget.familyMemberType) {
      case 1:
        return 'father';
      case 2:
        return 'mother';
      case 3:
        return 'guardian';
      default:
        return '';
    }
  }

  IconData _getFieldIcon() {
    switch (widget.editType) {
      case EditType.name:
        return Icons.person_outline;
      case EditType.date:
        return Icons.calendar_today_outlined;
      case EditType.singleField:
        if (widget.firestoreField == 'address') return Icons.location_on_outlined;
        if (widget.firestoreField == 'religion') return Icons.church_outlined;
        if (widget.firestoreField.contains('contact') || widget.firestoreField.contains('Contact')) return Icons.phone_outlined;
        if (widget.firestoreField.contains('occupation') || widget.firestoreField.contains('Occupation')) return Icons.work_outline;
        return Icons.edit_outlined;
    }
  }

  Future<void> _updateProfile() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final updateData = await _prepareUpdateData();
      if (updateData == null) return;

      await _performFirestoreUpdate(updateData);

      useToastify.showLoadingToast(
          context, 'Success', 'Profile updated successfully');
      widget.onRefresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _handleUpdateError(e);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<Map<String, dynamic>?> _prepareUpdateData() async {
    switch (widget.editType) {
      case EditType.name:
        return _prepareNameUpdateData();
      case EditType.date:
        return _prepareDateUpdateData();
      case EditType.singleField:
        return _prepareSingleFieldUpdateData();
    }
  }

  Map<String, dynamic> _prepareNameUpdateData() {
    final fieldMap = ProfileFieldMapper.getNameFields(widget.familyMemberType);
    return {
      fieldMap['00']!: _firstNameController.text,
      fieldMap['02']!: _middleNameController.text,
      fieldMap['01']!: _lastNameController.text,
    };
  }

  Map<String, dynamic>? _prepareDateUpdateData() {
    if (_selectedDate == null) {
      useToastify.showErrorToast(
          context, 'Error', 'Please select a valid date');
      return null;
    }
    return {'birthday': Timestamp.fromDate(_selectedDate!)};
  }

  Map<String, dynamic>? _prepareSingleFieldUpdateData() {
    if (_singleFieldController.text.trim().isEmpty) {
      useToastify.showErrorToast(context, 'Error', 'Field cannot be empty');
      return null;
    }
    return {widget.firestoreField: _singleFieldController.text.trim()};
  }

  Future<void> _performFirestoreUpdate(Map<String, dynamic> updateData) async {
    final userID = Provider.of<GlobalState>(context, listen: false).userID;
    final snapshot = await FirebaseFirestore.instance
        .collection('profile-information')
        .where('studentId', isEqualTo: userID)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      useToastify.showErrorToast(context, 'Error', 'Profile not found');
      return;
    }

    await FirebaseFirestore.instance
        .collection('profile-information')
        .doc(snapshot.docs.first.id)
        .update(updateData);
  }

  void _handleUpdateError(dynamic error) {
    useToastify.showErrorToast(context, 'Error', 'Failed to update profile');
    debugPrint('Update error: $error');
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.dateOfBirth.toDate(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: DynamicSizeService.calculateWidthSize(context, 0.45),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                child: _buildContent(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color.fromARGB(255, 52, 89, 149)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFieldIcon(),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.020),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Update your profile information',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentValueSection(),
          const SizedBox(height: 20),
          _buildEditSection(),
        ],
      ),
    );
  }

  Widget _buildCurrentValueSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Value',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            widget.currentValue.isNotEmpty ? widget.currentValue : 'No value set',
            style: GoogleFonts.montserrat(
              fontSize: DynamicSizeService.calculateAspectRatioSize(
                  context, 0.016),
              fontWeight: FontWeight.w500,
              color: widget.currentValue.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Value',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildFormContent(),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return switch (widget.editType) {
      EditType.name => _NameEditForm(
          firstNameController: _firstNameController,
          middleNameController: _middleNameController,
          lastNameController: _lastNameController,
        ),
      EditType.date => _DateEditForm(
          controller: _dateOfBirthController,
          onTap: _selectDate,
        ),
      EditType.singleField => _SingleFieldEditForm(
          controller: _singleFieldController,
          label: widget.label,
          isMultiline: widget.firestoreField == 'address',
        ),
    };
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isUpdating ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isUpdating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Update Profile',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileFieldMapper {
  static Map<String, String> getNameFields(int familyMemberType) {
    return switch (familyMemberType) {
      1 => {'00': 'fatherName00', '01': 'fatherName01', '02': 'fatherName02'},
      2 => {'00': 'motherName00', '01': 'motherName01', '02': 'motherName02'},
      3 => {
          '00': 'guardianName00',
          '01': 'guardianName01',
          '02': 'guardianName02'
        },
      _ => {},
    };
  }
}

class _NameEditForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;

  const _NameEditForm({
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildModernNameField('First Name', firstNameController, Icons.person_outline),
        const SizedBox(height: 16),
        _buildModernNameField('Middle Name', middleNameController, Icons.person_add_outlined),
        const SizedBox(height: 16),
        _buildModernNameField('Last Name', lastNameController, Icons.person_pin_outlined),
      ],
    );
  }

  Widget _buildModernNameField(String label, TextEditingController controller, IconData icon) {
    return _ModernTextField(
      controller: controller,
      label: label,
      prefixIcon: icon,
    );
  }
}

class _DateEditForm extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateEditForm({
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ModernTextField(
      controller: controller,
      label: 'Date of Birth',
      readOnly: true,
      onTap: onTap,
      prefixIcon: Icons.calendar_today_outlined,
      suffixIcon: Icons.arrow_drop_down,
    );
  }
}

class _SingleFieldEditForm extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isMultiline;

  const _SingleFieldEditForm({
    required this.controller,
    required this.label,
    this.isMultiline = false,
  });

  IconData _getIconForField(String label) {
    if (label.toLowerCase().contains('address')) return Icons.location_on_outlined;
    if (label.toLowerCase().contains('religion')) return Icons.church_outlined;
    if (label.toLowerCase().contains('contact') || label.toLowerCase().contains('phone')) return Icons.phone_outlined;
    if (label.toLowerCase().contains('occupation') || label.toLowerCase().contains('work')) return Icons.work_outline;
    return Icons.edit_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return _ModernTextField(
      controller: controller,
      label: label,
      maxLines: isMultiline ? 4 : 1,
      prefixIcon: _getIconForField(label),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  const _ModernTextField({
    required this.controller,
    required this.label,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: GoogleFonts.montserrat(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          labelText: label,
          labelStyle: GoogleFonts.montserrat(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: Colors.grey.shade500,
                  size: 20,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? Icon(
                  suffixIcon,
                  color: Colors.grey.shade500,
                  size: 20,
                )
              : null,
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 36, 66, 117),
              width: 2,
            ),
          ),
          enabledBorder: InputBorder.none,
          floatingLabelStyle: GoogleFonts.montserrat(
            color: const Color.fromARGB(255, 36, 66, 117),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}