---
title: Testes no Android com Espresso — parte 7
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

No [post anterior](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-6) aprendemos como criar _custom matchers_ e como tratar _run time permissions_ com UiAutomator. Nesta última parte vou focar mais em algumas dicas que acho importante, também vou falar sobre TestButler e Robots Pattern. Para acompanhar esta parte, utilize o branch ‘[part\_7](https://github.com/heitorcolangelo/EspressoTests/tree/part_7)’ do projeto.

Animações de Loading x AlertDialogs
-----------------------------------

Cuidado com animações que mostram progresso (_loadings_), especialmente se um dialog estiver por cima desta animação. Quando o dialog está por cima do loading, a animação ainda está acontecendo na UiThread. Ou seja, o estado _idle,_ que o Espresso fica esperando para poder seguir com o teste, nunca acontece. Alterei a LoginActivity para poder demonstrar isso, repare como ficou o método de click do botão de login. Desconsidere o layout e a funcionalidade desta alteração, a ideia é apenas demonstrar o problema em questão.

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

Com essa alteração, toda vez que o usuário clicar no botão de login, o loading é exibido na tela e, depois disso, fazemos o processo de login. O problema é que, quando os campos estão vazios, o dialog de erro é exibido, e isso nos coloca exatamente na situação que mencionei anteriormente, um dialog em cima de um loading. Rode os testes da LoginActivity e repare que os testes que envolvem o dialog de erro quebram.

```
**AppNotIdleException**: Looped for 3608 iterations over 60 SECONDS. The following Idle Conditions failed.
```

Portanto, sempre esconda os seus _loadings_ da tela antes de exibir um dialog para o usuário, e sempre que um teste estiver falhando por conta de uma **AppNotIdleException,** verifique se não existe um loading “escondido” na sua tela.

Teste o comportamento.
----------------------

Foque em testar o comportamento do app, não fique testando propriedades de layout. Se realmente precisar verificar as posições, use _position assertions_:

<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:694/format:webp/1*_YqXV5KcOhZJAYYWVvZKXQ.png" alt="Position assertions"/>
</p>

Position assertions from [espresso-cheat-sheet](https://google.github.io/android-testing-support-library/downloads/espresso-cheat-sheet-2.1.0.pdf).

Execute seus testes em devices pequenos.
----------------------------------------

Enquanto você roda seus testes em devices de tela grande, tudo ocorre muito bem, nada quebra. Mas não se esqueça que tem muita gente com dispositivos pequenos por aí, e que irão querer usar o seu app. Então seja bonzinho, lembre-se destas pessoas e execute seus testes em devices pequenos. Você vai perceber que muitos vão falhar, principalmente por conta de views que não estão na tela.

<div style="display: flex; justify-content: center;">
  <img src="https://miro.medium.com/v2/resize:fit:478/format:webp/1*2RwUM2Kl7JDj66RmE2-8_Q.png" alt="Dispositivo pequeno">
</div>

Em um dispositivo pequeno, o endereço do usuário não fica visível. O teste quebra.

Você vai ter que usar bastante o método _scrollTo()._

Ação de toque único em devices/emuladores lentos (antigos).
-----------------------------------------------------------

No Google I/O deste ano, mais especificamente [nesta palestra](https://www.youtube.com/watch?v=isihPOY2vS4&list=WL&index=5), foi apresentada uma informação importantíssima que é um problema de interpretação de toques únicos feitos pelo Espresso. Eles não entraram em detalhes, mas disseram que, em algumas vezes, o toque único é interpretado como um toque longo (long click) em dispositivos ou emuladores lentos. Isto acontece pois o toque em si é composto de duas ações: pressionar e soltar. Quando o dispositivo é muito antigo e lento, e tem alguma tarefa rodando em background, o tempo de resposta entre um evento e outro pode demorar, então este toque é interpretado como um _long click._ Para evitar que isto acabe quebrando seus testes, altere a seguinte configuração:

```
Settings -> Accessibility -> Touch and hold delay -> LONG
```

<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:480/format:webp/1*kv2M-P40FmQImu6S10o7Dw.png" alt="Property Touch and hold delay"/>
</p>

Mude a propriedade destacada para LONG.

O toast do Leak Canary.
-----------------------

[Leak Canary](https://github.com/square/leakcanary) é uma lib para detectar leaks de memória no seu app. É uma ótima lib porém, de vez em quando, ela lança automaticamente um toast na tela e, se isso acontecer durante a execução dos seus testes, eles vão quebrar, pois o toast vai bloquear a UI e o Espresso pode não encontrar a view com a qual ele está tentando interagir. Então, não instale o Leak Canary no device e/ou emulador que utilizará para fazer os testes.

TestButler, “descontaminando” o dispositivo para os testes.
-----------------------------------------------------------

Enquanto eu escrevia esta série de posts, o Linkedin lançou uma lib chamada [TestButler](https://github.com/linkedin/test-butler). Ela estabiliza o emulador em que os testes estão rodando, evitando que estes testes falhem por problemas nele. Por exemplo, você já deve ter se deparado com essa situação:

<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:578/format:webp/1*-Jyyt2Wmq6sbTDXJPwguUA.png" alt="TestButler"/>
</p>

Isso com certeza quebrará seu teste. A ideia do TestButler é evitar que isso ocorra. Além disso, você também consegue alterar algumas configurações globais do emulador, como:

*   Habilitar/Desabilitar WiFi;
*   Mudar orientação do dispositivo;
*   Definir o modo do location service (Alta precisão ou economia de energia);
*   Definir o Locale (língua padrão) da aplicação, caso seu app seja destinado a mais de um país isso vai te ajudar bastante.

Enfim, vale a pena estudar e usar esta lib, com certeza vai ajudar bastante.

[Test Butler](https://github.com/linkedin/test-butler)

Robots Pattern
--------------

Semana passada assisti um tech talk na [Concrete Solutions](https://medium.com/u/a791b2313cef?source=post_page-----dee47be84571--------------------------------) sobre [Robots Pattern](https://realm.io/news/kau-jake-wharton-testing-robots/). Este padrão, apresentado por Jake Wharton, tem o objetivo de deixar os testes mais estáveis, legíveis e fáceis de dar manutenção. Por exemplo, um dos nossos testes da LoginActivity está desta forma:

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

Aplicando Robots, o mesmo teste ficaria assim:

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

O código fica mais legível e você deixa na classe de testes somente os passos do teste em si. A maneira como estes passos serão implementados fica separado em outras classes:

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

Na palestra, Jake Wharton implementa Robots com [Kotlin](https://kotlinlang.org/). Se usarmos o Kotlin, nosso teste ficaria bem mais limpo, por exemplo:

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

Bem legal né? E isso é só o começo, dá pra brincar bastante e melhorar a maneira como testamos nossos apps com este padrão. Assista a palestra toda, vale muito a pena.

[Instrumentation Testing Robots](https://realm.io/news/kau-jake-wharton-testing-robots)

Tenha paciência.
----------------

Se é a primeira vez que você está dando a devida atenção aos testes, você vai achar que eles tomam muito tempo de desenvolvimento. Mas é o começo, todo começo é difícil. Seus testes vão falhar aparentemente sem explicação nenhuma, você vai descobrir que não é possível testar tudo somente com o Espresso (como foi o caso das RuntimePermissions), entre outros problemas que irão te fazer querer desistir. Mas não desista, depois que você pega a prática, as coisas fluem melhor. Você passa a perceber algumas coisas, como:

*   Começa a desenvolver pensando em como você vai testar aquele código;
*   Se sente mais seguro ao fazer uma grande alteração no código, pois sabe que os seus testes estarão te cobrindo, caso você quebre algo;
*   Passa a estimar suas tarefas já pensando no esforço dos testes.

É muito importante ter uma cultura de teste, seja com Espresso ou não, seja um app mobile ou não. Fiz esta série de posts pensando em incentivar os desenvolvedores a criar este hábito, tratar os testes como aliados e não como inimigos.

Obrigado!
---------

Espero que tenha gostado do conteúdo que compartilhei ao longo destes posts. Se tiver alguma dúvida, sugestão ou crítica, fique à vontade para me procurar.

Abraço!

heitorcolangelo@gmail.com
