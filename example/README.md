Exemple of architecture on how to use `shelf_helpers`

## Prerequisite

- sqlite3 >= 3.35 installed

## Run it

### Create database

First we need to create the database.
To do this run :
```sh
dart run tools/create_database.dart
```

### Launch your server

To launch the server :
```sh
dart run bin/server.dart                
```


### Launching your server with hot reload

```sh
dart run --enable-vm-service bin/dev.dart
```
