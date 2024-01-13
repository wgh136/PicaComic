import 'package:flutter/material.dart';
import 'package:pica_comic/views/jm_views/jm_week_recommendation_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pic_views/collections_page.dart';

Widget buildRecommendation(String key) {
  switch (key) {
    case "picacg":
      MainPage.to(() => const CollectionsPage());
    case "jm":
      MainPage.to(() => JmWeekRecommendationPage());
  }
  throw UnimplementedError();
}
