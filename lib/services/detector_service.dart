import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../config.dart';

class DetectorService {
  late Interpreter _interpreter;
  late Interpreter _ageInterpreter;
  late Interpreter _genderInterpreter;

  static const int inputSize = 300;

  Future<void> init() async {
    _interpreter = await Interpreter.fromAsset('assets/ssd_mobilenet_v2.tflite');
    _ageInterpreter = await Interpreter.fromAsset('assets/age_model.tflite');
    _genderInterpreter = await Interpreter.fromAsset('assets/gender_model.tflite');
  }

  List<Map<String, dynamic>> detect(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    final input = List.generate(1, (_) =>
        List.generate(inputSize, (y) =>
            List.generate(inputSize, (x) {
              final pixel = resized.getPixel(x, y);
              return [
                (pixel.r / 127.5) - 1.0,
                (pixel.g / 127.5) - 1.0,
                (pixel.b / 127.5) - 1.0,
              ];
            })));

    final boxes = List.filled(40, 0.0).reshape([1, 10, 4]);
    final classes = List.filled(10, 0.0).reshape([1, 10]);
    final scores = List.filled(10, 0.0).reshape([1, 10]);
    final count = List.filled(1, 0.0).reshape([1]);

    _interpreter.runForMultipleInputs([input], {
      0: boxes,
      1: classes,
      2: scores,
      3: count,
    });

    final results = <Map<String, dynamic>>[];
    final detectionCount = count[0].toInt();

    for (int i = 0; i < detectionCount; i++) {
      if (classes[0][i].toInt() == Config.personClassId &&
          scores[0][i] >= Config.confidenceThreshold) {
        results.add({
          'confidence': scores[0][i],
          'box': boxes[0][i],
        });
      }
    }

    return results;
  }

  Map<String, String> predictAgeGender(img.Image face) {
    final resized = img.copyResize(face, width: 224, height: 224);

    final input = [
      List.generate(224, (y) =>
          List.generate(224, (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          }))
    ];

    final ageOutput = List.filled(8, 0.0).reshape([1, 8]);
    final genderOutput = List.filled(2, 0.0).reshape([1, 2]);

    _ageInterpreter.run(input, ageOutput);
    _genderInterpreter.run(input, genderOutput);

    final ageIndex = ageOutput[0]
        .indexWhere((e) => e == ageOutput[0].reduce((a, b) => a > b ? a : b));

    final genderIndex = genderOutput[0][0] > genderOutput[0][1] ? 0 : 1;

    const ages = ['0-2','4-6','8-12','15-20','25-32','38-43','48-53','60+'];
    const genders = ['male','female'];

    return {
      'age': ages[ageIndex],
      'gender': genders[genderIndex],
    };
  }

  void dispose() {
    _interpreter.close();
    _ageInterpreter.close();
    _genderInterpreter.close();
  }
}
