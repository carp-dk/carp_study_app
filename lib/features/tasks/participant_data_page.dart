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
  bool _saving = false;

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
    final locale = RPLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelConfirmationDialog();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopBar(locale),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    key: ValueKey(currentStep),
                    children: [
                      _buildStepTitle(locale),
                      Padding(padding: const EdgeInsets.all(8), child: _buildStepContent(locale)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: _buildActionButtons(locale)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Matches Research Package's default [RPUITask] carousel bar: logo, step
  /// counter ("1 of N"), and primary-coloured close icon.
  Widget _buildTopBar(RPLocalizations locale) {
    final stepIndex = _includedSteps.indexOf(currentStep);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: AppBar().preferredSize.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 5,
              child: Image.asset(
                'assets/icons/carp_logo_example.png',
                package: 'research_package',
                fit: BoxFit.contain,
                height: 16,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${stepIndex + 1} ${locale.translate('of')} ${_includedSteps.length}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 5,
              child: IconButton(
                padding: const EdgeInsets.only(right: 30),
                alignment: Alignment.centerRight,
                icon: Icon(Icons.highlight_off, color: Theme.of(context).colorScheme.primary),
                onPressed: _showCancelConfirmationDialog,
              ),
            ),
          ],
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

  /// Matches RP's instruction / question step title styling.
  Widget _buildStepTitle(RPLocalizations locale) {
    final title = _stepTitles(locale)[currentStep] ?? '';
    final style = currentStep == ParticipantStep.presentTypes
        ? Theme.of(context).textTheme.headlineSmall
        : Theme.of(context).textTheme.titleLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
      child: Text(title, textAlign: TextAlign.left, style: style),
    );
  }

  /// Builds the content of the current step based on [_includedSteps].
  Widget _buildStepContent(RPLocalizations locale) {
    final List<Widget> fields = [];
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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: fields);
  }

  /// Displays the list of steps the participant is about to fill in.
  Widget _buildPresentTypes(List<String?> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text('• ${step ?? ''}', style: Theme.of(context).textTheme.bodyLarge),
        );
      }).toList(),
    );
  }

  /// Builds the review (last) step, displaying all the fields and their values.
  Widget _buildReviewStep(RPLocalizations locale, Set<StepField> fields) {
    final entries = fields.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) const Divider(height: 24),
          Text(
            locale.translate(entries[index].title),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(_reviewValue(entries[index]), style: Theme.of(context).textTheme.bodyLarge),
        ],
      ],
    );
  }

  String _reviewValue(StepField field) {
    if (field.controller == widget.model.phoneNumberController) {
      return '${widget.model.phoneNumberCodeController.text} ${field.controller.text}'.trim();
    }
    if (field.controller == widget.model.ssnController) {
      return '${widget.model.ssnCountryController.text} ${field.controller.text}'.trim();
    }
    return field.controller.text;
  }

  /// Matches Research Package's [RPUIChoiceQuestionBody]: hint line, dividers,
  /// and primary-coloured [Radio] / [Checkbox] rows.
  Widget _buildChoices(RPLocalizations locale, Map<String, String> options, {bool multiple = false}) {
    final field = _choiceFields[currentStep]!;
    final chosen = _choices.putIfAbsent(currentStep, () => {});
    _allUsedStepFields.add(field);

    void syncController() {
      // Listeners on the controller re-validate and rebuild.
      field.controller.text = options.entries
          .where((option) => chosen.contains(option.key))
          .map((option) => locale.translate(option.value))
          .join(', ');
    }

    void toggle(String value) {
      if (!chosen.remove(value)) {
        if (!multiple) chosen.clear();
        chosen.add(value);
      }
      syncController();
    }

    final entries = options.entries.toList();
    final primary = Theme.of(context).colorScheme.primary;
    final list = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final MapEntry(key: value, value: label) = entries[index];
        final selected = chosen.contains(value);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => toggle(value),
            child: Row(
              children: [
                if (multiple)
                  Checkbox(value: selected, onChanged: (_) => toggle(value), activeColor: primary)
                else
                  Radio<String>(value: value, toggleable: true, activeColor: primary),
                Expanded(
                  child: Text(locale.translate(label), style: Theme.of(context).textTheme.bodyLarge, softWrap: true),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('(${locale.translate(multiple ? 'choose_one_or_more_options' : 'choose_one_option')})'),
        ),
        if (multiple)
          list
        else
          RadioGroup<String>(
            groupValue: chosen.firstOrNull,
            onChanged: (value) {
              if (value == null) {
                chosen.clear();
                syncController();
              } else {
                toggle(value);
              }
            },
            child: list,
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
    _allUsedStepFields.add(stepField);
    if (isPhoneNumber) {
      return InternationalPhoneNumberInput(
        onInputChanged: (phoneNumber) {
          widget.model.phoneNumberCodeController.text = phoneNumber.dialCode ?? '';
        },
        textFieldController: stepField.controller,
        selectorConfig: SelectorConfig(selectorType: PhoneInputSelectorType.DIALOG, useBottomSheetSafeArea: true),
        inputDecoration: _buildInputDecoration(locale, stepField),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.disabled,
        selectorTextStyle: Theme.of(context).textTheme.bodyLarge,
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
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
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
              decoration: _buildInputDecoration(locale, stepField),
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
              textInputAction: isThicc ? TextInputAction.newline : TextInputAction.next,
              onFieldSubmitted: (_) {
                if (stepField.nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(stepField.nextFocusNode);
                }
              },
              readOnly: isDatePicker,
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
              keyboardType: isThicc ? TextInputType.multiline : TextInputType.text,
              minLines: isThicc ? 4 : 1,
              maxLines: isThicc ? null : 1,
              decoration: _buildInputDecoration(locale, stepField),
            ),
          ),
        ],
      );
    }
  }

  InputDecoration _buildInputDecoration(RPLocalizations locale, StepField stepField) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: locale.translate(stepField.title),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Matches Research Package's bottom bar: [OutlinedButton] BACK on the left
  /// (omitted on step 1) and [ElevatedButton] NEXT / DONE on the right.
  List<Widget> _buildActionButtons(RPLocalizations locale) {
    final idx = _includedSteps.indexOf(currentStep);
    final isFirst = idx == 0;
    final isLast = idx == _includedSteps.length - 1;
    final canProceed = isFirst || _nextEnabled;

    return [
      if (isFirst)
        const SizedBox.shrink()
      else
        OutlinedButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => currentStep = _includedSteps[idx - 1]);
            _validateRequiredFields();
          },
          child: Text(locale.translate('BACK')),
        ),
      ElevatedButton(
        onPressed: !canProceed || _saving
            ? null
            : () async {
                FocusManager.instance.primaryFocus?.unfocus();
                if (isLast) {
                  setState(() => _saving = true);
                  final ok = await _setParticipantData();
                  if (!mounted) return;
                  if (ok) {
                    context.pop();
                  } else {
                    setState(() => _saving = false);
                  }
                } else {
                  setState(() => currentStep = _includedSteps[idx + 1]);
                  _validateRequiredFields();
                }
              },
        child: Text(locale.translate(isLast ? 'DONE' : 'NEXT')),
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
    final locale = RPLocalizations.of(context)!;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(locale.translate('pages.audio_task.discard')),
          content: Text(locale.translate('discard_confirmation_body')),
          actions: <Widget>[
            OutlinedButton(onPressed: () => context.pop(), child: Text(locale.translate('CANCEL'))),
            FilledButton(
              onPressed: () {
                context.pop();
                context.pop();
              },
              child: Text(locale.translate('LEAVE')),
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
