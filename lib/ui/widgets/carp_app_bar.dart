part of carp_study_app;

class CarpAppBar extends StatelessWidget {
  final bool hasProfileIcon;
  const CarpAppBar({super.key, this.hasProfileIcon = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 8),
                    child: Image.asset(
                      'assets/carp_logo.png',
                      fit: BoxFit.contain,
                      height: 16,
                    ),
                  ),
                  if (hasProfileIcon)
                    IconButton(
                      icon: Icon(
                        Icons.account_circle,
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                      tooltip: 'Profile',
                      onPressed: () {
                        Navigator.push(context, SlidePageRoute(ProfilePage(ProfilePageViewModel())));
                      },
                    ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
