import 'package:flutter/material.dart';
import 'package:sis_project/services/dynamicsize_service.dart';

class WidgetSectionHeader extends StatelessWidget {
  final String title;

  const WidgetSectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
            top: DynamicSizeService.calculateHeightSize(context, 0.010),
            left: DynamicSizeService.calculateWidthSize(context, 0.010),
            right: DynamicSizeService.calculateWidthSize(context, 0.010)),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: DynamicSizeService.calculateAspectRatioSize(
                      context, 0.015),
                  child: Divider(thickness: 1.5, color: Colors.grey)),
              Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: DynamicSizeService.calculateWidthSize(
                          context, 0.009)),
                  child: Text(title,
                      style: TextStyle(
                          fontSize: DynamicSizeService.calculateAspectRatioSize(
                              context, 0.019),
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 74, 208)))),
              const Expanded(child: Divider(thickness: 1.5, color: Colors.grey))
            ]));
  }
}
