import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class ClipboardContainer extends StatelessWidget {
  const ClipboardContainer({super.key, required this.future});

  final Future<String> future;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 20,
        child: Container(
          margin: EdgeInsets.all(20),
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: Theme.of(context).secondaryHeaderColor,
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.all(23),
          child: FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SelectableText(
                  snapshot.data ?? "",
                  style: GoogleFonts.raleway(color: Colors.white, fontSize: 20),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(),
                child: AspectRatio(
                  aspectRatio: 16 / 20,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
