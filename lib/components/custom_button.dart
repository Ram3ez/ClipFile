import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

/// A customizable button with an animated opacity effect on press.
class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.onPress,
    required this.buttonText,
    required this.long,
    this.short = false,
    this.onLongPress,
  });

  final VoidCallback onPress;
  final VoidCallback? onLongPress;
  final String buttonText;
  final bool long;
  final bool short;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    // Calculate width based on flags
    final double width = widget.long
        ? MediaQuery.of(context).size.width * 0.9
        : widget.short
            ? MediaQuery.of(context).size.width * 0.3
            : MediaQuery.of(context).size.width * 0.4;

    final double height = widget.short ? 50 : 67;

    return GestureDetector(
      onTap: widget.onPress,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _opacity = 0.4),
      onTapUp: (_) => setState(() => _opacity = 1.0),
      onTapCancel: () => setState(() => _opacity = 1.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _opacity,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).secondaryHeaderColor,
            borderRadius: BorderRadius.circular(widget.short ? 15 : 25),
          ),
          child: Center(
            child: Text(
              widget.buttonText,
              style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
