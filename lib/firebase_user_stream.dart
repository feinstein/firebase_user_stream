// Copyright 2020 Michel Feinstein. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_user_stream;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

typedef EmissionPredicate = bool Function(User user);

class FirebaseUserReloader {
  static FirebaseAuth _auth;

  static FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth;
  }

  @visibleForTesting
  static set auth(FirebaseAuth value) {
    if (_auth != value && value != null) {
      _auth = value;
      _onAuthStateChangedOrReloaded =
          _mergeWithOnUserReloaded(_auth.authStateChanges());
    }
  }

  static final StreamController<User> _userReloadedStreamController =
      StreamController<User>.broadcast();

  /// Receive a [User] each time the user is reloaded by
  /// [reloadCurrentUser].
  static Stream<User> get onUserReloaded =>
      _userReloadedStreamController.stream;

  static Stream<User> _onAuthStateChangedOrReloaded =
      _mergeWithOnUserReloaded(auth.authStateChanges());

  /// Receive [User] each time the user signIn, signOut or is reloaded
  /// by [reloadCurrentUser].
  static Stream<User> get onAuthStateChangedOrReloaded =>
      _onAuthStateChangedOrReloaded;

  /// Merges the given [Stream] with [onUserReloaded] as a broadcast [Stream].
  static Stream<User> _mergeWithOnUserReloaded(Stream<User> stream) {
    return Rx.merge([stream, onUserReloaded]).publishValue()..connect();
  }

  /// Reloads the current [User], using an optional predicate to decide
  /// if the reloaded [User] should be emitted by [onUserReloaded] or
  /// not. If a predicate isn't provided the reloaded [User] will
  /// always be emitted.
  ///
  /// The reloaded [User] will always be returned, independently of the
  /// predicate's result.
  ///
  /// Example for getting updates only when [User.emailVerified]
  /// is true:
  ///
  /// ```dart
  /// FirebaseUserReloader.onUserUpdated.listen((user) {
  ///      print(user);
  /// });
  ///
  /// // Calling this will print the user, if its email has been verified.
  /// await FirebaseUserReloader.reloadCurrentUser(FirebaseAuth.instance,
  ///     (user) => user.emailVerified);
  /// ```
  static Future<User> reloadCurrentUser(
      [EmissionPredicate predicate]) async {
    User oldUser = auth.currentUser;
    // we need to first reload to then get the updated data.
    await oldUser.reload();
    User newUser = auth.currentUser;

    if (predicate == null || predicate(newUser)) {
      _userReloadedStreamController.add(newUser);
    }

    return newUser;
  }
}
