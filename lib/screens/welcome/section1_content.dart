import 'package:flutter/material.dart';
import 'package:sis_project/screens/welcome/multifunc_authenticate.dart';
import 'package:sis_project/services/dynamicsize_service.dart';
import 'package:sis_project/services/global_state.dart';
import 'package:provider/provider.dart';

class Section1Content extends StatefulWidget {
  const Section1Content({Key? key}) : super(key: key);

  @override
  _Section1ContentState createState() => _Section1ContentState();
}

class _Section1ContentState extends State<Section1Content> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.all(
                    DynamicSizeService.calculateAspectRatioSize(
                        context, 0.030)),
                child: Text("The Immaculate\nMother Academy Inc.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: DynamicSizeService.calculateAspectRatioSize(
                          context, 0.060),
                      fontWeight: FontWeight.bold,
                    ))),
            const Spacer(),
            Padding(
                padding: EdgeInsets.all(
                    DynamicSizeService.calculateAspectRatioSize(
                        context, 0.030)),
                child: SelectableText(
                    "${Provider.of<GlobalState>(context, listen: false).configAddr.value}\n${Provider.of<GlobalState>(context, listen: false).configCont.value}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: DynamicSizeService.calculateAspectRatioSize(
                          context, 0.014),
                      letterSpacing: 1.3,
                    )))
          ]),
      Expanded(
          child: AnimatedOpacity(
              opacity: Provider.of<GlobalState>(context).isVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: WidgetAuthenticate()))
    ]);
  }
}
