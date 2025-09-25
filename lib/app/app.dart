import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';
import '../presentation/seller/auth/login_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_controller.dart';
import '../presentation/shared/widgets/navbar.dart';

class InstagramCheckoutApp extends StatelessWidget {
  const InstagramCheckoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure navigationController is put only once
    final navController = Get.put(NavigationController());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram Checkout',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isInitialized) {
              return _buildLoadingScreen();
            }

            if (authProvider.error?.contains('service unavailable') ?? false) {
              return _buildErrorScreen(authProvider.error!, () => authProvider.clearError());
            }

            if (authProvider.isAuthenticated && authProvider.currentUser != null) {
              return Obx(() => IndexedStack(
                index: navController.selectedIndex.value,
                children: NavigationController.screens,
              ));
            }
            return const LoginScreen();
          },
        ),
        bottomNavigationBar: const Navbar(),
      ),
    );
  }

  Widget _buildLoadingScreen() => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/loading.json',
              width: 120,
              height: 120,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Setting up your account...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorScreen(String error, VoidCallback onRetry) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/error_icon.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Service Unavailable',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: Text(
                      error.length > 200 ? '${error.substring(0, 200)}...' : error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Add option to continue offline or with limited functionality
                    },
                    child: const Text(
                      'Continue with limited functionality',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}