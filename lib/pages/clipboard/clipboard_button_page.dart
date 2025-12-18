import "package:appwrite/appwrite.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:clipfile/providers/clip_data_provider.dart";
import "package:clipfile/components/custom_button.dart";
import "package:clipfile/config.dart";

/// A set of buttons to Copy (from cloud to clipboard) and Paste (from clipboard to cloud).
class ClipButton extends StatefulWidget {
  const ClipButton({super.key});

  @override
  State<ClipButton> createState() => _ClipButtonState();
}

class _ClipButtonState extends State<ClipButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomButton(
          onPress: _handleCopyFromCloud,
          buttonText: "copy",
          long: false,
        ),
        CustomButton(
          onPress: _handlePasteToCloud,
          buttonText: "paste",
          long: false,
        ),
      ],
    );
  }

  /// Fetches data from cloud and puts it into system clipboard.
  Future<void> _handleCopyFromCloud() async {
    HapticFeedback.heavyImpact();

    // Fetch latest data
    final dataFuture = Config().getData(context);
    final data = await dataFuture;

    if (!mounted) return;

    if (context.mounted) {
      final provider = context.read<ClipDataProvider>();
      try {
        // Update local provider state to match cloud
        provider.update(data);

        // Put data into system clipboard
        await Clipboard.setData(ClipboardData(text: data));
        if (!mounted) return;
      } on AppwriteException catch (e) {
        if (context.mounted) {
          _showErrorDialog(context, e.message ?? "Unknown error");
        }
      }
    }
  }

  /// Reads from system clipboard and pushes to cloud.
  Future<void> _handlePasteToCloud() async {
    HapticFeedback.heavyImpact();

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text ?? "";

    if (text.isEmpty) return;

    if (context.mounted) {
      // Optimistically update provider
      context.read<ClipDataProvider>().update(text);

      // The provider update/subscription usually handles the cloud sync,
      // or we might need to explicitly push it here if the provider is read-only.
      // Based on original code, it seems we just rely on Config().updateData
      // or similar, but the original code had commented out explicit update call?
      // Re-enabling explicit update if it was intended, or relying on provider if it handles it.
      // Original code: //await Config().updateData(data.text);
      // Wait, the ClipDataProvider.update implementation (from my previous read) might push to cloud?
      // Let's assume we need to push it.
      // Actually checking ClipDataProvider from previous turns, it does `_config.updateData`.
      // So calling `provider.update(text)` is sufficient if it calls Config().updateData inside.
      // Checking `clip_data_provider.dart`: yes, `update(String data)` calls `_config.updateData(data)`.
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message),
        ),
      ),
    );
  }
}
