---
title: Android Testing with Espresso — Part 1
date: 2016-08-10 00:00:00 Z
tags:
- software-testing
- android
layout: post
current: post
cover: assets/images/testes-no-android-com-espresso.png
navigation: true
class: post-template
subclass: post
author: heitor
---

> This post was translated from Portuguese using generative AI.

In this series of posts, I will show you how to efficiently test your Android app using [Espresso](https://google.github.io/android-testing-support-library/docs/espresso/). Additionally, as we progress, I'll provide tips on the main challenges you'll likely encounter along the way and how to solve them.

**About the Project**

Throughout the series, I will use the [EspressoTest](https://github.com/heitorcolangelo/EspressoTests) project. It's a simple app that consumes the [RandomUser](https://randomuser.me/) API. The app has 3 screens:

1. Login screen, with two EditText fields, _username_ and _password_. The only validation being done is for empty fields. This means that if both fields are not empty, you can enter any username and password and it will log you in.
2. After logging in, the second screen is the list of users returned by the API.
3. Clicking on one of the items in the list will take you to the details screen of the clicked item.

The libraries I'm using for the app are:

* [Picasso](http://square.github.io/picasso/)
* [ButterKnife](http://jakewharton.github.io/butterknife/)
* [EventBus](https://github.com/greenrobot/EventBus)
* [OkHttp](http://square.github.io/okhttp/)
* [Retrofit](http://square.github.io/retrofit/)

It's important that you understand the project well before starting the tests. For this reason, I've kept the app very simple so that this understanding doesn't take up too much time. To get started, clone the `start_project` branch of the project on github.

Without further ado, let's get started.

**Setting up Espresso in the project**

In the `build.gradle` file of the project, add the following dependencies:

```groovy
androidTestCompile 'com.android.support.test.espresso:espresso-core:3.0.1'  
androidTestCompile 'com.android.support.test:runner:1.0.1'
```

Now sync the gradle and you're all set, Espresso is configured correctly.

**Important**: Gradle will probably complain about the support-annotations dependency; to resolve this issue, add this line to your dependencies:

```groovy
androidTestCompile "com.android.support:support-annotations:$androidSupportVersion"
```

Where $androidSupportVersion is the version you are using for the support library.

I won't delve too much into the causes of this issue, as it's not the focus of the post. If you want to know more or are still having dependency issues, take a look at this link.

Okay, now that we have configured the project, let's start writing our tests. Up to this point, if you have any questions or encountered any problems, please leave your comment below.

So far, the only thing that has changed in the project you cloned (branch `start_project`) is the `build.gradle` file. Anyway, the final state of the app in this part of the tutorial is on the [`part_1`](https://github.com/heitorcolangelo/EspressoTests/tree/part_1) branch.

[Go to Part 2 — Simple Assertions and View Interactions >>](https://heitorcolangelo.dev/android-testing-with-espresso-part-2)