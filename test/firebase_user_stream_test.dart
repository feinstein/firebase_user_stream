// Copyright 2020 Michel Feinstein. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      await FirebaseUserReloader.reloadCurrentUser((_) => true);
    });

    test('Reloads does not emit the new User when predicate is false in '
         'onUserReloaded', () async {
      var subscription = FirebaseUserReloader.onUserReloaded.listen((_) {
        fail('Should not emit');
      });

      // Doesn't emit
      await FirebaseUserReloader.reloadCurrentUser((_) => false);
      await Future.delayed(const Duration(milliseconds: 500));
      await subscription.cancel();
    });

    test('Reloads emits the new User in onAuthStateChangedOrReloaded',
        () async {
      expect(FirebaseUserReloader.onAuthStateChangedOrReloaded,
          emitsInOrder([mockOldUser, mockNewUser]));
      await FirebaseUserReloader.reloadCurrentUser();
    });

    test('Current user is emmited when subscribing to '
         'onAuthStateChangedOrReloaded',
            () async {
          expect(FirebaseUserReloader.onAuthStateChangedOrReloaded,
              emits(mockOldUser));
        });
  });
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseUser extends Mock implements FirebaseUser {}
