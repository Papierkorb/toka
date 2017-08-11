# Toːka [![Build Status](https://travis-ci.org/Papierkorb/toka.svg?branch=master)](https://travis-ci.org/Papierkorb/toka)

A type-safe, object-oriented option parser using the mapping-pattern.

## Simple usage

**Note**: If you're unfamiliar with UNIX-style argument passing, see the
[explanation below](#explanation-of-argument-passing).

Doesn't get much simpler than this:

```crystal
require "toka"

class MyOptions # Create a container class
  Toka.mapping({ # Don't forget the opening braces!
    name: String, # Mandatory option
    last_name: String?, # Optional option
    verbose: Bool, # Mandatory option
  })
end

Now, create an instance:
opts = MyOptions.new # It will use `ARGV` by default!

And access the fields.  Bool-type fields have an question-mark getter too!
puts "Hello, #{opts.name} #{opts.last_name}" if opts.verbose?
```

With this, the user can pass something like `--name Alice --no-verbose`, or
just `--help` (or `-h`) to print a help page.

**Hint** You can find usage-examples in `samples/` !

**Note**: The default help page renderer will `exit()` the process after
printing its output!

### A note on running sample code

If you're running the sample code directly through `crystal` like this:
`$ crystal samples/simple.cr --name=Me --verbose`
you'll get a nasty error message from `crystal` that it doesn't know "--name".

For this to work, you have to tell crystal to stop processing arguments by
adding a "--" between the arguments for the sample program and the source file:

`$ crystal samples/simple.cr -- --name=Me --verbose`

If this is news to you, consider taking a refresher on [UNIX-style argument passing](#explanation-of-argument-passing).

## Advanced usage

`Toka` can do much more than that.  To adjust further settings, you can pass
a `NamedTuple` as value too!

First, an example:

```crystal
class MyOptions
  Toka.mapping({ # Still don't forget the opening braces!
    name: { # This is the settings (named-)tuple
      type: String, # Still a String
      default: "World", # But greet the World if none was given
      description: "Whom to greet", # For the help page
      value_name: "NAME", # Same ^
    },
    last_name: {
      type: String?,
      # nilable: true, # Alternatively, write `type: String` and this
    },
    verbose: {
      type: Bool?, # Trick to detect explicit activation and deactivation
    },
  }, { # Optionally, the info tuple
    banner: "Usage: my_cool_tool [--name]",
    footer: "I'm at the bottom!",
  })
end

Now, create an instance:
opts = MyOptions.new # It will use `ARGV` by default!

And access the fields.  Bool-type fields have an question-mark getter too!
puts "Hello, #{opts.name} #{opts.last_name}" if opts.verbose?
```

The settings tuple supports the following options:

* `type` The type.  Examples: `String`, `Int32?`, `Array(String)`
* `nilable` If the type is optional ("nil-able").  You can also make the `type` nilable for the same effect.
* `default` The default value.
* `long` Allows to manually configure long-options.  Auto-generated from the name otherwise.
* `short` Allows to manually configure short-options.  Auto-generated otherwise.  Set to `false` to disable.
* `converter` Converter to use for the value.  See below.
* `value_converter` Alias for `converter`.
* `key_converter` Converter for the key to use for a `Hash` type.
* `description` The human-readable description.  Can be multi-line.
* `value_name` Human-readable value name, shown next to the option name like: `--foo=HERE`
* `category` Human-readable category name, for grouping in the help page. Optional.

**Note**: The `long` and `short` fields can take a single string, or an
array of strings.  Do *not* prepend dashes yourself, `Toka` will do that!

The *info* argument allows the following options:

* `banner` The banner string.  Displayed as first line(s) in the help page.
* `footer` The footer string.  Displayed as last line(s) in the help page.
* `help` If to auto-generate the `--help`/`-h` option.  Defaults to `true`.
* `colors` If the help page shall be colorized.  Defaults to `true`.

## Positional options

All positional options are collected into a the `#positional_options` array.

This includes bare words, argument-looking words with a leading back-slash,
and everything after a stand-alone double-dash "argument":

The line `--one \--two three -- --four -five six` would activate the "one"
switch, and collect the positional options like this:
`[ "--two", "three", "--four", "-five", "six" ]`.

## Converters

A converter is a module or class, responding to `.read(raw_value : String) : T?`.
On success, this method returns an instance of `T`, otherwise, it can
either return `nil` to prompt a default error message, or raise a more
descriptive one itself.

```crystal
module IpV4Converter # Sample only!  Please do more error checking in your converters!
  def self.read(input : String) : Int32? # You can also just write `Int32`
    input.split(".", 4).map(&.to_u32).reduce(0u32){|x, a| (a << 8) | x}
  end
end

class MyOptions
  Toka.mapping({
    addr: { # Reacts to `--addr`
      type: UInt32, # The result will be a UInt32
      converter: IpV4Converter # And we want to use this converter
    },
  })
end
```
## Input verification

It is possible to verify input data before it's being used.  To do this,
pass a `Proc` through the `verifier` (or `value_verifier`) field setting.
For the key of a `Hash` type, `key_verifier` is what you're looking for.

This `Proc` gets passed the already converted value, and is then expected to
return either a `false` or a `String` to signal an error, or anything else
to signal success.

If the verifier responds with a `false`, the user will receive a generic
`Toka::VerificationError`.  If the response is a `String`, it will be
appeneded to its message for further context.

```crystal
class MyOptions
  Toka.mapping({
    name: {
      type: String, #  vvvvvv Type is required for Crystal!
      verifier: ->(x : String){ x == "Bob" } # Only accepts "Bob" as input
    },
    age: {
      type: Int32, # Simple age restriction with additional message:
      verifier: ->(x : Int32){ x >= 18 || "Must be an adult" }
    }
  })
end
```

**Note**: The verifier can be anything that responds to `#call()`, behaving
like a `Proc`.  You could also have a module which responds to
`self.call(x)`, and pass in that module.

## Error handling

When an error is encountered while parsing the input, a sub-class of
`Toka::Error` is raised.  All error classes provide additional data to
the error handler by carrying additional fields, next to the standard
message.

**Note**: A converter or verifier raising a custom error are not handled
by Toka.  They're passed through.  Albeit losing the additional information
Toka errors provide, this is supported.

## Sequential and associative options

By using `Array(T)` or `Hash(K, V)` as type, you allow the user to pass in
multiple values for a single option.  They're added in the order they're
read: The left-most value will be the first one to be added, and so on.

For `Array(T)`, the user has to repeat the option for each element to be
added. If you have an option called `many` of type `Array(String)`, the user
passes `--many one --many two --many three` to generate
`[ "one", "two", "three" ]`.

For `Hash(K, V)`, the user repeats the option for each key-value pair,
separating the key from the value using an equal-sign ("=") like this:
`--many foo=bar --many one=two` will generate
`{ "foo" => "bar", "one" => "two" }`.

You're not restricted to using `String`.  You can use whichever type you
want.  The built-in ones will just work, for others, use a custom converter.
Converters will be invoked with one value each, and thus work out of the box.

**Note**: These containers are not nil-able.  Instead, you'll get an empty
container.  You can still pass a default one though!

```crystal
class MyOptions
  Toka.mapping({
    name: Array(String), # Simple usage
    ints: Array(Int32), # Works too
    streets: {
      type: Array(String),
      default: [ "Foo st", "Bar st" ], # Will only be used if none are given.
    },
    birthday: {
      type: Hash(String, Time), # Associative data
      key_converter: TitelizeName, # Converter for the key
      value_converter: TimeConverter, # Converter for the value
      # converter: TimeConverter, # Alias, equivalent to the one above
    },
  })
end
```

**Note**: The parser is restricted to `Array` and `Hash`.  You can't use other
generic types.

## Boolean behaviour

`Bool` is somewhat special.  Switches of this type don't require a value.
If the user wants to explicitly set one, `--switch=false` has to be used.
A following `true` or `false` will **not** be detected.

Further, a `Bool` switch automatically gets two versions:  The active
version, and the inactive one.  The long-name for the inactive one is the
active name with a "no-" prepended: `--verbose` gets turned into
`--no-verbose`.  For the short-name, the existing short-names are taken and,
if no collisions are detected, inversed by uppercasing the character.  This
also works, if the short-name was auto-generated in the first place.  In
our example, the `--verbose` switch would be assigned `-v` as short switch,
and it would be uppercased to negate: From `-v` to `-V`.

As already noted, the user has to follow a value immediately if one is
passed.  Only the long-name supports this, the short-name **does not**.
So, this will work: `--verbose=true`, but this **will not**: `-vtrue`.

The following inputs will be turned into `true`: `true`, `yes`, `t` and `y`.
For `false`: `false`, `no`, `f`, `n`.  Other inputs will **raise an error**.

### Bool in containers

It's possible to mix containers with Bool, like `Array(Bool)` or
`Hash(String, Bool)`.  No automatic (de-)activation switch is generated
for these cases, meaning the user has to explicitly set the value.

Sample for an array: `-ayes -ayes -ano` gives `[ true, true, false ]`.
Hash sample: `-afoo=yes -abar=no` gives `{ "foo" => true, "bar" => false }`.

## Generation behaviour

The macro tries to do as much for you as possible, so here's what's possible:

* The long-name is generated from the dasherized name: `foo_bar: String` will be turned into `--foo-bar`.
* The short-names are generated from the long-name, prefering the first character of each word of each
  long-name, and using any following characters afterwards.  Done until an unique one is found, or none at all.
* `Bool` type options get both a getter with question-mark and one without: `#verbose` is the same as `#verbose?`
* A `--help` page is generated.  Upon activation through the user, the process is exited!

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  toka:
    github: Papierkorb/toka
```

## Explanation of argument passing

This just covers the common UNIX-style option-passing.  You can skip this if
you're familiar with it - `Toka` implements it!

**Note**: Windows-style passing, using a leading slash (e.g. `/f`) instead
of dashes, are not supported.

First, options are split word-wise (According to the program calling another
program, usually your shell).  A "word" may actually consist out of multiple
readable words separated by a space (" "), so don't get confused.

Second, there are two kinds of options: Switches, and positional options.
The first kind are those which are "named", and are accessed directly by
one of their names.  Positional options are not: All options which do not
look like an option ("bare words") are positional options.

Example: `wc -l foo` This invokes the `wc` utility, passing the `-l` switch,
and the `foo` positional option.

### Long- and short-options

Many options have a long-name, and a short-name. (They may have further
aliases).  Long-names are longer than their short-name counterparts.  They
are distinguished by the leading count of dashes: Two ("--") for a
long-name, and one ("-") for a short-name.

Long-names for an option are usually whole words, but can span multiple
words.  It is common to separate words using a single dash:
`--street-number`.  It is not possible to define multiple long-names at
once.  Sometimes long-names are case-sensitive, other times they're not.
`Toka` implements long-names case-sensitively.

Short-names are commonly one character only.  You can combine multiple
short-name switches into a single word: `-abc` will flip the switches
for `a`, `b` and `c`.  This is equivalent to doing the following: `-a -b -c`.

### Value passing

In many cases it's desirable to pass specific values to a switch for further
configuration.

For long-names, the value can either follow in the same word by separating
the value from the long-name using an equal-sign ("="): `--foo=bar` would
pass the value "bar" to the "foo" switch.  If no equal-sign is found while
requiring a value, the following word is used: `--foo bar` is equivalent.

For short-names, the value *immediately* follows the short option: `-fBar`
would pass "Bar" to the "f" switch.  This is a common source of confusion
and mistakes: Say we have the switch "a" not taking a value, and "b" taking
one.  Now, you want to invoke both, and pass a value to "b". So you write
`-ba foo` - And suddenly, you passed "a" to the "b" switch as value, and
"foo" is treated as positional option.  Correct is this: `-ab foo` - This
activates the "a" switch, and passes "foo" to the "b" switch.  You can also
combine non-value-taking with value-taking short-names into the same word:
`-abfoo` will activate "a", abd pass "foo" to "b".

### Cancelling option parsing

Sometimes it may be useful to tell the option parser that some options are
to be treated as positional options.  There are two solutions to this:

1. Escape it by prepending a back-slash: `\--foo`
2. Ignore everything following by stand-alone double-dash: `--foo -- --bar`
   will activate the "foo" switch, but pass "--bar" as positional option.

## Contributing

1. Fork it ( https://github.com/Papierkorb/toka/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Papierkorb](https://github.com/Papierkorb) Stefan Merettig - creator, maintainer
