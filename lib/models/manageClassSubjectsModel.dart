class ManageClassModel {
  final String classDepartment;
  final String classCode;
  final List<String> classList;
  final List<int> enrolledSubjects;
  final String adviser;

  ManageClassModel({
    required this.classDepartment,
    required this.classCode,
    required this.classList,
    required this.enrolledSubjects,
    required this.adviser,
  });

  Map<String, dynamic> toMap() {
    return {
      'class-code': classCode,
      'class-list': classList,
      'enrolled-subjects': enrolledSubjects,
      'adviser': adviser,
    };
  }
}

class ManageClassSubjectsModel {
  final String teacherId;
  final String subjectDepartment;
  final String subjectId;
  final String subjectName;
  final String subjectDescription;
  final String classSubjectCode;
  final String classSchedule;

  ManageClassSubjectsModel({
    required this.teacherId,
    required this.subjectDepartment,
    required this.subjectId,
    required this.subjectName,
    required this.subjectDescription,
    required this.classSubjectCode,
    required this.classSchedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'subjectDepartment': subjectDepartment,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectDescription': subjectDescription,
      'classSubjectCode': classSubjectCode,
      'classSchedule': classSchedule,
    };
  }
}
