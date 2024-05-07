---
title: Testes no Android com Espresso — parte 2
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

#### Asserções simples e interações com views.

Na [parte 1](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-1) nós vimos como configurar nosso projeto. Se você quiser começar a partir desta parte, clone o projeto [EspressoTests](https://github.com/heitorcolangelo/EspressoTests) no github e faça um fork da branch ‘part\_1’, que representa o estado do projeto ao final da parte 1.

**Criando o primeiro teste**

Vamos começar testando a tela de login. Para isso, crie uma classe `LoginActivityTest` no diretório `/app/src/androidTest/` do projeto, conforme a imagem abaixo:

![](https://cdn-images-1.medium.com/max/462/1*DiqC06BAa2stAKtKtJ4TUw.png)

Anote a classe que criamos com a anotação `@RunWith(AndroidJUnit4.class)`.

Isso irá indicar que esta classe deve ser executada com o AndroidJUnitRunner; se quiser saber mais sobre ele, acesse o [link](https://developer.android.com/reference/android/support/test/runner/AndroidJUnitRunner.html).

Agora, vamos definir nossa [ActivityTestRule](https://developer.android.com/reference/android/support/test/rule/ActivityTestRule.html) com a activity que será iniciada antes de todos os nossos testes, ou seja, a activity que queremos testar.

```java
@Rule  
public ActivityTestRule<LoginActivity>  
    mActivityRule = new ActivityTestRule<>(LoginActivity.class, false, true);
```
Os parâmetros do construtor são:

*   A activity que será testada (LoginActivity.class),
*   [initialTouchMode](http://android-developers.blogspot.com.br/2008/12/touch-mode.html) (false),
*   Se deve iniciar automaticamente ou não (true).

Seu código deve estar desta maneira:

```java
@RunWith(AndroidJUnit4.class)
public class LoginActivityTest {

  @Rule
  public ActivityTestRule<LoginActivity>
      mActivityRule = new ActivityTestRule<>(LoginActivity.class, false, true);
}
```

**Escrevendo o primeiro teste**

Agora vamos escrever nosso primeiro teste. Devemos testar os diferentes estados que a tela em questão pode assumir. Por exemplo, assim que iniciamos a LoginActivity, ela exibe uma imagem, dois campos de texto e um botão. Este pode ser considerado o estado inicial da tela. Vamos escrever um teste para verificar esse estado.

```java
@Test
public void whenActivityIsLaunched_shouldDisplayInitialState() {
  onView(withId(R.id.login_image)).check(matches(isDisplayed()));
  onView(withId(R.id.login_username)).check(matches(isDisplayed()));
  onView(withId(R.id.login_password)).check(matches(isDisplayed()));
  onView(withId(R.id.login_button)).check(matches(isDisplayed()));
}
```

Uma das vantagens do Espresso é que a sintaxe é bem intuitiva. Praticamente podemos ler em linguagem natural o que o teste está executando. Vamos analisar a primeira linha do teste:

`onView(withId(R.id.login_image)).check(matches(isDisplayed()));`

Poderíamos ler esta linha em linguagem natural, por exemplo: “_Verifique que a view com id login\_image está visível na tela”_. Agora, explicando um pouco o que está acontecendo:

*   `onView()` vai receber o `ViewMatchers` que passarmos como parâmetro e irá nos retornar um objeto `ViewInteraction`. Em outras palavras, estamos passando pra ele a view que queremos interagir;
*   `withId()` vai receber o id da view e irá nos retornar um `ViewMatchers`;
*   `check()` vai receber um `ViewAssertion`. Ou seja, vai verificar se é válida a asserção que estamos passando como parâmetro;
*   `matches()` vai receber um `ViewMatchers` e retornar um `ViewAssertion`;
*   `isDisplayed()` é o `ViewMatchers` que utilizaremos.

Para saber mais sobre os objetos, clique nos links sobre [ViewMatchers](https://developer.android.com/reference/android/support/test/espresso/matcher/ViewMatchers.html), [ViewInteraction](https://developer.android.com/reference/android/support/test/espresso/ViewInteraction.html) e [ViewAssertion](https://developer.android.com/reference/android/support/test/espresso/ViewAssertion.html).

**Executando o teste**

Agora é só executar o teste certo? Errado! Precisamos desativar as animações nas opções de desenvolvedor do nosso emulador/device. Para fazer isso, vá em _Configurações > Programador (ou opções de desenvolvedor)_ e desative estas três opções:

*   Animação em escala;
*   Escala de transição;
*   Escala de duração da animação.

O Espresso aguarda a UI Thread ficar ociosa (idle) para executar o próximo passo do teste. Porém, se as animações estiverem ligadas, ele irá se perder e os testes irão quebrar, leia mais sobre isso [aqui](https://google.github.io/android-testing-support-library/docs/espresso/setup/index.html).

Agora, para rodar este teste, basta clicar no botão direito do mouse sobre o método e depois clicar na opção _Run ‘whenActivityIsLaunched…’_. Se tudo correr bem, você deve ver o teste ser executado no seu emulador e o console de testes estará assim:

![](https://cdn-images-1.medium.com/max/1024/1*FdQm1REF0c1wfQ5XTm6s4Q.png)

Certo, mas como eu garanto que o Espresso está realmente funcionando e olhando se minhas views estão aparecendo na tela? Para garantir isso, vamos alterar a primeira linha deste teste que fizemos:

`onView(withId(R.id.login_image)).check(matches( not(isDisplayed()) ));`

O método `not()` irá inverter o resultado que esperávamos. Então, estou dizendo neste teste que a view com id `login_image` **não** estará visível na tela, o que não é verdade, pois ao iniciar a tela, a imagem estará visível. Então o teste deve obrigatoriamente falhar. Se rodarmos o teste novamente:

![](https://cdn-images-1.medium.com/max/1024/1*80B6EEH6aQ23BKFehl6AFA.png)

Ótimo, nosso teste falhou, o que significa que o Espresso está fazendo as asserções corretamente. Melhor que isso, repare no log que ele mostra:
```
Expected: not is displayed on the screen to the user  
Got: AppCompatImageView{..., visibility=VISIBLE, ...}
```

Ou seja, ele também nos mostra onde o teste está falhando. Agora podemos remover o método `not()` que adicionamos e rodar esse teste novamente. Deu verde? Então vamos em frente.

Este teste foi fácil, o que devemos fazer agora é testar os outros estados da tela. Um destes outros estados é quando deixamos um dos campos de texto em branco, e clicamos no botão de login. Quando isso acontece, o app exibe um dialog na tela. Vamos escrever um teste para verificar esse estado.

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

**Não execute o teste ainda**, ele não vai funcionar, mas por outro motivo que vou abordar mais pra frente. Primeiro, vamos somente analisar o código. Utilizamos três novos métodos:

*   `perform()`: vai executar a ViewAction que receber como parâmetro;
*   `typeText()`: ViewAction para digitar um texto na view;
*   `click()`: ViewAction para clicar na view;
*   `withText()`: vai procurar a view que contenha o texto passado como parâmetro.

O primeiro bloco do nosso teste está executando as seguintes ações:

*   Escrevendo um texto no campo _login\_username;_
*   Clicando no botão de login;
*   Verificando que o dialog está aparecendo (pois deixamos o campo senha em branco);
*   Clicando no _Ok_ do dialog para fechá-lo.

O segundo bloco faz basicamente a mesma coisa que o primeiro bloco, só que com o campo _login\_password. A_ única diferença é que ele limpa o campo _login\_username_ antes, pois o campo está preenchido por causa do bloco anterior. Isso não é muito legal, ter que limpar o que os passos anteriores do teste fizeram para executar os próximos passos. Nossos testes devem validar os cenários de maneira isolada. Então, vamos refatorar este código.

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

Ótimo, agora temos dois testes, e um não está influenciando no outro. Porém ainda repetimos os mesmos passos para ambos os testes. Acho que podemos refatorá-los novamente.

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

Agora está melhor, temos um código mais limpo e reutilizável. Este é um bom momento para eu dar a primeira dica desta série:

> **Faça testes pequenos, não faça testes longos.**

Evite fazer testes que executem várias coisas, foque em cenários pequenos e, de preferência, independentes.

Agora sim, tente rodar os testes. Como eu já havia dito antes, eles falham. Vamos analisar o log:

`Error performing 'single click - At Coordinates: ... **on view 'with id: com.example.heitorcolangelo.espressotests:id/login\_button'.**`

Aparentemente o Espresso não conseguiu efetuar o click no botão de login, ou seja, o problema está na segunda linha do método _testEmptyFieldState:_

`onView(withId(R.id.login_button)).perform(click());`

Coloque um _breakpoint_ nesta linha e vamos ver a tela do emulador neste momento:

![](https://cdn-images-1.medium.com/max/368/1*2_cNXc7l-2_qZZrHvZRy4w.png)

Repare que o teclado virtual está ocupando uma boa parte da tela, inclusive ele está cobrindo o nosso botão de login, por isso o Espresso não pode clicar no botão. Para corrigir este problema vamos utilizar o método _closeSoftKeyboard()._

```java
onView(withId(notEmptyFieldId)).perform(typeText("defaultText"), closeSoftKeyboard() );
```

Este método irá fechar o teclado virtual após digitarmos o texto “defaultText”. Nosso botão de login ficará visível e o Espresso conseguirá clicar nele. Rode o teste novamente, acredito que agora irá passar.

Aí vai a segunda dica:

> **Sempre que tiver um teste que envolva digitar texto em um EditText, não se esqueça de usar o método `closeSoftKeyboard()` para esconder o teclado virtual.**

Se você deixar o teclado virtual aberto durante os testes, ele vai ficar por cima de views que poder ser essenciais para seu teste, e este irá falhar.

Ufa, bastante coisa até aqui, mas ainda temos dois cenários para validar:

1.  Quando os dois campos estão vazios, deve exibir o dialog;
2.  Quando os dois campos são preenchidos, deve abrir a MainActivity.

O cenário 1 vou deixar como exercício para você resolver. O cenário 2 envolve outro conceito que vou deixar para o próximo post.

Ao final desta etapa, o seu código deve estar parecido com o branch [`part_2`](https://github.com/heitorcolangelo/EspressoTests/tree/part_2).

Se tiver dúvidas, sugestões ou encontrou alguma informação errada neste post, deixe um comentário abaixo.

[Ir para parte 3  —  testando intents >>](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-3)
