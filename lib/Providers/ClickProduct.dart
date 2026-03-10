import 'package:eboro/API/Provider.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/Widget/ProductDetails.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class ClickProduct extends StatefulWidget {
  @override
  final int? productID;
  final String? name;
  ClickProduct({Key? key,  required this.productID, required this.name}) : super(key: key);
  ClickProduct2  createState() => ClickProduct2();
}

class ClickProduct2 extends State <ClickProduct> {
  int tab = 2;
  TextEditingController _name = new TextEditingController();
  TextEditingController _price = new TextEditingController();

  @override
  void initState() {
    super.initState();

    _name.text = widget.name ?? '';

    // البحث عن المنتج بشكل آمن
    try {
      final product = Provider2.product?.firstWhere(
        (item) => item.id.toString() == widget.productID.toString(),
      );
      _price.text = product?.price?.toString() ?? '0';
    } catch (_) {
      _price.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tab,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              if(tab == 2 ||tab == 3)
                Tab(icon: Text(AppLocalizations.of(context)!.translate("description"), style: TextStyle())),
              if(tab == 2 ||tab == 3)
                Tab(icon: Text(AppLocalizations.of(context)!.translate("details"), style: TextStyle())),
              if(tab == 3)
                Tab(icon: Text('Offer', style: TextStyle())),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black45,
          ),
          centerTitle: true,
          backgroundColor: myColor,
          title: Text(widget.name!, style: TextStyle( color: Colors.white, fontSize: MyApp2.H! *.03)),
          iconTheme: new IconThemeData(color: Colors.white),
          actions: [
            //CartTextWidget(),
            if(MyApp2.type == '1')
              IconButton(
                icon: Icon(FontAwesomeIcons.edit,
                  size: 20,
                ),
                onPressed: () {
                  showBottomSheet(context);
                },
              )
          ],
        ),
        body: Container(
          child: TabBarView(
            children: [
                Container(
                  child: ProductDetails(productID: widget.productID),
                ),
             /* if(tab == 2 ||tab == 3)
                Container(
                    child: ProductDescription(productID: widget.productID),
                  ),

              if(tab == 3)
                Container(
                  child: ProductMeal(productID: widget.productID),
                ),*/
            ],
          ),
        ),
      ),
    );
  }



  void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                cursorColor: myColor,
                controller: _name,
                style: TextStyle(
                  fontSize: MyApp2.fontSize16, color: Colors.grey,),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate("name") ,
                  hintStyle: TextStyle(fontSize: MyApp2.fontSize16,
                    color: Colors.grey,),
                  contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W! * .025, horizontal: MyApp2.W! * .025),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey,
                        width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),

              TextField(
                cursorColor: myColor,
                controller: _price,
                style: TextStyle(
                  fontSize: MyApp2.fontSize16, color: Colors.grey,),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate("price") ,
                  hintStyle: TextStyle(fontSize: MyApp2.fontSize16,
                    color: Colors.grey,),
                  contentPadding: new EdgeInsets.symmetric(vertical: MyApp2.W! * .025, horizontal: MyApp2.W! * .025),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey,
                        width: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),

              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MaterialButton(
                    padding: const EdgeInsets.all(10),
                    child: Text('${AppLocalizations.of(context)!.translate("cancel")}',
                      style: TextStyle(
                        fontSize: MyApp2.fontSize14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    color: myColor,
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  MaterialButton(
                    padding: const EdgeInsets.all(10),
                    child: Text(AppLocalizations.of(context)!.translate("save"),
                      style: TextStyle(
                        fontSize: MyApp2.fontSize14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    color: myColor,
                    textColor: Colors.white,
                    onPressed: () {
                      Provider2.editProduct(_name.text, _price.text, widget.productID.toString(), context);
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
