import "package:clipfile/config.dart";
import "package:clipfile/providers/clip_data_provider.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart";
import "package:provider/provider.dart";

class ClipboardContainer extends StatelessWidget {
  const ClipboardContainer({super.key, required this.future});

  final Future<String> future;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        alignment: Alignment.topLeft,
        decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: EdgeInsets.all(23),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return LiquidPullToRefresh(
                  animSpeedFactor: 2,
                  onRefresh: () async {
                    var data = await Config().getData(context);
                    if (context.mounted) {
                      final reader = context.read<ClipDataProvider>();
                      reader.update(data);
                    }
                  },
                  color: Theme.of(context).primaryColor,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: SelectableText(
                        snapshot.data ?? "",
                        style: GoogleFonts.raleway(
                            color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(),
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ),
    );
  }
}
