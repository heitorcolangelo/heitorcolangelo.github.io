---
title: Android Testing with Espresso — part 5
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

In the [previous post](https://heitorcolangelo.dev/android-testing-with-espresso-part-4), we learned how to mock Android's intents. If you want to start from this post, use the branch '[part_4](https://github.com/heitorcolangelo/EspressoTests/tree/part_4)' of the project.

Assertions on the RecyclerView item's layout
--------------------------------------------

In our MainActivity, the next step is to verify whether the layout we defined for the item of our RecyclerView is displayed correctly. Let's take a look at our item's [layout](https://github.com/heitorcolangelo/EspressoTests/blob/part_4/app/src/main/res/layout/view_user_item.xml).

![User Item Image](https://miro.medium.com/v2/resize:fit:1066/format:webp/1*HVEH26Qsk_S_kpETw2eKmg.png)

It's a rather simple layout:

*   An _ImageView_ with id _user\_view\_image_;
*   A _TextView_ with id _user\_view\_name_.

Then, let's write a test that checks if these views are on the screen:

```java
@Test
public void checkUserItemView_isDisplayed() {
  server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS));
  mActivityRule.launchActivity(new Intent());
  onView(withId(R.id.user_view_image)).check(matches(isDisplayed()));
  onView(withId(R.id.user_view_name)).check(matches(isDisplayed()));
}
```

We queue a successful request, thus, our recycler is displayed. Then, we make a simple assertion on the ids that we have in the list item. Run this test, the result should be this:

```
AmbiguousViewMatcherException: 'with id: com.example.heitorcolangelo.espressotests:id/user\_view\_image' **matches multiple views in the hierarchy.**
```

The test did not work, and Espresso is telling us that there are several views with the id we passed, after all, there are several identical items in the list, ie several identical ids.

The way I usually solve this problem may seem a bit lazy, but it has worked very well so far. Just mock it with only one item in the list! :)

```java
@Test
public void checkUserItemView_isDisplayed() {
  server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS_SINGLE_ITEM));
  mActivityRule.launchActivity(new Intent());
  onView(withId(R.id.user_view_image)).check(matches(isDisplayed()));
  onView(withId(R.id.user_view_name)).check(matches(isDisplayed()));
}
```

The test will be like this, we only change the _body_ that we pass in the MockResponse, to pass the [mock with only one item](https://github.com/heitorcolangelo/EspressoTests/blob/part_5/app/src/androidTest/java/com/example/heitorcolangelo/espressotests/mocks/Mocks.java). Run the test again, it should pass. As we only have one item from the list displayed on the screen, we no longer have the problem of several identical ids. Now we can make the assertion easily.

Of course, I will not be simplistic, this will not always be enough. For example, if you have different types of layout on your list. So, let's do the same test without using the above "trick".

```java
@Test
public void checkUserItemView_isDisplayed_noTricks() {
  server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS));
  mActivityRule.launchActivity(new Intent());
  onView(allOf(withId(R.id.user_view_image), hasSibling(withText("Eddie Dunn")))).check(matches(isDisplayed()));
  onView(allOf(withId(R.id.user_view_name), withText("Eddie Dunn"))).check(matches(isDisplayed()));
}
```

We use two new methods:

*   allOf: matches all the conditions that we pass as a parameter. In this case, we pass _withId_ and _hasSibling_,
*   hasSibling: _sibling_ in English means "brother". This method searches for the view that has a "brother" that meets the conditions we pass as a parameter. In this case, we pass _withText_.

In line 5 we tell Espresso: "_Check if the view that has the id user\_view\_image and the brother with text "Eddie Dunn" is visible on the screen._" Thus, we avoid an _AmbiguousViewMatcherException_, as there is only **one** view that meets the above conditions.

At this point, you might wonder if it's correct to directly use the text "Eddie Dunn" for the assertion. After all, what if the item named "Eddie Dunn" is not visible on the screen at first? I can do this without problems, as I know that the first item in the list will always be "Eddie Dunn", since we are using a mocked response.

RecyclerViewActions
-------------------

So far, we have only made assertions in the items of our list. Now we will start making interactions, using the methods of the RecyclerViewActions class. For this, add this dependency in your build.gradle file:

```
androidTestCompile("com.android.support.test.espresso:espresso-contrib:$espressoVersion") {  
  exclude module: 'appcompat-v7'  
  exclude module: 'support-v4'  
  exclude module: 'support-annotations'  
  exclude module: 'recyclerview-v7'  
  exclude module: 'design'  
}
```

Now, let's test the following scenario:

*   When clicking on an item from the list, UserDetailsActivity should open.

```java
@Test
public void whenClickOnItemList_shouldStartUserDetailsActivity_withExtra() {
  server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS));
  mActivityRule.launchActivity(new Intent());
  Intents.init();
  Matcher<Intent> matcher = allOf(
    hasComponent(UserDetailsActivity.class.getName()),
    hasExtraWithKey(UserDetailsActivity.CLICKED_USER)
  );
  
  Instrumentation.ActivityResult
    result = new Instrumentation.ActivityResult(Activity.RESULT_OK, null);
  
  intending(matcher).respondWith(result);
  
  onView(withId(R.id.recycler_view)).perform(actionOnItemAtPosition(0, click()));
  
  intended(matcher);
  Intents.release();
}
```

Let's go through this test line-by-line:

*   Lines 3, 4 and 5: Nothing new, just queueing the requests that will be made, starting the activity and the intent service.
*   Line 6: We create an intent matcher the same as we did in the test of the [LoginActivityTest](https://gist.github.com/heitorcolangelo/354080abf09bdabd0e9dd0f5a268bc21). The only difference is that we add another matcher as condition, using the _hasExtraWithKey_ method. That is, besides checking if the launched intent is for the UserDetailsActivity, we verify if it contains an extra, which is the clicked user. Therefore, we pass the _UserDetailsActivity.CLICKED\_USER_ as parameter. This value is the same that is assigned to the _key_ of our intent _bundle_, when we want to launch UserDetailsActivity. For better understanding, check the code in the [MainActivity](https://github.com/heitorcolangelo/EspressoTests/blob/part_4/app/src/main/java/com/example/heitorcolangelo/espressotests/ui/activity/MainActivity.java).
*   Lines 11 to 14: No innovation, just setting what we will pass as result for the intent that will be launched.
*   Line 16: We use the [_actionOnItemAtPosition(int position, ViewAction viewAction)_](https://developer.android.com/reference/android/support/test/espresso/contrib/RecyclerViewActions.html#actionOnItemAtPosition(int, android.support.test.espresso.ViewAction))_ method,_ of the [RecyclerViewActions](https://developer.android.com/reference/android/support/test/espresso/contrib/RecyclerViewActions.html) class, which contains various other methods to interact with our list. There's no secret, it performs the _action_ at the _position_ we pass as parameter.

Run all the tests, they should pass. If something went wrong, go over the previous steps or leave a comment so I can help. At the end of this step, your code should look similar to the one in the '[part\_5](https://github.com/heitorcolangelo/EspressoTests/tree/part_5)' branch.

Let's move on to testing our last activity, the UserDetailsActivity.

[Go to Part 6 — Custom Matchers and Runtime Permissions>>](https://heitorcolangelo.dev/android-testing-with-espresso-part-6)
