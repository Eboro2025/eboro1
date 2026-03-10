
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:eboro/Providers/AllProviders.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/Widget/VIP.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VIPProvider extends StatefulWidget {
  final String? name, image;
  final int? id;
  VIPProvider({Key? key, required this.id, required this.name, required this.image}) : super(key: key);
  @override
  VIPProvider2  createState() => VIPProvider2();
}

class VIPProvider2 extends State <VIPProvider> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  bool _isButtonTapped = false;
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderController>(context);

    return Scaffold(
        appBar: AppBar(
            backgroundColor: myColor,
            centerTitle: true,
            title: Text(widget.name.toString(),  style: TextStyle( color: Colors.white, fontSize: MyApp2.H! *.03)),
            iconTheme: new IconThemeData(color: Colors.white)),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/icons/back.png'),
                fit: BoxFit.cover
            ),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (provider.providers!.firstWhereOrNull((element) => element.vip == 1 && element.state != '2') != null)
                  ...[
                    Center(
                      child: Container(
                        height: MyApp2.W! * 0.45,
                        child: ListView.builder(
                          physics: ClampingScrollPhysics(),
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: 1,
                          itemBuilder: (ctx, i) => VIP(),
                        ),
                      ),
                    ),
                  ],
                Center(
                    child: GestureDetector(
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CachedNetworkImage(
                              width: MyApp2.W! * .3,
                              height: MyApp2.W! * .3,
                              imageUrl: widget.image.toString(),
                              useOldImageOnUrlChange: true,
                              fit: BoxFit.fill,
                              progressIndicatorBuilder: (context, url, downloadProgress) =>
                                  CircularProgressIndicator(value: downloadProgress.progress),
                              errorWidget: (context, url, error) => Icon(Icons.error_outline, color: myColor,),
                              imageBuilder: (context, imageProvider) => Container(
                                  alignment: Alignment.topLeft,
                                  height: MediaQuery.of(context).size.height*.2,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(200.0)),
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                    ),
                                  )
                              ),
                            ),
                          ],
                        ),
                        onTap: () async{
                          if (!_isButtonTapped)
                          {
                            _isButtonTapped = true;
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AllProviders(catID: widget.id.toString(), name: widget.name)));
                            await provider.updateProvider(widget.id.toString());
                            _isButtonTapped = false;
                          }
                          else
                          {
                            // print("stop c");
                          }
                        }
                    )
                )
              ]
          ),
        )
    );
  }


}