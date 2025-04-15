import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/SysLogModel.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:web_browser_detect/web_browser_detect.dart';

class AdminFourthSection extends StatefulWidget {
  const AdminFourthSection({super.key});

  @override
  State<AdminFourthSection> createState() => _AdminFourthSectionState();
}

class _AdminFourthSectionState extends State<AdminFourthSection> {
  List<SysLogModel> logDataFetch = [], LogDataDeployed = [];
  bool isLogListLoaded = false, isHeaderClicked = false;
  double sortBy = 0;
  String query = '';

  @override
  void initState() {
    super.initState();
    _fetchLogList();
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate =
        DateFormat("MMMM d, yyyy | EEEE | h:mm a 'UTC' Z").format(dateTime);

    return formattedDate;
  }

  Future<void> _fetchLogList() async {
    try {
      final logCollection =
          FirebaseFirestore.instance.collection("sysactivity");
      final syslogQS = await logCollection.get();

      logDataFetch = syslogQS.docs.map((doc) {
        return SysLogModel(
          log_id: doc.get("log_id"),
          log_user: doc.get("log_user"),
          log_entity: doc.get("log_entity"),
          log_activity: doc.get("log_activity"),
          log_agent: doc.get("log_agent"),
          log_date: doc.get("log_date"),
        );
      }).toList();

      setState(() {
        LogDataDeployed = _filterLog(query);
        isLogListLoaded = true;
      });

      useToastify.showLoadingToast(
          context, "Loaded", "System logs fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch system logs.");
      print(e);
    }
  }

  List<SysLogModel> _filterLog(String query) {
    final filteredLogs = query.isEmpty
        ? logDataFetch
        : logDataFetch.where((log) {
            return log.log_user.toLowerCase().contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredLogs.sort((a, b) => a.log_id.compareTo(b.log_id));
      case 0.5:
        filteredLogs.sort((a, b) => b.log_id.compareTo(a.log_id));
      case 1:
        filteredLogs.sort((a, b) => a.log_user.compareTo(b.log_user));
      case 1.5:
        filteredLogs.sort((a, b) => b.log_user.compareTo(a.log_user));
      case 2:
        filteredLogs.sort((a, b) => a.log_entity.compareTo(b.log_entity));
      case 2.5:
        filteredLogs.sort((a, b) => b.log_entity.compareTo(a.log_entity));
      case 3:
        filteredLogs.sort((a, b) => a.log_activity.compareTo(b.log_activity));
      case 3.5:
        filteredLogs.sort((a, b) => b.log_activity.compareTo(a.log_activity));
      case 4:
        filteredLogs.sort((a, b) => a.log_date.compareTo(b.log_date));
      case 4.5:
        filteredLogs.sort((a, b) => b.log_date.compareTo(a.log_date));
      default:
        filteredLogs.sort((a, b) => b.log_id.compareTo(a.log_id));
    }
    return filteredLogs.take(10).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      LogDataDeployed = _filterLog(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
            padding: EdgeInsets.symmetric(
                horizontal:
                    DynamicSizeService.calculateWidthSize(context, 0.03),
                vertical:
                    DynamicSizeService.calculateHeightSize(context, 0.02)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.03)),
              Text('System Monitor',
                  style: TextStyle(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                        context, 0.035),
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(200, 0, 0, 0),
                  )),
              _showTimeAndUserAgent(),
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.03)),
              _buildSearchBar(),
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.05)),
              _buildTableHeader(),
              SizedBox(
                  height:
                      DynamicSizeService.calculateHeightSize(context, 0.02)),
              Expanded(
                  child: isLogListLoaded
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          itemCount: LogDataDeployed.length,
                          itemBuilder: (context, index) {
                            final log = LogDataDeployed[index];
                            return _buildTableRow(log);
                          })
                      : Center(
                          child: Text(
                              "Fetching system logs from the database...")))
            ])));
  }

  Widget _showTimeAndUserAgent() {
    return Text(
        '${formatTimestamp(Timestamp.now())} | ${Browser().browser} ${Browser().version} ${Browser().runtimeType}',
        style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize:
                DynamicSizeService.calculateAspectRatioSize(context, 0.013)));
  }

  Widget _buildSearchBar() {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: const Color(0xFFFFEDDD),
            borderRadius: BorderRadius.circular(12)),
        child: TextField(
            decoration: InputDecoration(
                hintText: "Find logs through available queries.",
                hintStyle: TextStyle(
                    fontSize: DynamicSizeService.calculateAspectRatioSize(
                        context, 0.015)),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    vertical:
                        DynamicSizeService.calculateHeightSize(context, 0.02),
                    horizontal:
                        DynamicSizeService.calculateWidthSize(context, 0.05))),
            onChanged: _onSearchChanged));
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
            _buildTableHeaderCell("LOG_ID"),
            _buildTableHeaderCell("USER_ID"),
            _buildTableHeaderCell("ENTITY"),
            _buildTableHeaderCell("ACTIVITY"),
            _buildTableHeaderCell("USER AGENT"),
            _buildTableHeaderCell("TIMESTAMP")
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
              case 'LOG_ID"':
                sortBy = 0;
                isHeaderClicked = true;
                break;
              case 'USER_ID':
                sortBy = 1;
                isHeaderClicked = true;
                break;
              case 'ENTITY':
                sortBy = 2;
                isHeaderClicked = true;
                break;
              case 'ACTIVITY':
                sortBy = 3;
                isHeaderClicked = true;
                break;
              case 'USER AGENT':
                sortBy = 4;
                isHeaderClicked = true;
                break;
              case 'TIMESTAMP':
                sortBy = 5;
                isHeaderClicked = true;
                break;
            }
          else
            switch (text) {
              case 'LOG_ID':
                sortBy = 0.5;
                isHeaderClicked = false;
                break;
              case 'USER_ID':
                sortBy = 1.5;
                isHeaderClicked = false;
                break;
              case 'ENTITY':
                sortBy = 2.5;
                isHeaderClicked = false;
                break;
              case 'ACTIVITY':
                sortBy = 3.5;
                isHeaderClicked = false;
                break;
              case 'TIMESTAMP':
                sortBy = 4.5;
                isHeaderClicked = false;
                break;
              case 'USER AGENT':
                sortBy = 5.5;
                isHeaderClicked = false;
                break;
            }
          LogDataDeployed = _filterLog(query);
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

  Widget _buildTableRow(SysLogModel syslog) {
    return Card(
        elevation: 0.5,
        color: Color.fromARGB(255, 253, 253, 253),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTableRowCell('${syslog.log_id}', 0),
                  _buildTableRowCell(syslog.log_user, 1),
                  _buildTableRowCell(_getEntityName(syslog.log_entity), 2),
                  _buildTableRowCell(syslog.log_activity, 3),
                  _buildTableRowCell(syslog.log_agent, 4),
                  _buildTableRowCell(syslog.log_date.toDate().toString(), 5),
                ])));
  }

  Widget _buildTableRowCell(String text, int type) {
    return SizedBox(
        width: DynamicSizeService.calculateWidthSize(context, 0.09),
        child: SelectableText(text,
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
        return "Teacher";
      default:
        return "Student";
    }
  }
}
