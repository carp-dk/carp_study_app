part of carp_study_app;

class StudyProgressCardWidget extends StatefulWidget {
  final StudyProgressCardViewModel model;

  final List<Color> colors;
  const StudyProgressCardWidget(
    this.model, {
    super.key,
    this.colors = const [CACHET.BLUE_1, CACHET.RED_1, CACHET.GREY_6],
  });

  @override
  StudyProgressCardWidgetState createState() => StudyProgressCardWidgetState();
}

class StudyProgressCardWidgetState extends State<StudyProgressCardWidget> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    widget.model.updateProgress();
    return StudiesMaterial(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder(
          stream: widget.model.userTaskEvents,
          builder: (context, AsyncSnapshot<UserTask> snapshot) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[Text(locale.translate('cards.study_progress.title'), style: Theme.of(context).textTheme.bodyLarge!.copyWith(letterSpacing: 1))],
                  ),
                ),
                SizedBox(
                  height: 130,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                widget.model.progress.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        widget.model.progress[index].value.toString(),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: widget.colors[index],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        locale.translate(widget.model.progress[index].state),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Circular Progress Representation
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18, right: 24.0),
                            child: SizedBox(
                              width: 104,
                              height: 104,
                              child: CustomPaint(
                                painter: TaskProgressPainter(
                                  values: widget.model.progress.map((p) => p.value).toList(),
                                  colors: widget.colors,
                                  faintColors: widget.colors.map((c) => c.withValues(alpha: 0.2)).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TaskProgressPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  final List<Color> faintColors;
  final double pi = 3.141592;

  TaskProgressPainter({required this.values, required this.colors, required this.faintColors});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset center = Offset(centerX, centerY);
    final double maxRadius = size.width / 2;
    final double ringWidth = maxRadius / 3;

    int totalTasks = values.reduce((a, b) => a + b);
    if (totalTasks == 0) return;

    List<double> percentages = values.map((v) => v / totalTasks).toList();

    Paint blackCircle = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // this -2 is to match the ring width of the other rings
    canvas.drawCircle(center, maxRadius + ringWidth - 2, blackCircle);

    for (int i = 0; i < 3; i++) {
      // i * 2 is the space between the rings
      double radius = maxRadius - (i * ringWidth) - i * 2;
      double sweepAngle = 2 * pi * percentages[i];
      Paint paintFill = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      Paint paintBackground = Paint()
        ..color = faintColors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      // draw the arc as a percentage of the full circle
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi / 2,
        sweepAngle > 0 ? sweepAngle : pi * (percentages[i] + 0.01),
        false,
        paintFill,
      );

      // draw a full circle as a background with a faint color
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, 2 * pi, false, paintBackground);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
