---
title: Creating observable state
sidebar_label: Observable state
hide_title: true
---

<script async type="text/javascript" src="//cdn.carbonads.com/carbon.js?serve=CEBD4KQ7&placement=mobxjsorg" id="_carbonads_js"></script>

# Creating observable state

Properties, entire objects, arrays, Maps and Sets can all be made observable.
The basics of making objects observable is specifying an annotation per property using `makeObservable`.
The most important annotations are:

-   `observable` defines a trackable field that stores the state.
-   `action` marks a method as action that will modify the state.
-   `computed` marks a getter that will derive new facts from the state and cache its output.

Collections such as arrays, Maps and Sets are made observable automatically.

## `makeObservable`

Usage:

-   `makeObservable(target, annotations?, options?)`

It can be used to trap _existing_ object properties and make them observable. Any JavaScript object (including class instances) can be passed into `target`.
Typically `makeObservable` is used in the constructor of a class, and its first argument is `this`.
The `annotations` argument maps [annotations](#available-annotations) to each member. Note that when using [decorators](enabling-decorators.md), the `annotations` argument can be omitted.

Methods that derive information and take arguments (for example `findUsersOlderThan(age: number): User[]`) don't need any annotation.
Their read operations will still be tracked when they are called from a reaction, but their output won't be memoized to avoid memory leaks. Check out [MobX-utils computedFn {🚀}](https://github.com/mobxjs/mobx-utils#computedfn) as well.

<!--DOCUSAURUS_CODE_TABS-->
<!--class + makeObservable-->

```javascript
import { makeObservable, observable, computed, action } from "mobx"

class Doubler {
    value

    constructor(value) {
        makeObservable(this, {
            value: observable,
            double: computed,
            increment: action
        })
        this.value = value
    }

    get double() {
        return this.value * 2
    }

    increment() {
        this.value++
    }
}
```

<!--subclass + makeObservable-->

```javascript
import { makeObservable, observable, computed, action } from "mobx"

class Parent {
    // not overridable
    observable1 = 0

    constructor(value) {
        makeObservable(this, {
            observable1: observable,
            computed1: computed,
            action1: action,
            arrowAction1: action
        })
    }

    // overridable
    get computed1() {
        return this.observable * 2
    }

    // overridable
    action1() {
        this.observable++
    }

    // not overridable
    arrowAction1 = () => {}

    // workaround - not annotated - overridable
    overridableArrowAction1 = action(() => {})
}

class Child extends Parent {
    // new
    observable2 = 0

    constructor(value) {
        makeObservable(this, {
            // overriden fields
            action1: override,
            computed1: override,
            // new fields
            observable2: observable,
            computed2: computed,
            action2: action,
            arrowAction2: action
        })
    }

    // overrides
    get computed1() {
        return super.computed1 * 2
    }

    // overrides
    action1() {
        super.action1()
    }

    // workaround - not annotated - overrides
    overridableArrowAction1 = action(() => {})

    // new
    get computed2() {
        return super.computed1 * 2
    }

    // new
    action2() {
        super.action1()
    }

    // new
    arrowAction2 = () => {}
}
```

All annotated fields are non-configurable.
All non-observable (stateless) fields (`action`, `flow`) are non-writable.
Only `action`, `computed`, `flow`, `action.bound` defined on prototype can be overriden by subclass.
Field can't be re-annotated in subclass, except with `override`.

<!--factory function + makeAutoObservable-->

```javascript
import { makeAutoObservable } from "mobx"

function createDoubler(value) {
    return makeAutoObservable({
        value,
        get double() {
            return this.value * 2
        },
        increment() {
            this.value++
        }
    })
}
```

Note that classes can leverage `makeAutoObservable` as well.
The difference in the examples just demonstrate how MobX can be applied to different programming styles.

<!--observable-->

```javascript
import { observable } from "mobx"

const todosById = observable({
    "TODO-123": {
        title: "find a decent task management system",
        done: false
    }
})

todosById["TODO-456"] = {
    title: "close all tickets older than two weeks",
    done: true
}

const tags = observable(["high prio", "medium prio", "low prio"])
tags.push("prio: for fun")
```

In contrast to the first example with `makeObservable`, `observable` supports adding (and removing) _fields_ to an object.
This makes `observable` great for collections like dynamically keyed objects, arrays, Maps and Sets.

<!--END_DOCUSAURUS_CODE_TABS-->

## `makeAutoObservable`

Usage:

-   `makeAutoObservable(target, overrides?, options?)`

`makeAutoObservable` is like `makeObservable` on steroids, as it infers all the properties by default. You can still use `overrides` to override the default behavior with specific annotations.
In particular `false` can be used to exclude a property or method from being processed entirely.
Check out the code tabs above for an example.
The `makeAutoObservable` function can be more compact and easier to maintain than using `makeObservable`, since new members don't have to be mentioned explicitly.
However, `makeAutoObservable` cannot be used on classes that have super or are subclassed.

Inference rules:

-   Any (inherited) member that contains a `function` value will be annotated with `autoAction`.
-   Any `get`ter will be annotated with `computed`.
-   Any other _own_ field will be marked with `observable`.
-   Any (inherited) member that is a generator function will be annotated with `flow`. (Note that generators functions are not detectable in some transpiler configurations, if flow doesn't work as expected, make sure to specify `flow` explicitly.)
-   Members marked with `false` in the `overrides` argument will not be annotated. For example, using it for read only fields such as identifiers.

## `observable`

Usage:

-   `observable(source, overrides?, options?)`

The `observable` annotation can also be called as a function to make an entire object observable at once.
The `source` object will be cloned and all members will be made observable, similar to how it would be done by `makeAutoObservable`.
Likewise, an `overrides` map can be provided to specify the annotations of specific members.
Check out the above code block for an example.

The object returned by `observable` will be a Proxy, which means that properties that are added later to the object will be picked up and made observable as well (except when [proxy usage](configuration.md#proxy-support) is disabled).

The `observable` method can also be called with collections types like [arrays](api.md#observablearray), [Maps](api.md#observablemap) and [Sets](api.md#observableset). Those will be cloned as well and converted into their observable counterparts.

<details id="observable-array"><summary>**Example:** observable array<a href="#observable-array" class="tip-anchor"></a></summary>

The following example creates an observable and observes it using [`autorun`](reactions.md#autorun).
Working with Map and Set collections works similarly.

```javascript
import { observable, autorun } from "mobx"

const todos = observable([
    { title: "Spoil tea", completed: true },
    { title: "Make coffee", completed: false }
])

autorun(() => {
    console.log(
        "Remaining:",
        todos
            .filter(todo => !todo.completed)
            .map(todo => todo.title)
            .join(", ")
    )
})
// Prints: 'Remaining: Make coffee'

todos[0].completed = false
// Prints: 'Remaining: Spoil tea, Make coffee'

todos[2] = { title: "Take a nap", completed: false }
// Prints: 'Remaining: Spoil tea, Make coffee, Take a nap'

todos.shift()
// Prints: 'Remaining: Make coffee, Take a nap'
```

Observable arrays have some additional nifty utility functions:

-   `clear()` removes all current entries from the array.
-   `replace(newItems)` replaces all existing entries in the array with new ones.
-   `remove(value)` removes a single item by value from the array. Returns `true` if the item was found and removed.

</details>

<details id="non-convertibles"><summary>**Note:** primitives and class instances are never converted to observables<a href="#non-convertibles" class="tip-anchor"></a></summary>

Primitive values cannot be made observable by MobX since they are immutable in JavaScript (but they can be [boxed](api.md#observablebox)).
Although there is typically no use for this mechanism outside libraries.

Class instances will never be made observable automatically by passing them to `observable` or assigning them to an `observable` property.
Making class members observable is considered the responsibility of the class constructor.

</details>

<details id="avoid-proxies"><summary>{🚀} **Tip:** observable (proxied) versus makeObservable (unproxied)<a href="#avoid-proxies" class="tip-anchor"></a></summary>

The primary difference between `make(Auto)Observable` and `observable` is that the first one modifies the object you are passing in as first argument, while `observable` creates a _clone_ that is made observable.

The second difference is that `observable` creates a `Proxy` object, to be able to trap future property additions in case you use the object as a dynamic lookup map.
If the object you want to make observable has a regular structure where all members are known up-front, we recommend to use `makeObservable` as non proxied objects are a little faster, and they are easier to inspect in the debugger and `console.log`.

Because of that, `make(Auto)Observable` is the recommended API to use in factory functions.
Note that it is possible to pass `{ proxy: false }` as an option to `observable` to get a non proxied clone.

</details>

## Available annotations

| Annotation                         | Description                                                                                                                                                                                                                |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `observable`<br/>`observable.deep` | Defines a trackable field that stores state. Any value assigned to an `observable` field will be made recursively observable as well, if possible. That is, if and only if the value is a plain object, array, Map or Set. |
| `observable.ref`                   | Like `observable`, but only reassignments will be tracked. The assigned values themselves won't be made observable automatically. For example, use this if you intend to store immutable data in an observable field.      |
| `observable.shallow`               | Like `observable.ref` but for collections. Any collection assigned will be made observable, but the contents of the collection itself won't become observable.                                                             |
| `observable.struct`                | Like `observable`, except that any assigned value that is structurally equal to the current value will be ignored.                                                                                                         |
| `action`                           | Mark a method as an action that will modify the state. Check out [actions](actions.md) for more details. Non-writable.                                                                                                     |
| `action.bound`                     | Like action, but will also bind the action to the instance so that `this` will always be set. Non-writable.                                                                                                                |
| `computed`                         | Can be used on a [getter](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/get) to declare it as a derived value that can be cached. Check out [computeds](computeds.md) for more details.      |
| `computed.struct`                  | Like `computed`, except that if after recomputing the result is structurally equal to the previous result, no observers will be notified.                                                                                  |
| `true`                             | Infer the best annotation. Check out [makeAutoObservable](#makeautoobservable) for more details.                                                                                                                           |
| `false`                            | Explicitly do not annotate this property.                                                                                                                                                                                  |
| `flow`                             | Creates a `flow` to manage asynchronous processes. Check out [flow](actions.md#using-flow-instead-of-async--await-) for more details. Note that the inferred return type in TypeScript might be off. Non-writable.         |
| `override`                         | Applicable to inherited `action`, `flow`, `computed`, `action.bound` overriden by subclass.                                                                                                                                |
| `autoAction`                       | Should not be used explicitly, but is used under the hood by `makeAutoObservable` to mark methods that can act as action or derivation, based on their calling context.                                                    |

## Limitations

1. `make(Auto)Observable` only supports properties that are already defined. Make sure your compiler configuration is [correct](installation.md#use-spec-compliant-transpilation-for-class-properties), or as work-around, that a value is assigned to all properties before using `make(Auto)Observable`. Without correct configuration, fields that are declared but not initialized (like in `class X { y; }`) will not be picked up correctly.
1. `makeObservable` can only annotate properties declared by its own class definition. If a sub- or superclass introduces observable fields, it will have to call `makeObservable` for those properties itself.
1. Every field can be annotated only once (except for `override`). The field annotation or configuration can't change in subclass.
1. All annotated fields of **non-plain** objects (classes) are **non-configurable**.
1. All non-observable (stateless) fields (`action`, `flow`) are **non-writable**.
1. Only `action`, `computed`, `flow`, `action.bound` defined on _prototype_ can be overriden by subclass.
1. By default TypeScript will not allow you to annotate private fields. This can be overcome by explicitly passing the relevant private fields as generic argument, like this: `makeObservable<MyStore, "myPrivateField" | "myPrivateField2">(this, { myPrivateField: observable, myPrivateField2: observable })`.
1. Calling `make(Auto)Observable` and providing annotations must be done unconditionally, as this makes it possible to cache the inference results.
1. JavaScript private fields are not supported (the `#field` syntax). When using TypeScript, it is recommended to use the `private` modifier instead.
1. Mixing annotations and decorators within single inheritance chain is not supported - eg you can't use decorators for parent class and annotations for subclass.

## Options {🚀}

The above APIs take an optional `options` argument which is an object that supports the following options:

-   `autoBind: true` automatically binds all created actions to the instance.
-   `deep: false` uses `observable.ref` by default, rather than `observable` to create new observable members.
-   `name: <string>` gives the object a debug name that is printed in error messages and reflection APIs.
-   `proxy: false` skips Proxy creating. This is a good option if the shape of the object will not change over time, as non-proxied objects are easier to debug and faster. See [avoiding proxies](#avoid-proxies).

## Converting observables back to vanilla JavaScript collections

Sometimes it is necessary to convert observable data structures back to their vanilla counterparts.
For example when passing observable objects to a React component that can't track observables, or to obtain a clone that should not be further mutated.

To convert a collection shallowly, the usual JavaScript mechanisms work:

```javascript
const plainObject = { ...observableObject }
const plainArray = observableArray.slice()
const plainMap = new Map(observableMap)
```

To convert a data tree recursively to plain objects, the [`toJS`](api.md#tojs) utility can be used.
For classes, it is recommend to implement a `toJSON()` method, as it will be picked up by `JSON.stringify`.

## A short note on classes

So far most examples above have been leaning towards the class syntax.
MobX is in principle unopinionated about this, and there are probably just as many MobX users that use plain objects.
However, a slight benefit of classes is that they have more easily discoverable APIs, e.g. TypeScript.
Also, `instanceof` checks are really powerful for type inference, and class instances aren't wrapped in `Proxy` objects, giving them a better experience in debuggers.
Finally, classes benefit from a lot of engine optimizations, since their shape is predictable, and methods are shared on the prototype.
But heavy inheritance patterns can easily become foot-guns, so if you use classes, keep them simple.
So, even though there is a slight preference to use classes, we definitely want to encourage you to deviate from this style if that suits you better.
