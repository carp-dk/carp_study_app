import 'package:flutter/material.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_study_app/features/tasks/participant_data_page.dart';
import 'package:carp_study_app/shared/view_model.dart';
import 'package:carp_study_app/main.dart';

/// View model for [ParticipantDataPage] - the participant data the study
/// expects, written back to the deployment when filled in.
class ParticipantDataPageViewModel extends ViewModel {
  Set<ExpectedParticipantData?> get expectedData => bloc.study.expectedParticipantData;

  /// Save the participant [data] for the current study.
  void setParticipantData(Map<String, Data> data) => bloc.study.setParticipantData(data);

  late TextEditingController address1Controller;
  late TextEditingController address2Controller;
  late TextEditingController streetController;
  late TextEditingController postalCodeController;
  late TextEditingController countryController;

  late TextEditingController effectiveDateController;
  late TextEditingController diagnosisDescriptionController;
  late TextEditingController icd11CodeController;
  late TextEditingController conclusionController;

  late TextEditingController firstNameController;
  late TextEditingController middleNameController;
  late TextEditingController lastNameController;

  late TextEditingController phoneNumberCodeController;
  late TextEditingController phoneNumberController;

  late TextEditingController ssnCountryController;
  late TextEditingController ssnController;

  late FocusNode address1FocusNode;
  late FocusNode address2FocusNode;
  late FocusNode streetFocusNode;
  late FocusNode postalCodeFocusNode;
  late FocusNode countryFocusNode;
  late FocusNode effectiveDateFocusNode;
  late FocusNode diagnosisDescriptionFocusNode;
  late FocusNode icd11CodeFocusNode;
  late FocusNode conclusionFocusNode;
  late FocusNode firstNameFocusNode;
  late FocusNode middleNameFocusNode;
  late FocusNode lastNameFocusNode;

  late StepField address1Field;
  late StepField address2Field;
  late StepField streetField;
  late StepField postalCodeField;
  late StepField countryField;
  late StepField effectiveDateField;
  late StepField diagnosisDescriptionField;
  late StepField icd11CodeField;
  late StepField conclusionField;
  late StepField firstNameField;
  late StepField middleNameField;
  late StepField lastNameField;
  late StepField phoneNumberField;
  late StepField ssnField;

  late Set<TextEditingController> nonOptionalControllers;
}
