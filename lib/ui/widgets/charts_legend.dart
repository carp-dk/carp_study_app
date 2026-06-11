part of carp_study_app;

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
                Text(title.toUpperCase(), style: fs16fw400ls1),
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
                              Text(' ${entry.value} ', style: fs12fw400),
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
