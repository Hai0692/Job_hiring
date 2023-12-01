import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_job_hiring/controllers/JobController.dart';
import 'package:flutter_job_hiring/controllers/applycationController.dart';
import 'package:flutter_job_hiring/controllers/authentication.dart';
import 'package:flutter_job_hiring/pages/detailJob_screen.dart';
import 'package:flutter_job_hiring/widgets/background.dart';
import 'package:flutter_job_hiring/widgets/buttonBack.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../commons/color_common.dart';
import '../controllers/favoriteController.dart';
import '../providers/favorite_provider.dart';
import '../widgets/card_jobdetails.dart';
import '../widgets/customeBottom.dart';

class HistoryApplyPage extends StatefulWidget {
  const HistoryApplyPage({super.key});

  @override
  State<HistoryApplyPage> createState() => _HistoryApplyPageState();
}

class _HistoryApplyPageState extends State<HistoryApplyPage> {
  final Authentication authentication = Get.put(Authentication());
  final JobController jobController = Get.put(JobController());
  final FavoriteController favoriteController = Get.put(FavoriteController());
  List<Map<String, dynamic>>? dataJob;
  late String userToken;
  Future<void> getData() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    var token = pref.getString("token") ?? "";
    userToken = token;

    if (token.isNotEmpty) {
      final response = await ApplycationController().historyApply(token);
      if (response != null) {
        setState(() {
          dataJob = List<Map<String, dynamic>>.from(
              json.decode(response)["application_history"]);
        });
      }
      print("response: $response");
    }
  }

  @override
  void initState() {
    getData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var favoriteProvider = Provider.of<FavoriteProvider>(context);
    return Scaffold(
        body: Stack(children: [
          const Background(),
          Positioned(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20, top: 20),
                child: Button_Back(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  "History Apply",
                  style: GoogleFonts.poppins(
                      color: ColorApp().color_black,
                      fontSize: 25,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (dataJob == null) ...{
                const Center(child: CircularProgressIndicator())
              } else if (dataJob!.isEmpty) ...{
                const Center(
                  child: Text(
                    "No application found",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              } else ...{
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: dataJob!.length,
                    itemBuilder: (BuildContext context, int i) {
                      Map<String, dynamic> historyApply = dataJob![i];
                      Map<String, dynamic> jobDetails = historyApply["job"];
                      Map<String, dynamic> businessDetails =
                          jobDetails["business"];

                      return detailJob(
                        //    isInFavorites: favoriteProvider.isInFavorites,
                        id: jobDetails["id"],
                        avatar: businessDetails["avatar"].toString(),
                        company: businessDetails["name"].toString(),
                        level: jobDetails["level"].join(", "),
                        location: businessDetails["location"].toString(),
                        position: jobDetails["position"].toString(),
                        salary: jobDetails["salary"].toString(),
                        skill: jobDetails["skill"].join(", "),
                        type: jobDetails["type"].join(", "),
                        onPress: () async {
                          final response =
                              await jobController.jobDetails(jobDetails["id"]);
                          final result = jsonDecode(response);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DetailJob(data: result)));
                        },

                        onPressFavorite: () async {
                
                          bool isAlreadyInFavorites =
                              favoriteProvider.isInFavorites(jobDetails["id"]);
                    
                          try {
                            favoriteProvider.setInFavorites(
                                jobDetails["id"], !isAlreadyInFavorites);
                        

                            bool actionResult =
                                await favoriteController.manageFavorite(
                              userToken,
                              jobDetails["id"],
                              isAdd: !isAlreadyInFavorites,
                            );

                            if (actionResult) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAlreadyInFavorites
                                        ? 'Job removed from favorites'
                                        : 'Job added to favorites',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update favorites'),
                                ),
                              );
                            }
                          } catch (e) {
                            print("Error: $e");
                            favoriteProvider.setInFavorites(
                                jobDetails["id"], isAlreadyInFavorites);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'An error occurred. Please try again.'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              }
            ],
          ))
        ]),
        bottomNavigationBar: const Custome_Bottom());
  }
}
