import "package:clipfile/config.dart";
import "package:clipfile/providers/clip_data_provider.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart";
import "package:provider/provider.dart";

/// A widget that displays clipboard content with pull-to-refresh functionality.
class ClipboardContainer extends StatelessWidget {
  const ClipboardContainer({super.key, required this.future});

  final Future<String> future;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        alignment: Alignment.topLeft,
        decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(23),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FutureBuilder<String>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildContent(context, snapshot.data ?? "");
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String data) {
    return LiquidPullToRefresh(
      animSpeedFactor: 2,
      onRefresh: () async => _handleRefresh(context),
      color: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.5,
          child: SelectableText(
            data,
            style: GoogleFonts.raleway(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    // Only refresh if context is valid
    if (!context.mounted) return;

    var data = await Config().getData(context);
    if (context.mounted) {
      context.read<ClipDataProvider>().update(data);
    }
  }
}
