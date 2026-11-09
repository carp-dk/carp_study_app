part of carp_study_app;

class StepsCardWidget extends StatefulWidget {
  final List<Color> colors;

  final StepsCardViewModel model;
  const StepsCardWidget(
    this.model, {
    super.key,
    this.colors = const [Color(0xffEC6330), Color(0xff82CEE9), Color(0xffB2E1F2)],
  });

  @override
  StepsCardWidgetState createState() => StepsCardWidgetState();
}

class StepsCardWidgetState extends State<StepsCardWidget> {
  num maxValue = 0;

  /// Steps for the trailing 7 days, oldest first - today is always last.
  List<DailySteps> get _days => widget.model.steps;

  /// The index (into [_days]) of the bar selected, or null for the week as a whole.
  int? _selectedIndex;

  /// The headline figure: the selected day, or the whole week when nothing is.
  num get _step => _selectedIndex != null ? _days[_selectedIndex!].steps : _days.fold(0, (sum, day) => sum + day.steps);

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: Colors.white,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = null),
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
                      child: Text('$_step', maxLines: 1, style: Theme.of(context).textTheme.headlineMedium!),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      _selectedIndex != null
                          ? '${locale.translate('cards.steps.steps')} ${weekdayName(context, _days[_selectedIndex!].date.weekday)}'
                          : locale.translate('cards.steps.per_week'),
                      style: Theme.of(context).textTheme.labelSmall!
                          .copyWith(fontWeight: FontWeight.w700)
                          .copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    weekRangeLabel(),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Colors.grey.shade600),
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
          touchTooltipData: noBarTooltip,
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            setState(() => _selectedIndex = response?.spot?.touchedBarGroupIndex);
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
    return _days.indexed.map((e) => generateGroupData(e.$1, e.$2.steps)).toList();
  }

  BarChartGroupData generateGroupData(int index, int step) {
    // Nothing selected means the week as a whole - every bar reads the same.
    bool isTouched = _selectedIndex == null || _selectedIndex == index;
    maxValue = max(maxValue, step);

    return BarChartGroupData(
      x: index,
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
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(letterSpacing: 1).copyWith(color: Colors.grey.shade600),
      ),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final index = value.toInt();
    if (index < 0 || index >= _days.length) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      child: Text(weekdayName(context, _days[index].date.weekday), style: style),
    );
  }
}
