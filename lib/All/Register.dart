import 'package:eboro/Auth/Signin.dart';
import 'package:eboro/Auth/Signup.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Register extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Image.asset(
                "images/icons/logo.png",
                height:  MyApp2.H! *.3,
                width: MyApp2.W,
                alignment: AlignmentDirectional.center
              ),


              Container(
                  width: MyApp2.W! *.6,
                  child:MaterialButton(
                    padding: const EdgeInsets.only(top: 12.5, bottom: 12.5),
                    child: Text(
                      AppLocalizations.of(context)!.translate("signin"),
                      style: TextStyle(
                        fontSize: MyApp2.fontSize20,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    color: myColor,
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                      },
                  )
              ),

              SizedBox(height: 25,),

              Container(
                width: MyApp2.W! *.6,
                child:MaterialButton(
                  padding: const EdgeInsets.only(top: 12.5, bottom: 12.5),
                  child: Text(
                    AppLocalizations.of(context)!.translate("signup"),
                    style: TextStyle(
                      fontSize: MyApp2.fontSize20,
                    ),
                  ),
                  shape: OutlineInputBorder(
                    borderSide: BorderSide(color: myColor, width: 1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  textColor: myColor,
                  color: Colors.white,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
                  },
                )
              ),

              SizedBox(height: 25,),
              MaterialButton(
                  child: Text(
                      AppLocalizations.of(context)!.translate("terms"),
                      style: TextStyle(fontSize: MyApp2.fontSize14, color: Colors.black26, )
                  ),
                  onPressed: () {
                    launchUrlString("$globalUrl/privacy-app");
                  })

            ],
          ),
        ),
      ),
    );
  }
}
