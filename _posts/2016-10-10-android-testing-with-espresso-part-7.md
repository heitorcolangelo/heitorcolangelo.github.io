---
title: Android testing with espresso — part 7
date: 2016-10-10 00:00:00 Z
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

In the [previous post](https://heitorcolangelo.dev/android-testing-with-espresso-part-6), we learned how to create _custom matchers_ and how to handle _run time permissions_ with UiAutomator. In this final part, I will focus more on some tips that I find important, I will also talk about TestButler and Robots Pattern. To follow along with this part, use the ‘[part\_7](https://github.com/heitorcolangelo/EspressoTests/tree/part_7)’ branch of the project.

Loading Animations x AlertDialogs
--------------------------------

Be careful with animations that show progress (_loadings_), especially if a dialog is on top of this animation. When the dialog is on top of the loading, the animation is still happening in the UiThread. That is, the _idle_ state, which Espresso waits for to proceed with the test, never happens. I modified the LoginActivity to demonstrate this, observe how the login button's click method turned out. Ignore the layout and functionality of this change, the idea is just to demonstrate the problem in question.


```
loginButton.setOnClickListener(new View.OnClickListener() {  
  @Override  
  public void onClick(View v) {  
    **showLoading();**  
    if (validateFields())  
      doLogin();  
    else  
      showErrorDialog();  
  }  
});
```

With this modification, every time the user clicks on the login button, the loading is displayed on the screen and after that, we proceed with the login process. The issue is that when the fields are empty, the error dialog is displayed, placing us in exactly the situation I mentioned previously, a dialog on top of a loading. Run the tests of the LoginActivity and notice that the tests involving the error dialog fail.

```
**AppNotIdleException**: Looped for 3608 iterations over 60 SECONDS. The following Idle Conditions failed.
```

Therefore, always hide your screen _loadings_ before displaying a dialog to the user, and whenever a test is failing due to an **AppNotIdleException,** check if there isn't a "hidden" loading on your screen.

Test the behavior.
------------------

Focus on testing the app's behavior, don't just test layout properties. If you really need to verify the positions, use _position assertions_:

<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:694/format:webp/1*_YqXV5KcOhZJAYYWVvZKXQ.png" alt="Position assertions"/>
</p>

Running your tests on small devices
-----------------------------------

While you are running your tests on large screen devices, everything goes very well, nothing breaks. But don't forget that there are a lot of people with small devices out there, and they will want to use your app. So please, remember these people and run your tests on small devices. You will notice that many will fail, mainly because of views that are not on the screen.

<div style="display: flex; justify-content: center;">
  <img src="https://miro.medium.com/v2/resize:fit:478/format:webp/1*2RwUM2Kl7JDj66RmE2-8_Q.png" alt="Dispositivo pequeno">
</div>

On a small device, the user's address is not visible. The test breaks.

You will have to use the _scrollTo()_ method quite a lot.

Single touch action on slow/old devices/emulators.
-----------------------------------------------------------

In this year's Google I/O, more specifically in [this lecture](https://www.youtube.com/watch?v=isihPOY2vS4&list=WL&index=5), a very important information was presented which is a problem of interpretation of single touches made by Espresso. They did not go into details, but they said that, sometimes, the single touch is interpreted as a long touch (long click) on slow or old devices or emulators. This happens because the touch itself is composed of two actions: pressing and releasing. When the device is too old and slow, and has some task running in the background, the response time between one event and another can take a long time, so this touch is interpreted as a _long click._ To prevent this from breaking your tests, modify the following setting:

```
Settings -> Accessibility -> Touch and hold delay -> LONG
```

<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:480/format:webp/1*kv2M-P40FmQImu6S10o7Dw.png" alt="Property Touch and hold delay"/>
</p>

Change the highlighted property to LONG.

The Leak Canary's toast.
----------------------

[Leak Canary](https://github.com/square/leakcanary) is a lib to detect memory leaks in your app. It's a great lib however, occasionally, it automatically throws a toast on the screen and, if that happens during the execution of your tests, they will break, as the toast will block the UI and the Espresso may not find the view with which it is trying to interact. So, do not install the Leak Canary on the device and/or emulator that you will use for the tests.

TestButler, 'decontaminating' the device for the tests.
--------------------------------------------------

While I was writing this series of posts, Linkedin released a lib called [TestButler](https://github.com/linkedin/test-butler). It stabilizes the emulator on which the tests are running, preventing these tests from failing due to problems in it. For example, you may have come across this situation:

<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:578/format:webp/1*-Jyyt2Wmq6sbTDXJPwguUA.png" alt="TestButler"/>
</p>

This will surely break your test. The idea of TestButler is to prevent this from happening. In addition, you can also change some global settings of the emulator, such as:

*   Enable/Disable WiFi;
*   Change device orientation;
*   Set the location service mode (High accuracy or power saving);
*   Set the Locale (default language) of the application, if your app is intended for more than one country this will help you a lot.

In short, it is worth studying and using this lib, it will definitely help a lot.

[Test Butler](https://github.com/linkedin/test-butler)

Robots Pattern
--------------

Last week I watched a tech talk at [Concrete Solutions](https://medium.com/u/a791b2313cef?source=post_page-----dee47be84571--------------------------------) about [Robots Pattern](https://realm.io/news/kau-jake-wharton-testing-robots/). This pattern, presented by Jake Wharton, aims to make tests more stable, readable, and easy to maintain. For example, one of our tests from the LoginActivity is as follows:


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

Applying Robots, the same test would look like this:

```java
@Test
public void whenBothFieldsAreFilled_andClickOnLoginButton_shouldOpenMainActivity() {
  LoginRobot login = new LoginRobot();
  ResultLoginRobot result = login
  .username("defaultText")
  .password("defaultText")
  .login();
  result.isSuccess()
}
```

The code becomes more readable and you leave in the test class only the test steps themselves. The way these steps will be implemented is separated into other classes:

```java
class LoginRobot {
    LoginRobot username(String username) { 
      onView(withId(R.id.login_username)).perform(typeText(username), closeSoftKeyboard());
      return this;
    }
    
    LoginRobot password(String password) { 
      onView(withId(R.id.login_password)).perform(typeText(password), closeSoftKeyboard());
      return this;
    }
    
    ResultLoginRobot login() {
      Intents.init();
      Matcher<Intent> matcher = hasComponent(MainActivity.class.getName()); 
      onView(withId(R.id.login_button)).perform(scrollTo(), click());
      return new ResultLoginRobot();
    }
  }
  
  class ResultLoginRobot { 
    ResultRobot isSuccess() {
      onView(withId(R.id.login_button)).perform(click());
      intended(matcher);
      Intents.release(); 
    }
  }
```

In the talk, Jake Wharton implements Robots with [Kotlin](https://kotlinlang.org/). If we use Kotlin, our test would be much cleaner, for example:

```kotlin
@Test
fun whenBothFieldsAreFilled_andClickOnLoginButton_shouldOpenMainActivity() {
  login {
    username("defaultText")
    password("defaultText")
  } doLogin {
    isSuccess()
  }
}
```

Cool, isn't it? And this is just the beginning, you can have a lot of fun and improve the way we test our apps with this standard. Watch the whole lecture, it's very worthwhile.

[Instrumentation Testing Robots](https://realm.io/news/kau-jake-wharton-testing-robots)

Have patience.
----------------

If this is the first time you're giving proper attention to testing, you're going to find that they take a lot of development time. But it's the beginning, every start is difficult. Your tests will fail seemingly without any explanation, you'll find that it's not possible to test everything only with Espresso (as was the case with RuntimePermissions), among other problems that will make you want to give up. But don't give up, once you get the hang of it, things flow better. You start to notice some things, like:

*   You start developing thinking about how you are going to test that code;
*   You feel safer making a major change in the code because you know your tests will be covering you in case you break something;
*   You start estimating your tasks already thinking about the effort of the tests.

It is very important to have a test culture, whether with Espresso or not, whether it's a mobile app or not. I made this series of posts thinking about encouraging developers to create this habit, to treat tests as allies and not as enemies.

Thank you!
---------

I hope you enjoyed the content I shared throughout these posts. If you have any questions, suggestions or criticism, feel free to find me.

Cheers!

heitorcolangelo@gmail.com
