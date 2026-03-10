import 'package:cached_network_image/cached_network_image.dart';
import 'package:eboro/API/Provider.dart';
import 'package:eboro/Helper/ProviderData.dart';
import 'package:eboro/Helper/ImageHelper.dart';
import 'package:eboro/RealTime/Provider/ProviderController.dart';
import 'package:eboro/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  @override
  Search2 createState() => Search2();
}

class Search2 extends State<Search> {
  static List type_id2 = [];
  static List vType = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProviderController>(context);
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Add this line to align items at the top
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: GestureDetector(
            onTap: () {
              // Clear filters when the "Clear Filters" icon is tapped
              setState(() {
                type_id2.clear();
                // Reset providers to the original list
                provider.updateScreen(Provider2.provider ?? []);
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 60.0,
                  width: 60.0,
                  decoration: BoxDecoration(
                    color: type_id2.isEmpty
                        ? Colors.red.withOpacity(0.1)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          type_id2.isEmpty ? Colors.red : Colors.grey.shade300,
                      width: type_id2.isEmpty ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: type_id2.isEmpty
                            ? Colors.red.withOpacity(0.3)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: type_id2.isEmpty ? 8 : 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        "images/icons/all.png",
                        fit: BoxFit.contain,
                        color: type_id2.isEmpty
                            ? Colors.red
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'All',
                  style: TextStyle(
                    color: type_id2.isEmpty ? Colors.red : Colors.grey.shade700,
                    fontSize: 13.0,
                    fontWeight:
                        type_id2.isEmpty ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: MyApp2.H! * 0.15, // Set a fixed height or adjust as needed
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: Provider2.type?.length ?? 0,
              itemBuilder: (context, index) {
                var item = Provider2.type![index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (!type_id2.contains(item.id)) {
                        type_id2.clear();
                        type_id2.add(item.id);

                        // Filter providers based on the selected type_id2 values
                        List<ProviderData> filteredProviders = [];
                        provider.providers?.forEach((filteredProvider) {
                          filteredProvider.type?.forEach((element) {
                            if (type_id2.contains(element.type?.id)) {
                              filteredProviders.add(filteredProvider);
                            }
                          });
                        });

                        provider.updateScreen(filteredProviders);
                        // print("${provider.filteredProviders?.length} asdsad");
                      } else {
                        type_id2.remove(item.id);

                        // Handle the case when type_id2 becomes empty
                        if (type_id2.isEmpty) {
                          provider.updateScreen(Provider2.provider ?? []);
                        } else {
                          // Filter providers based on the updated type_id2 values
                          List<ProviderData> filteredProviders = [];
                          provider.providers?.forEach((filteredProvider) {
                            filteredProvider.type?.forEach((element) {
                              if (type_id2.contains(element.type?.id)) {
                                filteredProviders.add(filteredProvider);
                              }
                            });
                          });
                          // Update Providers2.filteredProviders
                          provider.updateScreen(filteredProviders);
                        }
                      }
                    });
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 60.0,
                          width: 60.0,
                          decoration: BoxDecoration(
                            color: type_id2.contains(item.id)
                                ? Colors.red.withOpacity(0.1)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: type_id2.contains(item.id)
                                  ? Colors.red
                                  : Colors.grey.shade300,
                              width: type_id2.contains(item.id) ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: type_id2.contains(item.id)
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: type_id2.contains(item.id) ? 8 : 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: (item.image?.isEmpty ?? true)
                                  ? Image.asset("images/icons/logo.png",
                                      color: Colors.grey.shade400,
                                      fit: BoxFit.contain)
                                  : CachedNetworkImage(
                                      imageUrl: fixImageUrl(item.image),
                                      fit: BoxFit.contain,
                                      progressIndicatorBuilder:
                                          (context, url, downloadProgress) =>
                                              Center(
                                        child: CircularProgressIndicator(
                                          value: downloadProgress.progress,
                                          strokeWidth: 2,
                                          color: Colors.red,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Image.asset("images/icons/logo.png",
                                              color: Colors.grey.shade400),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "${item.type.toString()}",
                          style: TextStyle(
                            color: type_id2.contains(item.id)
                                ? Colors.red
                                : Colors.grey.shade700,
                            fontSize: 13.0,
                            fontWeight: type_id2.contains(item.id)
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
