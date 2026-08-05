part of carp_study_app;

class MobilityCard extends StatefulWidget {
  final List<Color> colors;

  final MobilityCardViewModel model;
  const MobilityCard(this.model, {super.key, this.colors = const [Color(0xff7E9146), Color(0xffEC6330), Color(0xffB2E1F2)]});

  @override
  State<MobilityCard> createState() => _MobilityCardState();
}

class _MobilityCardState extends State<MobilityCard> {
  int touchedIndex = DateTime.now().weekday;

  num _homestay = 0;
  num _places = 0;

  @override
  void initState() {
    _homestay = widget.model.weekData[DateTime.now().weekday]!.homeStay;
    _places = widget.model.weekData[DateTime.now().weekday]!.places;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('$_homestay%', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: widget.colors[0])),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    "${locale.translate('cards.mobility.homestay')} ${_getDayName(touchedIndex)}",
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  "${widget.model.currentMonth} ${widget.model.startOfWeek} - ${int.parse(widget.model.endOfWeek) < int.parse(widget.model.startOfWeek) ? widget.model.nextMonth : widget.model.currentMonth} ${widget.model.endOfWeek}, ${widget.model.currentYear}",
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Colors.grey.shade600),
                ),
                Spacer(),
              ],
            ),
            SizedBox(
              height: 160,
              width: MediaQuery.of(context).size.width * 0.9,
              child: StreamBuilder(
                stream: widget.model.mobilityEvents,
                builder: (context, snapshot) {
                  return barCharts;
                },
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Text('$_places', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.colors[0])),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        locale.translate('cards.mobility.places'),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Colors.grey.shade900),
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
        barGroups: barChartsGroups,
        maxY: 100,
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
    return widget.model.weekData.entries
        .map((e) => generateGroupData(e.key, e.value.homeStay, e.value.places))
        .toList();
  }

  BarChartGroupData generateGroupData(int x, int homestay, int places) {
    bool isTouched = touchedIndex == x;
    if (isTouched) {
      _homestay = homestay;
      _places = places;
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: places.toDouble(),
          color: widget.colors[1].withValues(alpha: isTouched ? 0.8 : 1),
          width: 16,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: homestay.toDouble(),
          color: widget.colors[0].withValues(alpha: isTouched ? 0.8 : 1),
          width: 16,
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

  Widget leftTitles(double value, TitleMeta meta) {
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
