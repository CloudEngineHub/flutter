// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'text_input_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutofillClient', () {
    late FakeTextChannel fakeTextChannel;
    final FakeAutofillScope scope = FakeAutofillScope();

    setUp(() {
      fakeTextChannel = FakeTextChannel((MethodCall call) async {});
      TextInput.setChannel(fakeTextChannel);
      scope.clients.clear();
    });

    tearDown(() {
      TextInputConnection.debugResetId();
      TextInput.setChannel(SystemChannels.textInput);
    });

    test('Does not throw if the hint list is empty', () async {
      Object? exception;
      try {
        const AutofillConfiguration(
          uniqueIdentifier: 'id',
          autofillHints: <String>[],
          currentEditingValue: TextEditingValue.empty,
        );
      } catch (e) {
        exception = e;
      }

      expect(exception, isNull);
    });

    test(
      'AutofillClients send the correct configuration to the platform and responds to updateEditingStateWithTag method correctly',
      () async {
        final FakeAutofillClient client1 = FakeAutofillClient(
          const TextEditingValue(text: 'test1'),
        );
        final FakeAutofillClient client2 = FakeAutofillClient(
          const TextEditingValue(text: 'test2'),
        );

        client1.textInputConfiguration = TextInputConfiguration(
          autofillConfiguration: AutofillConfiguration(
            uniqueIdentifier: client1.autofillId,
            autofillHints: const <String>['client1'],
            currentEditingValue: client1.currentTextEditingValue,
          ),
        );

        client2.textInputConfiguration = TextInputConfiguration(
          autofillConfiguration: AutofillConfiguration(
            uniqueIdentifier: client2.autofillId,
            autofillHints: const <String>['client2'],
            currentEditingValue: client2.currentTextEditingValue,
          ),
        );

        scope.register(client1);
        scope.register(client2);
        client1.currentAutofillScope = scope;
        client2.currentAutofillScope = scope;

        scope.attach(client1, client1.textInputConfiguration);

        final Map<String, dynamic> expectedConfiguration = client1.textInputConfiguration.toJson();
        expectedConfiguration['fields'] = <Map<String, dynamic>>[
          client1.textInputConfiguration.toJson(),
          client2.textInputConfiguration.toJson(),
        ];

        fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
          MethodCall('TextInput.setClient', <dynamic>[1, expectedConfiguration]),
        ]);

        const TextEditingValue text2 = TextEditingValue(text: 'Text 2');
        fakeTextChannel.incoming?.call(
          MethodCall('TextInputClient.updateEditingStateWithTag', <dynamic>[
            0,
            <String, dynamic>{client2.autofillId: text2.toJSON()},
          ]),
        );

        expect(client2.currentTextEditingValue, text2);
      },
    );
  });

  group('AutoFillConfiguration', () {
    late AutofillConfiguration fakeAutoFillConfiguration;
    late AutofillConfiguration fakeAutoFillConfiguration2;

    setUp(() {
      // If you create two objects with `const` with the same values, the second object will be equal to the first one by reference.
      // This means that even without overriding the `equals` method, the test will pass.
      // ignore: prefer_const_constructors
      fakeAutoFillConfiguration = AutofillConfiguration(
        uniqueIdentifier: 'id1',
        // ignore: prefer_const_literals_to_create_immutables
        autofillHints: <String>['client1'],
        currentEditingValue: TextEditingValue.empty,
        hintText: 'hint',
      );
      // ignore: prefer_const_constructors
      fakeAutoFillConfiguration2 = AutofillConfiguration(
        uniqueIdentifier: 'id1',
        // ignore: prefer_const_literals_to_create_immutables
        autofillHints: <String>['client1'],
        currentEditingValue: TextEditingValue.empty,
        hintText: 'hint',
      );
    });

    test('equality operator works correctly', () {
      expect(fakeAutoFillConfiguration, equals(fakeAutoFillConfiguration2));
      expect(fakeAutoFillConfiguration.enabled, equals(fakeAutoFillConfiguration2.enabled));
      expect(
        fakeAutoFillConfiguration.uniqueIdentifier,
        equals(fakeAutoFillConfiguration2.uniqueIdentifier),
      );
      expect(
        fakeAutoFillConfiguration.autofillHints,
        equals(fakeAutoFillConfiguration2.autofillHints),
      );
      expect(
        fakeAutoFillConfiguration.currentEditingValue,
        equals(fakeAutoFillConfiguration2.currentEditingValue),
      );
      expect(fakeAutoFillConfiguration.hintText, equals(fakeAutoFillConfiguration2.hintText));
    });

    test('hashCode works correctly', () {
      expect(fakeAutoFillConfiguration.hashCode, equals(fakeAutoFillConfiguration2.hashCode));
      expect(
        fakeAutoFillConfiguration.enabled.hashCode,
        equals(fakeAutoFillConfiguration2.enabled.hashCode),
      );
      expect(
        fakeAutoFillConfiguration.uniqueIdentifier.hashCode,
        equals(fakeAutoFillConfiguration2.uniqueIdentifier.hashCode),
      );
      expect(
        Object.hashAll(fakeAutoFillConfiguration.autofillHints),
        equals(Object.hashAll(fakeAutoFillConfiguration2.autofillHints)),
      );
      expect(
        fakeAutoFillConfiguration.currentEditingValue.hashCode,
        equals(fakeAutoFillConfiguration2.currentEditingValue.hashCode),
      );
      expect(
        fakeAutoFillConfiguration.hintText.hashCode,
        equals(fakeAutoFillConfiguration2.hintText.hashCode),
      );
    });
  });
}

class FakeAutofillClient implements TextInputClient, AutofillClient {
  FakeAutofillClient(this.currentTextEditingValue);

  @override
  String get autofillId => hashCode.toString();

  @override
  late TextInputConfiguration textInputConfiguration;

  @override
  void updateEditingValue(TextEditingValue newEditingValue) {
    currentTextEditingValue = newEditingValue;
    latestMethodCall = 'updateEditingValue';
  }

  @override
  AutofillScope? currentAutofillScope;

  String latestMethodCall = '';

  @override
  TextEditingValue currentTextEditingValue;

  @override
  void performAction(TextInputAction action) {
    latestMethodCall = 'performAction';
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    latestMethodCall = 'performPrivateCommand';
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    latestMethodCall = 'commitContent';
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    latestMethodCall = 'updateFloatingCursor';
  }

  @override
  void connectionClosed() {
    latestMethodCall = 'connectionClosed';
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    latestMethodCall = 'showAutocorrectionPromptRect';
  }

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {
    latestMethodCall = 'didChangeInputControl';
  }

  @override
  void autofill(TextEditingValue newEditingValue) => updateEditingValue(newEditingValue);

  @override
  void showToolbar() {
    latestMethodCall = 'showToolbar';
  }

  @override
  void insertTextPlaceholder(Size size) {
    latestMethodCall = 'insertTextPlaceholder';
  }

  @override
  void removeTextPlaceholder() {
    latestMethodCall = 'removeTextPlaceholder';
  }

  @override
  void performSelector(String selectorName) {
    latestMethodCall = 'performSelector';
  }
}

class FakeAutofillScope with AutofillScopeMixin implements AutofillScope {
  final Map<String, AutofillClient> clients = <String, AutofillClient>{};

  @override
  Iterable<AutofillClient> get autofillClients => clients.values;

  @override
  AutofillClient getAutofillClient(String autofillId) => clients[autofillId]!;

  void register(AutofillClient client) {
    clients.putIfAbsent(client.autofillId, () => client);
  }
}
