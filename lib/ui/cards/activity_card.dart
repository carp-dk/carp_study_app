part of carp_study_app;

class ActivityCard extends StatefulWidget {
  final ActivityCardViewModel model;
  final List<Color> colors;
  const ActivityCard(this.model, {super.key, this.colors = const [CACHET.CAQUI, CACHET.OCEAN, CACHET.BLUE_2]});

  @override
  State<StatefulWidget> createState() => ActivityCardState();
}

class ActivityCardState extends State<ActivityCard> {
  num? _walk = 0;
  num? _run = 0;
  num? _cycle = 0;

  num maxValue = 0;
  int touchedIndex = DateTime.now().weekday;

  final betweenSpace = 2.4;

  List<List<int>> activitiesList = List.generate(
    7,
    (_) => List.generate(4, (index) => index, growable: false),
    growable: false,
  );

  @override
  void initState() {
    _walk = widget.model.activities[ActivityType.WALKING]![DateTime.now().weekday];
    _run = widget.model.activities[ActivityType.RUNNING]![DateTime.now().weekday];
    _cycle = widget.model.activities[ActivityType.ON_BICYCLE]![DateTime.now().weekday];

    /// Doing some conversions to make the data readable by the chart
    /// The data is organized in a list of lists, where each list represents a day
    /// and each element in the list represents the time spent doing a specific
    /// activity.
    widget.model.activities.forEach((activityType, innerMap) {
      int idx;
      if (activityType == ActivityType.WALKING) {
        idx = 1;
      } else if (activityType == ActivityType.RUNNING) {
        idx = 2;
      } else if (activityType == ActivityType.ON_BICYCLE) {
        idx = 3;
      } else {
        return;
      }
      innerMap.forEach((weekday, time) {
        activitiesList[weekday - 1][0] = weekday; // Assign weekday at index 0
        activitiesList[weekday - 1][idx] = time;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.white!,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${_walk! + _run! + _cycle!}',
                  style: fs28fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey900!),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    '${locale.translate('cards.activity.total.min')} ${_getDayName(touchedIndex)}',
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
                          Text('$_walk', style: fs22fw700.copyWith(color: widget.colors[0])),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              locale.translate('cards.activity.walking'),
                              style: fs12fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey800),
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
                            child: Text('$_run', style: fs12fw700.copyWith(color: widget.colors[1])),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              locale.translate('cards.activity.running'),
                              style: fs12fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('$_cycle', style: fs22fw700.copyWith(color: widget.colors[2])),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        locale.translate('cards.activity.cycling'),
                        style: fs12fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
          enabled: false,
          touchCallback: (p0, p1) {
            setState(() {
              touchedIndex = (p1?.spot?.touchedBarGroupIndex ?? DateTime.now().weekday - 1) + 1;
            });
          },
        ),
        groupsSpace: 4,
        barGroups: activitiesList.map((e) => generateGroupData(e[0], e[1], e[2], e[3])).toList(),
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

  BarChartGroupData generateGroupData(int x, num walking, num running, num cycling) {
    double roundness = 2;
    bool isTouched = touchedIndex == x;
    maxValue = max(maxValue, walking + running + cycling);
    if (isTouched) {
      _walk = walking;
      _run = running;
      _cycle = cycling;
    }

    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: walking + 0,
          color: widget.colors[0].withValues(alpha: isTouched ? 0.8 : 1),
          width: 32,
          borderRadius: BorderRadius.all(Radius.circular(roundness)),
        ),
        BarChartRodData(
          fromY: walking + betweenSpace,
          toY: walking + betweenSpace + running,
          color: widget.colors[1].withValues(alpha: isTouched ? 0.8 : 1),
          width: 32,
          borderRadius: BorderRadius.all(Radius.circular(roundness)),
        ),
        BarChartRodData(
          fromY: walking + betweenSpace + running + betweenSpace,
          toY: walking + betweenSpace + running + betweenSpace + cycling,
          color: widget.colors[2].withValues(alpha: isTouched ? 0.8 : 1),
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
