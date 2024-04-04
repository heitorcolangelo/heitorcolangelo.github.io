---
title: Android Testing with Espresso — Part 2
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

#### Simple assertions and interactions with views.

In [part 1](https://medium.com/@heitorcolangelo/testes-no-android-com-espresso-parte-1-8d739672a235#.r5toy52vk) we saw how to configure our project. If you want to start from this part, clone the [EspressoTests](https://github.com/heitorcolangelo/EspressoTests) project on GitHub and fork the 'part\_1' branch, which represents the project state at the end of part 1.

**Creating the first test**

Let's start by testing the login screen. To do this, create a `LoginActivityTest` class in the `/app/src/androidTest/` directory of the project, as shown in the image below:

![](https://cdn-images-1.medium.com/max/462/1*DiqC06BAa2stAKtKtJ4TUw.png)

Annotate the class we created with the `@RunWith(AndroidJUnit4.class)` annotation.

This will indicate that this class should be executed with AndroidJUnitRunner; to learn more about it, access the [link](https://developer.android.com/reference/android/support/test/runner/AndroidJUnitRunner.html).

Now, let's define our [ActivityTestRule](https://developer.android.com/reference/android/support/test/rule/ActivityTestRule.html) with the activity that will be started before all our tests, that is, the activity we want to test.

```java
@Rule  
public ActivityTestRule<LoginActivity> mActivityRule = new ActivityTestRule<>(
    LoginActivity.class,
    false,
    true
);
```
The constructor parameters are:

* The activity to be tested (LoginActivity.class),
* [initialTouchMode](http://android-developers.blogspot.com.br/2008/12/touch-mode.html) (false),,
* Whether to start automatically or not (true).

Your code should look like this:

```java
@RunWith(AndroidJUnit4.class)
public class LoginActivityTest {

  @Rule
  public ActivityTestRule<LoginActivity> mActivityRule = new ActivityTestRule<>(
        LoginActivity.class,
        false,
        true
  );

}
```

**Writing the first test**

Now let's write our first test. We should test the different states that the screen in question can assume. For example, as soon as we start LoginActivity, it displays an image, two text fields, and a button. This can be considered the initial state of the screen. Let's write a test to verify this state.

```java
@Test
public void whenActivityIsLaunched_shouldDisplayInitialState() {
  onView(withId(R.id.login_image)).check(matches(isDisplayed()));
  onView(withId(R.id.login_username)).check(matches(isDisplayed()));
  onView(withId(R.id.login_password)).check(matches(isDisplayed()));
  onView(withId(R.id.login_button)).check(matches(isDisplayed()));
}
```

One of the advantages of Espresso is that the syntax is very intuitive. We can practically read in natural language what the test is executing. Let's analyze the first line of the test:

`onView(withId(R.id.login_image)).check(matches(isDisplayed()));`

We could read this line in natural language, for example: "_Check that the view with id login_image is visible on the screen"_. Now, explaining a bit what's happening:

* `onView()` will receive the `ViewMatchers` we pass as a parameter and will return to us a `ViewInteraction` object. In other words, we are passing to it the view we want to interact with;
* `withId()` will receive the id of the view and will return a `ViewMatchers`;
* `check()` will receive a `ViewAssertion`. That is, it will check if the assertion we are passing as a parameter is valid;
* `matches()` will receive a `ViewMatchers` and return a `ViewAssertion`;
* `isDisplayed()` is the `ViewMatchers` we will use.

To learn more about the objects, click on the links about [ViewMatchers](https://developer.android.com/reference/android/support/test/espresso/matcher/ViewMatchers.html), [ViewInteraction](https://developer.android.com/reference/android/support/test/espresso/ViewInteraction.html), and [ViewAssertion](https://developer.android.com/reference/android/support/test/espresso/ViewAssertion.html).

**Running the test**

Now just run the test, right? Wrong! We need to disable animations in the developer options of our emulator/device. To do this, go to _Settings > Developer options_ and turn off these three options:

* Window animation scale;
* Transition animation scale;
* Animator duration scale.

Espresso waits for the UI Thread to become idle to execute the next test step. However, if the animations are on, it will get lost and the tests will break, read more about it [here](https://google.github.io/android-testing-support-library/docs/espresso/setup/index.html).

Now, to run this test, just click the right mouse button on the method and then click on the option _Run 'whenActivityIsLaunched...'_. If everything goes well, you should see the test being executed on your emulator and the test console will be like this:

![Test console](https://cdn-images-1.medium.com/max/1024/1*FdQm1REF0c1wfQ5XTm6s4Q.png)

Alright, but how do I ensure that Espresso is really working and looking at whether my views are appearing on the screen? To ensure this, let's change the first line of this test that we did:

`onView(withId(R.id.login_image)).check(matches( not(isDisplayed()) ));`

The `not()` method will invert the result we expected. So, in this test, I am saying that the view with id `login_image` **will not** be visible on the screen, which is not true, because when starting the screen, the image will be visible. So the test must fail. If we run the test again:

![Test failed](https://cdn-images-1.medium.com/max/1024/1*80B6EEH6aQ23BKFehl6AFA.png)

Great, our test failed, which means that Espresso is making the assertions correctly. Better than that, notice the log it shows:
```
Expected: not is displayed on the screen to the user  
Got: AppCompatImageView{..., visibility=VISIBLE, ...}
```

That is, it also shows us where the test is failing. Now we can remove the `not()` method we added and run this test again. Is it green? Then let's move on.

This test was easy, what we should do now is test the other states of the screen. One of these other states is when we leave one of the text fields blank and click on the login button. When this happens, the app displays a dialog on the screen. Let's write a test to verify this state.

```java
@Test
public void whenAnyEditTextIsEmpty_andClickOnLoginButton_shouldDisplayDialog() {
  onView(withId(R.id.login_username)).perform(typeText("admin"));
  onView(withId(R.id.login_button)).perform(click());
  onView(withText(R.string.validation_message)).check(matches(isDisplayed()));
  onView(withText(R.string.ok)).perform(click());

  onView(withId(R.id.login_username)).perform(clearText());
  onView(withId(R.id.login_password)).perform(typeText("pass123"));
  onView(withId(R.id.login_button)).perform(click());
  onView(withText(R.string.validation_message)).check(matches(isDisplayed()));
  onView(withText(R.string.ok)).perform(click());
}
```

**Do not execute the test yet**, it won't work, but for another reason I'll address later. First, let's just analyze the code. We use three new methods:

* `perform()`: will execute the ViewAction it receives as a parameter;
* `typeText()`: ViewAction to type text into the view;
* `click()`: ViewAction to click on the view;
* `withText()`: will search for the view containing the text passed as a parameter.

The first block of our test is performing the following actions:

* Typing text in the _login\_username_ field;
* Clicking on the login button;
* Verifying that the dialog is appearing (because we left the password field blank);
* Clicking _Ok_ in the dialog to close it.

The second block does basically the same thing as the first block, only with the _login\_password_ field. The only difference is that it clears the _login\_username_ field before, because the field is filled because of the previous block. This is not very good, having to clear what the previous steps of the test did to execute the next steps. Our tests should validate scenarios in an isolated manner. So let's refactor this code.

```java
@Test
public void whenPasswordIsEmpty_andClickOnLoginButton_shouldDisplayDialog() {
  onView(withId(R.id.login_username)).perform(typeText("admin"));
  onView(withId(R.id.login_button)).perform(click());
  onView(withText(R.string.validation_message)).check(matches(isDisplayed()));
  onView(withText(R.string.ok)).perform(click());
}

@Test
public void whenUserNameIsEmpty_andClickOnLoginButton_shouldDisplayDialog() {
  onView(withId(R.id.login_password)).perform(typeText("pass123"));
  onView(withId(R.id.login_button)).perform(click());
  onView(withText(R.string.validation_message)).check(matches(isDisplayed()));
  onView(withText(R.string.ok)).perform(click());
}
```
Great, now we have two tests, and one is not influencing the other. However, we still repeat the same steps for both tests. I think we can refactor them again.

```java
@Test
public void whenPasswordIsEmpty_andClickOnLoginButton_shouldDisplayDialog() {
  testEmptyFieldState(R.id.login_username);
}

@Test
public void whenUserNameIsEmpty_andClickOnLoginButton_shouldDisplayDialog() {
  testEmptyFieldState(R.id.login_password);
}

private void testEmptyFieldState(int notEmptyFieldId){
  onView(withId(notEmptyFieldId)).perform(typeText("defaultText"));
  onView(withId(R.id.login_button)).perform(click());
  onView(withText(R.string.validation_message)).check(matches(isDisplayed()));
  onView(withText(R.string.ok)).perform(click());
}
```
Now it's better, we have cleaner and more reusable code. This is a good time for me to give you the first tip of this series:

> **Write small tests, don't write long tests.**

Avoid writing tests that do several things, focus on small, preferably independent scenarios.

Now, try to run the tests. As I mentioned before, they fail. Let's analyze the log:

`Error performing 'single click - At Coordinates: ... **on view 'with id: com.example.heitorcolangelo.espressotests:id/login\_button'.**`

Apparently Espresso couldn't click on the login button, that is, the problem is in the second line of the `testEmptyFieldState` method:

`onView(withId(R.id.login_button)).perform(click());`

Put a breakpoint on this line and let's see the emulator screen at this moment:

![Emulator screen](https://cdn-images-1.medium.com/max/368/1*2_cNXc7l-2_qZZrHvZRy4w.png)

Notice that the virtual keyboard is taking up a good part of the screen, it is even covering our login button, so Espresso cannot click on the button. To fix this problem, let's use the `closeSoftKeyboard()` method.

onView(withId(notEmptyFieldId)).perform(typeText("defaultText"), closeSoftKeyboard());

This method will close the virtual keyboard after we type the text "defaultText". Our login button will be visible and Espresso will be able to click on it. Run the test again, I believe it will pass now.

Here's the second tip:

> **Whenever you have a test that involves typing text in an EditText, don't forget to use the `closeSoftKeyboard()` method to hide the virtual keyboard.**

If you leave the virtual keyboard open during tests, it will cover views that may be essential for your test, and it will fail.

Phew, quite a bit so far, but we still have two scenarios to validate:

1. When both fields are empty, it should display the dialog;
2. When both fields are filled, it should open MainActivity.

I'll leave scenario 1 as an exercise for you to solve. Scenario 2 involves another concept that I'll leave for the next post.

At the end of this step, your code should look like the [`part_2`](https://github.com/heitorcolangelo/EspressoTests/tree/part_2) branch.

If you have any questions, suggestions, or found any incorrect information in this post, leave a comment below.

[Go to part 3 — testing intents >>](https://heitorcolangelo.dev/android-testing-with-espresso-part-3)
