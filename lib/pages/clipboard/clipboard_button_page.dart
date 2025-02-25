import "package:appwrite/appwrite.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:clipfile/providers/clip_data_provider.dart";
import "package:clipfile/components/custom_button.dart";
import "package:clipfile/config.dart";

// ignore: must_be_immutable
class ClipButton extends StatefulWidget {
  ClipButton({super.key});

  late Future<String> clipData;

  @override
  State<ClipButton> createState() => _ClipButtonState();
}

class _ClipButtonState extends State<ClipButton> {
  @override
  void initState() {
    super.initState();
    widget.clipData = Config().getData(context);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomButton(
          onPress: () async {
            HapticFeedback.heavyImpact();
            widget.clipData = Config().getData(context);
            var data = await widget.clipData;
            if (context.mounted) {
              final reader = context.read<ClipDataProvider>();
              try {
                reader.update(data);
              } on AppwriteException catch (e) {
                showDialog(
                    context: context,
                    builder: (context) => Dialog(
                          child: Text(e.message!),
                        ));
              }
            }
            Clipboard.setData(ClipboardData(text: data));
          },
          buttonText: "copy",
          long: false,
        ),
        CustomButton(
          onPress: () async {
            HapticFeedback.heavyImpact();
            var data = await Clipboard.getData(Clipboard.kTextPlain);
            widget.clipData = Future.value(data!.text);
            //await Config().updateData(data.text);
            if (context.mounted) {
              final updater = context.read<ClipDataProvider>();
              updater.update(data.text!);
            }

            //ClipDataState().update(data.text ?? "");
          },
          buttonText: "paste",
          long: false,
        ),
      ],
    );
  }
}
