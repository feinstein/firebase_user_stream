import 'package:firebase_user_stream/firebase_user_stream.dart';

/// This example is just to show how can you use the library on your code. As
/// this library works very tightly with [FirebaseAuth] it's hard to make a
/// simple example, as we will need to add a sign-in or sign-out in the example
/// itself, which goes beyond the libraries' purposes.
void main() {
  FirebaseUserReloader.onUserReloaded.listen((user) {
    print('Reloaded: $user');
  });

  FirebaseUserReloader.onAuthStateChangedOrReloaded.listen((user) {
    print('Reloaded or auth state changed: $user');
  });

  FirebaseUserReloader.reloadCurrentUser();
  FirebaseUserReloader.reloadCurrentUser((user) => user.emailVerified);
}