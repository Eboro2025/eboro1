/*
import 'package:eboro/API/Provider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:eboro/app_localizations.dart';

class Filter extends StatefulWidget {
  final String? catID, name;
  Filter({Key? key, required this.catID, required this.name}) : super(key: key);

  @override
  Filter2 createState() => Filter2();
}

class Filter2 extends State <Filter> {

  List <String> order2 = [
    'Near_Me',
    'Top_Rate',
    'Time',];

  List <String> offers2 = [
    'All_offers',
    'BITM',
    'Free_Delivery',
    'Free_Items',
    'Halal'];

  List <String> order = [
    'Near Me',
    'Top Rated',
    'Time'];

  List <String> offers = [
    'All offers',
    'Best in month',
    'Free Delivery',
    'Free Items',
    'Halal'];

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: myColor,
            centerTitle: true,
            title: Text(AppLocalizations.of(context)!.translate("Filter"),  style: TextStyle( color: Colors.white, fontSize: MyApp2.H! *.03)),
            iconTheme: new IconThemeData(color: Colors.white),
            actions: [
              Container(
                padding: EdgeInsets.all(20),
                  child: GestureDetector(
                child: Text(
                  'Reset'
                ),
                onTap: () {
                  setState(() {
                    type_id2.clear();
                    vType.clear();
                  });
                },
              ))
            ]
        ),
      body: Center(
        child: Column(children: [
          Expanded(child:
      ListView(
        children: [
          Container(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                AppLocalizations.of(context)!.translate("order"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: myColor2,
                  fontSize: 24,
                ),
              )
          ),
          GridView.count(
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 5,
            mainAxisSpacing: 20.0,
            crossAxisSpacing: 4.0,
            shrinkWrap: true,
            children: _getOrder(),
          ),
          Container(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child:Text(
                AppLocalizations.of(context)!.translate("Offers"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: myColor2,
                  fontSize: 24,
                ),
              )),
          GridView.count(
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 5,
            mainAxisSpacing: 20.0,
            crossAxisSpacing: 4.0,
            shrinkWrap: true,
            children: _getOffers(),
          ),
          Container(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child:Text(
                AppLocalizations.of(context)!.translate("Types"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: myColor2,
                  fontSize: 24,
                ),
              )),
          GridView.count(
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 4,
            mainAxisSpacing: 20.0,
            crossAxisSpacing: 4.0,
            shrinkWrap: true,
            children: _getTypes(),
          ),
        ],
      )),
          Container(
            width: MyApp2.W! * .5,
            child: MaterialButton(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Show',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MyApp2.H! *.023,
                ),),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              color: myColor,
              textColor: Colors.white,
              onPressed: () {
                Provider2.showFilter(widget.catID, widget.name, context);
              },
            ),),
        ])
    )),
    );
  }

  List<Widget> _getOrder() {
    final List<Widget> tiles = <Widget>[];
    for(int i = 0; i<order.length; i++){
      tiles.add(new GestureDetector(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: vType.contains(order2[i]) ? myColor : Colors.white,
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(color: vType.contains(order2[i]) ? myColor : Colors.grey)
          ),
          child: Text(
              AppLocalizations.of(context)!.translate(order2[i].toString()),

            style: TextStyle(
              color: vType.contains(order2[i]) ? Colors.white : Colors.grey,
              fontSize: MyApp2.H! *.023,

            ),
          ),
        ),onTap: () {
        if (!vType.contains(order2[i])) {
          setState(() {
            vType.add(order2[i]);
          });
        } else {
          setState(() {
            vType.remove(order2[i]);
          });
        }
      },));
    }
    return tiles;
  }

  List<Widget> _getOffers() {
    final List<Widget> tiles = <Widget>[];
    for(int i = 0; i<offers.length; i++){
      tiles.add(new GestureDetector(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: vType.contains(offers2[i]) ? myColor : Colors.white,
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(color: vType.contains(offers2[i]) ? myColor : Colors.grey)
          ),
          child: Text(
              AppLocalizations.of(context)!.translate(offers2[i].toString()),
            style: TextStyle(
              color: vType.contains(offers2[i]) ? Colors.white : Colors.grey,
              fontSize: MyApp2.H! *.023,
            ),
          ),
        ),onTap: () {
        if (!vType.contains(offers2[i])) {
          setState(() {
            vType.add(offers2[i]);
          });
        } else {
          setState(() {
            vType.remove(offers2[i]);
          });
        }
      },));
    }
    return tiles;
  }

  List<Widget> _getTypes() {
    final List<Widget> tiles = <Widget>[];
    ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: Provider2.type?.length ?? 0,
      itemBuilder: (context, index) {
        var item = Provider2.type![index];
        return GestureDetector(
          onTap: () {
            setState(() {
              if (!type_id2.contains(item.id)) {
                type_id2.add(item.id);
              } else {
                type_id2.remove(item.id);
              }
            });

          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 50.0,
                  width: 50.0,
                  decoration: BoxDecoration(
                    color: type_id2.contains(item.id) ? myColor : Colors.white,
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                      color: type_id2.contains(item.id) ? myColor : Colors.grey,
                    ),
                  ),
                  child: Icon(
                    Icons.check, // Replace with your icon or use item.icon if available
                    color: type_id2.contains(item.id) ? Colors.white : Colors.grey,
                    size: 30.0,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  item.type.toString(),
                  style: TextStyle(
                    color: type_id2.contains(item.id) ? Colors.white : Colors.grey,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return tiles;
  }


}*/
