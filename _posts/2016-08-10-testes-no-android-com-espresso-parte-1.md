---
title: Testes no Android com Espresso — parte 1
date: 2016-08-10 00:00:00 Z
tags:
- software-testing
- android
layout: post
class: post-template
subclass: post
author: heitor
cover: assets/images/testes-no-android-com-espresso.png
---

![](https://cdn-images-1.medium.com/max/1024/1*99qTbnhUu3jQsGn3eWIgrA.png)

Nesta série de posts, vou mostrar como realizar testes eficientes no seu app Android utilizando o [Espresso](https://google.github.io/android-testing-support-library/docs/espresso/). Além disso, conforme formos evoluindo, vou dando dicas das principais dificuldades que você provavelmente irá encontrar pelo caminho, e como resolvê-las.

**Sobre o projeto**

Durante toda a série de posts, vou usar o projeto [EspressoTest](https://github.com/heitorcolangelo/EspressoTests). É um app simples que consome a API do [RandomUser](https://randomuser.me/). O app tem 3 telas:

1.  Tela de login, com dois EditText, _username_ e _password_. A única validação que está sendo feita é de campo vazio, ou seja, não estando vazios os dois campos, você pode colocar qualquer usuário e senha que ele vai fazer o login.
2.  Fazendo o login, a segunda tela é a lista dos usuários retornada pela API.
3.  Clicando em um dos itens da lista, você será direcionado para a tela de detalhes do item clicado.

As bibliotecas que estou utilizando para o app são:

*   [Picasso](http://square.github.io/picasso/)
*   [ButterKnife](http://jakewharton.github.io/butterknife/)
*   [EventBus](https://github.com/greenrobot/EventBus)
*   [OkHttp](http://square.github.io/okhttp/)
*   [Retrofit](http://square.github.io/retrofit/)

É importante que você entenda bem o projeto antes de começar os testes. Por esse motivo, deixei o app bem simples para que este entendimento não tome muito tempo. Para iniciar, clone o branch `start_project` do projeto no github.

Sem mais enrolação, vamos à prática.

**Configurando o Espresso no projeto**

No arquivo `build.gradle` do projeto, adicione as seguintes dependências:

```groovy
androidTestCompile 'com.android.support.test.espresso:espresso-core:3.0.1'  
androidTestCompile 'com.android.support.test:runner:1.0.1'
```

Agora dê um sync no gradle e pronto, o Espresso já está configurado corretamente. 
**Importante:** o gradle provavelmente irá reclamar por causa da dependência `support-annotations`; para resolver este problema, adicione esta linha nas suas dependências.

```groovy
androidTestCompile "com.android.support:support-annotations:$androidSupportVersion"
```

onde `$androidSupportVersion` é a versão que você está utilizando para support library.

Não vou me aprofundar muito nas causas deste problema, não é o foco do post. Se quiser saber mais ou ainda estiver com problemas de dependência, dê uma olhada [neste link](http://stackoverflow.com/questions/33317555/conflict-with-dependency-com-android-supportsupport-annotations-resolved-ver).

Ok, agora que já configuramos o projeto, vamos começar a fazer nossos testes. Até aqui, se você tiver alguma dúvida ou teve algum problema, deixe seu comentário abaixo.

Por enquanto a única coisa que mudou no projeto que você clonou (branch `start_project`) foi o arquivo `build.gradle`. De qualquer modo, o estado final do app nesta parte do tutorial está no branch [`part_1`](https://github.com/heitorcolangelo/EspressoTests/tree/part_1).

[Ir para parte 2 — Asserções simples e interações com views >>](https://medium.com/@heitorcolangelo/testes-no-android-com-espresso-parte-2-5180ee03ed9a#.7hwn7r3fe)

![](https://medium.com/_/stat?event=post.clientViewed&referrerSource=full_rss&postId=8d739672a235)