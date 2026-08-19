# Documentation

## General Information

### `Main.dart`

In this file, the debug level and the deployment mode can be configured.
The deployment mode needs to be aligned with the deployment of the protocol, else it is not found.

### `carp_study_app.dart`

In this file the localization the study deployment is configured. Contains the app class.

### Theming

App-wide styling (colors, typography, component themes) comes from
`package:carp_themes_package`'s `carpTheme`. Use `Theme.of(context).colorScheme`
and `Theme.of(context).textTheme` in widgets rather than hard-coding styles.

### UI

#### `home_page.dart`

Contains the navigator bar: Tasks, About, Data, Devices.

#### `task_list_page.dart`

Contains the pending & completed tasks & stats about the study participations (`scoreboard_card`). Makes use of `task_list_page_view_model.dart`.

#### `study_page.dart`

Contains the information about the study and the messages. When taping on them, `study_details_page.dart` or `message_details_page.dart` is oppened to display all the details. Makes use of `study_page_view_model.dart`.

#### `data_viz_page.dart`

Checks which type of data is being collected and displays it on cards: `activity_card`, `measures_card`, `media_card`, `mobility_card`, `study_progress_card`

#### `informed_consent_page.dart`

Gets the informed consent from the bloc and displays it.

#### `audio_task.dart`

It is the equivalent of the RPSurveyTasks but for collecting audio. Does not allow playback, but allows to retake.

#### `camera_task.dart`

It is the equivalent of the RPSurveyTasks but for collecting videos and pictures. Displays the video/picture and allows to retake.

#### `profile_page`

Displays account information. Used to abandon a study, sign out or contact researcher.

### View Models

Contains the models for each of the screens & cards.

### Assets

#### `lang\`

Contains localization files for the UI (EN, DA, ES). Important to remember to update all files whenever a key is updated.

#### `lang_local\`

Contains localization files for the local protocols (EN, DA). USed only in `DeploymentMode.LOCAL`

### Data

#### `carp_backend.dart`

#### `local_resource_manager.dart`

A local resource manager handling: informed consent, localization & study descriptions

#### `local_settings.dart`

Local settings manager storing: authentication crdentials & study id

#### `localization_loader.dart`

Loads localization from Localization manager

### Sensing

### Blocs

#### `app_bloc.dart`

#### `common.dart`

Used to define enums

## Before submiting to the stores

1. Check if `DeploymentMode` is correctly set
2.
3. Update build number

## Generate study

[More info here](https://pub.dev/packages/carp_study_generator)
[Study configuration repo](https://github.com/carp-dk/carp_study_app_configurations)

1. Create `carpspec.yaml` & **do not add to version control**
2. In server, point to the right uri:

   - PROD <carp.computerome.dk>
   - DEV <dev.carp.dk>
   - TEST <test.carp.dk>

3. Add username & password of the researcher account
4. Make sure the following paths exist

   ```
    consent:
    path: carp/resources/consent.json

    protocol:
    path: carp/resources/protocol.json

    message:
    path: carp/messages/
    # list the messages supported
    # for each message, a json file in the 'messages' folder must be added
    messages:
        - 1
        - 2

    localization:
    path: carp/lang/
    # list the locales supported
    # for each locale, a json file in the 'lang' folder must be added
    locales:
        - en
        - da
   ```

5. After making changes in any of these, `local_protocol_manager.dart`,`local_resource_manager.dart`,`local_surveys.dart`, run the respectiive test & copy the output into the respective `.json`
6. Run command:

`flutter test carp/<command>`
`      help                   Prints this help message.\\
        dryrun                 Makes a dryrun testing access to the CARP server the correctness of the json resources.\\
        create                 Create a study protocol based on a json file and uploads it to the CARP server.\\
        update                 Update an existing study protocol as a new version.\\
        consent                Create an informed consent based on a json file and uploads it to the CARP server.\\
        localization           Upload the localization files to the CARP server.\\
        message                Upload the list of messages to the CARP server.\\
        message-delete-all     Delete all messages on the CARP server.\\
` 7. Notes:

- Once the protocol is created it can be updated unless there are changes in the protocolName
- Once a study ha started, the protocol can not be updated, but the informed consent, localization & messages can. Thus, the suty is bonded to whatever version of the protocol it was firstly assigned.
- The consent, localization & messages need to be uploaded to each study. To do so, once a protocol is created, a study needs to be created. Copy the `study_id` shown in the portal into the `carspec.yaml` & run `consent`,`localization`,`message` commands.

## Submision to stores

**Make sure to update build number**

### iOS

1. Xcode: Product > Archive --> Window > Organizer > Distribute App > App Store Connect > Upload
2. App Store Connect: TestFlight > [build number] > [yes to everything] > invite WristAngel Testing group
3. Users: Add users to WristAngel Testing group (requires email)
4. Note: Builds in TestFlit expire after 90 days, make sure to check expiration time.

### Android

1. `flutter build appbundle`
2. Play Console: Testing > Open testing > new release > App bundles > upload > [/carp_study_app/build/app/outputs/bundle/release/app-release.aab]

## Known issues & status

### Age restriction on Stores

#### Android

> 3 y.0.

####  iOS:

> 12 y.o, can be surpased with parental control. Workaround described [here](https://trello.com/c/RhwGuXxu/146-age-restriction-on-ios)

#### TestFlight

> 13 y.o requires to change birthday. Workaround described [here](https://trello.com/c/RhwGuXxu/146-age-restriction-on-ios)

### Store releases status

#### Android

Working in open testing. Latest version 11/02/2022.

#### iOS

Rejected for testing. [Latest rejection](https://appstoreconnect.apple.com/apps/1569798025/appstore/reviewsubmissions/threads/01bf226f-2fa1-3c31-8dfe-3836dd2ebfbf)\\
Working in TestFlight
