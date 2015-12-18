# autocompile-jade package

Auto compile jade file on save.

---

Add the parameters on the first line of the jade file.

```
out (string): relative path to html file to create
compress (bool): compress JS file (defaults to true)
obj (bool): relative path to json file to include
```

```
//- out: .
```

```
//- out: ../build/
```

```
//- out: . ,obj: index.json ,compress: false
```

Uses the jade installation of your current project, but falls back to its own jade installation if there is none. Never uses a global one.

Jade is called over its own cli, so it runs in node and not in atom.

## License
Copyright (c) 2015 Paul Pflugradt
Licensed under the MIT license.
