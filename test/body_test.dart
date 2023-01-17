import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:test/test.dart';

class Test {
  final String title;

  const Test(this.title);
}

class TestBody extends Body<Test> {
  const TestBody(super.data);

  @override
  Test parse() => Test(data['title']);
}

void main() {
  test('body', () {
    final testBody = TestBody({'title': 'Shelf helpers example'});

    final test = testBody.parse();
    expect(test.title, 'Shelf helpers example');
  });
}
