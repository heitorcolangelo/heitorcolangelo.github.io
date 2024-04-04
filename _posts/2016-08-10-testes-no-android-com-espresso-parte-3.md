---
title: Testes no Android com Espresso — parte 3
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

No [post anterior](https://medium.com/@heitorcolangelo/testes-no-android-com-espresso-parte-2-5180ee03ed9a#.7hwn7r3fe) fizemos nosso primeiro teste na tela de Login. Caso queira iniciar a partir deste post, utilize o branch ‘[part\_2](https://github.com/heitorcolangelo/EspressoTests/tree/part_2)’ do projeto.

**Simulando resultados de intents.**

Vamos escrever o teste para o seguinte cenário:

*   Quando _username_ e _password_ não são vazios e o usuário clica no botão de login, o app deve abrir a tela principal (MainActivity).

Poderíamos escrever um teste que preencha os dois campos, clique no botão de login e em seguida verifique se o layout da MainActivity estará visível, algo deste tipo:

Porém, isso é errado por dois motivos. O primeiro pode ser considerado mais uma dica:

> **Evite fazer testes que façam navegações através do app, inicie as activities diretamente no estado desejado.**

O segundo motivo é que a MainActivity faz uma requisição para a API, o que torna este teste dependente de um recurso externo. E aí vai outra dica, que na verdade, deve ser uma **regra**:

> **Os testes devem ser isolados de qualquer dependência externa.**

Para testarmos se uma _activity_ é iniciada, devemos testar se a _intent_ desta _activity_ é lançada, afinal de contas, quem define qual _activity_ será iniciada é a _intent_. Para podermos validar a _intent_, devemos adicionar a seguinte dependência no nosso arquivo _build.gradle_:

```groovy
androidTestCompile "com.android.support.test.espresso:espresso-intents:$espressoVersion"
```

Essa é uma extensão do Espresso que nos permite trabalhar com intents (mais informações neste [link](https://google.github.io/android-testing-support-library/docs/espresso/intents/)).

Antes de escrevermos o teste, vamos analisar o trecho do código que inicia a nossa MainActivity (LoginActivity.java, linha 53).

```java
private void doLogin() {  
  startActivity(new Intent(this, MainActivity.class));  
}
```

A _intent_ que estamos montando é bem simples, possui apenas o nome da classe (MainActivity.class) e o contexto como parâmetros. Vamos utilizar o nome da classe para validar nossa _intent_. O nosso teste ficará assim:

Vamos analisar o código:

*   Linha 3: Estamos iniciando a gravação das intents com o método [_init()_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#init())_;_
*   Linhas 5 e 6: Nada de novo, apenas preenchendo os campos _username_ e _password;_
*   Linha 8: Usamos o método _IntentMatchers._[_hasComponent_](https://developer.android.com/reference/android/support/test/espresso/intent/matcher/IntentMatchers.html#hasComponent(java.lang.String))_(String className)_ passando como parâmetro o nome da classe MainActivity, que é a _activity_ que será iniciada;
*   Linha 10: Fazemos o click no botão de login;
*   Linha 12: O método [_intended(Matcher<Intent> matcher)_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#intended(org.hamcrest.Matcher<android.content.Intent>)) verifica que o _matcher_ passado como parâmetro é o que a activity em teste irá lançar, garantindo também que esta intent seja única;
*   Linha 14: O método [_release()_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#release())  limpa os estados das intents.

O que estamos fazendo é falar para o Espresso: “_Cara, quando eu preencher estes dois campos e clicar no botão de login, o app deve lançar uma intent para abrir a MainActivity.”._ Simples assim.

Se rodarmos o teste, ele passa. Porém ainda há algo errado nele. Repare que a MainActivity ainda abre. E faz sentido, afinal de contas, a única coisa que fizemos foi garantir que a intent lançada é a correta, não fizemos nada para impedir que a MainActivity se inicie.

Para garantir que o nosso teste esteja isolado e evitar a navegação pelo app, vamos simular o resultado desta intent. Refatorando o teste, vai ficar assim:

Foram adicionadas duas linhas:

*   Linha 8: Estamos criando um objeto [_ActivityResult_](https://developer.android.com/reference/android/app/Instrumentation.ActivityResult.html) que irá simular o resultado da activity;
*   Linha 9: Usamos o método [_intending()_](https://developer.android.com/reference/android/support/test/espresso/intent/Intents.html#intending(org.hamcrest.Matcher<android.content.Intent>)) para devolver um resultado assim que a intent for lançada.

Um ponto importante na documentação do Espresso sobre esse método:

```
**Note:** the destination activity will not be launched.
```

*   Linha 9: Chamamos o método [_respondWith()_](https://developer.android.com/reference/android/support/test/espresso/intent/OngoingStubbing.html#respondWith(android.app.Instrumentation.ActivityResult))_,_ passando como parâmetro o nosso objeto ActivityResult definido na linha 8.

Novamente, o que estamos falando para o Espresso é: _“Quando esta intent for lançada, responda com esse resultado.”_, evitando que a MainActivity inicie.

Rode o teste, ele deve passar sem problemas e a MainActivity não será iniciada. Se algo deu errado, retome os passos anteriores ou deixe um comentário abaixo para eu poder te ajudar.

Ótimo, agora que já cobrimos nossa primeira tela com testes, podemos seguir em frente. Antes, verifique se o seu código está parecido com o que está na branch ‘part\_3’ do [repositório](https://github.com/heitorcolangelo/EspressoTests).

Se tiver alguma dúvida, sugestão, ou se encontrou um erro no post, deixe um comentário.

[Ir para Parte 4 — mockando requisições para a API >>](https://medium.com/@heitorcolangelo/testes-no-android-com-espresso-parte-4-6107e3e023bc#.2zuajz688)
