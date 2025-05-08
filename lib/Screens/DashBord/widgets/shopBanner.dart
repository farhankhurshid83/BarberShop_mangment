import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ShopBannerWidget extends StatelessWidget {
  const ShopBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final GetStorage storage = GetStorage();
    final String shopName = storage.read('shopName') ?? 'My Barber Shop';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Shop Logo
          SizedBox(
            width: 70,
            height: 70,
            child: ClipOval(
              child: Image.asset(
                'assets/images/Logo.png', // Replace with your logo path
                fit: BoxFit.contain,
                color: Colors.black,
                errorBuilder: (context, error, stackTrace) =>  Icon(
                  Icons.store,
                  size: 30,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Shop Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}