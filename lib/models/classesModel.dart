class classSubjectModel {
  final String classCode;
  final String classSubjectCode;
  final String classClassSubjectCode;
  final String classSubject;
  final String classDepartment;
  final String classProgram;
  final String classLevel;
  final String classSection;
  final int classEnrolled;
  final String teacherId;
  classSubjectModel(
      {required this.classCode,
      required this.classSubjectCode,
      required this.classClassSubjectCode,
      required this.classSubject,
      required this.classDepartment,
      required this.classProgram,
      required this.classLevel,
      required this.classSection,
      required this.classEnrolled,
      required this.teacherId});
}
