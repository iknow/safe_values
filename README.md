# SafeValues

`Value` generates `Struct` classes with safer constructors. It is designed to
provide a superset of the interface of the `Values` gem, with better
performance, by subclassing actual native `Struct`s.

`Value` constructors require all mandatory arguments to be provided, and supply
default values for all optional arguments. Additionally, the resulting instance
is frozen. To obtain a mutable `Value`, use `dup`.

`Value` types are created similarly to `Struct`s, with the addition that
optional arguments are may be specified as keyword arguments:

```ValueType = Value.new(:a, :b, c: default_value)```

The default values to optional arguments are saved at class creation time and
supplied as default constructor arguments to instances. Default values are
aliased, so providing mutable defaults is discouraged.

Two instance constructors are provided, with positional and keyword arguments.

Value types may be constructed with positional arguments using `new`. Arguments
are provided in the same order as specified at class initialization time, with
mandatory arguments before optional ones. For example:

```ValueType.new(1, 2)```
or
```ValueType.new(1, 2, 3)```

Value types may be constructed with keyword arguments using `with`. For example:

```ValueType.with(a: 1, b: 2)```
or
```ValueType.with(a: 1, b: 2, c: 3)```
