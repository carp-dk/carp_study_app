part of carp_study_app;

/// Which aggregation the heart rate chart shows.
enum HeartRateRange { day, week }

class HeartRateCardWidget extends StatefulWidget {
  final HeartRateCardViewModel model;
  const HeartRateCardWidget(this.model, {super.key});

  @override
  HeartRateCardWidgetState createState() => HeartRateCardWidgetState();
}

class HeartRateCardWidgetState extends State<HeartRateCardWidget> {
  HeartRateRange _range = HeartRateRange.day;

  /// The selected bar, dimming the rest. Stays put until another bar is tapped
  /// or the user taps away from the bars.
  int? _touched;

  /// The bands drawn as bars: one per hour of today, or one per day this week.
  Map<int, HeartRateMinMaxPrHour> get _bands =>
      _range == HeartRateRange.day ? widget.model.hourlyHeartRate : widget.model.dailyHeartRate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CarpColors>()!;

    return StudiesMaterial(
      backgroundColor: colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          stream: widget.model.heartRateStream,
          builder: (context, AsyncSnapshot<double> snapshot) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _rangeSummary(colors)),
                  _rangePicker(colors),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: _chart(colors)),
              const SizedBox(height: 12),
              _averageHeartRate(colors),
            ],
          ),
        ),
      ),
    );
  }

  /// The buckets that actually hold a reading - what the bars are drawn from,
  /// so a selection index means the same thing here as in the chart.
  List<MapEntry<int, HeartRateMinMaxPrHour>> get _measuredBands =>
      _bands.entries.where((entry) => entry.value.max != null).toList();

  /// The selected bar's band, or the range over everything on screen.
  Widget _rangeSummary(CarpColors colors) {
    final locale = RPLocalizations.of(context)!;
    final measuredBands = _measuredBands;
    final selected = _touched != null && _touched! < measuredBands.length ? measuredBands[_touched!] : null;

    final range =
        selected?.value ??
        (_range == HeartRateRange.day ? widget.model.dayMinMax : HeartRateCardViewModel.rangeOf(_bands.values));
    final measured = range.min != null && range.max != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected != null ? _label(selected.key) : locale.translate('cards.heartrate.range'),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colors.grey600),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(measured ? '${range.min!.toInt()} - ${range.max!.toInt()}' : '-', style: Theme.of(context).textTheme.headlineMedium!),
            if (measured) ...[
              const SizedBox(width: 6),
              Text(locale.translate('cards.heartrate.bpm'), style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colors.grey600)),
            ],
          ],
        ),
      ],
    );
  }

  /// A segmented day / week switch.
  Widget _rangePicker(CarpColors colors) {
    final locale = RPLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: colors.grey100, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final range in HeartRateRange.values)
            GestureDetector(
              onTap: () => setState(() => _range = range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _range == range ? colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  locale.translate('cards.heartrate.${range.name}'),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: _range == range ? colors.grey900 : colors.grey600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The average over what is on screen, spelled out rather than left as a
  /// bare number.
  Widget _averageHeartRate(CarpColors colors) {
    final locale = RPLocalizations.of(context)!;
    final average = HeartRateCardViewModel.averageOf(_bands.values);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.favorite, color: Theme.of(context).extension<CarpColors>()!.heartRate, size: 16),
        const SizedBox(width: 8),
        Text(locale.translate('cards.heartrate.average'), style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colors.grey600)),
        const Spacer(),
        Text(average != null ? average.toStringAsFixed(0) : '-', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: colors.grey900)),
        const SizedBox(width: 4),
        Text(locale.translate('cards.heartrate.bpm'), style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colors.grey600)),
      ],
    );
  }

  /// The y axis fitted to what is on screen - a fixed 0-200 leaves a resting
  /// heart rate as a flat band in the bottom quarter of the chart.
  ///
  /// Rounded out to whole tens with a little headroom, and always at least
  /// 40 BPM tall so a steady day does not get magnified into noise.
  (double, double, double) get _axis {
    final range = HeartRateCardViewModel.rangeOf(_bands.values);
    if (range.min == null || range.max == null) return (0, 200, 50);

    var low = max(0.0, ((range.min! - 10) / 10).floor() * 10.0);
    var high = ((range.max! + 10) / 10).ceil() * 10.0;
    if (high - low < 40) high = low + 40;

    // Four gridlines, on a whole-ten interval so the labels stay round.
    final interval = max(10.0, ((high - low) / 4 / 10).ceil() * 10.0);
    return (low, low + interval * 4, interval);
  }

  Widget _chart(CarpColors colors) {
    final (minY, maxY, interval) = _axis;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        minY: minY,
        maxY: maxY,
        groupsSpace: 4,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: _tooltip(colors),
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            setState(() => _touched = response?.spot?.touchedBarGroupIndex);
          },
        ),
        barGroups: [
          // Only measured buckets get a bar - a zero-height rod at y=0 would
          // sit outside the axis now that it no longer starts there.
          for (final (index, band) in _measuredBands.indexed)
            BarChartGroupData(
              x: band.key,
              barRods: [
                BarChartRodData(
                  fromY: band.value.min,
                  toY: band.value.max!,
                  // Dim the other bars while one is held, so the tooltip is
                  // clearly about this bar.
                  color: _touched == null || _touched == index
                      ? Theme.of(context).extension<CarpColors>()!.heartRate
                      : Theme.of(context).extension<CarpColors>()!.heartRate.withValues(alpha: 0.25),
                  width: _range == HeartRateRange.day ? 6 : 14,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: _bottomTitle),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: _rightTitle,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: interval,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: colors.grey300, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarTouchTooltipData _tooltip(CarpColors colors) {
    final locale = RPLocalizations.of(context)!;

    return BarTouchTooltipData(
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      tooltipMargin: 4,
      getTooltipColor: (_) => colors.grey900,
      getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
        '${_label(group.x)}\n',
        Theme.of(context).textTheme.labelSmall!.copyWith(color: colors.grey300),
        textAlign: TextAlign.left,
        children: [
          TextSpan(
            text: '${rod.fromY.toInt()}-${rod.toY.toInt()} ${locale.translate('cards.heartrate.bpm')}',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colors.white),
          ),
        ],
      ),
    );
  }

  /// What one bar covers: an hour of today, or a date this week.
  String _label(int x) =>
      _range == HeartRateRange.day ? '${x.toString().padLeft(2, '0')}:00' : DateFormat('dd/MM').format(_dateOf(x));

  /// The date of [weekday] in the current week.
  DateTime _dateOf(int weekday) {
    final today = DateTime.now();
    return today.subtract(Duration(days: today.weekday - weekday));
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final hour = value.toInt();
    // A label under every bar only fits for a week; a day gets one every 6h.
    if (_range == HeartRateRange.day && hour % 6 != 0) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        _range == HeartRateRange.day ? hour.toString().padLeft(2, '0') : DateFormat('dd/MM').format(_dateOf(hour)),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
      ),
    );
  }

  Widget _rightTitle(double value, TitleMeta meta) => SideTitleWidget(
    meta: meta,
    space: 6,
    child: Text(
      value.toInt().toString(),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
    ),
  );
}
