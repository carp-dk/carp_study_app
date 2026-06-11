part of carp_study_app;

class MediaCardWidget extends StatefulWidget {
  final List<TaskCardViewModel> modelsList;
  final List<Color> colors;
  const MediaCardWidget(this.modelsList, {super.key, this.colors = CACHET.COLOR_LIST});
  @override
  MediaCardWidgetState createState() => MediaCardWidgetState();
}

class MediaCardWidgetState extends State<MediaCardWidget> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    var total = 0;
    for (var element in widget.modelsList) {
      total += element.tasksDone;
    }

    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.white!,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Column(
              children: [
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 5),
                          Text('$total MEDIA', style: fs16fw400ls1),
                          Column(
                            children: widget.modelsList
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 15),
                                      Text(
                                        '${entry.value.tasksDone} ${locale.translate('cards.${entry.value.taskType}.title')}',
                                        style: fs16fw400ls1.copyWith(fontSize: 14),
                                      ),
                                      LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                        return HorizontalBar(
                                            parentWidth: constraints.maxWidth,
                                            names: entry.value.taskCount
                                                .map((task) => locale.translate(task.title))
                                                .toList(),
                                            values: entry.value.taskCount.map((task) => task.size).toList(),
                                            colors: CACHET.COLOR_LIST,
                                            height: 18);
                                      }),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
