plugins {
 id("com.android.application")
 id("org.jetbrains.kotlin.android")
 id("org.jetbrains.kotlin.plugin.compose")
}

val firebaseApiKey = providers.gradleProperty("WISESELL_FIREBASE_API_KEY").orElse("").get()

android {
 namespace = "com.wisesellai.app"
 compileSdk = 35
 defaultConfig {
  applicationId = "com.wisesellai.app"
  minSdk = 23
  targetSdk = 35
  versionCode = 1
  versionName = "1.0.0"
  buildConfigField("String", "FIREBASE_API_KEY", "\"$firebaseApiKey\"")
  buildConfigField("String", "API_BASE_URL", "\"https://wise-sell-ai-app2.abdico-veiws22.workers.dev\"")
 }
 buildFeatures { compose = true; buildConfig = true }
 compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
 kotlinOptions { jvmTarget = "17" }
}
dependencies {
 implementation(platform("androidx.compose:compose-bom:2024.12.01"))
 implementation("androidx.activity:activity-compose:1.10.0")
 implementation("androidx.compose.ui:ui")
 implementation("androidx.compose.ui:ui-tooling-preview")
 implementation("androidx.compose.material3:material3")
 implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
 implementation("com.squareup.okhttp3:okhttp:4.12.0")
 implementation("org.json:json:20240303")
 debugImplementation("androidx.compose.ui:ui-tooling")
}
