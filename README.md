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
