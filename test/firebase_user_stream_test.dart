// Copyright 2020 Michel Feinstein. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_user_stream/firebase_user_stream.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('FirebaseUserReloader', () {
    MockFirebaseAuth mockAuth;
    MockFirebaseUser mockNewUser;
    MockFirebaseUser mockOldUser;

    MockFirebaseUser currentUser;

    StreamSubscription<FirebaseUser> subscription;

    setUp(() {
      mockOldUser = MockFirebaseUser();
      mockNewUser = MockFirebaseUser();

      when(mockOldUser.reload()).thenAnswer((_) async {
        currentUser = mockNewUser;
        return null;
      });

      when(mockOldUser.isEmailVerified).thenReturn(false);
      when(mockNewUser.isEmailVerified).thenReturn(true);

      mockAuth = MockFirebaseAuth();
      when(mockAuth.currentUser())
          .thenAnswer((_) => Future<FirebaseUser>.value(currentUser));
      when(mockAuth.onAuthStateChanged)
          .thenAnswer((_) => Stream<FirebaseUser>.value(mockOldUser));

      currentUser = mockOldUser;
      FirebaseUserReloader.auth = mockAuth;
    });

    test('Reloads returns the new User', () async {
      var user = await FirebaseUserReloader.reloadCurrentUser();
      expect(user, equals(mockNewUser));
    });

    test('Reloads emits the new User in onUserReloaded', () async {
      expect(FirebaseUserReloader.onUserReloaded, emits(mockNewUser));
      await FirebaseUserReloader.reloadCurrentUser();
    });

    test('Reloads emits the new User when predicate is true in onUserReloaded',
        () async {
      expect(FirebaseUserReloader.onUserReloaded, emits(mockNewUser));
      await FirebaseUserReloader.reloadCurrentUser(predicate: (_) => true);
    });

    test('Reloads emits the new User when given oldUser in onUserReloaded', () async {
      expect(FirebaseUserReloader.onUserReloaded, emits(mockNewUser));
      await FirebaseUserReloader.reloadCurrentUser(oldUser: mockOldUser);
    });

    test('Reloads does not emit the new User when predicate is false in '
         'onUserReloaded', () async {
      subscription = FirebaseUserReloader.onUserReloaded.listen((_) {
        fail('Should not emit');
      });

      // Doesn't emit
      await FirebaseUserReloader.reloadCurrentUser(predicate: (_) => false);
      await Future.delayed(const Duration(milliseconds: 500));
    });

    test('Reloads emits the new User in onAuthStateChangedOrReloaded', () async {
      final List<FirebaseUser> expected = [mockOldUser, mockNewUser];
      int i = 0;

      subscription = FirebaseUserReloader.onAuthStateChangedOrReloaded.listen(expectAsync1(
        (user) => expect(user, expected[i++]),
        count: expected.length,
      ));

      await FirebaseUserReloader.reloadCurrentUser();
    });

    test('Current user is emitted when subscribing to onAuthStateChangedOrReloaded', () {
      subscription = FirebaseUserReloader.onAuthStateChangedOrReloaded.listen(
        expectAsync1((user) => expect(user, mockOldUser)),
      );
    });

    test('Allow many subscribers to the onUserReloaded Stream', () {
      expect(FirebaseUserReloader.onUserReloaded.isBroadcast, isTrue);
    });

    test('Allow many subscribers to the onAuthStateChangedOrReloaded Stream', () {
      expect(FirebaseUserReloader.onAuthStateChangedOrReloaded.isBroadcast, isTrue);
    });

    // good tips on how to test streams: https://github.com/dart-lang/stream_transform/blob/06a0740059e0595694b61b27342b7aad85123a3f/test/merge_test.dart#L54-L74
    test('onAuthStateChangedOrReloaded never shuts down, '
         'even if all listeners disconnect', () async {
      int i = 0;

      subscription = FirebaseUserReloader.onAuthStateChangedOrReloaded.listen(
        (_) => i++,
      );

      await FirebaseUserReloader.reloadCurrentUser();

      while (i < 2) {
        // necessary to get the stream async emissions.
        await Future(() {});
      }

      subscription?.cancel();

      subscription = FirebaseUserReloader.onAuthStateChangedOrReloaded.listen(
        expectAsync1((user) => expect(user, mockNewUser), count: 2),
      );

      await FirebaseUserReloader.reloadCurrentUser();
    });

    tearDown(() async => await subscription?.cancel());
  });
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements FirebaseUser {}
