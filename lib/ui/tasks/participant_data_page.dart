part of carp_study_app;

enum ParticipantStep {
  presentTypes,
  address,
  diagnosis,
  fullName,
  phoneNumber,
  socialSecurityNumber,
  review
}

class ParticipantDataPage extends StatefulWidget {
  static const String route = '/participant_data';
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
    widget.model._address1Controller = TextEditingController();
    widget.model._address2Controller = TextEditingController();
    widget.model._streetController = TextEditingController();
    widget.model._postalCodeController = TextEditingController();
    widget.model._countryController = TextEditingController();
    widget.model._effectiveDateController = TextEditingController();
    widget.model._diagnosisDescriptionController = TextEditingController();
    widget.model._icd11CodeController = TextEditingController();
    widget.model._conclusionController = TextEditingController();
    widget.model._firstNameController = TextEditingController();
    widget.model._middleNameController = TextEditingController();
    widget.model._lastNameController = TextEditingController();
    widget.model._phoneNumberCodeController = TextEditingController();
    widget.model._phoneNumberController = TextEditingController();
    widget.model._ssnCountryController = TextEditingController(text: "DK");
    widget.model._ssnController = TextEditingController();

    widget.model._address1FocusNode = FocusNode();
    widget.model._address2FocusNode = FocusNode();
    widget.model._streetFocusNode = FocusNode();
    widget.model._postalCodeFocusNode = FocusNode();
    widget.model._countryFocusNode = FocusNode();
    widget.model._effectiveDateFocusNode = FocusNode();
    widget.model._diagnosisDescriptionFocusNode = FocusNode();
    widget.model._icd11CodeFocusNode = FocusNode();
    widget.model._conclusionFocusNode = FocusNode();
    widget.model._firstNameFocusNode = FocusNode();
    widget.model._middleNameFocusNode = FocusNode();
    widget.model._lastNameFocusNode = FocusNode();

    for (final key in _stepMap.keys) {
      if (widget.model.expectedData.any(
          (dataType) => dataType!.attribute!.inputDataType.contains(key))) {
        _includedSteps.add(_stepMap[key]!);
      }
    }

    /// Always include the review step at the end
    _includedSteps.add(ParticipantStep.review);

    widget.model._nonOptionalControllers = {
      widget.model._address1Controller,
      widget.model._streetController,
      widget.model._postalCodeController,
      widget.model._countryController,
      widget.model._effectiveDateController,
      widget.model._icd11CodeController,
      widget.model._conclusionController,
      widget.model._firstNameController,
      widget.model._lastNameController,
      widget.model._phoneNumberCodeController,
      widget.model._phoneNumberController,
      widget.model._ssnCountryController,
      widget.model._ssnController,
    };

    for (final controller in widget.model._nonOptionalControllers) {
      controller.addListener(_validateRequiredFields);
    }

    widget.model.address1Field = StepField(
      title: "tasks.participant_data.address.address1",
      controller: widget.model._address1Controller,
      focusNode: widget.model._address1FocusNode,
      nextFocusNode: widget.model._address2FocusNode,
    );
    widget.model.address2Field = StepField(
      title: "tasks.participant_data.address.address2",
      controller: widget.model._address2Controller,
      focusNode: widget.model._address2FocusNode,
      nextFocusNode: widget.model._streetFocusNode,
    );
    widget.model.streetField = StepField(
      title: "tasks.participant_data.address.street",
      controller: widget.model._streetController,
      focusNode: widget.model._streetFocusNode,
      nextFocusNode: widget.model._postalCodeFocusNode,
    );
    widget.model.postalCodeField = StepField(
      title: "tasks.participant_data.address.postal_code",
      controller: widget.model._postalCodeController,
      focusNode: widget.model._postalCodeFocusNode,
      nextFocusNode: widget.model._countryFocusNode,
    );
    widget.model.countryField = StepField(
      title: "tasks.participant_data.address.country",
      controller: widget.model._countryController,
      focusNode: widget.model._countryFocusNode,
    );

    widget.model.effectiveDateField = StepField(
      title: "tasks.participant_data.diagnosis.effective_date",
      controller: widget.model._effectiveDateController,
      focusNode: widget.model._effectiveDateFocusNode,
      nextFocusNode: widget.model._diagnosisDescriptionFocusNode,
    );
    widget.model.diagnosisDescriptionField = StepField(
      title: "tasks.participant_data.diagnosis.diagnosis_description",
      controller: widget.model._diagnosisDescriptionController,
      focusNode: widget.model._diagnosisDescriptionFocusNode,
      nextFocusNode: widget.model._icd11CodeFocusNode,
    );
    widget.model.icd11CodeField = StepField(
      title: "tasks.participant_data.diagnosis.icd11_code",
      controller: widget.model._icd11CodeController,
      focusNode: widget.model._icd11CodeFocusNode,
      nextFocusNode: widget.model._conclusionFocusNode,
    );
    widget.model.conclusionField = StepField(
      title: "tasks.participant_data.diagnosis.conclusion",
      controller: widget.model._conclusionController,
      focusNode: widget.model._conclusionFocusNode,
    );

    widget.model.firstNameField = StepField(
      title: "tasks.participant_data.full_name.first_name",
      controller: widget.model._firstNameController,
      focusNode: widget.model._firstNameFocusNode,
      nextFocusNode: widget.model._middleNameFocusNode,
    );
    widget.model.middleNameField = StepField(
      title: "tasks.participant_data.full_name.middle_name",
      controller: widget.model._middleNameController,
      focusNode: widget.model._middleNameFocusNode,
      nextFocusNode: widget.model._lastNameFocusNode,
    );
    widget.model.lastNameField = StepField(
      title: "tasks.participant_data.full_name.last_name",
      controller: widget.model._lastNameController,
      focusNode: widget.model._lastNameFocusNode,
    );

    widget.model.phoneNumberField = StepField(
      title: "tasks.participant_data.phone_number.phone_number",
      controller: widget.model._phoneNumberController,
    );

    widget.model.ssnField = StepField(
      title: "tasks.participant_data.ssn.ssn",
      controller: widget.model._ssnController,
    );
  }

  @override
  void dispose() {
    widget.model._address1Controller.dispose();
    widget.model._streetController.dispose();
    widget.model._postalCodeController.dispose();
    widget.model._countryController.dispose();
    widget.model._effectiveDateController.dispose();
    widget.model._diagnosisDescriptionController.dispose();
    widget.model._icd11CodeController.dispose();
    widget.model._conclusionController.dispose();
    widget.model._firstNameController.dispose();
    widget.model._middleNameController.dispose();
    widget.model._lastNameController.dispose();
    widget.model._phoneNumberController.dispose();
    widget.model._ssnController.dispose();

    widget.model._address1FocusNode.dispose();
    widget.model._streetFocusNode.dispose();
    widget.model._postalCodeFocusNode.dispose();
    widget.model._countryFocusNode.dispose();
    widget.model._effectiveDateFocusNode.dispose();
    widget.model._diagnosisDescriptionFocusNode.dispose();
    widget.model._icd11CodeFocusNode.dispose();
    widget.model._conclusionFocusNode.dispose();
    widget.model._firstNameFocusNode.dispose();
    widget.model._middleNameFocusNode.dispose();
    widget.model._lastNameFocusNode.dispose();

    super.dispose();
  }

  /// Validates the required fields based on the current step.
  /// Updates the [_nextEnabled] state variable accordingly.
  /// This method is called whenever a relevant text field changes.
  void _validateRequiredFields() {
    setState(() {
      switch (currentStep) {
        case ParticipantStep.address:
          _nextEnabled = widget.model._address1Controller.text.isNotEmpty &&
              widget.model._streetController.text.isNotEmpty &&
              widget.model._postalCodeController.text.isNotEmpty &&
              widget.model._countryController.text.isNotEmpty;
          break;
        case ParticipantStep.diagnosis:
          _nextEnabled =
              widget.model._effectiveDateController.text.isNotEmpty &&
                  widget.model._icd11CodeController.text.isNotEmpty &&
                  widget.model._conclusionController.text.isNotEmpty;
          break;
        case ParticipantStep.fullName:
          _nextEnabled = widget.model._firstNameController.text.isNotEmpty &&
              widget.model._lastNameController.text.isNotEmpty;
          break;
        case ParticipantStep.phoneNumber:
          _nextEnabled = widget.model._phoneNumberController.text.isNotEmpty;
          break;
        case ParticipantStep.socialSecurityNumber:
          _nextEnabled = widget.model._ssnController.text.isNotEmpty;
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
      backgroundColor:
          Theme.of(context).extension<CarpColors>()!.backgroundGray!,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 10),
                    child: const CarpAppBar(
                      hasProfileIcon: false,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    color: Theme.of(context).extension<CarpColors>()!.grey900!,
                    onPressed: () {
                      _showCancelConfirmationDialog();
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                    ),
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
                          child: SizedBox(
                            child: _buildStepContent(
                                locale, widget.model.expectedData),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
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
      ParticipantStep.presentTypes:
          locale.translate("tasks.participant_data.present_data.title"),
      ParticipantStep.address:
          locale.translate("tasks.participant_data.address.title"),
      ParticipantStep.diagnosis:
          locale.translate("tasks.participant_data.diagnosis.title"),
      ParticipantStep.fullName:
          locale.translate("tasks.participant_data.full_name.title"),
      ParticipantStep.phoneNumber:
          locale.translate("tasks.participant_data.phone_number.title"),
      ParticipantStep.socialSecurityNumber:
          locale.translate("tasks.participant_data.ssn.title"),
      ParticipantStep.review:
          locale.translate("tasks.participant_data.review.title"),
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
                style: fs22fw700.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the content of the current step based on the [_includedSteps].
  Widget _buildStepContent(
      RPLocalizations locale, Set<ExpectedParticipantData?> expectedData) {
    List<Widget> fields = [];
    switch (currentStep) {
      case ParticipantStep.presentTypes:
        fields.add(_buildPresentTypes(
          _includedSteps
              .where((step) =>
                  step != ParticipantStep.presentTypes &&
                  step != ParticipantStep.review)
              .map((step) => participantStepDescriptions[step])
              .toList(),
        ));
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
          _buildField(locale, widget.model.effectiveDateField,
              isDatePicker: true),
          _buildField(locale, widget.model.diagnosisDescriptionField,
              isOptional: true),
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
        fields.add(_buildField(locale, widget.model.phoneNumberField,
            isPhoneNumber: true));
        break;
      case ParticipantStep.socialSecurityNumber:
        fields.add(_buildField(locale, widget.model.ssnField, isCPR: true));
        break;
      case ParticipantStep.review:
        fields.add(_buildReviewStep(
          locale,
          _allUsedStepFields,
        ));
        break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields,
      ),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
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
          if (fields.elementAt(index).controller ==
              widget.model._phoneNumberController) {
            input =
                "${widget.model._phoneNumberCodeController.text} ${fields.elementAt(index).controller.text}";
          } else if (fields.elementAt(index).controller ==
              widget.model._ssnController) {
            input =
                "${widget.model._ssnCountryController.text} ${fields.elementAt(index).controller.text}";
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                input,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
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
          widget.model._phoneNumberCodeController.text =
              phoneNumber.dialCode ?? '';
        },
        textFieldController: stepField.controller,
        selectorConfig: SelectorConfig(
          selectorType: PhoneInputSelectorType.DIALOG,
          useBottomSheetSafeArea: true,
        ),
        inputDecoration: _buildInputDecoration(locale, stepField, isThicc),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.disabled,
        selectorTextStyle: TextStyle(color: Colors.black),
        formatInput: true,
        keyboardType:
            TextInputType.numberWithOptions(signed: true, decimal: true),
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
                    border: Border.all(
                      color:
                          Theme.of(context).extension<CarpColors>()!.grey600!,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: CountryCodePicker(
                    onChanged: (value) {
                      stepField.controller.clear();
                      widget.model._ssnCountryController.text =
                          value.code ?? '';
                      stepField.controller.text = stepField.controller.text;
                    },
                    initialSelection: 'DK',
                    showCountryOnly: true,
                    showOnlyCountryWhenClosed: true,
                    alignLeft: false,
                    textStyle: fs16fw600.copyWith(
                      color:
                          Theme.of(context).extension<CarpColors>()!.grey900!,
                    ),
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
                    FocusScope.of(context)
                        .requestFocus(stepField.nextFocusNode);
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
                          stepField.controller.text =
                              "${pickedDate.toLocal()}".split(' ')[0];
                        }
                      }
                    : null,
                keyboardType: TextInputType.multiline,
                maxLines: isThicc ? null : 1,
                decoration: _buildInputDecoration(locale, stepField, isThicc)),
          ),
        ],
      );
    }
  }

  InputDecoration _buildInputDecoration(
      RPLocalizations locale, StepField stepField, bool isThicc) {
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
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: isThicc ? 70 : 12));
  }

  /// Builds the action buttons at the bottom of the page.
  /// Includes "Cancel", "Previous", "Next", and "Submit" buttons.
  /// The "Next" button is enabled only if the required fields for the current step are filled.
  List<Widget> _buildActionButtons(RPLocalizations locale) {
    Widget buildTranslatedButton(String key, VoidCallback onPressed,
        bool enabled, ButtonStyle? buttonStyle, TextStyle? buttonTextStyle) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Text(
          locale.translate(key).toUpperCase(),
          style: buttonTextStyle,
        ),
        style: buttonStyle,
      );
    }

    return [
      currentStep == ParticipantStep.presentTypes
          ? buildTranslatedButton("cancel", () {
              context.pop();
            }, true, null, null)
          : buildTranslatedButton("previous", () {
              setState(() {
                final idx = _includedSteps.indexOf(currentStep);
                if (currentStep.index - 1 >= 0) {
                  currentStep = _includedSteps[idx - 1];
                }
              });
            }, true, null, null),
      currentStep.index == ParticipantStep.values.length - 1
          ? buildTranslatedButton(
              "submit",
              () {
                _setParticipantData();
                context.pop();
              },
              _nextEnabled,
              ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).extension<CarpColors>()!.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              TextStyle(
                color: Colors.white,
              ),
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
                backgroundColor:
                    Theme.of(context).extension<CarpColors>()!.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              TextStyle(
                color: Colors.white,
              ),
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
        AddressInput.type: AddressInput(
          address1: widget.model._address1Controller.text,
          address2: widget.model._address2Controller.text,
          street: widget.model._streetController.text,
          postalCode: widget.model._postalCodeController.text,
          country: widget.model._countryController.text,
        ),
      },
      ParticipantStep.diagnosis: {
        DiagnosisInput.type: DiagnosisInput(
          effectiveDate: widget.model._effectiveDateController.text.isNotEmpty
              ? DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")
                  .parse(
                      '${widget.model._effectiveDateController.text}T00:00:00Z')
                  .toUtc()
              : null,
          diagnosis: widget.model._diagnosisDescriptionController.text,
          icd11Code: widget.model._icd11CodeController.text,
          conclusion: widget.model._conclusionController.text,
        ),
      },
      ParticipantStep.fullName: {
        FullNameInput.type: FullNameInput(
          firstName: widget.model._firstNameController.text,
          middleName: widget.model._middleNameController.text,
          lastName: widget.model._lastNameController.text,
        ),
      },
      ParticipantStep.phoneNumber: {
        PhoneNumberInput.type: PhoneNumberInput(
          countryCode: widget.model._phoneNumberCodeController.text,
          number: widget.model._phoneNumberController.text,
        ),
      },
      ParticipantStep.socialSecurityNumber: {
        SocialSecurityNumberInput.type: SocialSecurityNumberInput(
          country: widget.model._ssnCountryController.text,
          socialSecurityNumber: widget.model._ssnController.text,
        ),
      },
    };
    for (final step in _includedSteps) {
      final dataMap = participantStepToDataType[step];
      if (dataMap != null) {
        participantData.addAll(dataMap);
      }
    }

    bloc.setParticipantData(
      bloc.study!.studyDeploymentId,
      participantData,
      bloc.study!.participantRoleName,
    );
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
            )
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

  StepField({
    required this.title,
    required this.controller,
    this.focusNode,
    this.nextFocusNode,
  });
}
