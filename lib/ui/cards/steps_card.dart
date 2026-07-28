part of carp_study_app;

class StepsCardWidget extends StatefulWidget {
  final List<Color> colors;

  final StepsCardViewModel model;
  const StepsCardWidget(this.model, {super.key, this.colors = const [CACHET.ORANGE, CACHET.BLUE_2, CACHET.BLUE_3]});

  @override
  StepsCardWidgetState createState() => StepsCardWidgetState();
}

class StepsCardWidgetState extends State<StepsCardWidget> {
  num maxValue = 0;

  /// The weekday whose bar is selected, or null for the week as a whole.
  int? _selectedDay;

  /// The headline figure: the selected day, or the whole week when nothing is.
  num get _step => _selectedDay != null
      ? widget.model.weeklySteps[_selectedDay] ?? 0
      : widget.model.weeklySteps.values.fold(0, (sum, steps) => sum + steps);

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.white!,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = null),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$_step',
                        maxLines: 1,
                        style: fs28fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey900!),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      _selectedDay != null
                          ? '${locale.translate('cards.steps.steps')} ${_getDayName(_selectedDay!)}'
                          : locale.translate('cards.steps.per_week'),
                      style: fs12fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "${widget.model.currentMonth} ${widget.model.startOfWeek} - ${int.parse(widget.model.endOfWeek) < int.parse(widget.model.startOfWeek) ? widget.model.nextMonth : widget.model.currentMonth} ${widget.model.endOfWeek}, ${widget.model.currentYear}",
                    style: fs12fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(
                height: 160,
                width: MediaQuery.of(context).size.width * 0.9,
                child: StreamBuilder(
                  stream: widget.model.pedometerEvents,
                  builder: (context, snapshot) {
                    return barCharts;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChart get barCharts {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: bottomTitles, reservedSize: 20),
          ),
          leftTitles: const AxisTitles(),
          rightTitles: AxisTitles(
            // Wide enough for a five-digit step count without wrapping.
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: rightTitles, reservedSize: 60),
          ),
          topTitles: const AxisTitles(),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          // The count above the chart already names the selected day.
          touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => Colors.transparent),
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            final index = response?.spot?.touchedBarGroupIndex;
            setState(() => _selectedDay = index == null ? null : index + 1);
          },
        ),
        groupsSpace: 4,
        barGroups: barChartsGroups,
        maxY: (maxValue) * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: true, border: Border.all(width: 1, color: Colors.grey.withValues(alpha: 0.2))),
      ),
    );
  }

  List<BarChartGroupData> get barChartsGroups {
    return widget.model.weeklySteps.entries.map((e) => generateGroupData(e.key, e.value)).toList();
  }

  BarChartGroupData generateGroupData(int x, int step) {
    // Nothing selected means the week as a whole - every bar reads the same.
    bool isTouched = _selectedDay == null || _selectedDay == x;
    maxValue = max(maxValue, step);

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: step.toDouble(),
          // Solid for the selected day, washed out for the rest.
          color: isTouched ? widget.colors[1] : widget.colors[1].withValues(alpha: 0.3),
          width: 32,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget rightTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        value.toInt() % meta.appliedInterval == 0 ? value.toInt().toString() : '',
        style: fs14ls1.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
      ),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    return SideTitleWidget(
      meta: meta,
      child: Text(_getDayName(value.toInt()), style: style),
    );
  }

  String _getDayName(int dayIndex) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    switch (dayIndex) {
      case 1:
        return locale.translate("pages.data_viz.mon");
      case 2:
        return locale.translate("pages.data_viz.tue");
      case 3:
        return locale.translate("pages.data_viz.wed");
      case 4:
        return locale.translate("pages.data_viz.thu");
      case 5:
        return locale.translate("pages.data_viz.fri");
      case 6:
        return locale.translate("pages.data_viz.sat");
      case 7:
        return locale.translate("pages.data_viz.sun");
      default:
        return '';
    }
  }
}
