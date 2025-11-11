part of carp_study_app;

class HorizontalBar extends StatelessWidget {
  final List<String> names;
  final List<int> values;
  final List<Color> colors;
  final OrderType? order;
  final double height;
  final LabelOrientation? labelOrientation;
  final double? parentWidth;

  const HorizontalBar({
    super.key,
    required this.names,
    required this.values,
    required this.colors,
    this.parentWidth,
    this.order = OrderType.descending,
    this.height = 25,
    this.labelOrientation = LabelOrientation.vertical,
  });

  List<MyAsset> assetList() {
    List<MyAsset> assetList = [];
    for (int i = 0; i < names.length; i++) {
      assetList.add(MyAsset(
          size: values.elementAt(i),
          color: colors.elementAt(i),
          name: names.elementAt(i)));
    }
    return assetList;
  }

  @override
  Widget build(BuildContext context) {
    double width = parentWidth ?? MediaQuery.of(context).size.width;

    if (names.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(height / 2)),
            child: Container(
              decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.tertiary),
              width: width,
              height: height,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: MyAssetsBar(
          width: width,
          background: const Color(0x00cfd8dc),
          order: order,
          assets: assetList(),
          height: height,
          labelOrientation: labelOrientation,
        ),
      );
    }
  }
}

enum OrderType { ascending, descending, none }

enum LabelOrientation { vertical, horizontal }

class MyAsset {
  final int? size;
  final Color? color;
  final String? name;

  MyAsset({this.size, this.color, this.name});
}

class MyAssetsBar extends StatelessWidget {
  const MyAssetsBar({
    super.key,
    required this.width,
    required this.height,
    required this.labelOrientation,
    this.radius,
    required this.assets,
    this.order,
    this.background = Colors.grey,
  });

  final double width;
  final double height;
  final double? radius;
  final List<MyAsset> assets;
  final OrderType? order;
  final Color background;
  final LabelOrientation? labelOrientation;

  double _getValuesSum() {
    double sum = 0;
    for (var single in assets) {
      sum += single.size!;
    }
    return sum;
  }

  void orderMyAssetsList() {
    switch (order) {
      case OrderType.ascending:
        {
          //From the smallest to the largest
          assets.sort((a, b) {
            return a.size!.compareTo(b.size!);
          });
          break;
        }
      case OrderType.descending:
        {
          //From largest to smallest
          assets.sort((a, b) {
            return b.size!.compareTo(a.size!);
          });
          break;
        }
      case OrderType.none:
      default:
        {
          break;
        }
    }
  }

  //single.size : assetsSum = x : width
  Widget _createSingle(MyAsset singleAsset) {
    return SizedBox(
      width: singleAsset.size! != 0
          ? singleAsset.size! * (width / _getValuesSum())
          : 0,
      child: Container(color: singleAsset.color),
    );
  }

  Widget _labelOrientation() {
    if (labelOrientation == LabelOrientation.horizontal) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: assets
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, color: entry.value.color, size: 12.0),
                      Text(' ${entry.value.name!} ${entry.value.size}',
                          style: fs12fw400, textAlign: TextAlign.right),
                    ],
                  )),
            )
            .toList(),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        primary: true,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.vertical,
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 1,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        childAspectRatio: 8,
        children: assets
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, color: entry.value.color, size: 12.0),
                      Text(' ${entry.value.size}',
                          style: fs12fw400, textAlign: TextAlign.left),
                      Expanded(
                          child: Text(' ${entry.value.name!}',
                              style: fs12fw400,
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  )),
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // order assetsList
    orderMyAssetsList();

    final double rad = radius ?? (height / 2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(rad)),
          child: Container(
            decoration: BoxDecoration(color: background),
            width: width,
            height: height,
            child: Row(
                children: assets
                    .map((singleAsset) => _createSingle(singleAsset))
                    .toList()),
          ),
        ),
        _labelOrientation(),
      ],
    );
  }
}
