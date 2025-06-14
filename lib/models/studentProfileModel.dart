import 'package:cloud_firestore/cloud_firestore.dart';

class studentProfileModel {
  String? studentName00;
  String? studentName01;
  String? studentName02;
  String studentId;
  String entryYear;
  String enrolledClass;
  String address;
  Timestamp dateOfBirth;
  String religion;
  String contactNumber;
  String fatherName00;
  String fatherName01;
  String fatherName02;
  String fatherOccupation;
  String fatherContact;
  String motherName00;
  String motherName01;
  String motherName02;
  String motherOccupation;
  String motherContact;
  String guardianName00;
  String guardianName01;
  String guardianName02;
  String guardianOccupation;
  String guardianContact;
  String guardianRelation;
  bool birthCertificate;
  bool form137;

  studentProfileModel(
      {this.studentName00,
      this.studentName01,
      this.studentName02,
      required this.studentId,
      required this.entryYear,
      required this.enrolledClass,
      required this.address,
      required this.dateOfBirth,
      required this.religion,
      required this.contactNumber,
      required this.fatherName00,
      required this.fatherName01,
      required this.fatherName02,
      required this.fatherOccupation,
      required this.fatherContact,
      required this.motherName00,
      required this.motherName01,
      required this.motherName02,
      required this.motherOccupation,
      required this.motherContact,
      required this.guardianName00,
      required this.guardianName01,
      required this.guardianName02,
      required this.guardianOccupation,
      required this.guardianContact,
      required this.guardianRelation,
      required this.birthCertificate,
      required this.form137});

  factory studentProfileModel.fromMap(Map<String, dynamic> data) {
    return studentProfileModel(
      studentName00: data['studentName00'],
      studentName01: data['studentName01'],
      studentName02: data['studentName02'],
      studentId: data['studentId'] ?? 'N/A',
      entryYear: data['entryYear'] ?? 'N/A',
      enrolledClass: data['enrolledClass'],
      address: data['address'] ?? 'N/A',
      dateOfBirth: data['birthday'] ?? Timestamp.now(),
      religion: data['religion'] ?? 'N/A',
      contactNumber: data['contactNumber'] ?? 'N/A',
      fatherName00: data['fatherName00'] ?? 'N/A',
      fatherName01: data['fatherName01'] ?? 'N/A',
      fatherName02: data['fatherName02'] ?? 'N/A',
      fatherOccupation: data['fatherOccupation'] ?? 'N/A',
      fatherContact: data['fatherContact'] ?? 'N/A',
      motherName00: data['motherName00'] ?? 'N/A',
      motherName01: data['motherName01'] ?? 'N/A',
      motherName02: data['motherName02'] ?? 'N/A',
      motherOccupation: data['motherOccupation'] ?? 'N/A',
      motherContact: data['motherContact'] ?? 'N/A',
      guardianName00: data['guardianName00'] ?? 'N/A',
      guardianName01: data['guardianName01'] ?? 'N/A',
      guardianName02: data['guardianName02'] ?? 'N/A',
      guardianOccupation: data['guardianOccupation'] ?? 'N/A',
      guardianContact: data['guardianContact'] ?? 'N/A',
      guardianRelation: data['guardianRelationship'] ?? 'N/A',
      birthCertificate: (data['birthCertificate'] as bool?) ?? false,
      form137: (data['form137'] as bool?) ?? false,
    );
  }
}
