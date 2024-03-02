---
title: Writing clean and readable Espresso tests with Kappuccino
date: 2017-10-27 00:00:00 Z
tags:
- espresso
layout: post
current: post
cover: assets/images/espresso-android.png
navigation: true
class: post-template
subclass: post
author: heitorcolangelo
---

# Writing clean and readable Espresso tests with Kappuccino

Using Espresso to write your UI tests can be quite repetitive and, as a consequence, boring. Most of the time you end up repeating the same methods a lot of times and you have to write a lot of code to make a simple task in your UI:

![](https://cdn-images-1.medium.com/max/800/1*aanpYt1jNyWmKyO2McEfdQ.png)

When user types a not registered e-mail, the app shows register form.

Did you notice how many times the methods _onView, withId, check, matches, isDisplayed_ are repeated? That makes the code quite confusing to read and maintain. If you notice, the only thing that changes between each line, is the _id_ of the view that you want to check the visibility.

What if we could write this test in a more concise, easy and clean way? Like this:

![](https://cdn-images-1.medium.com/max/800/1*wjzVyVQZjqJMxMJxwAZrIQ.png)

Same test, more readable

Well, now with [Kappuccino](https://github.com/heitorcolangelo/kappuccino) you can!

When you write all of this lines of code

![](https://cdn-images-1.medium.com/max/800/1*N0OpkopS_n5zlxMgGHjMTA.png)

All you really want to do is: check if the views with these _ids_ (in purple) are displayed on the screen. So we used this idea and create a library so you can write your tests following this principle.

You can match the views with a lot of different matches:

*   id (as the example above)
*   text (passing a String, StringRes id or String matcher as parameter)
*   contentDescription
*   image
*   background
*   textColor
*   parent
*   descendant
*   or a custom matcher if you need.

Also, kappuccino provides a lot of custom matchers that are commonly used during UI tests, making your task to write them much easier. For example, interact with a RecyclerView is simple like this:

And much more!

*   Handle RuntimePermissions
*   IntentMatcher
*   Background Matcher
*   TextColor Matcher
*   Drawable Matcher (roadmap)

You can add kappuccino by adding this to your project:

androidTestCompile 'br.com.concretesolutions:kappuccino:1.0.6'

Feel free to fork us on [GitHub](https://github.com/concretesolutions/kappuccino), test in your project and give us some feedback!  
Thanks!

By [Heitor Colangelo](https://medium.com/@heitorcolangelo) on [October 27, 2017](https://medium.com/p/60cfb29d96a0).

[Canonical link](https://medium.com/@heitorcolangelo/writing-clean-and-readable-espresso-tests-with-kappuccino-60cfb29d96a0)

Exported from [Medium](https://medium.com) on March 2, 2024.