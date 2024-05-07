---
title: Android Testing with Espresso — part 4
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

In the [previous post](https://heitorcolangelo.dev/android-testing-with-espresso-part-3), we learned how to mock Android intents. If you want to start from this post, use the 'part_3' branch of the project.

Scenarios for MainActivity
------------------------

MainActivity contains the list with the users we receive from the API. If an error occurs in the request, MainActivity will display an error screen instead of the list, and while no response comes back from the API, a loading screen remains on the display. So, initially, we have three scenarios to test:

1. When the request is successful, we should see the list with the users;
2. When there is an error in the request, we should see the error screen;
3. When we do not receive any response from the API, we should see the loading screen.

Great, we have identified the initial states to test our activity. However, we have a problem with the third scenario.

In the tests we have done so far, Espresso has made several interactions with our app, but have you ever stopped to think about how Espresso knows when it can interact with the app? After all, apps have animations and in many cases the UI can only be used when the animation ends. Well, Espresso does exactly that, it waits for the [UI Thread](http://stackoverflow.com/questions/3652560/what-is-the-android-uithread-ui-thread) of the application to become idle. While the UI is not finished with the animations, Espresso does not interact with it. If the app does not become idle within 60 seconds, Espresso returns an error:

```
AppNotIdleException: Looped for 3544 iterations over 60 SECONDS. The following Idle Conditions failed .
```

Knowing this, you can already imagine that the test for the third scenario won't work because since the loading screen is an infinite animation, the UI Thread will never become idle and Espresso will never interact with it. So, let's eliminate this scenario with this **very important tip that will save you a lot of headaches**:

> **Be careful with loading animations on the screen. If they are present, your test will surely fail.**

Writing the Tests
--------------------

Let's create our tests to cover the first two scenarios. I'll leave the initial setup of the MainActivityTest class up to you; it is identical to the initial setup of the LoginActivityTest, the only difference is in the last parameter to create the ActivityTestRule. In LoginActivityTest, we use _true,_ here we will use _false._ Remember what this parameter is for? It indicates whether the activity should be started automatically.

At the end of this setup, your class should look like this:

```java
@RunWith(AndroidJUnit4.class)
public class MainActivityTest {

    @Rule
    public ActivityTestRule<MainActivity> mActivityRule = new ActivityTestRule<>(
        /* activityClass */ MainActivity.class,
        /* initialTouchMode */ false,
        /* launchActivity */ false
    );

}
```

Okay, we could simply start writing the tests in the same way we did in LoginActivityTest. However, since this activity makes a request to the API as soon as it is started, we depend on the result of the request for the test to pass or fail. This is bad, as I mentioned before, we should keep our tests isolated. So, let's isolate our test by mocking the result of the request that the app makes to the API. To do this, we'll use the library [MockWebServer](https://github.com/square/okhttp/tree/master/mockwebserver).

Setting up MockWebServer
--------------------------

Add the following dependency to your build.gradle file:

```groovy
androidTestCompile "com.squareup.okhttp3:mockwebserver:$okHttpVersion"
```

Synchronise the project and let's set up the MockWebServer in our MainActivityTest. Take a look at the implementation below:

```java
@RunWith(AndroidJUnit4.class)
public class MainActivityTest {

  private MockWebServer server;
  
  @Rule
  public ActivityTestRule<MainActivity> mActivityRule = new ActivityTestRule<>(
      /* activityClass */ MainActivity.class,
      /* initialTouchMode */ false,
      /* launchActivity */ false
  );
  
  @Before
  public void setUp() throws Exception {
      server = new MockWebServer();
      server.start();
  }
  
  @After
  public void tearDown() throws IOException {
      server.shutdown();
  }
}
```

We declare two new methods: `setUp` and `tearDown`. We annotate these methods with `@Before` and `@After`, respectively. Methods annotated with _Before_ will be executed before the activity is started. Methods annotated with _After_, will be executed at the end of each test. Apart from this, nothing too special, we are just creating a new instance of MockWebServer and giving a start to the server.

But, our app is still pointing to the real URL of the API, that is:

```
http://api.randomuser.me/
```

This means that, if we write a test, our app will still make the request to the real API, and not to our MockWebServer. However, due to our implementation, the url is defined as a variable in our build.gradle file, which makes this URL redefinition a bit more difficult. To simplify our lives, we will use the lib [Mirror](http://projetos.vidageek.net/mirror-pt/mirror/).

**Important:** before you continue, review how the app is making the requests to the API. This will help you understand what we are going to do from here on out.

Add this dependency in your build.gradle file:

```groovy
androidTestCompile "net.vidageek:mirror:1.6.1"
```

Agora vamos criar os métodos para alterar a url da nossa classe UsersApi, vou mostrar o código e explicar linha a linha.
```java
@RunWith(AndroidJUnit4.class)
public class MainActivityTest {

    private MockWebServer server;
    
    @Rule
    public ActivityTestRule<MainActivity> mActivityRule = new ActivityTestRule<>(MainActivity.class, false, false);
    
    @Before
    public void setUp() throws Exception {
        server = new MockWebServer();
        server.start();
        setupServerUrl();
    }
    
    @After
    public void tearDown() throws IOException {
        server.shutdown();
    }
    
    private void setupServerUrl() {
        String url = server.url("/").toString();
        
        HttpLoggingInterceptor interceptor = new HttpLoggingInterceptor();
        interceptor.setLevel(HttpLoggingInterceptor.Level.BODY);
        
        OkHttpClient client = new OkHttpClient.Builder().addInterceptor(interceptor).build();
        
        final UsersApi usersApi = UsersApi.getInstance();
        
        final Api api = new Retrofit.Builder()
                .baseUrl(url)
                .addConverterFactory(GsonConverterFactory.create(UsersApi.GSON))
                .client(client)
                .build()
                .create(Api.class);
                
        setField(usersApi, "api", api);
    }
    
    private void setField(Object target, String fieldName, Object value) {
        new Mirror()
                .on(target)
                .set()
                .field(fieldName)
                .withValue(value);
    }
}
```

In line 13, we call the `setupServerUrl()` method. Let's break it down:

*   Line 22: we set our MockWebServer url to "/", get the total url value and store it in the _url string;_
*   Line 24 and 25: we just set the log level of our [HttpLoggingInterceptor](https://github.com/square/okhttp/tree/master/okhttp-logging-interceptor) object;
*   Line 27: we create an [OkHttpClient](http://square.github.io/okhttp/) object and pass our interceptor;
*   Line 29: reference the UsersApi instance;
*   Line 31: we create a new Api object with retrofit, but this time passing the url of our MockWebServer;
*   Line 38: we call the setField method, which takes as parameters:  
    1- The _target_, which is the object that will have the field changed using reflection with the mirror;  
    2- The name of the field that will be changed;  
    3- The new value that will be assigned to the changed field.

The setField method is where we will actually use the Mirror lib. I believe it's quite simple to understand what it does, basically we are telling Mirror to get the "api" field from our target (which is an object of the UsersApi class) and to change the value of this field to the object we pass in the value parameter. This way, we are changing the base url of our project to point to our MockWebServer.

It's important to note that if your implementation allows you to set the endpoint url in a simpler way, you probably won't need to use _reflection_.

If you are still in doubt, go back over the previous steps before proceeding; if, despite this, you're still in doubt, leave a comment and I can help.

Now our test is isolating our app from the API calls. However, we still haven't defined the response that our MockWebServer will return for each test case.

Mocking the request return
-----------------------------

To be able to mock the return, we should have a mock of the json object just like the one the API returns. This is simple, all we need to do is simulate a request to the API in our browser, for example:
 
[http://api.randomuser.me/?results=20](http://api.randomuser.me/?results=20)

Then, you just need to copy the json that appears in the browser and put it into a _string_ in a location accessible to the tests. I usually place it in an interface, as I did in the Mocks.java file.

Now, let's write our first test for the MainActivity. In this test we will check if when the API returns the users successfully, we can see the user list on the screen.

```java
@Test
public void whenResultIsOk_shouldDisplayListWithUsers() {
    server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS));
    mActivityRule.launchActivity(new Intent());
    onView(withId(R.id.recycler_view)).check(matches(isDisplayed()));
}
```

Line 3: we are calling the _enqueue_ method of the MockWebServer. This method is going to enqueue the [MockResponse](https://github.com/square/okhttp/blob/master/mockwebserver/src/main/java/okhttp3/mockwebserver/MockResponse.java) object that we pass as a parameter. We are setting the _responseCode_ as 200, i.e., a successful request. We are also setting the _body_ with the mock that we just copied and placed in the Mocks.java interface. In summary: we are telling the MockWebServer: "When you receive a request, return this MockResponse";

Line 4: we start the activity and pass a simple intent as no extras are needed in this activity;

Line 5: we check if our list is visible.

Run the test, it should pass. Now, check out the log:

```
D/OkHttp: --> GET [http://localhost:41183/?page=0&results=20](http://localhost:41183/?page=0&results=20) http/1.1  
D/OkHttp: --> END GET  
D/OkHttp: <-- 200 OK [http://localhost:41183/?page=0&results=20](http://localhost:41183/?page=0&results=20) (34ms)
```

Note that now our endpoint is localhost, that is, the MockWebServer.

We managed to test a scenario of our activity in an isolated way. But there is still another scenario missing, the one that when a request fails (code between 400 and 500), the error screen appears. I'll leave this test for you to implement. It's quite simple, you'll just have to change the return code and the body.

If something went wrong, go through the previous steps or leave a comment below so I can help you. By the end of this stage (after implementing the second test scenario), your code should look similar to the one in the 'part_4' branch.

If you have any questions, suggestions, or found an error in the post, leave a comment.

We still need to test if the layout we defined for our item in the recycler view is being displayed correctly. We also need to check if by clicking on an item, we are sending the correct information to the details activity. These will be our next test scenarios.

[Go to Part 5 — assertions and interactions in the recycler view >>](https://heitorcolangelo.dev/android-testing-with-espresso-part-5)
