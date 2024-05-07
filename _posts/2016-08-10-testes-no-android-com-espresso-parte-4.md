---
title: Testes no Android com Espresso — parte 4
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

No [post anterior](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-3) aprendemos como mockar as intents do Android. Caso queira iniciar a partir deste post, utilize o branch ‘part_3’ do projeto.


Cenários da MainActivity
------------------------

A MainActivity possui a lista com os usuários que recebemos da API. Caso ocorra um erro na requisição, a MainActivity exibirá uma tela com um erro ao invés da lista, e enquanto nenhuma resposta volta da API, um loading permanece na tela. Então, a princípio, temos três cenários para testar:

1.  Quando a requisição é feita com sucesso, devemos ver a lista com os usuários;
2.  Quando houver um erro na requisição, devemos ver a tela de erro;
3.  Quando não recebemos nenhuma resposta da API, devemos ver a tela de loading.

Ótimo, levantamos os primeiros estados para testarmos nossa activity. Porém, temos um problema com o terceiro cenário.

Nos testes que fizemos até aqui, o Espresso fez várias interações com o nosso app mas, já parou para pensar como o Espresso sabe a hora que pode interagir com o app? Afinal de contas, os apps possuem animações e em muitos casos a UI só pode ser utilizada quando a animação acaba. Pois é, o espresso faz exatamente isso, ele espera a [UI Thread](http://stackoverflow.com/questions/3652560/what-is-the-android-uithread-ui-thread) da aplicação ficar ociosa — em inglês, _idle._ Enquanto a UI não termina as animações, o Espresso não interage com ela. Se o app não ficar _idle_ em 60 segundos, o Espresso devolve um erro:

```
AppNotIdleException: Looped for 3544 iterations over 60 SECONDS. The following Idle Conditions failed .
```

Sabendo disso, você já consegue imaginar que o teste do terceiro cenário não vai funcionar, pois como a tela de loading é uma animação infinita, a _UI Thread_ nunca vai ficar _idle_ e o Espresso nunca vai interagir com ela. Então, vamos eliminar este cenário com esta **dica muito importante e que vai te poupar muita dor de cabeça**:

> **Cuidado com animações de ‘loading’ na tela. Se elas estiverem na tela, o seu teste com certeza irá falhar.**

Escrevendo os testes
--------------------

Vamos criar nossos testes para atender os dois primeiros cenários. Vou deixar a configuração inicial da classe MainActivityTest por sua conta; ela é idêntica a configuração inicial da LoginActivityTest, a única diferença é no último parâmetro para criar a ActivityTestRule. Na LoginActivityTest usamos _true,_ nesta iremos usar _false._ Lembra pra que serve este parâmetro? Ele indica se a activity deve ser iniciada automaticamente.

Ao final desta configuração, sua classe deve estar desta maneira:

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

Ok, poderíamos simplesmente sair escrevendo os testes da mesma maneira que fizemos na LoginActivityTest. Porém, como esta activity faz uma requisição para a API logo que é iniciada, dependemos do resultado da requisição para que o teste dê certo ou não. Isso é ruim, como eu havia dito, devemos manter nossos testes isolados. Vamos então isolar nosso teste mockando o resultado da requisição que o app faz para a API. Para isso, vamos utilizar a lib [MockWebServer](https://github.com/square/okhttp/tree/master/mockwebserver).

Configurando MockWebServer
--------------------------

Adicione a seguinte dependência no seu arquivo build.gradle:

```groovy
androidTestCompile "com.squareup.okhttp3:mockwebserver:$okHttpVersion"
```

Sincronize o projeto e vamos configurar o MockWebServer na nossa MainActivityTest. Dê uma olhada na implementação abaixo:

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

Declaramos dois novos métodos: `setUp` e `tearDown`. Anotamos estes métodos com `@Before` e `@After`, respectivamente. Os métodos anotados com _Before_ serão executados antes da activity ser iniciada. Os métodos anotados com _After_, serão executados ao final de cada teste. Fora isso, nada de muito especial, estamos apenas criando uma nova instância de MockWebServer e dando um start no server.

Porém, nosso app ainda está apontando para a url real da API, ou seja:

```
http://api.randomuser.me/
```

Isso significa que, se escrevermos um teste, nosso app ainda irá fazer a requisição para a API real, e não para nosso MockWebServer. Porém, pela nossa implementação, a url é definida como uma variável no nosso arquivo build.gradle, o que torna essa redefinição de URL um pouco mais difícil. Para facilitar nossa vida, vamos usar a lib [Mirror](http://projetos.vidageek.net/mirror-pt/mirror/).

**Importante:** antes de continuar, revise como o app está fazendo as requisições para a API. Isso vai te ajudar a entender o que vamos fazer daqui pra frente.

Adicione esta dependência no seu arquivo build.gradle:

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

Na linha 13, chamamos o método `setupServerUrl()`. Vamos analisá-lo:

*   Linha 22: definimos a url do nosso MockWebServer para “/”, pegamos o valor total da url e armazenamos na string _url;_
*   Linha 24 e 25: apenas definimos o nível de log do nosso objeto [HttpLogginInterceptor](https://github.com/square/okhttp/tree/master/okhttp-logging-interceptor);
*   Linha 27: criamos um objeto [OkHttpClient](http://square.github.io/okhttp/) e passamos o nosso interceptor;
*   Linha 29: referenciamos a instância de UsersApi;
*   Linha 31: criamos um novo objeto Api com o retrofit, só que desta vez passando a url do nosso MockWebServer;
*   Linha 38: chamamos o método setField, que recebe como parâmetros:  
    1- O _target_, que é o objeto que terá o field alterado usando reflection com o mirror;  
    2- O nome do field que será alterado;  
    3- O novo valor que será atribuído ao field alterado.

O método setField é onde de fato usaremos a lib Mirror. Acredito que seja bem simples entender o que ele faz, basicamente estamos falando para o Mirror pegar o field “api” do nosso target(que é um objeto da classe UsersApi) e alterar o valor deste field para o objeto que passamos no parâmetro value. Deste modo, estamos alterando a url base do nosso projeto para apontar para o nosso MockWebServer.

É importante ressaltar que, se sua implementação te permitir definir a url do endpoint de maneira mais simples, é bem provável que você não precise usar _reflection_.

Se você ficou com alguma dúvida, retome os passos anteriores antes de prosseguir; se, mesmo assim, estiver com dúvida, deixe nos comentários para que eu possa ajudar.

Agora nosso teste está isolando nosso app das chamadas da API. Porém, ainda não definimos a resposta que nosso MockWebServer irá retornar para cada caso de teste.

Mockando o retorno da request
-----------------------------

Para podermos mockar o retorno, devemos ter um mock do objeto json igual ao que a API retorna. Isso é simples, basta simularmos uma requisição para a API no nosso navegador, por exemplo:
 
[http://api.randomuser.me/?results=20](http://api.randomuser.me/?results=20)

Então, é só você copiar o json que aparecer no navegador e colocar em uma _string_ em um lugar acessível aos testes. Eu costumo colocar em uma interface, conforme fiz no arquivo Mocks.java.

Agora vamos escrever nosso primeiro teste para a MainActivity. Neste teste iremos verificar se, quando a API retorna com sucesso os usuários, nós visualizamos a lista de usuários na tela.

Linha 3: estamos chamando o método _enqueue_ do MockWebServer. Este método vai enfileirar (_enqueue_, em inglês) o objeto [MockResponse](https://github.com/square/okhttp/blob/master/mockwebserver/src/main/java/okhttp3/mockwebserver/MockResponse.java) que passamos como parâmetro. Estamos definindo o _responseCode_ como 200, ou seja, uma requisição com sucesso. Também estamos definindo o _body_ com o mock que acabamos de copiar e colocamos na interface Mocks.java. Resumindo: estamos dizendo para o MockWebServer: “Quando chegar uma requisição para você, retorne este MockResponse” ;

Linha 4: iniciamos a activity, passamos uma intent simples, uma vez que não é necessário nenhum extra nesta activity;

Linha 5: estamos verificando se nossa lista está visível.

Rode o teste, ele deve passar. Agora veja como ficou o log:

```
D/OkHttp: --> GET [http://localhost:41183/?page=0&results=20](http://localhost:41183/?page=0&results=20) http/1.1  
D/OkHttp: --> END GET  
D/OkHttp: <-- 200 OK [http://localhost:41183/?page=0&results=20](http://localhost:41183/?page=0&results=20) (34ms)
```

Veja que agora nosso endpoint é o _localhost_, ou seja, o MockWebServer.

Conseguimos testar um cenário da nossa activity de maneira isolada. Mas ainda falta outro cenário, aquele que quando uma requisição falha (código entre 400 e 500), aparece a tela de erro. Vou deixar esse teste para você implementar. Ele é bem simples, você apenas terá que mudar o código de retorno e o body.

Se algo deu errado, retome os passos anteriores ou deixe um comentário abaixo para eu poder te ajudar. Ao final desta etapa (após ter implementado o segundo cenário de teste) seu código deve estar parecido com o da branch ‘part_4’.

Se tiver alguma dúvida, sugestão, ou se encontrou um erro no post, deixe um comentário.

Ainda precisamos testar se o layout que definimos para o nosso item da recycler view está sendo apresentado corretamente. Também precisamos verificar se ao clicar em um item, enviamos as informações corretas para a activity de detalhes. Estes serão nossos próximos cenários de teste.

[Ir para Parte 5 — asserções e interações na recycler view >>](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-5)
