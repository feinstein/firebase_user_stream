// Copyright 2020 Michel Feinstein. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_user_stream;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

typedef EmissionPredicate = bool Function(FirebaseUser user);

class FirebaseUserReloader {
  static FirebaseAuth _auth = FirebaseAuth.instance;

  @visibleForTesting
  static set auth(FirebaseAuth value) {
    if (_auth != value) {
      _auth = value;
      _onAuthStateChangedOrReloaded =
          _mergeWithOnUserReloaded(_auth.onAuthStateChanged);
    }
  }

  static FirebaseAuth get auth => _auth;

  static final StreamController<FirebaseUser> _userReloadedStreamController =
      StreamController<FirebaseUser>.broadcast();

  /// Receive a [FirebaseUser] each time the user is reloaded by
  /// [reloadCurrentUser].
  static Stream<FirebaseUser> get onUserReloaded =>
      _userReloadedStreamController.stream;

  static Stream<FirebaseUser> _onAuthStateChangedOrReloaded =
      _mergeWithOnUserReloaded(_auth.onAuthStateChanged);

  /// Receive [FirebaseUser] each time the user signIn, signOut or is reloaded
  /// by [reloadCurrentUser].
  static Stream<FirebaseUser> get onAuthStateChangedOrReloaded =>
      _onAuthStateChangedOrReloaded;

  /// Merges the given [Stream] with [onUserReloaded] as a broadcast [Stream].
  static Stream<FirebaseUser> _mergeWithOnUserReloaded(
      Stream<FirebaseUser> stream) {
    return Rx.merge([stream, onUserReloaded]).publishValue()..connect();
  }

  /// Reloads the current [FirebaseUser], using an optional [predicate] to decide
  /// if the reloaded [FirebaseUser] should be emitted by [onUserReloaded] or
  /// not. If a predicate isn't provided the reloaded [FirebaseUser] will
  /// always be emitted. An optional [oldUser] is also given, if you already
  /// have this.
  ///
  /// The reloaded [FirebaseUser] will always be returned, independently of the
  /// predicate's result.
  ///
  /// Example for getting updates only when [FirebaseUser.isEmailVerified]
  /// is true:
  ///
  /// ```dart
  /// FirebaseUserReloader.onUserUpdated.listen((user) {
  ///      print(user);
  /// });
  ///
  /// // Calling this will print the user, if its email has been verified.
  /// await FirebaseUserReloader.reloadCurrentUser(
  ///     predicate: (user) => user.isEmailVerified);
  /// ```
  static Future<FirebaseUser> reloadCurrentUser({
    EmissionPredicate predicate,
    FirebaseUser oldUser,
  }) async {
    if (oldUser == null) {
      oldUser = await auth.currentUser();
    }
    // we need to first reload to then get the updated data.
    await oldUser.reload();
    FirebaseUser newUser = await auth.currentUser();

    if (predicate == null || predicate(newUser)) {
      _userReloadedStreamController.add(newUser);
    }

    return newUser;
  }
}
