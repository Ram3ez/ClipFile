import 'package:clipfile/config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImagePreview {
  static void imagePreview(
      BuildContext context, String fileID, String fileName) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).secondaryHeaderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 20,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        fileName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FutureBuilder(
                        future: Config().getImage(fileID),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.connectionState ==
                                  ConnectionState.done) {
                            return Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                clipBehavior: Clip.antiAlias,
                                child: Image.memory(
                                  fit: BoxFit.cover,
                                  snapshot.data!,
                                ),
                              ),
                            );
                          } else {
                            return Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                        }),
                  ],
                )),
          );
        });
  }
}
