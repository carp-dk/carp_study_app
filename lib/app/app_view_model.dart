import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_study_app/features/connections/connection_view_model.dart';
import 'package:carp_study_app/features/onboarding/informed_consent_view_model.dart';
import 'package:carp_study_app/features/onboarding/invitations_view_model.dart';
import 'package:carp_study_app/features/onboarding/login_view_model.dart';
import 'package:carp_study_app/features/profile/profile_view_model.dart';
import 'package:carp_study_app/features/statistics/statistics_view_model.dart';
import 'package:carp_study_app/features/study/home_view_model.dart';
import 'package:carp_study_app/features/study/study_view_model.dart';
import 'package:carp_study_app/features/tasks/participant_data_view_model.dart';
import 'package:carp_study_app/features/tasks/task_list_view_model.dart';
import 'package:carp_study_app/shared/view_model.dart';

/// The root view model - owns one instance of every page view model and
/// forwards [init], [clear], and [dispose] to them.
class AppViewModel extends ViewModel {
  final HomePageViewModel _homePageViewModel = HomePageViewModel();
  final LoginViewModel _loginViewModel = LoginViewModel();
  final StatisticsViewModel _statisticsViewModel = StatisticsViewModel();
  final StudyPageViewModel _studyPageViewModel = StudyPageViewModel();
  final TaskListPageViewModel _taskListPageViewModel = TaskListPageViewModel();
  final ProfilePageViewModel _profilePageViewModel = ProfilePageViewModel();
  final ConnectionListPageViewModel _connectionListPageViewModel = ConnectionListPageViewModel();
  final InvitationsViewModel _invitationsListViewModel = InvitationsViewModel();
  final InformedConsentViewModel _informedConsentViewModel = InformedConsentViewModel();
  final ParticipantDataPageViewModel _participantDataPageViewModel = ParticipantDataPageViewModel();

  AppViewModel() : super();

  HomePageViewModel get homePageViewModel => _homePageViewModel;
  LoginViewModel get loginViewModel => _loginViewModel;
  StatisticsViewModel get statisticsViewModel => _statisticsViewModel;
  StudyPageViewModel get studyPageViewModel => _studyPageViewModel;
  TaskListPageViewModel get taskListPageViewModel => _taskListPageViewModel;
  ProfilePageViewModel get profilePageViewModel => _profilePageViewModel;
  ConnectionListPageViewModel get connectionListPageViewModel => _connectionListPageViewModel;
  InvitationsViewModel get invitationsListViewModel => _invitationsListViewModel;
  InformedConsentViewModel get informedConsentViewModel => _informedConsentViewModel;
  ParticipantDataPageViewModel get participantDataPageViewModel => _participantDataPageViewModel;

  @override
  void init(SmartphoneStudyController ctrl) {
    super.init(ctrl);
    _homePageViewModel.init(ctrl);
    _taskListPageViewModel.init(ctrl);
    _studyPageViewModel.init(ctrl);
    _statisticsViewModel.init(ctrl);
    _connectionListPageViewModel.init(ctrl);

    _profilePageViewModel.init(ctrl);
    _invitationsListViewModel.init(ctrl);
    _informedConsentViewModel.init(ctrl);
    _participantDataPageViewModel.init(ctrl);
  }

  @override
  void clear() {
    _homePageViewModel.clear();
    _taskListPageViewModel.clear();
    _studyPageViewModel.clear();
    _statisticsViewModel.clear();
    _connectionListPageViewModel.clear();

    _profilePageViewModel.clear();
    _informedConsentViewModel.clear();
    // so the invitation list is refetched after leaving a study
    _invitationsListViewModel.clear();

    super.clear();
  }

  @override
  void dispose() {
    _homePageViewModel.dispose();
    _taskListPageViewModel.dispose();
    _studyPageViewModel.dispose();
    _statisticsViewModel.dispose();
    _connectionListPageViewModel.dispose();

    _profilePageViewModel.dispose();
    _invitationsListViewModel.dispose();
    _informedConsentViewModel.dispose();

    super.dispose();
  }
}
