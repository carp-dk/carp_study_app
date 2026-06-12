part of carp_study_app;

class ParticipantDataPageViewModel extends ViewModel {
  Set<ExpectedParticipantData?> get expectedData => bloc.study.expectedParticipantData;

  /// Save the participant [data] for the current study.
  void setParticipantData(Map<String, Data> data) => bloc.study.setParticipantData(data);

  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _streetController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  late TextEditingController _effectiveDateController;
  late TextEditingController _diagnosisDescriptionController;
  late TextEditingController _icd11CodeController;
  late TextEditingController _conclusionController;

  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;

  late TextEditingController _phoneNumberCodeController;
  late TextEditingController _phoneNumberController;

  late TextEditingController _ssnCountryController;
  late TextEditingController _ssnController;

  late FocusNode _address1FocusNode;
  late FocusNode _address2FocusNode;
  late FocusNode _streetFocusNode;
  late FocusNode _postalCodeFocusNode;
  late FocusNode _countryFocusNode;
  late FocusNode _effectiveDateFocusNode;
  late FocusNode _diagnosisDescriptionFocusNode;
  late FocusNode _icd11CodeFocusNode;
  late FocusNode _conclusionFocusNode;
  late FocusNode _firstNameFocusNode;
  late FocusNode _middleNameFocusNode;
  late FocusNode _lastNameFocusNode;

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

  late Set<TextEditingController> _nonOptionalControllers;
}
