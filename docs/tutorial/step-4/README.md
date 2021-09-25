# Minion Logic

## General Idea

The `Minion` scene shares many similarities with the `ActionBar`, described in the [previous step](https://github.com/git-afsantos/hs-mercs-clone/blob/main/docs/tutorial/step-3/README.md).
It is not a top-level scene, but rather a reusable component.
As such, its logic should be implemented in a way that is independent of its parent node.

The Minion scene script should provide a functional interface, to be called by high-level logic, and its events should be communicated back to the high-level logic via signals.
In addition, `Minion` nodes will hold all the data pertaining to the minion they display, such as *Health* or *Attack* values.

> **Note:** For a more advanced and maintainable approach, all logic data should be implemented in its own files and classes (for example with `Resource`, or some class extending `Reference`).
> To simplify this tutorial, however, everything will be implemented directly in the `Minion` script.


