---
title: Testes no Android com Espresso — parte 5
date: 2016-08-20 00:00:00 Z
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

No [post anterior](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-4) aprendemos como mockar as intents do Android. Caso queira iniciar a partir deste post, utilize o branch ‘[part_4](https://github.com/heitorcolangelo/EspressoTests/tree/part_4)’ do projeto.

Asserções no layout do item da RecyclerView
-------------------------------------------

Na nossa MainActivity, o próximo passo é verificar se o layout que definimos para o item da nossa RecyclerView é exibido corretamente. Vamos analisar o [layout do nosso item](https://github.com/heitorcolangelo/EspressoTests/blob/part_4/app/src/main/res/layout/view_user_item.xml).

![User Item Image](https://miro.medium.com/v2/resize:fit:1066/format:webp/1*HVEH26Qsk_S_kpETw2eKmg.png)

É um layout bem simples:

*   Um _ImageView_ com id _user\_view\_image_;
*   Um _TextView_ com id _user\_view\_name_.

Então, vamos escrever um teste que verifique se estas views estão na tela:

```java
@Test
public void checkUserItemView_isDisplayed() {
  server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS));
  mActivityRule.launchActivity(new Intent());
  onView(withId(R.id.user_view_image)).check(matches(isDisplayed()));
  onView(withId(R.id.user_view_name)).check(matches(isDisplayed()));
}
```

Enfileiramos uma requisição de sucesso, assim, nossa recycler é exibida. Depois, fazemos uma asserção simples nos ids que temos no item da lista. Rode este teste, o resultado deve ser esse:

```
AmbiguousViewMatcherException: 'with id: com.example.heitorcolangelo.espressotests:id/user\_view\_image' **matches multiple views in the hierarchy.**
```

O teste não funcionou, e o Espresso está nos dizendo que existem várias views com o id que passamos, afinal de contas, existem vários itens iguais na lista, ou seja, vários ids iguais.

A maneira que eu costumo resolver este problema pode parecer um pouco preguiçosa, mas tem funcionado muito bem até então. Basta fazer um mock com apenas um item na lista! :)

```java
@Test
public void checkUserItemView_isDisplayed() {
  server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS_SINGLE_ITEM));
  mActivityRule.launchActivity(new Intent());
  onView(withId(R.id.user_view_image)).check(matches(isDisplayed()));
  onView(withId(R.id.user_view_name)).check(matches(isDisplayed()));
}
```

O teste ficará desta maneira, mudando apenas o _body_ que passamos no MockResponse, para passar o [mock com apenas um item](https://github.com/heitorcolangelo/EspressoTests/blob/part_5/app/src/androidTest/java/com/example/heitorcolangelo/espressotests/mocks/Mocks.java). Rode o teste novamente, ele deve passar. Como temos apenas um item da lista exibido na tela, não temos mais o problema de vários ids iguais. Agora podemos fazer a asserção tranquilamente.

Claro, não vou ser simplista, isso nem sempre vai ser suficiente. Por exemplo, se você tiver diferentes tipos de layout na sua lista. Vamos, então, fazer o mesmo teste sem usar o “truque” acima.

```java
@Test
public void checkUserItemView_isDisplayed_noTricks() {
  server.enqueue(new MockResponse().setResponseCode(200).setBody(Mocks.SUCCESS));
  mActivityRule.launchActivity(new Intent());
  onView(allOf(withId(R.id.user_view_image), hasSibling(withText("Eddie Dunn")))).check(matches(isDisplayed()));
  onView(allOf(withId(R.id.user_view_name), withText("Eddie Dunn"))).check(matches(isDisplayed()));
}
```

Utilizamos dois métodos novos:

*   allOf: faz um match com todas as condições que passarmos como parâmetro. No caso, passamos _withId_ e _hasSibling_,
*   hasSibling: _sibling_ em inglês quer dizer “irmão”. Este método procura a view que tenha um “irmão” que atenda as condições que passarmos como parâmetro. No caso, passamos _withText_.

Na linha 5 falamos para o Espresso: “_Verifique se a view que tem o id user\_view\_image e o irmão com texto “Eddie Dunn” está visível na tela.”_. Assim, evitamos que ocorra um _AmbiguousViewMatcherException_, pois só existe **uma** view que atende as condições acima.

Neste momento, você pode se perguntar se é correto utilizar diretamente o texto “Eddie Dunn” para fazer a asserção. Afinal de contas, e se o item com o nome “Eddie Dunn” não estiver visível na tela em um primeiro momento? Posso fazer isso sem problemas, pois sei que o primeiro item da lista sempre será “Eddie Dunn”, uma vez que estamos utilizando uma resposta mockada.

RecyclerViewActions
-------------------

Até agora, fizemos apenas asserções nos itens da nossa lista. Agora vamos começar a fazer interações, utilizando os métodos da classe RecyclerViewActions. Para isto, adicione esta dependência no seu arquivo build.gradle:

```
androidTestCompile("com.android.support.test.espresso:espresso-contrib:$espressoVersion") {  
  exclude module: 'appcompat-v7'  
  exclude module: 'support-v4'  
  exclude module: 'support-annotations'  
  exclude module: 'recyclerview-v7'  
  exclude module: 'design'  
}
```

Agora, vamos testar o seguinte cenário:

*   Ao clicar em um item da lista, deve abrir a UserDetailsActivity.

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

Vamos passar este teste linha-a-linha:

*   Linhas 3, 4 e 5: Nada de novo, apenas enfileirando as requests que serão feitas, iniciando a activity e iniciando o serviço de intents.
*   Linha 6: Criamos um matcher de intent igual ao que fizemos no teste da [LoginActivityTest](https://gist.github.com/heitorcolangelo/354080abf09bdabd0e9dd0f5a268bc21). A diferença é que passamos mais um matcher como condição, usando o método _hasExtraWithKey._ Ou seja, além de verificar se a intent que está sendo lançada é para a UserDetailsActivity, verificamos se ela contém um extra, que é o usuário clicado. Por isso, passamos o _UserDetailsActivity.CLICKED\_USER_ como parâmetro. Este valor é o mesmo que é atribuído ao _key_ do _bundle_ da nossa _intent_, quando queremos iniciar a UserDetailsActivity. Para entender melhor, confira o código na [MainActivity](https://github.com/heitorcolangelo/EspressoTests/blob/part_4/app/src/main/java/com/example/heitorcolangelo/espressotests/ui/activity/MainActivity.java).
*   Linhas 11 até 14: Nenhuma novidade, apenas definindo o que vamos passar de resultado para a _intent_ que será lançada.
*   Linha 16: Usamos o método [_actionOnItemAtPosition(int position, ViewAction viewAction)_](https://developer.android.com/reference/android/support/test/espresso/contrib/RecyclerViewActions.html#actionOnItemAtPosition(int, android.support.test.espresso.ViewAction))_,_ da classe [RecyclerViewActions](https://developer.android.com/reference/android/support/test/espresso/contrib/RecyclerViewActions.html), que contém vários outros métodos para interagir com a nossa lista. Não tem nenhum segredo, ele executa a _action_ na _position_ que passamos como parâmetro.

Execute todos os testes, eles devem passar. Se algo deu errado, retome os passos anteriores ou deixe um comentário para que eu possa ajudar. Ao final desta etapa, seu código devete método estar parecido com o da branch ‘[part\_5](https://github.com/heitorcolangelo/EspressoTests/tree/part_5)’.

Vamos partir para os testes na nossa última activity, a UserDetailsActivity.

[Ir para Parte 6 — Custom Matchers e Runtime Permissions>>](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-6)
