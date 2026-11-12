import 'package:carp_survey_package/survey.dart';
import 'package:research_package/research_package.dart';

import 'exports.dart';

void main() {
  test('badJsonValues names the NaN that breaks storing a measurement', () {
    CarpMobileSensing.ensureInitialized();
    final task = RPTaskResult(identifier: 'task')
      ..results['flanker'] = (RPActivityResult(identifier: 'flanker')..results['meanIncongruent'] = double.nan);
    final measurement = Measurement.fromData(RPTaskResultData(SurveyStatus.submitted, task));

    expect(Sensing.badJsonValues(measurement.toJson(), r'$'), [
      r'$.data.result.results.flanker.results.meanIncongruent = NaN',
    ]);
  });
}
