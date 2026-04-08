import 'package:flutter/material.dart';
import '../config.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isCloud = AppConfig.isCloudReady;
    
    return Tooltip(
      message: isCloud ? "Cloud Sync Active" : "Local Storage Only",
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCloud ? const Color(0xFF39FF14) : Colors.amber,
          boxShadow: [
            if (isCloud)
              BoxShadow(
                color: const Color(0xFF39FF14).withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
      ),
    );
  }
}
