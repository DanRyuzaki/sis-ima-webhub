import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/models/authModel.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/screens/admin/section2_content/section2_adduser.dart';
import 'package:sis_project/screens/admin/section2_content/section2_edituser.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class AdminSecondSection extends StatefulWidget {
  const AdminSecondSection({super.key});

  @override
  State<AdminSecondSection> createState() => _AdminSecondSectionState();
}

class _AdminSecondSectionState extends State<AdminSecondSection> {
  List<AuthModel> userDataFetch = [], userDataDeployed = [];
  bool isUserListLoaded = false, isHeaderClicked = false;
  String query = '';
  double sortBy = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  Future<void> _fetchUserList() async {
    try {
      final userCollection = FirebaseFirestore.instance.collection("entity");
      final querySnapshot = await userCollection.get();

      userDataFetch = querySnapshot.docs.map((doc) {
        return AuthModel(
          userID: doc.get("userID"),
          firstName: doc.get("userName00"),
          lastName: doc.get("userName01"),
          entityType: doc.get("entity"),
          userMail: doc.get("userMail"),
          userKey: doc.get("userKey"),
          userPhotoID: doc.get("userPhotoID"),
          lastSession: doc.get("lastSession"),
        );
      }).toList();

      setState(() {
        userDataDeployed = _filterUsers(query);
        isUserListLoaded = true;
      });

      useToastify.showLoadingToast(
          context, "Loaded", "Users fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(context, "Error", "Failed to fetch users.");
    }
  }

  List<AuthModel> _filterUsers(String query) {
    final filteredUsers = query.isEmpty
        ? userDataFetch
        : userDataFetch.where((user) {
            return user.userID.toLowerCase().contains(query.toLowerCase()) ||
                user.firstName.toLowerCase().contains(query.toLowerCase()) ||
                user.lastName.toLowerCase().contains(query.toLowerCase()) ||
                user.userMail.toLowerCase().contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredUsers.sort((a, b) => a.userID.compareTo(b.userID));
      case 0.5:
        filteredUsers.sort((a, b) => b.userID.compareTo(a.userID));
      case 1:
        filteredUsers.sort((a, b) => a.firstName.compareTo(b.firstName));
      case 1.5:
        filteredUsers.sort((a, b) => b.firstName.compareTo(a.firstName));
      case 2:
        filteredUsers.sort((a, b) => a.entityType.compareTo(b.entityType));
      case 2.5:
        filteredUsers.sort((a, b) => b.entityType.compareTo(a.entityType));
      case 3:
        filteredUsers.sort((a, b) => a.userMail.compareTo(b.userMail));
      case 3.5:
        filteredUsers.sort((a, b) => b.userMail.compareTo(a.userMail));
      case 4:
        filteredUsers.sort((a, b) => a.lastSession.compareTo(b.lastSession));
      case 4.5:
        filteredUsers.sort((a, b) => b.lastSession.compareTo(a.lastSession));
      default:
        filteredUsers.sort((a, b) => a.entityType.compareTo(b.entityType));
    }
    return filteredUsers.take(10).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      userDataDeployed = _filterUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 36, 66, 117),
        child:
            HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddUserDialog(
                onRefresh: _refreshUserList,
                userDataDeployed: userDataDeployed),
          );
        },
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshUserList,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DynamicSizeService.calculateWidthSize(context, 0.03),
            vertical: DynamicSizeService.calculateHeightSize(context, 0.02),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.03)),
              Text(
                "Manage Users",
                style: TextStyle(
                  fontSize: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.035),
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(200, 0, 0, 0),
                ),
              ),
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.01)),
              _buildSearchBar(),
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.05)),
              _buildTableHeader(),
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.02)),
              Expanded(
                child: isUserListLoaded
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: ScrollPhysics(),
                        itemCount: userDataDeployed.length,
                        itemBuilder: (context, index) {
                          final user = userDataDeployed[index];
                          return _buildTableRow(user);
                        },
                      )
                    : Center(
                        child: Text("Fetching users from the database...")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDDD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Find users through user ID, name, or email.",
          hintStyle: TextStyle(
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.015),
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: DynamicSizeService.calculateHeightSize(context, 0.02),
            horizontal: DynamicSizeService.calculateWidthSize(context, 0.05),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildTableHeader() {
    return Card(
      elevation: 0.5,
      color: Color.fromARGB(255, 253, 253, 253),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTableHeaderCell("USER_ID"),
            _buildTableHeaderCell("NAME"),
            _buildTableHeaderCell("ENTITY"),
            _buildTableHeaderCell("EMAIL"),
            _buildTableHeaderCell("PASSWORD"),
            _buildTableHeaderCell("LAST SESSION"),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isHeaderClicked == false)
            switch (text) {
              case 'USER_ID':
                sortBy = 0;
                isHeaderClicked = true;
                break;
              case 'NAME':
                sortBy = 1;
                isHeaderClicked = true;
                break;
              case 'ENTITY':
                sortBy = 2;
                isHeaderClicked = true;
                break;
              case 'EMAIL':
                sortBy = 3;
                isHeaderClicked = true;
                break;
              case 'LAST SESSION':
                sortBy = 4;
                isHeaderClicked = true;
                break;
            }
          else
            switch (text) {
              case 'USER_ID':
                sortBy = 0.5;
                isHeaderClicked = false;
                break;
              case 'NAME':
                sortBy = 1.5;
                isHeaderClicked = false;
                break;
              case 'ENTITY':
                sortBy = 2.5;
                isHeaderClicked = false;
                break;
              case 'EMAIL':
                sortBy = 3.5;
                isHeaderClicked = false;
                break;
              case 'LAST SESSION':
                sortBy = 4.5;
                isHeaderClicked = false;
                break;
            }

          // 👇 ADD THIS
          userDataDeployed = _filterUsers(query);
        });
      },
      child: SizedBox(
        width: DynamicSizeService.calculateWidthSize(context, 0.09),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.013),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(AuthModel user) {
    return InkWell(
        onTap: () {
          useToastify.showLoadingToast(
              context, 'Edit?', 'You may edit this segment by double tapping.');
        },
        onDoubleTap: () {
          if (user.entityType != 0)
            showDialog(
                context: context,
                builder: (context) => EditUserDialog(
                    onRefresh: _refreshUserList,
                    userDataDeployed: userDataDeployed,
                    user: user));
          else
            useToastify.showErrorToast(context, 'Oops!',
                'To modify admin\'s information, please seek your Hosting Engineer.');
        },
        child: Card(
            elevation: 0.5,
            color: Color.fromARGB(255, 253, 253, 253),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0)),
            child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTableRowCell(user.userID, 0),
                      _buildTableRowCell(
                          "${user.firstName} ${user.lastName}", 1),
                      _buildTableRowCell(_getEntityName(user.entityType), 2),
                      _buildTableRowCell(user.userMail, 3),
                      _buildTableRowCell(
                          user.userKey.replaceAll(RegExp(r'.'), '*'), 4),
                      _buildTableRowCell(
                          user.lastSession.toDate().toString(), 5),
                    ]))));
  }

  Widget _buildTableRowCell(String text, int type) {
    return SizedBox(
        width: DynamicSizeService.calculateWidthSize(context, 0.09),
        child: Text(text,
            style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: DynamicSizeService.calculateAspectRatioSize(
                    context, 0.013))));
  }

  String _getEntityName(double entityType) {
    switch (entityType) {
      case 0:
        return "Admin";
      case 1:
        return "Faculty";
      default:
        return "Student";
    }
  }

  Future<void> _refreshUserList() async {
    setState(() {
      isUserListLoaded = false;
      userDataFetch.clear();
      userDataDeployed.clear();
    });

    await _fetchUserList();
  }
}
