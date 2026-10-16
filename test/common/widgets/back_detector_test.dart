import 'package:PiliPlus/common/widgets/back_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show SizedBox;

void main() {
  test('accepts a sufficiently long right swipe from the left screen edge', () {
    expect(
      isEdgeBackSwipe(const Offset(12, 140), const Offset(122, 145)),
      isTrue,
    );
  });

  test('rejects swipes that start away from the left edge', () {
    expect(
      isEdgeBackSwipe(const Offset(40, 140), const Offset(160, 145)),
      isFalse,
    );
  });

  test('rejects short and vertically dominant swipes', () {
    expect(
      isEdgeBackSwipe(const Offset(12, 140), const Offset(100, 145)),
      isFalse,
    );
    expect(
      isEdgeBackSwipe(const Offset(12, 10), const Offset(130, 100)),
      isFalse,
    );
  });

  test('rejects movement to the left', () {
    expect(
      isEdgeBackSwipe(const Offset(12, 140), const Offset(-90, 142)),
      isFalse,
    );
  });

  testWidgets('uses fallback when native route gesture is inactive', (
    tester,
  ) async {
    var backCount = 0;
    await tester.pumpWidget(
      BackDetector(
        enableEdgeSwipe: true,
        nativePopGestureInProgress: () => false,
        onBack: () => backCount++,
        child: const SizedBox.expand(),
      ),
    );

    final gesture = await tester.startGesture(const Offset(10, 140));
    await gesture.moveBy(const Offset(120, 0));
    await gesture.up();

    expect(backCount, 1);
  });

  testWidgets('defers to a native route gesture already in progress', (
    tester,
  ) async {
    var backCount = 0;
    await tester.pumpWidget(
      BackDetector(
        enableEdgeSwipe: true,
        nativePopGestureInProgress: () => true,
        onBack: () => backCount++,
        child: const SizedBox.expand(),
      ),
    );

    final gesture = await tester.startGesture(const Offset(10, 140));
    await gesture.moveBy(const Offset(120, 0));
    await gesture.up();

    expect(backCount, 0);
  });
}
