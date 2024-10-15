---
title: Our journey into mobile E2E testing
date: 2024-08-30 00:00:00 Z
tags:
  - software-testing
layout: post
current: post
cover: assets/images/e2e-testing.webp
navigation: true
class: post-template
subclass: post
author: heitor
---

At Fresco, we aim to meet high-quality standards while keeping our workflow efficient. Early on, we used automated
end-to-end testing, hoping it would help us release more confidently and faster. However, we faced unreliable test
results, high maintenance costs, and the need to double-check everything manually, defeating the purpose of automation.

Facing these issues, we switched off automation and relied only on manual testing. While this gave us the accuracy we
needed, it became unsustainable as the app grew. So, we decided to give automation another chance, but this time, it was
different.

In this post, I’ll share our journey of retrying automated end-to-end testing, including the challenges, lessons
learned, and new solutions that made our tests more reliable and effective.

Testing Recap
=============

Software engineers should regularly verify if the application they are building works as intended. This means checking
that new features, bug fixes, or improvements haven’t caused problems or disruptions. That validation is done using
different types of tests, which are usually distributed following the testing pyramid.

![](https://miro.medium.com/v2/resize:fit:1400/format:webp/1*01JvCaXqQQvgxvUGsIcv5Q.jpeg)

[https://martinfowler.com/articles/practical-test-pyramid.html#TheTestPyramid](https://martinfowler.com/articles/practical-test-pyramid.html#TheTestPyramid)

The testing pyramid is commonly divided into three levels, from bottom to top:

* **Unit tests** verify most of the codebase and check specific components in isolation. Therefore, they are the most
  cost-effective type of testing, but they also have a limited scope.
* **Integration tests** verify inputs, outputs, and interactions between services or components. Compared to Unit tests,
  integration tests require more effort to set up and more time to run, but they offer broader coverage.
* **End-to-end (E2E) tests** validate the entire application flow at the top level, simulating real user scenarios from
  start to finish. They are the slowest to execute, most complex to implement, and require a fully working environment
  to run.

The pyramid emphasises the importance of having many unit tests, few integration tests, and even fewer end-to-end tests.

Unit and Integration tests are easier to automate and usually run whenever a new change is introduced in the codebase.

End-to-end tests, which will be the article’s focus and hereafter be referred to as just “tests” for simplicity, are
often executed manually by a dedicated team due to their complexity in automating. This is the current scenario at
Fresco. However, it was not always like that.

Historical and Product Context
==============================

At [Fresco](https://frescocooks.com/), we aim to spread the love of home cooking by making it effortless and rewarding
while unlocking the full potential
of [smart kitchen appliances](https://frescocooks.com/blog/what-makes-a-kitchen-appliance-smart) (from now on, they will
be referred to as just "appliances"). From a technical point of view, this means that our apps must interact (connect,
send, and receive messages) with these appliances, and testing these scenarios requires a physical mobile device and a
physical appliance.

A few years ago, we implemented a suite of automated tests running on physical mobile devices in our office. This was
necessary as the office also had testing appliances that we could use to test the interactions with the APPs. However,
several issues arose, including:

* Connection instability.
* Physical interference with the equipment.
* Devices being disconnected from testing machines.
* Flakiness in the testing framework (Appium).

This led to a lack of trust in the test suite, causing us to ignore its results and retest every scenario manually. Over
time, we discontinued the automated tests and relied exclusively on manual execution.

While maintaining the automated suite was solely the engineers’ responsibility, this manual testing distributed the
workload between the engineering and other teams inside the company, as any of our colleagues at Fresco could manually
execute the scenarios.

As everything in software has trade-offs, this manual process also brings some limitations, such as:

* **Error-prone:** Testers can miss defects or make mistakes while executing the test cases, resulting in missed bugs or
  security vulnerabilities released to production.
* **Inefficient:** Repeating the same steps over and over takes time, and usually more time than a machine would take to
  perform the same task. Also, this can lead to boredom and fatigue, increasing the chances of missing defects.
* **Scaling is costly:** As the product evolves and more tests are added, more time and testers are required to execute
  the test cases.

We also noticed that, although manual testing gave us more confidence in testing more complex scenarios (like pairing an
appliance), it decreased our productivity in more straightforward and well-defined scenarios (like authentication).

The Current Process
===================

At the end of each sprint, a new release is made available to everyone in the company so they can test the latest
features, bug fixes, and improvements that the engineers worked on during this period. In fact, we release a new version
of our apps whenever new code is added to the codebase, thanks to our automated CI/CD process. But this is a topic for
another blog post. The difference is that the release at the end of a sprint is likely the one that will be promoted to
production, reaching all users.

With a new release in hand, our colleagues put on their ‘tester hats’ and manually run a series of scripted tests
against our apps to detect any possible regressions or new bugs.

Think Big, Start Small
======================

We wanted to improve this situation by reducing most of the manual work. But we also wanted to avoid returning to the
same costly and unreliable testing structure we had before.

After some discussion, the team decided to take an iterative ([Plan-Do-Check-Act](https://en.wikipedia.org/wiki/PDCA))
approach. The plan was to estimate the effort required to implement all the current testing scenarios and sort them by
complexity, starting with the more straightforward scenarios and ending with the most complex ones.

After this, we would implement the first two or three scenarios from this list in an "implementation cycle". At the end
of this cycle, the engineers involved in this work must formally evaluate the overall implementation experience. Here
are a few questions we judged as essential to be constantly checking:

1. Were all chosen scenarios successfully automated? If not, which and why?
2. Did you have to do any work as preparation before writing your test?
3. Have you faced any unexpected situations that will impact the automation of future scenarios?
4. Are the implemented scenarios showing flakiness?
5. How difficult was implementing these scenarios from 0 (very easy) to 5 (very hard)?
6. Do you see any reason not to continue with the automation now?

If the answers to these questions indicate everything is going according to plan, we will pick the next couple of
scenarios to automate and repeat the process. However, if the questions show that our plan is not working as expected,
we should halt the automation process and discuss the next steps with the entire mobile team. The following steps could
also include stopping the automation process.

This allows us to work in small increments, receive frequent feedback, and adjust as needed. It also prevents us from
investing too much in this initiative only to realise at the very end that we have returned to the same situation we had
in the past.

With a strategy defined, it was time to pick the right tool for the job. So, we started investigating and testing the
different frameworks available on the market.

Testing the Testing Tools
=========================

The investigation and testing consisted of implementing two test scenarios in each framework. The picked scenarios were:

1. **Signing in with an existing user:** This straightforward scenario helps determine how easy or difficult the
   framework is to set up and use.
2. **Register a new user with email.** This scenario requires more interactions and an email validation step, requiring
   actions outside our application. The intention is to assess how the frameworks behave in more complex scenarios.

The expected output of this proof-of-concept (PoC) was to determine whether any tool would fit our needs and, if so,
which one we feel more comfortable investing our time in. The intention was not to elect ‘the best’ but to identify the
one that works better for our context (team size, skills, time, budget, scenarios, etc.).

After this experiment, our engineers compiled a list of the pros and cons of each framework tested. Here is a summary of
our findings by tool:

Summary of findings by experimented framework

The team decided to move on with the Maestro tool; although it is relatively new, the overall experience implementing
the PoC was better than the others. Although I didn’t explicitly mention security in this summary, it was considered in
the experiment, and we found that the Mobile.dev company
is [SOC 2](https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2) compliant, which
brings more confidence in the decision.

With the right plan and tools in hand, it is time to start the implementation. However, we haven’t started automating
straight away.

Preparing the ground
====================

In the Maestro framework, the testing scenarios are named _flows_. Here are a few examples of our _flows_:

* Sign in and Sign up.
* Search for a recipe.
* Save a recipe in "my recipes".

However, not every work is related to a _flow. S_ometimes, we have to do some preparation work before implementing a
_flow_. For example:

* Create the repository to hold the automation code.
* Set up a CI/CD job to run the scenarios.
* Set up the publishing of the results in the correct channels.
* Create accessibility tags in both iOS and Android projects. Maestro will use these tags to reference a view in the
  automation.
* Custom scripts that a _flow_ might need.
* Setting up testing credentials.
* Documentation with instructions to onboard other engineers.

We named these types of work _support_ to clarify whether any support work is needed before implementing a _flow_. This
helps reduce the amount of unplanned work that shows up at implementation time, makes our tasks smaller, and our
estimations more precise.

Once the support work is done, we can finally start automating the scenarios.

The Road So Far
===============

By the time I'm writing this article, we have around ten scenarios automated and running before every release.

On the good side:

* We are identifying non-intentional differences between iOS and Android.
* There is an increase in cross-platform collaboration between engineers.
* We are not facing any flakiness from the framework.
* Writing _flows_ is relatively easy.

On the not-so-good side:

* Some scenarios require custom scripts that interact with third-party services, which can be unstable, leading to a
  failure in the _flow._
* Constant refactoring of _flows_ to avoid code duplication, as some _flows_ rely on the same routine of a different
  _flow_.
* During development, you might need to open Android Studio, XCode, an Android emulator, and an iOS simulator. This
  consumes a lot of memory and CPU power from the engineer’s machine and can slow the process. A third IDE (or text
  editor) might also be used to edit the YAML file with the _flow_.
* The engineers are the only ones responsible for maintaining this structure up and running.

Even with these challenges, the team agrees that the automation should continue. But these are not the only challenges.

The Road Ahead
==============

As mentioned before, some scenarios require a physical mobile device and appliance. We still have to overcome this
challenge in the automation process because the tests run in a cloud
environment ([Maestro cloud service](https://cloud.mobile.dev/)), where physical devices are not present.

When we did our research, we didn't consider any AI tool as an option. However, we are now seeing a few new tools on the
market that could be a good fit for us.

Although automation is progressing well, we’ve decided it’s not yet time to remove manual testing. Once more scenarios
are implemented and confidence in our automated suite is increased, we can begin phasing out manual testing, ensuring
that omitting manual testing for a scenario does not compromise application quality. Until then, we will continue
automating our scenarios, writing flows, working on support tasks, evaluating the results, and adjusting the plan as
needed.

Conclusion
==========

This project is a work in progress with significant potential for evolution as we continue to refine our approach. The
decisions we’ve made are based on our current understanding, but they are by no means final. We are constantly learning
and adapting our strategy to ensure it aligns with our goal: delivering high-quality applications and empowering
millions of home cooks to get better cooking results every day.

I hope this discussion has provided valuable insights and sparked ideas for your own automation journey. Whether you’re
just starting or already deep into your automation efforts, remember that flexibility and continuous learning are key.

Feel free to share any questions, experiences, or insights in the comments. I look forward to hearing from you!
