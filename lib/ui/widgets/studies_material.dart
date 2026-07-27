part of carp_study_app;

/// A [Card] for this app that makes all cards looks the same.
class StudiesMaterial extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry margin;
  final ShapeBorder shape;
  final Clip? clipBehavior;
  final bool hasBorder;
  final bool hasBox;
  final Color backgroundColor;
  final Color borderColor;

  const StudiesMaterial({
    super.key,
    required this.child,
    this.elevation = 0,
    this.margin = const EdgeInsets.only(bottom: 16, left: 16, right: 16),
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
    this.clipBehavior,
    this.hasBorder = false,
    this.hasBox = false,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: margin,
      child: Container(
        // Soft "modern" shadow instead of Material elevation.
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: backgroundColor,
          elevation: elevation,
          shape: shape,
          clipBehavior: clipBehavior ?? Clip.hardEdge,
          child: Container(
            decoration: hasBorder
                ? BoxDecoration(
                    border: Border(left: BorderSide(color: borderColor, width: 4.0)),
                  )
                : hasBox
                ? BoxDecoration(
                    border: Border.all(color: CACHET.LIGHT_2, width: 1.0),
                    borderRadius: BorderRadius.circular(16.0),
                  )
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}
