## 1.0.0-alpha.6

- add a module to manage accounts
    - we currently only support the creation of an account
- add a module to manage authentication
    - we currently only support the login action

To implement this two module we have a bunch of new things
- pbkdf2 implementation for hashing password
- jwt implementation to generate Json Web Token

We also added some minor improvment to the sessionManager middleware and the getBody middleware.

## 1.0.0-alpha.5

- fix parsing on cookie
- add session

## 1.0.0-alpha.4

- cookie manager

## 1.0.0-alpha.3

- auth middleware
- docs
- migrate to Dart 3

## 1.0.0-alpha.2

This version **break** compatibility with the previous one

- Rewrite of everything
