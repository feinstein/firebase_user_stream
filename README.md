# Firebase User Stream

[![pub package](https://img.shields.io/pub/v/firebase_user_stream.svg)](https://pub.dartlang.org/packages/firebase_user_stream)

A Package for subscribing to User reload updates.

# ATTENTION
Since `firebase_auth` version 0.18.0 this library is mostly pointless as `firebase_auth` (finally) adds 
`authStateChanges()` which mostly substitutes this package, fixing the problem described below.

I mean mostly because here we can have further functionality like: 

 * Reloading based on a predicate
 * Reload and get the user in the same line. 

Although that's not useful to most people.  

## The (old, pre firebase_auth version 0.18.0) problem
The FirebaseAuth Flutter plugin provides a `Stream<FirebaseUser>` with 
`onAuthStateChanged`, which is useful for getting updates when a user signs-in 
or signs-out, but it fails to provide an update when the user data itself changes.

A common problem is when we want to detect if the user has just verified his e-mail 
address, in other words get if `FirebaseUser.isEmailVerified` changed its value, as
this is updated server-side and not pushed to the app. 

`FirebaseAuth.currentUser()` will only detect changes made locally to the user, but 
if any server-side changes occur, it won't detect them, unless `FirebaseUser.reload()`
is called first, then we need to call `FirebaseAuth.currentUser()` again to get 
the reloaded user, but still this user won't be emitted by `onAuthStateChanged`.

## The solution

There are two ways we can get a new `FirebaseUser`, with the latest information on 
the server: 

1. Do it manually:

```dart
Future<FirebaseUser> reloadCurrentUser() async {
  FirebaseUser oldUser = await FirebaseAuth.instance.currentUser();    
  oldUser.reload();
  FirebaseUser newUser = await FirebaseAuth.instance.currentUser();
  // Add newUser to a Stream, maybe merge this Stream with onAuthStateChanged?
  return newUser; 
}
```

2. Let us do it for you!

## Getting Started

After you install this package you can use `FirebaseUserReloader` to get reload updates 
using the `onUserReloaded` and `onAuthStateChangedOrReloaded` streams. 

`FirebaseUserReloader` internally uses the 
`FirebaseAuth` instance returned by `FirebaseAuth.instance`, so your entire App will have the same
[Singleton](https://en.wikipedia.org/wiki/Singleton_pattern) instance, you don't have to configure anything, it just works out of the box.

In order to get reload updates just do:

```dart
var subscription = FirebaseUserReloader.onUserReloaded.listen((user) {
  // A new user will be printed each time there's a reload
  print(user);
});

// This will trigger a reload and the reloaded user will be emitted by onUserReloaded
FirebaseUserReloader.reloadCurrentUser();

subscription.cancel();
```

Each time you call `reloadCurrentUser()` a reloaded user will be emitted by 
`onUserReloaded`.

Keep in mind that `onUserReloaded` will emit reloaded users, they might be new, or just the
current one if the user data didn't change.

As a bonus, you can provide a predicate to `reloadCurrentUser()`, in order to only get reloaded 
users that matter to you:

```dart
var subscription = FirebaseUserReloader.onUserReloaded.listen((user) {
  // A new user will be printed each time there's a reload
  print(user);
});

// This will trigger a reload and the reloaded user will be emitted by onUserReloaded
// only if isEmailVerified == true
FirebaseUserReloader.reloadCurrentUser((user) => user.isEmailVerified);

subscription.cancel();
```

You also can get the reloaded user as the return value of `reloadCurrentUser`, but in this case, 
the predicate will be ignored, and the reloaded user will always be returned.

```dart
var user = await FirebaseUserReloader.reloadCurrentUser();
 ```

If you want to listen for updates on sign-ins, sign-outs and user reloads, use 
`onAuthStateChangedOrReloaded` instead, it's just a convenient merge of `onUserReloaded` and
`FirebaseAuth.onAuthStateChanged` and it works as a broadcast [Behavior Subject](https://pub.dev/documentation/rxdart/latest/rx/BehaviorSubject-class.html):

```dart
var subscription = FirebaseUserReloader.onAuthStateChangedOrReloaded.listen((user) {
  // A new user will be printed each time there's a reload, login or logout
  print(user);
});

// This will trigger a reload and the reloaded user will be emitted by onUserReloaded
// only if isEmailVerified == true
FirebaseUserReloader.reloadCurrentUser((user) => user.isEmailVerified);

subscription.cancel();
```

Both `onAuthStateChangedOrReloaded` and `onUserReloaded` are broadcast streams.

## Testing

This library uses `static` methods for easiness of usage, but this doesn't limit its 
testability.

`FirebaseUserReloader` can be injected with a mocked instance of `FirebaseAuth` for unit testing.

For any examples on how to control its behavior under tests, please take a look at our 
own tests inside the `test` folder.