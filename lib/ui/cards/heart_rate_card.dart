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

  /// The bands drawn as bars, oldest first: one per hour of the last 24h, or
  /// one per day of the last 7d. A bar's index is always its real distance
  /// from now, so position and time agree - no separate "which hours are
  /// measured" bookkeeping needed.
  List<(DateTime, HeartRateMinMaxPrHour)> get _bands => _range == HeartRateRange.day
      ? widget.model.hourlyHeartRate.map((b) => (b.hour, b.value)).toList()
      : widget.model.dailyHeartRate.map((b) => (b.date, b.value)).toList();

  @override
  Widget build(BuildContext context) {
    return StudiesMaterial(
      backgroundColor: Colors.white,
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
                  Expanded(child: _rangeSummary()),
                  _rangePicker(),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: _chart()),
              const SizedBox(height: 12),
              _averageHeartRate(),
            ],
          ),
        ),
      ),
    );
  }

  /// The selected bar's band, or the range over everything on screen.
  Widget _rangeSummary() {
    final locale = RPLocalizations.of(context)!;
    final bands = _bands;
    final selected = _touched != null && _touched! < bands.length ? bands[_touched!] : null;

    final range =
        selected?.$2 ??
        (_range == HeartRateRange.day
            ? widget.model.dayMinMax
            : HeartRateCardViewModel.rangeOf(bands.map((b) => b.$2)));
    final measured = range.min != null && range.max != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected != null ? _label(selected.$1) : locale.translate('cards.heartrate.range'),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              measured ? '${range.min!.toInt()} - ${range.max!.toInt()}' : '-',
              style: Theme.of(context).textTheme.headlineMedium!,
            ),
            if (measured) ...[
              const SizedBox(width: 6),
              Text(
                locale.translate('cards.heartrate.bpm'),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// A segmented day / week switch.
  Widget _rangePicker() {
    final locale = RPLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(100)),
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
                  color: _range == range ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  locale.translate('cards.heartrate.${range.name}'),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: _range == range ? Colors.grey.shade900 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The average over what is on screen, spelled out rather than left as a
  /// bare number.
  Widget _averageHeartRate() {
    final locale = RPLocalizations.of(context)!;
    final average = HeartRateCardViewModel.averageOf(_bands.map((b) => b.$2));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.favorite, color: const Color(0xffEB4B62), size: 16),
        const SizedBox(width: 8),
        Text(
          locale.translate('cards.heartrate.average'),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(average != null ? average.toStringAsFixed(0) : '-', style: Theme.of(context).textTheme.titleMedium!),
        const SizedBox(width: 4),
        Text(
          locale.translate('cards.heartrate.bpm'),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// The y axis fitted to what is on screen - a fixed 0-200 leaves a resting
  /// heart rate as a flat band in the bottom quarter of the chart.
  ///
  /// Rounded out to whole tens with a little headroom, and always at least
  /// 40 BPM tall so a steady day does not get magnified into noise.
  (double, double, double) get _axis {
    final range = HeartRateCardViewModel.rangeOf(_bands.map((b) => b.$2));
    if (range.min == null || range.max == null) return (0, 200, 50);

    var low = max(0.0, ((range.min! - 10) / 10).floor() * 10.0);
    var high = ((range.max! + 10) / 10).ceil() * 10.0;
    if (high - low < 40) high = low + 40;

    // Four gridlines, on a whole-ten interval so the labels stay round.
    final interval = max(10.0, ((high - low) / 4 / 10).ceil() * 10.0);
    return (low, low + interval * 4, interval);
  }

  Widget _chart() {
    final (minY, maxY, interval) = _axis;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        minY: minY,
        maxY: maxY,
        groupsSpace: 8,
        barTouchData: BarTouchData(
          enabled: true,
          // No tooltip - the range summary above the chart already shows the
          // selected bar's label and min-max bpm.
          touchTooltipData: noBarTooltip,
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            setState(() => _touched = response?.spot?.touchedBarGroupIndex);
          },
        ),
        barGroups: [
          // One group per hour/day in the window, in position order, so a
          // bar's index is its real distance from now - an unmeasured slot
          // simply has no rod, but still holds its place and its label.
          for (final (index, band) in _bands.indexed)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  // An unmeasured slot still needs a full-width rod, or the
                  // group collapses and spaceEvenly bunches up its label.
                  fromY: band.$2.min ?? minY,
                  toY: band.$2.max ?? minY,
                  // Dim the other bars while one is selected, so the range
                  // summary is clearly about this bar.
                  color: _touched == null || _touched == index
                      ? const Color(0xffEB4B62)
                      : const Color(0xffEB4B62).withValues(alpha: 0.25),
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // BarChart ignores SideTitles.interval - it always places one
              // title per bar group - so thinning has to happen in
              // getTitlesWidget itself, see _bottomTitle.
              getTitlesWidget: _bottomTitle,
            ),
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
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  /// What one bar covers: an hour, or a weekday - "Mon" fits where "19/08"
  /// does not, with seven of them side by side.
  String _label(DateTime x) =>
      _range == HeartRateRange.day ? '${x.hour.toString().padLeft(2, '0')}:00' : weekdayName(context, x.weekday);

  /// One label per bar in week view (7 bars, all fit); every 4th hour in
  /// day view (24 bars is too many for one label each).
  int get _labelStep => _range == HeartRateRange.day ? 4 : 1;

  Widget _bottomTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= _bands.length) return const SizedBox.shrink();
    if (index % _labelStep != 0) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        _label(_bands[index].$1),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _rightTitle(double value, TitleMeta meta) => SideTitleWidget(
    meta: meta,
    space: 6,
    child: Text(
      value.toInt().toString(),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.grey.shade600),
    ),
  );
}
