---
title: Android Testing with Espresso — Part 4
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

* This post was translated from Portuguese using GPT.

### Simulating Intent Results

In the [previous post](https://medium.com/@heitorcolangelo/testes-no-android-com-espresso-parte-2-5180ee03ed9a#.7hwn7r3fe), we performed our first test on the Login screen. If you want to start from this post, use the 'part_2' branch of the project.

**Simulating Intent Results**

Let's write the test for the following scenario:

- When _username_ and _password_ are not empty and the user clicks on the login button, the app should open the main screen (MainActivity).

We could write a test that fills in both fields, clicks on the login button, and then verifies if the layout of MainActivity will be visible, something like this:

```java
@Test
public void whenBothFieldsAreFilled_andClickOnLoginButton_shouldOpenMainActivity() {
  onView(withId(R.id.login_username)).perform(typeText("defaultText"), closeSoftKeyboard());
  onView(withId(R.id.login_password)).perform(typeText("defaultText"), closeSoftKeyboard());
  onView(withId(R.id.login_button)).perform(click());
  onView(withId(R.id.main_activity_container)).check(matches(isDisplayed()));
}
```
However, this is wrong for two reasons. The first can be considered more of a tip:

> **Avoid writing tests that navigate through the app; start activities directly in the desired state.**

The second reason is that MainActivity makes a request to the API, which makes this test dependent on an external resource. And here's another tip, which actually should be a **rule**:

> **Tests should be isolated from any external dependency.**

To test if an _activity_ is started, we should test if the _intent_ of this _activity_ is launched because, after all, the _intent_ defines which _activity_ will be started. To validate the _intent_, we need to add the following dependency to our _build.gradle_ file:

```groovy
androidTestCompile "com.android.support.test.espresso:espresso-intents:$espressoVersion"
```

This is an extension of Espresso that allows us to work with intents (more information in this [link](https://google.github.io/android-testing-support-library/docs/espresso/intents/)).

Before writing the test, let's analyze the code snippet that starts our MainActivity (LoginActivity.java, line 53).
```java
private void doLogin() {
  startActivity(new Intent(this, MainActivity.class));
}
```
The _intent_ we are assembling is very simple, it only contains the class name (MainActivity.class) and the context as parameters. We will use the class name to validate our _intent_. Our test will look like this:

```java
@Test
public void whenBothFieldsAreFilled_andClickOnLoginButton_shouldOpenMainActivity() {
  Intents.init();

  onView(withId(R.id.login_username)).perform(typeText("username"), closeSoftKeyboard());
  onView(withId(R.id.login_password)).perform(typeText("password"), closeSoftKeyboard());

  Matcher<Intent> matcher = hasComponent(MainActivity.class.getName());

  onView(withId(R.id.login_button)).perform(click());

  intended(matcher);

  Intents.release();
}
```
Let's analyze the code:

- Line 3: We are starting the intent recording with the [_init()_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#init()) method;
- Lines 5 and 6: Nothing new, just filling in the _username_ and _password_ fields;
- Line 8: We use the _IntentMatchers._[_hasComponent_](https://developer.android.com/reference/android/support/test/espresso/intent/matcher/IntentMatchers.html#hasComponent(java.lang.String))_(String className)_ method passing the name of the MainActivity class as a parameter, which is the _activity_ that will be started;
- Line 10: We click on the login button;
- Line 12: The [_intended(Matcher<Intent> matcher)_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#intended(org.hamcrest.Matcher<android.content.Intent>)) method checks that the matcher passed as a parameter is the one that the activity under test will launch, also ensuring that this intent is unique;
- Line 14: The [_release()_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#release()) method clears the intent states.

What we are doing is telling Espresso: "_Hey, when I fill in these two fields and click on the login button, the app should launch an intent to open MainActivity._" Simple as that.

If we run the test, it passes. However, there's still something wrong with it. Notice that MainActivity still opens. And it makes sense because all we did was ensure that the launched intent is correct, we did nothing to prevent MainActivity from starting.

To ensure that our test is isolated and to avoid navigation through the app, let's simulate the result of this intent. Refactoring the test, it will look like this:

```java
@Test
public void whenBothFieldsAreFilled_andClickOnLoginButton_shouldOpenMainActivity() {
  Intents.init();
  onView(withId(R.id.login_username)).perform(typeText("defaultText"), closeSoftKeyboard());
  onView(withId(R.id.login_password)).perform(typeText("defaultText"), closeSoftKeyboard());
  Matcher<Intent> matcher = hasComponent(MainActivity.class.getName());

  ActivityResult result = new ActivityResult(Activity.RESULT_OK, null);
  intending(matcher).respondWith(result);

  onView(withId(R.id.login_button)).perform(click());
  intended(matcher);
  Intents.release();
}
```
Two lines were added:

- Line 8: We are creating an [_ActivityResult_](https://developer.android.com/reference/android/app/Instrumentation.ActivityResult.html) object that will simulate the activity result;
- Line 9: We use the [_intending()_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#intending(org.hamcrest.Matcher<android.content.Intent>)) method to return a result as soon as the intent is launched.

An important point in the Espresso documentation about this method:

```
**Note:** the destination activity will not be launched.
```

- Line 9: We call the [_respondWith()_](https://developer.android.com/reference/android/support/test/espresso/intent/OngoingStubbing.html#respondWith(android.app.Instrumentation.ActivityResult)) method, passing our ActivityResult object defined in line 8.

Again, what we are telling Espresso is: "_When this intent is launched, respond with this result._" This prevents MainActivity from starting.

Run the test, it should pass without any problems, and MainActivity will not be started. If something went wrong, go back to the previous steps or leave a comment below so I can help you.

Great, now that we've covered our first screen with tests, we can move on. Before that, make sure your code looks similar to what's in the 'part_3' branch of the [repository](https://github.com/heitorcolangelo/EspressoTests).

If you have any questions, suggestions, or if you found an error in the post, leave a comment.

[Go to Part 4 — mocking API requests >>](https://heitorcolangelo.dev/android-testing-with-espresso-part-4)