import 'dart:async';
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/features/tasks/participant_data_view_model.dart';
import 'package:carp_study_app/shared/widgets/carp_app_bar.dart';

enum ParticipantStep { presentTypes, address, diagnosis, fullName, phoneNumber, socialSecurityNumber, review }

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

  final Map<String, ParticipantStep> _stepMap = {
    "address": ParticipantStep.address,
    "diagnosis": ParticipantStep.diagnosis,
    "full_name": ParticipantStep.fullName,
    "phone_number": ParticipantStep.phoneNumber,
    "ssn": ParticipantStep.socialSecurityNumber,
  };

  final Map<ParticipantStep, String> participantStepDescriptions = {
    ParticipantStep.address: 'Address',
    ParticipantStep.diagnosis: 'Diagnosis',
    ParticipantStep.fullName: 'Full Name',
    ParticipantStep.phoneNumber: 'Phone Number',
    ParticipantStep.socialSecurityNumber: 'Social Security Number',
    ParticipantStep.review: 'Review',
  };

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

    for (final key in _stepMap.keys) {
      if (widget.model.expectedData.any((dataType) => dataType!.attribute!.inputDataType.contains(key))) {
        _includedSteps.add(_stepMap[key]!);
      }
    }

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

  /// Builds the title of the dialog based on the current step.
  Widget _buildDialogTitle(RPLocalizations locale) {
    final stepTitleMap = {
      ParticipantStep.presentTypes: locale.translate("tasks.participant_data.present_data.title"),
      ParticipantStep.address: locale.translate("tasks.participant_data.address.title"),
      ParticipantStep.diagnosis: locale.translate("tasks.participant_data.diagnosis.title"),
      ParticipantStep.fullName: locale.translate("tasks.participant_data.full_name.title"),
      ParticipantStep.phoneNumber: locale.translate("tasks.participant_data.phone_number.title"),
      ParticipantStep.socialSecurityNumber: locale.translate("tasks.participant_data.ssn.title"),
      ParticipantStep.review: locale.translate("tasks.participant_data.review.title"),
    };
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
                .map((step) => participantStepDescriptions[step])
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
              },
              true,
              null,
              null,
            ),
      currentStep.index == ParticipantStep.values.length - 1
          ? buildTranslatedButton(
              "submit",
              () {
                _setParticipantData();
                context.pop();
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
  void _setParticipantData() {
    final Map<String, Data> participantData = {};

    final Map<ParticipantStep, Map<String, Data>> participantStepToDataType = {
      ParticipantStep.address: {
        InputType.ADDRESS: AddressInput(
          address1: widget.model.address1Controller.text,
          address2: widget.model.address2Controller.text,
          street: widget.model.streetController.text,
          postalCode: widget.model.postalCodeController.text,
          country: widget.model.countryController.text,
        ),
      },
      ParticipantStep.diagnosis: {
        InputType.DIAGNOSIS: DiagnosisInput(
          effectiveDate: widget.model.effectiveDateController.text.isNotEmpty
              ? DateFormat(
                  "yyyy-MM-dd'T'HH:mm:ss'Z'",
                ).parse('${widget.model.effectiveDateController.text}T00:00:00Z').toUtc()
              : null,
          diagnosis: widget.model.diagnosisDescriptionController.text,
          icd11Code: widget.model.icd11CodeController.text,
          conclusion: widget.model.conclusionController.text,
        ),
      },
      ParticipantStep.fullName: {
        InputType.FULL_NAME: FullNameInput(
          firstName: widget.model.firstNameController.text,
          middleName: widget.model.middleNameController.text,
          lastName: widget.model.lastNameController.text,
        ),
      },
      ParticipantStep.phoneNumber: {
        InputType.PHONE_NUMBER: PhoneNumberInput(
          countryCode: widget.model.phoneNumberCodeController.text,
          number: widget.model.phoneNumberController.text,
        ),
      },
      ParticipantStep.socialSecurityNumber: {
        InputType.SSN: SocialSecurityNumberInput(
          country: widget.model.ssnCountryController.text,
          socialSecurityNumber: widget.model.ssnController.text,
        ),
      },
    };
    for (final step in _includedSteps) {
      final dataMap = participantStepToDataType[step];
      if (dataMap != null) {
        participantData.addAll(dataMap);
      }
    }

    widget.model.setParticipantData(participantData);
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
