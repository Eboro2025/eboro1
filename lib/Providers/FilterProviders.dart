import 'package:eboro/Widget/FilterProvider.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';

class FilterProviders extends StatefulWidget {
  final String? catID;
  final String? name;

  const FilterProviders({
    Key? key,
    required this.catID,
    required this.name,
  }) : super(key: key);

  @override
  FilterProviders2 createState() => FilterProviders2();
}

class FilterProviders2 extends State<FilterProviders> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If you want to use catID here, you can call API or Provider
    // Example:
    // final provider = Provider.of<ProviderController>(context, listen: false);
    // provider.filterByCategory(widget.catID);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: myColor,
          centerTitle: true,
          title: Text(
            widget.name ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: MyApp2.H! * .03,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            // Separate search button - enable later if needed
            // IconButton(
            //   icon: const Icon(Icons.search),
            //   onPressed: () {},
            // ),
          ],
        ),

        // ===== Page body =====
        body: Column(
          children: [
            // Optional search field above the list
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Cerca in questa sezione...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  // Here you can connect search with Provider / FilterProvider
                  // For example:
                  // final provider = Provider.of<ProviderController>(context, listen: false);
                  // provider.searchInFilter(value);
                },
              ),
            ),

            // The rest is scrollable: FilterProvider
            Expanded(
              child: FilterProvider(),
            ),
          ],
        ),
      ),
    );
  }
}
