import 'dart:async';
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart' show warning;
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/features/tasks/participant_data_view_model.dart';
import 'package:carp_study_app/shared/widgets/carp_app_bar.dart';

enum ParticipantStep {
  presentTypes,
  address,
  diagnosis,
  fullName,
  phoneNumber,
  socialSecurityNumber,
  sex,
  language,
  occupation,
  educationalDegree,
  review,
}

/// The step asking for each input data type, by the last part of its name
/// (e.g. 'dk.carp.webservices.input.language' -> 'language').
const participantDataSteps = {
  "address": ParticipantStep.address,
  "diagnosis": ParticipantStep.diagnosis,
  "full_name": ParticipantStep.fullName,
  "phone_number": ParticipantStep.phoneNumber,
  "ssn": ParticipantStep.socialSecurityNumber,
  "sex": ParticipantStep.sex,
  "language": ParticipantStep.language,
  "occupation": ParticipantStep.occupation,
  "educational_degree": ParticipantStep.educationalDegree,
};

/// The input data types in [expected] that [role] is asked for on this page.
List<String> askableParticipantData(Iterable<ExpectedParticipantData?> expected, String? role) => [
  for (final data in expected.nonNulls)
    if ((data.assignedTo.isAssignedToAll || (data.assignedTo.roleNames?.contains(role) ?? false)) &&
        participantDataSteps.containsKey(data.attribute?.inputDataType.split('.').last))
      data.attribute!.inputDataType,
];

/// Occupations as offered in the CARP portal - sent as is, translated for display.
const occupations = [
  'Student',
  'Employed',
  'Unemployed',
  'Retired',
  'Homemaker',
  'Engineer',
  'Researcher',
  'Healthcare Professional',
  'Other',
];

/// Preferred languages, shown in their own language.
const languages = {
  'en': 'English',
  'da': 'Dansk',
  'sv': 'Svenska',
  'nb': 'Norsk',
  'fi': 'Suomi',
  'de': 'Deutsch',
  'nl': 'Nederlands',
  'fr': 'Français',
  'it': 'Italiano',
  'es': 'Español',
  'pt': 'Português',
  'pl': 'Polski',
  'uk': 'Українська',
  'tr': 'Türkçe',
  'ar': 'العربية',
  'hi': 'हिन्दी',
  'zh': '中文',
  'ja': '日本語',
  'ko': '한국어',
};

class ParticipantDataPage extends StatefulWidget {
  final ParticipantDataPageViewModel model;
  const ParticipantDataPage({super.key, required this.model});

  @override
  ParticipantDataPageState createState() => ParticipantDataPageState();
}

class ParticipantDataPageState extends State<ParticipantDataPage> {
  ParticipantStep currentStep = ParticipantStep.presentTypes;

  final Set<StepField> _allUsedStepFields = {};

  bool _nextEnabled = false;

  /// Always include the present types step at the beginning
  /// and the review step at the end.
  final List<ParticipantStep> _includedSteps = [ParticipantStep.presentTypes];

  /// The expected input data type each included step sets.
  final Map<ParticipantStep, String> _stepType = {};

  /// The single or multiple choice steps - the field shows the chosen
  /// labels (for review), [_choices] holds the chosen values.
  final Map<ParticipantStep, StepField> _choiceFields = {
    ParticipantStep.sex: StepField(title: "tasks.participant_data.sex.title", controller: TextEditingController()),
    ParticipantStep.language: StepField(
      title: "tasks.participant_data.language.title",
      controller: TextEditingController(),
    ),
    ParticipantStep.occupation: StepField(
      title: "tasks.participant_data.occupation.title",
      controller: TextEditingController(),
    ),
    ParticipantStep.educationalDegree: StepField(
      title: "tasks.participant_data.educational_degree.title",
      controller: TextEditingController(),
    ),
  };
  final Map<ParticipantStep, Set<String>> _choices = {};

  @override
  void initState() {
    super.initState();
    widget.model.address1Controller = TextEditingController();
    widget.model.address2Controller = TextEditingController();
    widget.model.streetController = TextEditingController();
    widget.model.postalCodeController = TextEditingController();
    widget.model.countryController = TextEditingController();
    widget.model.effectiveDateController = TextEditingController();
    widget.model.diagnosisDescriptionController = TextEditingController();
    widget.model.icd11CodeController = TextEditingController();
    widget.model.conclusionController = TextEditingController();
    widget.model.firstNameController = TextEditingController();
    widget.model.middleNameController = TextEditingController();
    widget.model.lastNameController = TextEditingController();
    widget.model.phoneNumberCodeController = TextEditingController();
    widget.model.phoneNumberController = TextEditingController();
    widget.model.ssnCountryController = TextEditingController(text: "DK");
    widget.model.ssnController = TextEditingController();

    widget.model.address1FocusNode = FocusNode();
    widget.model.address2FocusNode = FocusNode();
    widget.model.streetFocusNode = FocusNode();
    widget.model.postalCodeFocusNode = FocusNode();
    widget.model.countryFocusNode = FocusNode();
    widget.model.effectiveDateFocusNode = FocusNode();
    widget.model.diagnosisDescriptionFocusNode = FocusNode();
    widget.model.icd11CodeFocusNode = FocusNode();
    widget.model.conclusionFocusNode = FocusNode();
    widget.model.firstNameFocusNode = FocusNode();
    widget.model.middleNameFocusNode = FocusNode();
    widget.model.lastNameFocusNode = FocusNode();

    for (final type in widget.model.askableData) {
      _stepType[participantDataSteps[type.split('.').last]!] = type;
    }
    _includedSteps.addAll(ParticipantStep.values.where(_stepType.containsKey));

    /// Always include the review step at the end
    _includedSteps.add(ParticipantStep.review);

    widget.model.nonOptionalControllers = {
      widget.model.address1Controller,
      widget.model.streetController,
      widget.model.postalCodeController,
      widget.model.countryController,
      widget.model.effectiveDateController,
      widget.model.icd11CodeController,
      widget.model.conclusionController,
      widget.model.firstNameController,
      widget.model.lastNameController,
      widget.model.phoneNumberCodeController,
      widget.model.phoneNumberController,
      widget.model.ssnCountryController,
      widget.model.ssnController,
      for (final field in _choiceFields.values) field.controller,
    };

    for (final controller in widget.model.nonOptionalControllers) {
      controller.addListener(_validateRequiredFields);
    }

    widget.model.address1Field = StepField(
      title: "tasks.participant_data.address.address1",
      controller: widget.model.address1Controller,
      focusNode: widget.model.address1FocusNode,
      nextFocusNode: widget.model.address2FocusNode,
    );
    widget.model.address2Field = StepField(
      title: "tasks.participant_data.address.address2",
      controller: widget.model.address2Controller,
      focusNode: widget.model.address2FocusNode,
      nextFocusNode: widget.model.streetFocusNode,
    );
    widget.model.streetField = StepField(
      title: "tasks.participant_data.address.street",
      controller: widget.model.streetController,
      focusNode: widget.model.streetFocusNode,
      nextFocusNode: widget.model.postalCodeFocusNode,
    );
    widget.model.postalCodeField = StepField(
      title: "tasks.participant_data.address.postal_code",
      controller: widget.model.postalCodeController,
      focusNode: widget.model.postalCodeFocusNode,
      nextFocusNode: widget.model.countryFocusNode,
    );
    widget.model.countryField = StepField(
      title: "tasks.participant_data.address.country",
      controller: widget.model.countryController,
      focusNode: widget.model.countryFocusNode,
    );

    widget.model.effectiveDateField = StepField(
      title: "tasks.participant_data.diagnosis.effective_date",
      controller: widget.model.effectiveDateController,
      focusNode: widget.model.effectiveDateFocusNode,
      nextFocusNode: widget.model.diagnosisDescriptionFocusNode,
    );
    widget.model.diagnosisDescriptionField = StepField(
      title: "tasks.participant_data.diagnosis.diagnosis_description",
      controller: widget.model.diagnosisDescriptionController,
      focusNode: widget.model.diagnosisDescriptionFocusNode,
      nextFocusNode: widget.model.icd11CodeFocusNode,
    );
    widget.model.icd11CodeField = StepField(
      title: "tasks.participant_data.diagnosis.icd11_code",
      controller: widget.model.icd11CodeController,
      focusNode: widget.model.icd11CodeFocusNode,
      nextFocusNode: widget.model.conclusionFocusNode,
    );
    widget.model.conclusionField = StepField(
      title: "tasks.participant_data.diagnosis.conclusion",
      controller: widget.model.conclusionController,
      focusNode: widget.model.conclusionFocusNode,
    );

    widget.model.firstNameField = StepField(
      title: "tasks.participant_data.full_name.first_name",
      controller: widget.model.firstNameController,
      focusNode: widget.model.firstNameFocusNode,
      nextFocusNode: widget.model.middleNameFocusNode,
    );
    widget.model.middleNameField = StepField(
      title: "tasks.participant_data.full_name.middle_name",
      controller: widget.model.middleNameController,
      focusNode: widget.model.middleNameFocusNode,
      nextFocusNode: widget.model.lastNameFocusNode,
    );
    widget.model.lastNameField = StepField(
      title: "tasks.participant_data.full_name.last_name",
      controller: widget.model.lastNameController,
      focusNode: widget.model.lastNameFocusNode,
    );

    widget.model.phoneNumberField = StepField(
      title: "tasks.participant_data.phone_number.phone_number",
      controller: widget.model.phoneNumberController,
    );

    widget.model.ssnField = StepField(title: "tasks.participant_data.ssn.ssn", controller: widget.model.ssnController);
  }

  @override
  void dispose() {
    widget.model.address1Controller.dispose();
    widget.model.streetController.dispose();
    widget.model.postalCodeController.dispose();
    widget.model.countryController.dispose();
    widget.model.effectiveDateController.dispose();
    widget.model.diagnosisDescriptionController.dispose();
    widget.model.icd11CodeController.dispose();
    widget.model.conclusionController.dispose();
    widget.model.firstNameController.dispose();
    widget.model.middleNameController.dispose();
    widget.model.lastNameController.dispose();
    widget.model.phoneNumberController.dispose();
    widget.model.ssnController.dispose();

    widget.model.address1FocusNode.dispose();
    widget.model.streetFocusNode.dispose();
    widget.model.postalCodeFocusNode.dispose();
    widget.model.countryFocusNode.dispose();
    widget.model.effectiveDateFocusNode.dispose();
    widget.model.diagnosisDescriptionFocusNode.dispose();
    widget.model.icd11CodeFocusNode.dispose();
    widget.model.conclusionFocusNode.dispose();
    widget.model.firstNameFocusNode.dispose();
    widget.model.middleNameFocusNode.dispose();
    widget.model.lastNameFocusNode.dispose();
    for (final field in _choiceFields.values) {
      field.controller.dispose();
    }

    super.dispose();
  }

  /// Validates the required fields based on the current step.
  /// Updates the [_nextEnabled] state variable accordingly.
  /// This method is called whenever a relevant text field changes.
  void _validateRequiredFields() {
    setState(() {
      switch (currentStep) {
        case ParticipantStep.address:
          _nextEnabled =
              widget.model.address1Controller.text.isNotEmpty &&
              widget.model.streetController.text.isNotEmpty &&
              widget.model.postalCodeController.text.isNotEmpty &&
              widget.model.countryController.text.isNotEmpty;
          break;
        case ParticipantStep.diagnosis:
          _nextEnabled =
              widget.model.effectiveDateController.text.isNotEmpty &&
              widget.model.icd11CodeController.text.isNotEmpty &&
              widget.model.conclusionController.text.isNotEmpty;
          break;
        case ParticipantStep.fullName:
          _nextEnabled =
              widget.model.firstNameController.text.isNotEmpty && widget.model.lastNameController.text.isNotEmpty;
          break;
        case ParticipantStep.phoneNumber:
          _nextEnabled = widget.model.phoneNumberController.text.isNotEmpty;
          break;
        case ParticipantStep.socialSecurityNumber:
          _nextEnabled = widget.model.ssnController.text.isNotEmpty;
          break;
        case ParticipantStep.sex:
        case ParticipantStep.language:
        case ParticipantStep.occupation:
        case ParticipantStep.educationalDegree:
          _nextEnabled = _choiceFields[currentStep]!.controller.text.isNotEmpty;
          break;
        case ParticipantStep.review:
          _nextEnabled = true;
          break;
        default:
          _nextEnabled = false;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const CarpAppBar(hasProfileIcon: false),
                  Spacer(),
                  IconButton(
                    color: Colors.grey.shade900,
                    onPressed: () {
                      _showCancelConfirmationDialog();
                    },
                    icon: const Icon(Icons.close, size: 30),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDialogTitle(locale),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(child: _buildStepContent(locale, widget.model.expectedData)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _buildActionButtons(locale),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<ParticipantStep, String> _stepTitles(RPLocalizations locale) => {
    ParticipantStep.presentTypes: locale.translate("tasks.participant_data.present_data.title"),
    ParticipantStep.address: locale.translate("tasks.participant_data.address.title"),
    ParticipantStep.diagnosis: locale.translate("tasks.participant_data.diagnosis.title"),
    ParticipantStep.fullName: locale.translate("tasks.participant_data.full_name.title"),
    ParticipantStep.phoneNumber: locale.translate("tasks.participant_data.phone_number.title"),
    ParticipantStep.socialSecurityNumber: locale.translate("tasks.participant_data.ssn.title"),
    for (final MapEntry(:key, :value) in _choiceFields.entries) key: locale.translate(value.title),
    ParticipantStep.review: locale.translate("tasks.participant_data.review.title"),
  };

  /// Builds the title of the dialog based on the current step.
  Widget _buildDialogTitle(RPLocalizations locale) {
    final stepTitleMap = _stepTitles(locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                stepTitleMap[currentStep] ?? '',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the content of the current step based on the [_includedSteps].
  Widget _buildStepContent(RPLocalizations locale, Set<ExpectedParticipantData?> expectedData) {
    List<Widget> fields = [];
    switch (currentStep) {
      case ParticipantStep.presentTypes:
        fields.add(
          _buildPresentTypes(
            _includedSteps
                .where((step) => step != ParticipantStep.presentTypes && step != ParticipantStep.review)
                .map((step) => _stepTitles(locale)[step])
                .toList(),
          ),
        );
        break;
      case ParticipantStep.address:
        fields.addAll([
          _buildField(locale, widget.model.address1Field),
          _buildField(locale, widget.model.address2Field, isOptional: true),
          _buildField(locale, widget.model.streetField),
          _buildField(locale, widget.model.postalCodeField),
          _buildField(locale, widget.model.countryField),
        ]);
        break;
      case ParticipantStep.diagnosis:
        fields.addAll([
          _buildField(locale, widget.model.effectiveDateField, isDatePicker: true),
          _buildField(locale, widget.model.diagnosisDescriptionField, isOptional: true),
          _buildField(locale, widget.model.icd11CodeField),
          _buildField(locale, widget.model.conclusionField, isThicc: true),
        ]);
        break;
      case ParticipantStep.fullName:
        fields.addAll([
          _buildField(locale, widget.model.firstNameField),
          _buildField(locale, widget.model.middleNameField, isOptional: true),
          _buildField(locale, widget.model.lastNameField),
        ]);
        break;
      case ParticipantStep.phoneNumber:
        fields.add(_buildField(locale, widget.model.phoneNumberField, isPhoneNumber: true));
        break;
      case ParticipantStep.socialSecurityNumber:
        fields.add(_buildField(locale, widget.model.ssnField, isCPR: true));
        break;
      case ParticipantStep.sex:
        fields.add(
          _buildChoices(locale, {for (final sex in Sex.values) sex.name: "tasks.participant_data.sex.${sex.name}"}),
        );
        break;
      case ParticipantStep.language:
        fields.add(_buildChoices(locale, languages));
        break;
      case ParticipantStep.occupation:
        fields.add(
          _buildChoices(locale, {
            for (final occupation in occupations)
              occupation: "tasks.participant_data.occupation.${occupation.toLowerCase().replaceAll(' ', '_')}",
          }, multiple: true),
        );
        break;
      case ParticipantStep.educationalDegree:
        fields.add(
          _buildChoices(locale, {
            for (final level in IscedLevel.values)
              level.name: "tasks.participant_data.educational_degree.${level.name.toLowerCase()}",
          }),
        );
        break;
      case ParticipantStep.review:
        fields.add(_buildReviewStep(locale, _allUsedStepFields));
        break;
    }

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: fields),
    );
  }

  /// Builds the present types section and the review section, displaying the steps that are included
  Widget _buildPresentTypes(List<String?> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "\u2022 ${step ?? ''}",
            textAlign: TextAlign.start,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the review (last) step, displaying all the fields and their values.
  Widget _buildReviewStep(RPLocalizations locale, Set<StepField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(fields.length, (index) {
        final String field = fields.elementAt(index).title;
        String input = "";
        if (index < fields.length) {
          if (fields.elementAt(index).controller == widget.model.phoneNumberController) {
            input = "${widget.model.phoneNumberCodeController.text} ${fields.elementAt(index).controller.text}";
          } else if (fields.elementAt(index).controller == widget.model.ssnController) {
            input = "${widget.model.ssnCountryController.text} ${fields.elementAt(index).controller.text}";
          } else {
            input = fields.elementAt(index).controller.text;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.translate(field),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
              ),
              Text(input, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
            ],
          ),
        );
      }),
    );
  }

  /// The [options] (value -> label key) of the current choice step.
  Widget _buildChoices(RPLocalizations locale, Map<String, String> options, {bool multiple = false}) {
    final field = _choiceFields[currentStep]!;
    final chosen = _choices.putIfAbsent(currentStep, () => {});
    _allUsedStepFields.add(field);

    void toggle(String value) {
      if (!multiple) chosen.clear();
      if (!chosen.remove(value)) chosen.add(value);
      // Listeners on the controller re-validate and rebuild.
      field.controller.text = options.entries
          .where((option) => chosen.contains(option.key))
          .map((option) => locale.translate(option.value))
          .join(', ');
    }

    return Column(
      children: [
        for (final MapEntry(key: value, value: label) in options.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            selected: chosen.contains(value),
            leading: Icon(
              multiple
                  ? (chosen.contains(value) ? Icons.check_box : Icons.check_box_outline_blank)
                  : (chosen.contains(value) ? Icons.radio_button_checked : Icons.radio_button_unchecked),
            ),
            title: Text(locale.translate(label)),
            onTap: () => toggle(value),
          ),
      ],
    );
  }

  /// Is used to build all the text fields in the participant data page.
  /// Is called as many times as the number of steps in each participant data page.
  Widget _buildField(
    RPLocalizations locale,
    StepField stepField, {
    bool isPhoneNumber = false,
    bool isCPR = false,
    bool isOptional = false,
    bool isThicc = false,
    bool isDatePicker = false,
  }) {
    _validateRequiredFields();
    _allUsedStepFields.add(stepField);
    if (isPhoneNumber) {
      return InternationalPhoneNumberInput(
        onInputChanged: (phoneNumber) {
          widget.model.phoneNumberCodeController.text = phoneNumber.dialCode ?? '';
        },
        textFieldController: stepField.controller,
        selectorConfig: SelectorConfig(selectorType: PhoneInputSelectorType.DIALOG, useBottomSheetSafeArea: true),
        inputDecoration: _buildInputDecoration(locale, stepField, isThicc),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.disabled,
        selectorTextStyle: TextStyle(color: Colors.black),
        formatInput: true,
        keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
        inputBorder: OutlineInputBorder(),
      );
    } else if (isCPR) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 125,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade600, width: 1.0),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: CountryCodePicker(
                    onChanged: (value) {
                      stepField.controller.clear();
                      widget.model.ssnCountryController.text = value.code ?? '';
                      stepField.controller.text = stepField.controller.text;
                    },
                    initialSelection: 'DK',
                    showCountryOnly: true,
                    showOnlyCountryWhenClosed: true,
                    alignLeft: false,
                    textStyle: Theme.of(context).textTheme.labelLarge!,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: stepField.controller,
              decoration: _buildInputDecoration(locale, stepField, isThicc),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: stepField.controller,
              focusNode: stepField.focusNode,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                if (stepField.nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(stepField.nextFocusNode);
                }
              },
              onTap: isDatePicker
                  ? () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        stepField.controller.text = "${pickedDate.toLocal()}".split(' ')[0];
                      }
                    }
                  : null,
              keyboardType: TextInputType.multiline,
              maxLines: isThicc ? null : 1,
              decoration: _buildInputDecoration(locale, stepField, isThicc),
            ),
          ),
        ],
      );
    }
  }

  InputDecoration _buildInputDecoration(RPLocalizations locale, StepField stepField, bool isThicc) {
    return InputDecoration(
      labelText: locale.translate(stepField.title),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isThicc ? 70 : 12),
    );
  }

  /// Builds the action buttons at the bottom of the page.
  /// Includes "Cancel", "Previous", "Next", and "Submit" buttons.
  /// The "Next" button is enabled only if the required fields for the current step are filled.
  List<Widget> _buildActionButtons(RPLocalizations locale) {
    Widget buildTranslatedButton(
      String key,
      VoidCallback onPressed,
      bool enabled,
      ButtonStyle? buttonStyle,
      TextStyle? buttonTextStyle,
    ) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Text(locale.translate(key), style: buttonTextStyle),
        style: buttonStyle,
      );
    }

    return [
      currentStep == ParticipantStep.presentTypes
          ? buildTranslatedButton(
              "cancel",
              () {
                context.pop();
              },
              true,
              null,
              null,
            )
          : buildTranslatedButton(
              "previous",
              () {
                setState(() {
                  final idx = _includedSteps.indexOf(currentStep);
                  if (currentStep.index - 1 >= 0) {
                    currentStep = _includedSteps[idx - 1];
                  }
                });
                _validateRequiredFields();
              },
              true,
              null,
              null,
            ),
      currentStep.index == ParticipantStep.values.length - 1
          ? buildTranslatedButton(
              "done",
              () async {
                if (await _setParticipantData() && mounted) context.pop();
              },
              _nextEnabled,
              ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              TextStyle(color: Colors.white),
            )
          : buildTranslatedButton(
              "next",
              () {
                setState(() {
                  final idx = _includedSteps.indexOf(currentStep);
                  if (currentStep.index + 1 < ParticipantStep.values.length) {
                    currentStep = _includedSteps[idx + 1];
                  }
                });
                _validateRequiredFields();
              },
              currentStep == ParticipantStep.presentTypes ? true : _nextEnabled,
              ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              TextStyle(color: Colors.white),
            ),
    ];
  }

  // This method can be used to set the participant data
  // if needed before submitting.
  // Currently, it is called when the "Submit" button is pressed.
  /// Saves the answers. Returns false (and tells the participant) if that failed.
  Future<bool> _setParticipantData() async {
    final Map<String, Data> participantData = {};
    String chosen(ParticipantStep step) => _choices[step]!.single;

    final Map<ParticipantStep, Data Function()> participantStepToData = {
      ParticipantStep.address: () => AddressInput(
        address1: widget.model.address1Controller.text,
        address2: widget.model.address2Controller.text,
        street: widget.model.streetController.text,
        postalCode: widget.model.postalCodeController.text,
        country: widget.model.countryController.text,
      ),
      ParticipantStep.diagnosis: () => DiagnosisInput(
        effectiveDate: widget.model.effectiveDateController.text.isNotEmpty
            ? DateFormat(
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
              ).parse('${widget.model.effectiveDateController.text}T00:00:00Z').toUtc()
            : null,
        diagnosis: widget.model.diagnosisDescriptionController.text,
        icd11Code: widget.model.icd11CodeController.text,
        conclusion: widget.model.conclusionController.text,
      ),
      ParticipantStep.fullName: () => FullNameInput(
        firstName: widget.model.firstNameController.text,
        middleName: widget.model.middleNameController.text,
        lastName: widget.model.lastNameController.text,
      ),
      ParticipantStep.phoneNumber: () => PhoneNumberInput(
        countryCode: widget.model.phoneNumberCodeController.text,
        number: widget.model.phoneNumberController.text,
      ),
      ParticipantStep.socialSecurityNumber: () => SocialSecurityNumberInput(
        country: widget.model.ssnCountryController.text,
        socialSecurityNumber: widget.model.ssnController.text,
      ),
      ParticipantStep.sex: () => SexInput(value: Sex.values.byName(chosen(ParticipantStep.sex))),
      ParticipantStep.language: () => PreferredLanguageInput(
        languageCode: chosen(ParticipantStep.language),
        displayName: languages[chosen(ParticipantStep.language)],
      ),
      ParticipantStep.occupation: () => OccupationInput(roles: _choices[ParticipantStep.occupation]!.toList()),
      ParticipantStep.educationalDegree: () =>
          EducationalDegreeInput(level: IscedLevel.values.byName(chosen(ParticipantStep.educationalDegree))),
    };
    try {
      // Keyed by the type the protocol expects, as the backend only accepts those.
      for (final MapEntry(key: step, value: type) in _stepType.entries) {
        participantData[type] = participantStepToData[step]!();
      }
      await widget.model.setParticipantData(participantData);
      return true;
    } catch (error) {
      // Keep the page and its answers, so the participant can retry.
      warning('$runtimeType - Could not save participant data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RPLocalizations.of(context)!.translate('tasks.participant_data.save_failed'))),
        );
      }
      return false;
    }
  }

  Future<void> _showCancelConfirmationDialog() {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(locale.translate("pages.audio_task.discard")),
          actions: <Widget>[
            TextButton(
              child: Text(locale.translate("NO")),
              onPressed: () {
                context.pop();
              },
            ),
            TextButton(
              child: Text(locale.translate("YES")),
              onPressed: () {
                context.pop();
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class StepField {
  final String title;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  StepField({required this.title, required this.controller, this.focusNode, this.nextFocusNode});
}
