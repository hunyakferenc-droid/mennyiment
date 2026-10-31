import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/savings_milestones.dart';

void main() {
  test('Nem jutalmazza a még nem félretett pénzt', () {
    expect(MentiMilestones.achieved(savedFt: 0, targetFt: 10000), isEmpty);
    expect(MentiMilestones.percent(savedFt: 0, targetFt: 10000), 0);
  });
  test('A mérföldkövek küszöb alapján nyílnak meg', () {
    expect(MentiMilestones.achieved(savedFt: 2499, targetFt: 10000), isEmpty);
    expect(MentiMilestones.achieved(savedFt: 2500, targetFt: 10000), [25]);
    expect(MentiMilestones.achieved(savedFt: 5000, targetFt: 10000), [25, 50]);
    expect(MentiMilestones.achieved(savedFt: 10000, targetFt: 10000), [25, 50, 75, 100]);
  });
  test('A túlfinanszírozott cél 100%-nál megáll', () {
    expect(MentiMilestones.percent(savedFt: 20000, targetFt: 10000), 100);
  });
  test('A nulla célösszeg nem eredményez mérföldkövet', () {
    expect(MentiMilestones.achieved(savedFt: 1000, targetFt: 0), isEmpty);
  });
}
