import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../presentation/seller/dashboard/dashboard_screen.dart';
import '../presentation/seller/orders/orders_screen.dart';
import '../presentation/seller/products/products_screen.dart';
import '../presentation/seller/products/add_product_screen.dart';

class NavigationController extends GetxController {
  static final List<Widget> screens = [
    const DashboardScreen(),
    const OrdersScreen(),
    const ProductsScreen(),
    const AddProductScreen(),
  ];

  final selectedIndex = 0.obs;
  final navbarOffset = 0.0.obs;

  double _lastScrollPosition = 0.0;

  void changeIndex(int index) {
    if (selectedIndex.value != index) {
      selectedIndex.value = index;
      showNavbar();
    }
  }

  void handleScroll(double currentPosition) {
    final delta = currentPosition - _lastScrollPosition;
    if (delta < -5) {
      showNavbar();
    } else if (delta > 5 && currentPosition > 100) {
      hideNavbar();
    }
    _lastScrollPosition = currentPosition;
  }

  void hideNavbar() => navbarOffset.value = 100; // slide down by 100
  void showNavbar() => navbarOffset.value = 0;
}
