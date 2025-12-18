import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clipfile/components/custom_button.dart';
import 'package:clipfile/providers/discovery_provider.dart';

class DiscoveryButtonPage extends StatefulWidget {
  const DiscoveryButtonPage({super.key});

  @override
  State<DiscoveryButtonPage> createState() => _DiscoveryButtonPageState();
}

class _DiscoveryButtonPageState extends State<DiscoveryButtonPage> {
  @override
  Widget build(BuildContext context) {
    // Watch provider to update button states (labels or colors)
    final provider = context.watch<DiscoveryProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomButton(
          onPress: () async {
            if (provider.isScanning) {
              await provider.stopScanning();
            } else {
              await provider.startScanning();
            }
          },
          buttonText: provider.isScanning ? "Stop Scan" : "Scan",
          long: false,
        ),
        CustomButton(
          onPress: () async {
            if (provider.isAdvertising) {
              await provider.stopAdvertising();
            } else {
              await provider.startAdvertising();
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(provider.isAdvertising
                        ? "Advertising started"
                        : "Advertising stopped")),
              );
            }
          },
          buttonText: provider.isAdvertising ? "Stop Ad" : "Advertise",
          long: false,
        ),
      ],
    );
  }
}
