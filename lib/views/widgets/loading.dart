import 'package:flutter/material.dart';

Widget showLoading(BuildContext context, {bool withScaffold=false}){
  if(withScaffold){
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }else{
    return Stack(
      children: [
        Positioned(child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text(""),
            ),
          ],
        )),
        const Center(
          child: CircularProgressIndicator(),
        )
      ],
    );
  }
}