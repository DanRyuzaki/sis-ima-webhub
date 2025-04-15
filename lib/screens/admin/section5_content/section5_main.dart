import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sis_project/components/package_toastification.dart';
import 'package:sis_project/models/configModel.dart';
import 'package:sis_project/screens/admin/section5_content/section5_editconfig.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:web_browser_detect/web_browser_detect.dart';

class AdminFifthSection extends StatefulWidget {
  const AdminFifthSection({super.key});

  @override
  State<AdminFifthSection> createState() => _AdminFifthSectionState();
}

class _AdminFifthSectionState extends State<AdminFifthSection> {
  List<ConfigModel> configDataFetch = [], configDataDeployed = [];
  bool isConfigListLoaded = false, isHeaderClicked = false;
  double sortBy = 0;
  String query = '';

  @override
  void initState() {
    super.initState();
    _fetchConfigList();
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate =
        DateFormat("MMMM d, yyyy | EEEE | h:mm a 'UTC' Z").format(dateTime);

    return formattedDate;
  }

  Future<void> _fetchConfigList() async {
    try {
      final configCollection = FirebaseFirestore.instance.collection("config");
      final configQS = await configCollection.get();

      configDataFetch = configQS.docs.map((doc) {
        return ConfigModel(
            id: doc.get('id'),
            category: doc.get('category'),
            name: doc.get('name'),
            value: doc.get('value'));
      }).toList();

      setState(() {
        configDataDeployed = _filterConfig(query);
        isConfigListLoaded = true;
      });

      useToastify.showLoadingToast(
          context, "Loaded", "System logs fetched successfully.");
    } catch (e) {
      useToastify.showErrorToast(
          context, "Error", "Failed to fetch system logs.");
      print(e);
    }
  }

  List<ConfigModel> _filterConfig(String query) {
    final filteredConfigs = query.isEmpty
        ? configDataFetch
        : configDataFetch.where((config) {
            return config.category
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                config.name.toLowerCase().contains(query.toLowerCase()) ||
                config.value.toLowerCase().contains(query.toLowerCase());
          }).toList();

    switch (sortBy) {
      case 0:
        filteredConfigs.sort((a, b) => a.category.compareTo(b.category));
      case 0.5:
        filteredConfigs.sort((a, b) => b.category.compareTo(a.category));
      case 1:
        filteredConfigs.sort((a, b) => a.name.compareTo(b.name));
      case 1.5:
        filteredConfigs.sort((a, b) => b.name.compareTo(a.name));
      case 2:
        filteredConfigs.sort((a, b) => a.value.compareTo(b.value));
      case 2.5:
        filteredConfigs.sort((a, b) => b.value.compareTo(a.value));
      default:
        filteredConfigs.sort((a, b) => a.category.compareTo(b.category));
    }
    return filteredConfigs.take(10).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      this.query = query;
      configDataDeployed = _filterConfig(query);
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
              Text('Configuration Settings',
                  style: TextStyle(
                      fontSize: DynamicSizeService.calculateAspectRatioSize(
                          context, 0.035),
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(200, 0, 0, 0))),
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
                  child: isConfigListLoaded
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          itemCount: configDataDeployed.length,
                          itemBuilder: (context, index) {
                            final config = configDataDeployed[index];
                            return _buildTableRow(config);
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
                hintText: "Find config parameters through available queries.",
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
    final double categoryWidth =
        DynamicSizeService.calculateWidthSize(context, 0.2);
    final double nameWidth =
        DynamicSizeService.calculateWidthSize(context, 0.2);
    final double valueWidth =
        DynamicSizeService.calculateWidthSize(context, 0.35);

    return Card(
      elevation: 0.5,
      color: Color.fromARGB(255, 253, 253, 253),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            _buildTableHeaderCell("CATEGORY", categoryWidth),
            _buildTableHeaderCell("NAME", nameWidth),
            _buildTableHeaderCell("VALUE", valueWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: DynamicSizeService.calculateAspectRatioSize(context, 0.013),
        ),
      ),
    );
  }

  Widget _buildTableRow(ConfigModel config) {
    final double categoryWidth =
        DynamicSizeService.calculateWidthSize(context, 0.2);
    final double nameWidth =
        DynamicSizeService.calculateWidthSize(context, 0.2);
    final double valueWidth =
        DynamicSizeService.calculateWidthSize(context, 0.35);

    return InkWell(
        onTap: () => useToastify.showLoadingToast(context, 'Edit?',
            'To edit \'${config.name}\', double-tap this segment.'),
        onDoubleTap: () => showDialog(
            context: context,
            builder: (context) => EditConfigDialog(
                onRefresh: _refreshConfigList,
                configDataDeployed: configDataDeployed,
                config: config)),
        child: Card(
          elevation: 0.5,
          color: Color.fromARGB(255, 253, 253, 253),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                _buildTableRowCell(
                    config.category.trim().split('=')[1], categoryWidth),
                _buildTableRowCell(config.name, nameWidth),
                _buildTableRowCell(config.value, valueWidth),
              ],
            ),
          ),
        ));
  }

  Widget _buildTableRowCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: DynamicSizeService.calculateAspectRatioSize(context, 0.013),
        ),
      ),
    );
  }

  Future<void> _refreshConfigList() async {
    setState(() {
      isConfigListLoaded = false;
      configDataFetch.clear();
      configDataDeployed.clear();
    });

    await _fetchConfigList();
  }
}
