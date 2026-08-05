part of carp_study_app;

class ActivityCard extends StatefulWidget {
  final ActivityCardViewModel model;
  final List<Color> colors;
  const ActivityCard(this.model, {super.key, this.colors = const [Color(0xff7E9146), Color(0xff228B89), Color(0xff82CEE9)]});

  @override
  State<StatefulWidget> createState() => ActivityCardState();
}

class ActivityCardState extends State<ActivityCard> {
  final betweenSpace = 2.4;

  /// The weekday whose bar is selected, or null for the week as a whole.
  int? _selectedDay;

  /// The three activity types this card charts, bottom of the bar upwards.
  static const List<ActivityType> _types = [ActivityType.WALKING, ActivityType.RUNNING, ActivityType.ON_BICYCLE];

  /// Minutes of [type] on [weekday].
  num _minutesOn(ActivityType type, int weekday) => widget.model.activities[type]?[weekday] ?? 0;

  /// Minutes of [type] on the selected day, or across the week when none is.
  num _minutes(ActivityType type) => _selectedDay != null
      ? _minutesOn(type, _selectedDay!)
      : (widget.model.activities[type]?.values.fold<num>(0, (sum, minutes) => sum + minutes) ?? 0);

  num get _walk => _minutes(ActivityType.WALKING);
  num get _run => _minutes(ActivityType.RUNNING);
  num get _cycle => _minutes(ActivityType.ON_BICYCLE);

  /// The tallest stacked bar, so the axis has somewhere to end.
  num get _maxValue => List.generate(
    7,
    (index) => _types.fold<num>(0, (sum, type) => sum + _minutesOn(type, index + 1)),
  ).fold<num>(0, max);

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.white,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = null),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${_walk + _run + _cycle}',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey900),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      '${locale.translate('cards.activity.total.min')} ${_selectedDay != null ? _getDayName(_selectedDay!) : ''}',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "${widget.model.currentMonth} ${widget.model.startOfWeek} - ${int.parse(widget.model.endOfWeek) < int.parse(widget.model.startOfWeek) ? widget.model.nextMonth : widget.model.currentMonth} ${widget.model.endOfWeek}, ${widget.model.currentYear}",
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(
                height: 160,
                width: MediaQuery.of(context).size.width * 0.9,
                child: StreamBuilder(
                  stream: widget.model.activityEvents,
                  builder: (context, snapshot) {
                    return barCharts;
                  },
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text('$_walk', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.colors[0])),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                locale.translate('cards.activity.walking'),
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Theme.of(context).extension<CarpColors>()!.grey800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text('$_run', style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: widget.colors[1])),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                locale.translate('cards.activity.running'),
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Theme.of(context).extension<CarpColors>()!.grey800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('$_cycle', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.colors[2])),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          locale.translate('cards.activity.cycling'),
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Theme.of(context).extension<CarpColors>()!.grey800),
                        ),
                      ),
                    ],
                  ),
                ],
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
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: rightTitles, reservedSize: 48),
          ),
          topTitles: const AxisTitles(),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          // The totals above and below the chart already name the selected day.
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
        barGroups: [
          for (int weekday = 1; weekday <= 7; weekday++)
            generateGroupData(
              weekday,
              _minutesOn(ActivityType.WALKING, weekday),
              _minutesOn(ActivityType.RUNNING, weekday),
              _minutesOn(ActivityType.ON_BICYCLE, weekday),
            ),
        ],
        maxY: _maxValue * 1.2,
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

  BarChartGroupData generateGroupData(int x, num walking, num running, num cycling) {
    double roundness = 2;
    // Nothing selected means the week as a whole - every bar reads the same.
    bool isTouched = _selectedDay == null || _selectedDay == x;
    // Solid for the selected day, washed out for the rest.
    Color shade(Color color) => isTouched ? color : color.withValues(alpha: 0.3);

    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: walking + 0,
          color: shade(widget.colors[0]),
          width: 32,
          borderRadius: BorderRadius.all(Radius.circular(roundness)),
        ),
        BarChartRodData(
          fromY: walking + betweenSpace,
          toY: walking + betweenSpace + running,
          color: shade(widget.colors[1]),
          width: 32,
          borderRadius: BorderRadius.all(Radius.circular(roundness)),
        ),
        BarChartRodData(
          fromY: walking + betweenSpace + running + betweenSpace,
          toY: walking + betweenSpace + running + betweenSpace + cycling,
          color: shade(widget.colors[2]),
          width: 32,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
            bottomLeft: Radius.circular(roundness),
            bottomRight: Radius.circular(roundness),
          ),
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
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(letterSpacing: 1).copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
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
