import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controllers/authController.dart';
import '../../Controllers/dataController.dart';
import '../../Controllers/appointmentController.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Set up animations
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // Navigate after animation
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    final AuthController authController = Get.find();
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (authController.isLoggedIn.value && authController.currentUser.value != null) {
        // Load data for logged-in user
        await Get.find<DataController>().loadData();
        await Get.find<AppointmentController>().loadAppointments();

        // Check user role and navigate accordingly
        final userRole = authController.currentUser.value?.role;
        if (userRole == 'staff') {
          Get.offAllNamed('/staff-navbar');
        } else {
          Get.offAllNamed('/navbar');
        }
      } else {
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/Logo.png",
                  width: 200,
                  height: 300,
                  color: Theme.of(context).colorScheme.secondary,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.store,
                    size: 100,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  "Barber Shop",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}