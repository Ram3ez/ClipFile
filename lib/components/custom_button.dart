import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class CustomButton extends StatefulWidget {
  CustomButton({
    super.key,
    required this.onPress,
    required this.buttonText,
    required this.long,
    this.short = false,
    this.onLongPress,
  });

  final void Function() onPress;
  final void Function()? onLongPress;
  final String buttonText;
  final bool long;
  final bool short;
  double opacity = 1;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //borderRadius: BorderRadius.circular(25),
      onTap: widget.onPress,
      onLongPress: widget.onLongPress,
      onTapDown: (details) {
        setState(() {
          widget.opacity = 0.4;
        });
      },
      onTapUp: (details) {
        setState(() {
          widget.opacity = 1.0;
        });
      },
      onTapCancel: () {
        setState(() {
          widget.opacity = 1;
        });
      },
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 150),
        opacity: widget.opacity,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).secondaryHeaderColor,
            borderRadius: widget.short
                ? BorderRadius.circular(15)
                : BorderRadius.circular(25),
          ),
          width: widget.long
              ? MediaQuery.of(context).size.width * 0.9
              : widget.short
                  ? MediaQuery.of(context).size.width * 0.3
                  : MediaQuery.of(context).size.width * 0.4,
          height: widget.short ? 50 : 67,
          child: Center(
              child: Text(
            widget.buttonText,
            style: GoogleFonts.raleway(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
          )),
        ),
      ),
    );
  }
}
