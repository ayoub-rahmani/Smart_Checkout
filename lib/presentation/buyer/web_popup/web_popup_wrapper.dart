// presentation/buyer/web_popup/web_popup_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'product_popup_page.dart';

class WebPopupWrapper extends StatelessWidget {
  const WebPopupWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Checkout',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ProductPopupPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void configureApp() {
  setUrlStrategy(PathUrlStrategy());
}