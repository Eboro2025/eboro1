import 'dart:async';
import 'package:eboro/API/Auth.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class EmailVerification extends StatefulWidget {
@override
EmailVerification2  createState() => EmailVerification2();
}

class EmailVerification2 extends State <EmailVerification> {
  String currentText = "";
  final _pinController = PinInputController();
  late Timer _timer;
  int _start = 0;

  void startTimer() {
    _start = 180;
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pinController.dispose();
    super.dispose();
  }
//mFkDUL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myColor,
        iconTheme: new IconThemeData(color: Colors.white),
        title: Text(AppLocalizations.of(context)!.translate("emailVerification"), style: TextStyle( color: Colors.white, fontSize: MyApp2.fontSize20)),
      ),

      body: Container(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 0, bottom: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialPinField(
              length: 6,
              pinController: _pinController,
              autoFocus: true,
              theme: MaterialPinTheme(
                shape: MaterialPinShape.outlined,
                cellSize: Size(MyApp2.W! * .125, MyApp2.W! * .125),
                spacing: 8,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderWidth: 1,
                focusedBorderWidth: 2,
                borderColor: Color(0xFFCBCBCB),
                focusedBorderColor: myColor,
                filledBorderColor: myColor,
                textStyle: TextStyle(fontSize: MyApp2.fontSize20, color: myColor2, height: 1.6),
              ),
              onCompleted: (v) {
                setState(() {
                  Auth2.verifyEmail(v, context);
                });
              },
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(left: 0, right: 0, top: 50, bottom: 0),
                  child: Text(
                      '${AppLocalizations.of(context)!.translate("dReceiveAnyCode")}',
                      style: TextStyle(fontSize: MyApp2.fontSize22, color: Color(0xFFCBCBCB), )
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                GestureDetector(
                  child: Text(
                      _start == 0 ? AppLocalizations.of(context)!.translate("resendCode"):"Pleas wait $_start",
                      style: TextStyle(fontSize: MyApp2.fontSize16, color: myColor)
                  ),
                  onTap: () {
                    if(_start == 0)
                    {
                      startTimer();
                      Auth2.resendVerifyEmail(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
