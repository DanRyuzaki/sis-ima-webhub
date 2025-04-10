import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sis_project/screens/welcome/widget_buildsectionheader.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:web/web.dart' as web;

class WidgetSectionSocials extends StatelessWidget {
  const WidgetSectionSocials({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: DynamicSizeService.calculateWidthSize(context, 1),
        height: DynamicSizeService.calculateHeightSize(context, 1) * 0.35,
        color: Colors.white,
        child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 30,
                horizontal:
                    DynamicSizeService.calculateWidthSize(context, 0.012)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  WidgetSectionHeader(title: "Follow Us"),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialCard(
                            HugeIcons.strokeRoundedFacebook01,
                            'Facebook',
                            'https://www.facebook.com/imacaloocan',
                            context),
                        _buildSocialCard(
                            HugeIcons.strokeRoundedInstagram,
                            'Instagram',
                            'https://www.instagram.com/imacaloocan',
                            context),
                        _buildSocialCard(
                            HugeIcons.strokeRoundedTwitterSquare,
                            'Twitter/X',
                            'https://www.x.com/imacaloocan',
                            context)
                      ])
                ])));
  }

  Widget _buildSocialCard(
      IconData icon, String title, String url, BuildContext context) {
    return Expanded(
        child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal:
                    DynamicSizeService.calculateWidthSize(context, 0.015)),
            child: InkWell(
                onTap: () => web.window.open(url, '_blank'),
                child: Card(
                    elevation: 9.0,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    child: Padding(
                        padding: EdgeInsets.all(
                            DynamicSizeService.calculateAspectRatioSize(
                                context, 0.013)),
                        child: Column(children: [
                          SizedBox(
                              height: DynamicSizeService.calculateHeightSize(
                                  context, 0.010)),
                          Row(children: [
                            Icon(icon,
                                size:
                                    DynamicSizeService.calculateAspectRatioSize(
                                        context, 0.045)),
                            SizedBox(
                                width: DynamicSizeService.calculateWidthSize(
                                    context, 0.015)),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: DynamicSizeService
                                              .calculateAspectRatioSize(
                                                  context, 0.018),
                                          color: Color.fromARGB(
                                              250, 13, 46, 102))),
                                  SizedBox(
                                      height: DynamicSizeService
                                          .calculateHeightSize(context, 0.003)),
                                  SizedBox(
                                      width:
                                          DynamicSizeService.calculateWidthSize(
                                              context, 0.030),
                                      child: Divider(
                                          thickness: 2.5,
                                          color: Color.fromARGB(
                                              250, 13, 46, 102))),
                                  SizedBox(
                                      height: DynamicSizeService
                                          .calculateHeightSize(context, 0.003)),
                                  Text(url,
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                        color: Color.fromARGB(191, 0, 0, 0),
                                        fontSize: DynamicSizeService
                                            .calculateAspectRatioSize(
                                                context, 0.012),
                                      )),
                                  SizedBox(
                                      height: DynamicSizeService
                                          .calculateHeightSize(context, 0.010))
                                ]))
                          ])
                        ]))))));
  }
}
