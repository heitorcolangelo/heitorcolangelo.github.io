---
title: Testes no Android com Espresso — parte 6
date: 2016-09-12 00:00:00 Z
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

No [post anterior](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-5) aprendemos como fazer asserções e interações em uma _recyclerview_. Caso queira iniciar a partir deste post, utilize o branch ‘part\_5’ do projeto.

Nesta parte do tutorial, vamos ver como fazer um _matcher_ customizado e aprender a tratar as runtime permissions. Para isso, foi necessário fazer uma alteração no projeto inicial. Confira esta alteração na classe _ImageAndTextView.java(linha 47)_ e na classe _UserDetailsActivity_. Entenda bem esta alteração antes de prosseguir.

Primeiro cenário
----------------

A UserDetailsActivity possui o seguinte layout:

```
<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:696/format:webp/1*2E5Ck9MdFOVgEHsr6LvHcw.png" />
</p>
```

Temos a foto do usuário, o nome, telefone, e-mail e endereço. Este pode ser o primeiro cenário: verificar se todas as informações aparecem na tela. Como é um cenário simples, vou deixar como tarefa para você implementar.

Segundo cenário
---------------

Com exceção do nome, o usuário nem sempre terá todos estes dados e, caso ele não tenha telefone, e-mail ou endereço, a mensagem “_No info available._” deve aparecer, em vermelho. Conforme imagem abaixo:

```
<p style="text-align:center;">
  <img src="https://miro.medium.com/v2/resize:fit:684/format:webp/1*ogfkyvm6gtxJeFm-mO3rwA.png">
</p>
```

Então, um outro cenário é: verificar se o texto _“No info available.”_ aparece quando o usuário não possui e-mail, telefone ou endereço.

```java
@Test
public void whenEmailIsMissing_shouldDisplay_noInfoMessage() {
    mActivityRule.launchActivity(createIntent(true));
    onView(withId(R.id.user_details_image)).check(matches(isDisplayed()));
    onView(withId(R.id.user_details_name)).check(matches(isDisplayed()));
    onView(allOf(
            withId(R.id.image_and_text_image),
            hasSibling(withText("No info available."))))
            .check(matches(isDisplayed()));
}

private Intent createIntent(boolean missingInfo) {
    return new Intent().putExtra(UserDetailsActivity.CLICKED_USER, getMockedUser(missingInfo));
}

private UserVO getMockedUser(boolean missingInfo) {
    final String mock = missingInfo ? Mocks.USER_MISSING_INFO : Mocks.USER;
    return UsersApi.GSON.fromJson(mock, UserVO.class);
}
```

Nada de novo neste teste, apenas iniciando a UserDetailsActivity com uma intent que contém um usuário sem e-mail (Mocks.USER\_MISSING\_INFO) e verificando se o texto _“No info available.”_ está visível. Porém, não testamos se a cor do texto é vermelha. Para fazer isso, vamos criar um _custom matcher._

Crie um pacote _matcher_ e uma classe _TextColorMatcher_, conforme imagem abaixo:

<div style="display: flex; justify-content: center;">
    <img src="https://miro.medium.com/v2/resize:fit:920/format:webp/1*zdJgqgZPFJeCMUWlD8kHgA.png" alt=""/>
</div>

A classe _TextColorMatcher_ ficará assim:

```java
public class TextColorMatcher {

    private TextColorMatcher(){}

    public static Matcher<View> withTextColor(@ColorInt final int expectedColor) {
        return new BoundedMatcher<View, TextView>(TextView.class) {
            int currentColor = 0;
            @Override
            public void describeTo(Description description) {
                description.appendText("expected TextColor: ")
                        .appendValue(Integer.toHexString(expectedColor));
                description.appendText(" current TextColor: ")
                        .appendValue(Integer.toHexString(currentColor));
            }
    
            @Override
            protected boolean matchesSafely(TextView item) {
                if(currentColor == 0)
                    currentColor = item.getCurrentTextColor();
                return currentColor == expectedColor;
            }
        };
    }
}
```

*   Linha 5: declaramos o método _withTextColor_ que recebe uma cor como parâmetro e retorna um _Matcher<View>._
*   Linha 6: criamos uma nova instância da classe [BoundedMatcher](https://developer.android.com/reference/android/support/test/espresso/matcher/BoundedMatcher.html), que permitirá a criação do nosso _view matcher._
*   Linha 7: inicializamos a variável que vai armazenar o valor atual da cor do texto do nosso textview.
*   Linhas 8 à 13: sobrescrevemos o método _describeTo._ É neste método que iremos atribuir ao objeto, do tipo _Description,_ aquilo que será exibido no log caso a asserção falhe.
*   Linhas 16 à 21: sobrescrevemos o método _matchesSafely,_ que é onde faremos a comparação entre a cor atual do TextView, e a cor que esperamos que ele tenha.

Agora é só usarmos o nosso custom matcher no teste:

```java
@Test
public void whenEmailIsMissing_shouldDisplay_noInfoMessage() {
    mActivityRule.launchActivity(createIntent(true));
    onView(withId(R.id.user_details_image)).check(matches(isDisplayed()));
    onView(withId(R.id.user_details_name)).check(matches(isDisplayed()));
    onView(allOf(
        withId(R.id.image_and_text_image),
        hasSibling(withText("No info available.")))
    ).check(matches(isDisplayed()));
    
    onView(allOf(
        withText("No info available."),
        withTextColor(ContextCompat.getColor(mActivityRule.getActivity(), R.color.red)))
    ).check(matches(isDisplayed()));
}
```

Para garantir que está funcionando, tente passar uma cor diferente para verificar se o teste falha. Verifique também se a mensagem de erro é a que foi configurada no nosso _custom_ _matcher_.

```
**NoMatchingViewException**: No views in hierarchy found matching: (with text: is “No info available.” and **expected TextColor:** “ffff4081” **current TextColor:** “fff44336”)
```

Outro detalhe desta tela é que cada informação executa uma ação quando clicada:

*   No número do telefone, uma ligação é feita;
*   No e-mail, uma nova mensagem é aberta para ser enviada ao usuário;
*   No endereço, o Google Maps é aberto e é possível traçar uma rota.

Vamos escrever o teste para o clique no telefone. Os outros dois testes deixo para você implementar.

Runtime Permissions
-------------------

A partir do Android 6, as permissões são solicitadas em tempo de execução. Isso afeta os nossos testes, pois temos que fazer um tratamento especial para este tipo de situação.

<p style="text-align:center">
  <img src="https://miro.medium.com/v2/resize:fit:736/format:webp/1*sZcT-X15p5IMl4D75ulCsg.png" alt="Permissão para fazer ligação"/>
</p>

Por exemplo, teremos problemas se executarmos um teste como esse:

```java
@Test
public void clickOnPhone_shouldStartPhoneIntent() {
    mActivityRule.launchActivity(createIntent(false));
    Intents.init();
    intending(hasAction(Intent.ACTION_CALL))
            .respondWith(new Instrumentation.ActivityResult(Activity.RESULT_OK, new Intent()));
    onView(withId(R.id.user_details_phone)).perform(scrollTo(), click());
    intended(hasAction(Intent.ACTION_CALL));
    Intents.release();
}
```

Em devices anteriores ao Android 6 este teste passa, mas em devices com versão Marshmallow em diante, ele vai falhar.

Também não conseguimos fazer o Espresso clicar no botão “Allow”, pois este _dialog_ está fora do contexto da aplicação.

Para este tipo de interação, vamos usar o [UiAutomator](https://developer.android.com/topic/libraries/testing-support-library/index.html#UIAutomator), pois ele nos permite executar interações com apps do Android. Se você quiser saber melhor a diferença entre Espresso e UiAutomator, dê uma olhada [nesta discussão](http://stackoverflow.com/questions/31076228/android-testing-uiautomator-vs-espresso) no stackoverflow.

Para começar, adicione esta configuração no seu arquivo build.gradle:

```
// UiAutomator  
androidTestCompile "com.android.support.test.uiautomator:uiautomator-v18:2.1.2"
```

Sincronize o projeto, você provavelmente verá este erro:

```
Manifest merger failed :   
**uses-sdk:minSdkVersion 16 cannot be smaller than version 18 declared in library ... uiautomator-v18:2.1.2  
**...  
**Suggestion:   
use tools:overrideLibrary=”android.support.test.uiautomator.v18" to force usage**
```

Para solucionar este problema, é só seguir a sugestão do próprio log de erro: _“use tools:overrideLibrary=”android.support.test.uiautomator.v18 to force usage"._

Primeiro, crie um novo arquivo _AndroidManifest.xml_ dentro da sua pasta _androidTest:_

<p style="text-align:center">
  <img src="https://miro.medium.com/v2/resize:fit:568/format:webp/1*EDfoMAUtgkpu1PHfeSuHvw.png" alt="Novo AndroidManifest.xml">
</p>

Dentro deste arquivo, coloque o código abaixo:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.heitorcolangelo.espressotests">

<uses-sdk tools:overrideLibrary="android.support.test.uiautomator.v18"/>
</manifest>
```
Quando ocorrer o merge do Manifest, o erro não ocorrerá novamente.

Eu peguei essa dica [desta resposta](http://stackoverflow.com/a/31880936/3279958) no stackoverflow. O que acontece é que a lib do UiAutomator tem minSdk 18, e o nosso app tem minSdk 16. Mas como vamos utilizar o UiAutomator somente para os testes, não tem problema sobrescrevermos este valor no Manifest. Fiz os testes com essa alteração em emuladores com API 16+ e tudo funcionou normalmente.

Seguindo com nosso teste, temos o UiAutomator configurado corretamente. Vamos utilizá-lo para interagir com o dialog de permissão do Android.

```java
/**
 * From: https://gist.github.com/rocboronat/65b1187a9fca9eabfebb5121d818a3c4
    */
public class PermissionUtils {
    private static final int PERMISSIONS_DIALOG_DELAY = 3000;
    private static final int GRANT_BUTTON_INDEX = 1;

    public static void allowPermissionsIfNeeded(String permissionNeeded) {
        try {
            Context context = InstrumentationRegistry.getTargetContext();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !hasNeededPermission(context, permissionNeeded)) {
                sleep(PERMISSIONS_DIALOG_DELAY);
                UiDevice device = UiDevice.getInstance(getInstrumentation());
                UiObject allowPermissions = device.findObject(new UiSelector()
                        .clickable(true)
                        .checkable(false)
                        .index(GRANT_BUTTON_INDEX));
                if (allowPermissions.exists()) {
                    allowPermissions.click();
                }
            }
        } catch (UiObjectNotFoundException e) {
            System.out.println("There is no permissions dialog to interact with");
        }
    }

    private static boolean hasNeededPermission(Context context, String permissionNeeded) {
        int permissionStatus = ContextCompat.checkSelfPermission(context, permissionNeeded);
        return permissionStatus == PackageManager.PERMISSION_GRANTED;
    }

    private static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            throw new RuntimeException("Cannot execute Thread.sleep()");
        }
    }
}
```

Esta classe eu encontrei [neste gist](https://gist.github.com/rocboronat/65b1187a9fca9eabfebb5121d818a3c4). Vamos analisá-la por partes:

*   Linha 11: Verificamos se a versão do Android é 6 ou mais, e se a permissão que precisamos ainda não foi dada.
*   Linha 13: Recuperamos a instância singleton da class [UiDevice](https://developer.android.com/reference/android/support/test/uiautomator/UiDevice.html). Isto permitirá a interação com o dispositivo.
*   Linha 14 até 17: Procuramos pelo botão “Allow” do dialog de permissão. Para isso, criamos um objeto [UiSelector](https://developer.android.com/reference/android/support/test/uiautomator/UiSelector.html) e chamamos alguns métodos do _builder_ desta classe para configurar nosso objeto. Um destes métodos é o _index(int index)._ Este método vai definir o ID do botão que queremos clicar. No caso do dialog, o botão “Allow” tem valor 1. Se quiséssemos clicar no “Deny” usaríamos o index = 0.
*   Linha 18 e 19: Se o botão “Allow” foi encontrado, efetuamos um clique nele.

No nosso teste, vamos chamar o método _allowPermissionsIfNeeded_ do _PermissionUtils_ logo depois do clique no telefone. Ficará assim:

Tente executar o teste, verifique se ele passa. Se algo deu errado, retome os passos anteriores ou deixe um comentário para que eu possa ajudar.

Existem outros cenários a serem testados nesta tela, mas o conhecimento necessário para isso já foi abordado neste tutorial. Então, mãos à obra. 😉

Ao final desta etapa, seu código deve estar parecido com o da branch ‘[part\_6](https://github.com/heitorcolangelo/EspressoTests/tree/part_6)’.

[Ir para parte 7 — Dicas finais, TestButler e Robots Pattern>>.](https://heitorcolangelo.dev/testes-no-android-com-espresso-parte-7)
