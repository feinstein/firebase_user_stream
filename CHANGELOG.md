## 1.0.0-alpha.3

* Changed the `onAuthStateChangedOrReloaded` to never shutdown, even if all listeners disconnect, so new listeners in the future can still subscribe.
* Modified the tests to include `onAuthStateChangedOrReloaded` new behavior.
* Improved the README.

## 1.0.0-alpha.2

* Changed the `onAuthStateChangedOrReloaded` to be a Behavior Subject.
* Minor modification on the tests.
* Improved the README.

## 1.0.0-alpha

* Fixed the onAuthStateChangedOrReloaded to be a broadcast Stream, as intended originally.
* Added a `await` for the old user reload as this is more consistent and what's expected, even though it's not necessary, as reload is just a simple MethodChannel call.
* Fixed a typo.
* Updated the tests to check if onUserReloaded and onAuthStateChangedOrReloaded are broadcast streams.
* Reformatted the tests.
* Updated the README with information about broadcast streams.

## 0.1.0+4

* Added a pub badge to the README.

## 0.1.0+3

* Added a Testability section to the README.

## 0.1.0+2

* Made the description shorter.

## 0.1.0+1

* Added an example.
* Updated the package description.

## 0.1.0

* Initial release.
