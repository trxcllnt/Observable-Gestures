Observables
===========

Observables is a set of common UI gestures described with Reactive Extensions Observables.

Observables is a set of C# extension methods, a JS class and jQuery plugin, and an AS3 class.

Observables manages interaction state, only one gestural Observable fires at a time even though other gestural Observables may have been triggered along the way.

Interaction targets can be registered in a global Observables pool. Observables exposes a single Observable per gesture, which fires when any registered targets are interacted with.
