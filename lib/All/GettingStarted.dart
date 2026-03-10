import 'dart:async';
import 'package:eboro/All/Register.dart';
import 'package:eboro/app_localizations.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class GettingStartedScreen extends StatefulWidget {
  @override
  _GettingStartedScreenState createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentPage < 4) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 50, bottom: 50),
        height: MyApp2.H,
        width: MyApp2.W,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: <Widget>[
                  PageView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: slideList.length,
                    itemBuilder: (ctx, i) => SlideItem(i),
                  ),
                  Stack(
                    alignment: AlignmentDirectional.topStart,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(bottom: 30),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            for (int i = 0; i < slideList.length; i++)
                              if (i == _currentPage)
                                SlideDots(true)
                              else
                                SlideDots(false)
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            Container(
                width: MyApp2.W! * .8,
                child: MaterialButton(
                  child: Text(
                    "${AppLocalizations.of(context)!.translate("Getstarted")}",
                    style: TextStyle(
                      fontSize: MyApp2.fontSize18,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.all(10),
                  color: myColor,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => Register()));
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class Slide {
  final String? imageUrl;
  final String? title;
  final String? description;

  Slide({
    this.imageUrl,
    this.title,
    this.description,
  });
}

final slideList = [
  Slide(),
  Slide(),
  Slide(),
  Slide(),
  Slide(),
];

class SlideDots extends StatefulWidget {
  bool isActive;
  SlideDots(this.isActive);

  @override
  State<SlideDots> createState() => _SlideDotsState();
}

class _SlideDotsState extends State<SlideDots> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: widget.isActive ? MyApp2.W! * .022 : MyApp2.W! * .015,
      width: widget.isActive ? MyApp2.W! * .1 : MyApp2.W! * .05,
      decoration: BoxDecoration(
        color:
            widget.isActive ? Theme.of(context).primaryColorDark : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
    );
  }
}

class SlideItem extends StatelessWidget {
  final int index;
  SlideItem(this.index);

  @override
  Widget build(BuildContext context) {
    final slideList = [
      Slide(
        imageUrl: 'images/icons/getstartedrestaurant.png',
        title: AppLocalizations.of(context)!.translate("restaurant"),
        description: '',
      ),
      Slide(
        imageUrl: 'images/icons/getstartedstores.png',
        title: AppLocalizations.of(context)!.translate("store"),
        description: '',
      ),
      Slide(
        imageUrl: 'images/icons/getstartedpharmacy.png',
        title: AppLocalizations.of(context)!.translate("pharmacy"),
        description: '',
      ),
      Slide(
        imageUrl: 'images/icons/getstartedsupermarket.png',
        title: AppLocalizations.of(context)!.translate("supermarket"),
        description: '',
      ),
      Slide(
        imageUrl: 'images/icons/getstartedparty.png',
        title: AppLocalizations.of(context)!.translate("party"),
        description: '',
      ),
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          height: MyApp2.W! * .3,
          width: MyApp2.W! * .3,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("${slideList[index].imageUrl}"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(
          height: MyApp2.W! * .05,
        ),
        Text(
          "${slideList[index].title}",
          style: TextStyle(
            fontSize: MyApp2.fontSize26,
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        SizedBox(
          height: MyApp2.W! * .05,
        ),
        Text(
          "${slideList[index].description}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: myColor2,
            fontSize: MyApp2.fontSize14,
          ),
        ),
      ],
    );
  }
}
