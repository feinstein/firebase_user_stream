# FirebaseUser Stream

A Package for subscribing to FirebaseUser reload updates.

## The problem
The FirebaseAuth Flutter plugin provides a `Stream<FirebaseUser>` with 
`onAuthStateChanged`, which is useful for getting updates when a user signs-in 
or signs-out, but it fails to provide an update when the user data itself changes.

A common problem is when we want to detect if the user has just verified his e-mail 
address, in other words get if `FirebaseUser.isEmailVerified` changed its value, as
this is updated server-side and not pushed to the app. 

`FirebaseAuth.currentUser()` will only detect changes made locally to the user, but 
if any changes are made server-side, it won't detect, unless `FirebaseUser.reload()`
is called first and then we need to call `FirebaseAuth.currentUser()` again to get 
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
using `onUserReloaded` or `onAuthStateChangedOrReloaded`, it's pretty simple. In order
to get reload updates just do:

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
the predicate will be ignored and the reloaded user will always be returned.

```dart
var user = await FirebaseUserReloader.reloadCurrentUser();
 ```

If you want to listen for updates on sign-ins, sign-outs and user reloads, use 
`onAuthStateChangedOrReloaded` instead, it's just a convenient merge of `onUserReloaded` and
`FirebaseAuth.onAuthStateChanged`:

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
## Testing

This library uses `static` methods for easiness of usage, but this doesn't limit its 
testability.

`FirebaseUserReloader` can be injected with a mocked instance of `FirebaseAuth`, which 
can then be used for unit testing.

For any examples on how to control its behavior under tests, please take a loot at our 
own tests inside the `test` folder.