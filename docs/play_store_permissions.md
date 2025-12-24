# Google Play Console 権限宣言用テキスト

Google Play Console の「アプリのコンテンツ」>「権限の宣言」等で使用する説明文です。

## 1. android.permission.ACTIVITY_RECOGNITION

**（身体活動データ / Activity Recognition）**

**使用目的:**
本アプリはヘルスケア RPG であり、ユーザーの「歩数」をゲーム内の経験値（EXP）に変換してキャラクターを育成します。身体活動データの権限は、デバイスの歩数センサーから正確な歩数を取得し、ウォーキング活動をゲームの進行に反映させるために必要不可欠です。広告表示やその他の目的には使用されません。

**English:**
This app is a healthcare RPG that converts the user's "steps" into in-game Experience Points (EXP) to raise characters. The Activity Recognition permission is essential to retrieve accurate step counts from the device's sensor and reflect walking activity in the gameplay. It is not used for advertising or any other purposes.

---

## 2. android.permission.health.READ_STEPS

**（Health Connect - 歩数データの読み取り）**

**使用目的:**
本アプリは Google Health Connect と連携し、ユーザーの過去および現在の歩数データを取得して、以下の機能を提供するためにこの権限を使用します：

1. ゲーム内のキャラクター育成（経験値への変換）
2. 日々の歩数履歴グラフの表示
   取得したデータはアプリ内の機能提供のみに使用され、第三者への販売や、ユーザーの同意のない広告ターゲティングには使用されません。

**English:**
This app integrates with Google Health Connect and uses this permission to read the user's past and current step count data to provide the following features:

1. In-game character growth (converting steps to EXP).
2. Displaying daily step count history graphs.
   The retrieved data is used solely for providing in-app features and is not sold to third parties or used for unauthorized ad targeting.
