## [Unreleased]

## 1.6.0 - 2024-11-17

* Add more readable method aliases.
* Make token buffer's state accessible attribute.
* Split files such as parsers.  You might need to require individual files.
* Change token buffer class not to inherit from array class.
* Move XML token generator class to upper namespace.

## 1.5.1 - 2024-11-10

This is a maintenance release, no user facing changes.

* Lint codes: remove unused local variables.
* Use the string scanner's eos check method instead of the empty check one.
* Simplify grammar class implementation.
* Add links about this gem.

## [1.5.0] - 2024-11-08

* Support Ruby 3.1 or later.
* Fix and add tests.
* Format documents.
* Rename some modules; Moved `TDPUtils` and `TDPXML` to `TDParser`.
* Rename require path from `tdp` to `tdparser`.
* Rename the gem name to TDParser from TDP4R.
