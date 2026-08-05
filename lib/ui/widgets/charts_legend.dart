part of carp_study_app;

/// Ordered palette for multi-series charts and their legends.
const List<Color> kChartColors = <Color>[
  Color(0xFF7FC9E3),
  Color(0xFFEB4B62),
  Color(0xFF2192C9),
  Color(0xFF809AE5),
  Color(0xFF630A1A),
  Color(0xFF1282B0),
  Color(0xFFC052A2),
  Color(0xFFBA0022),
  Color(0xFF6FB4E9),
  Color(0xFFA379CE),
  Color(0xFFCA2366),
];

class ChartsLegend extends StatelessWidget {
  final Icon? iconAssetName;
  final String title;
  final List<String> values;
  final String? heroTag;
  final List<Color> colors;

  const ChartsLegend({
    super.key,
    this.heroTag,
    this.iconAssetName,
    required this.title,
    this.values = const [],
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: Theme.of(context).textTheme.bodyLarge!.copyWith(letterSpacing: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: values
                        .asMap()
                        .entries
                        .map(
                          (entry) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(Icons.circle, color: colors[entry.key], size: 12.0),
                              Text(' ${entry.value} ', style: Theme.of(context).textTheme.bodySmall!),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
