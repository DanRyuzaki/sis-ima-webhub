class ManageSubjectModel {
  final String subjectId;
  final String subjectName;
  final String subjectDepartment;
  final String subjectDescription;

  ManageSubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectDepartment,
    required this.subjectDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectDepartment': subjectDepartment,
      'subjectDescription': subjectDescription,
    };
  }

  factory ManageSubjectModel.fromJson(Map<String, dynamic> json) {
    return ManageSubjectModel(
      subjectId: json['subjectId'],
      subjectName: json['subjectName'],
      subjectDepartment: json['subjectDepartment'],
      subjectDescription: json['subjectDescription'],
    );
  }
}
