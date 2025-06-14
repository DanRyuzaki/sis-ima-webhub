class gradesModel {
  String gradesStudentID;
  String gradesSubName;
  double gradesFirGrade;
  double gradesSecGrade;
  double gradesThiGrade;
  double gradesFouGrade;
  double gradesFinGrade;
  String gradesGraStat;

  gradesModel({
    required this.gradesStudentID,
    required this.gradesSubName,
    required this.gradesFirGrade,
    required this.gradesSecGrade,
    required this.gradesThiGrade,
    required this.gradesFouGrade,
    required this.gradesFinGrade,
    required this.gradesGraStat,
  });

  factory gradesModel.fromMap(Map<String, dynamic> data) {
    return gradesModel(
      gradesStudentID: data['gradesStudentID'] ?? '',
      gradesSubName: data['gradesSubName'] ?? '',
      gradesFirGrade: data['gradesFirGrade'] ?? '',
      gradesSecGrade: data['gradesSecGrade'] ?? '',
      gradesThiGrade: data['gradesThiGrade'] ?? '',
      gradesFouGrade: data['gradesFouGrade'] ?? '',
      gradesFinGrade: data['gradesFinGra'] ?? '',
      gradesGraStat: data['gradesGraStat'] ?? '',
    );
  }
}
