part of carp_study_app;

class BatteryPercentage extends StatelessWidget {
  const BatteryPercentage({
    super.key,
    required this.batteryLevel,
    this.scale = 1.0,
  }) : assert(batteryLevel >= 0 && batteryLevel <= 100, 'Battery level must be between 0 and 100');

  // Battery level from 0 to 100
  final int batteryLevel;
  // Scale of the battery icon
  final double scale;

  @override
  Widget build(BuildContext context) {
    double width = 25 * scale;
    double height = 12 * scale;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              border: Border.all(color: Theme.of(context).primaryColor)),
          width: width,
          height: height,
          child: Row(children: [
            SizedBox(
                width: batteryLevel != 0 ? batteryLevel * (width * 0.9 / 100) : 0,
                height: height * 0.75,
                child: Container(color: Theme.of(context).primaryColor)),
          ]),
        ),
      ),
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              border: Border.all(color: Theme.of(context).primaryColor)),
          width: 2,
          height: 4,
        ),
      ),
      const SizedBox(width: 4),
      Text("$batteryLevel%")
    ]);
  }
}
