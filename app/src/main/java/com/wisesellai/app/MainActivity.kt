package com.wisesellai.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

private data class Agent(val id: String, val name: String)
private val agents = listOf(
 Agent("business-assistant", "AI Business Assistant"),
 Agent("sales-agent", "AI Sales Agent"),
 Agent("digital-marketing", "Digital Marketing Agent"),
 Agent("seo-content", "SEO & Content Marketing Agent"),
 Agent("social-media", "Social Media Agent"),
 Agent("video-audio", "Video & Audio Marketing Agent")
)
private val http = OkHttpClient()

class MainActivity : ComponentActivity() {
 override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  setContent { WiseSellScreen() }
 }
}

@Composable
private fun WiseSellScreen() {
 var email by remember { mutableStateOf("") }
 var password by remember { mutableStateOf("") }
 var token by remember { mutableStateOf("") }
 var createAccount by remember { mutableStateOf(false) }
 var selected by remember { mutableStateOf(agents.first()) }
 var prompt by remember { mutableStateOf("") }
 var answer by remember { mutableStateOf("Select an agent and ask a business question.") }
 var status by remember { mutableStateOf("Create an account or sign in with your Firebase account.") }
 var busy by remember { mutableStateOf(false) }
 val scope = rememberCoroutineScope()

 MaterialTheme(colorScheme = lightColorScheme(primary = Color(0xFF155EEF))) {
  Column(Modifier.fillMaxSize().background(Color(0xFFF4F7FC)).padding(16.dp)) {
   Text("WiseSell AI", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF173B73))
   Text("Your six-agent business growth team", color = Color.DarkGray)
   Spacer(Modifier.height(12.dp))
   if (token.isBlank()) {
    Text(if (createAccount) "Create your WiseSell AI account" else "Sign in to WiseSell AI", fontWeight = FontWeight.Bold, fontSize = 18.sp)
    OutlinedTextField(email, { email = it }, label = { Text("Email") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
    OutlinedTextField(password, { password = it }, label = { Text("Password (at least 6 characters)") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
    Button(onClick = {
     scope.launch {
      busy = true
      status = if (createAccount) "Creating account…" else "Signing in…"
      try {
       token = withContext(Dispatchers.IO) {
        if (createAccount) firebaseCreateAccount(email.trim(), password)
        else firebaseSignIn(email.trim(), password)
       }
       status = if (createAccount) "Account created. You are signed in." else "Signed in successfully."
      } catch (e: Exception) {
       status = e.message ?: if (createAccount) "Account creation failed." else "Sign-in failed."
      }
      busy = false
     }
    }, enabled = !busy && email.isNotBlank() && password.length >= 6, modifier = Modifier.fillMaxWidth()) {
     Text(if (busy) "Please wait…" else if (createAccount) "Create account" else "Sign in")
    }
    TextButton(onClick = {
     createAccount = !createAccount
     status = if (createAccount) "Enter your email and a password of at least 6 characters." else "Sign in with your existing account."
    }, modifier = Modifier.fillMaxWidth(), enabled = !busy) {
     Text(if (createAccount) "Already have an account? Sign in" else "New to WiseSell AI? Create account")
    }
    if (BuildConfig.FIREBASE_API_KEY.isBlank()) Text("Build setup needed: configure GitHub secret WISESELL_FIREBASE_API_KEY.", color = Color(0xFFB54708), fontSize = 12.sp)
   } else {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
     Text("Signed in", color = Color(0xFF027A48), fontWeight = FontWeight.Bold)
     TextButton(onClick = { token = ""; password = ""; status = "Signed out." }) { Text("Sign out") }
    }
    Text("Choose an AI agent", fontWeight = FontWeight.Bold, fontSize = 18.sp)
    LazyColumn(Modifier.heightIn(max = 180.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
     items(agents) { agent ->
      Row(Modifier.fillMaxWidth().background(if (selected.id == agent.id) Color(0xFFDCE8FF) else Color.White, RoundedCornerShape(10.dp)).clickable { selected = agent }.padding(12.dp)) {
       Text(agent.name, fontWeight = if (selected.id == agent.id) FontWeight.Bold else FontWeight.Normal)
      }
     }
    }
    OutlinedTextField(prompt, { prompt = it }, label = { Text("What do you need help with?") }, modifier = Modifier.fillMaxWidth(), minLines = 2)
    Button(onClick = {
     scope.launch {
      busy = true; answer = "Generating response…"
      try { answer = withContext(Dispatchers.IO) { askAgent(selected.id, prompt, token) } }
      catch (e: Exception) { answer = e.message ?: "Request failed." }
      busy = false
     }
    }, enabled = !busy && prompt.isNotBlank(), modifier = Modifier.fillMaxWidth()) { Text(if (busy) "Generating…" else "Ask selected agent") }
    Text("Response", fontWeight = FontWeight.Bold)
    LazyColumn(Modifier.weight(1f).fillMaxWidth().background(Color.White, RoundedCornerShape(12.dp)).padding(12.dp)) {
     item { Text(answer, fontSize = 14.sp) }
    }
   }
   Spacer(Modifier.height(8.dp))
   Text(status, fontSize = 12.sp, color = Color.Gray)
   Text("Current backend mode: built-in zero-cost fallback. No social posts or messages are sent automatically.", fontSize = 11.sp, color = Color.Gray)
  }
 }
}

private fun firebaseCreateAccount(email: String, password: String): String {
 require(BuildConfig.FIREBASE_API_KEY.isNotBlank()) { "Firebase Web API key is not configured. Add WISESELL_FIREBASE_API_KEY to GitHub Actions secrets." }
 require(password.length >= 6) { "Password must be at least 6 characters." }
 return firebaseAuthRequest("signUp", email, password)
}

private fun firebaseSignIn(email: String, password: String): String {
 require(BuildConfig.FIREBASE_API_KEY.isNotBlank()) { "Firebase Web API key is not configured. Add WISESELL_FIREBASE_API_KEY to GitHub Actions secrets." }
 return firebaseAuthRequest("signInWithPassword", email, password)
}

private fun firebaseAuthRequest(method: String, email: String, password: String): String {
 val payload = JSONObject().put("email", email).put("password", password).put("returnSecureToken", true).toString()
 val request = Request.Builder().url("https://identitytoolkit.googleapis.com/v1/accounts:" + method + "?key=" + BuildConfig.FIREBASE_API_KEY)
  .post(payload.toRequestBody("application/json".toMediaType())).build()
 http.newCall(request).execute().use { response ->
  val json = JSONObject(response.body?.string().orEmpty())
  if (!response.isSuccessful) {
   val code = json.optJSONObject("error")?.optString("message").orEmpty()
   val friendly = when {
    code.contains("EMAIL_EXISTS") -> "This email is already registered. Please sign in instead."
    code.contains("WEAK_PASSWORD") -> "Choose a stronger password with at least 6 characters."
    code.contains("INVALID_EMAIL") -> "Enter a valid email address."
    code.contains("OPERATION_NOT_ALLOWED") -> "Email/password sign-up is disabled in Firebase Authentication. Enable the Email/Password provider in Firebase Console."
    code.contains("API_KEY_INVALID") -> "The Firebase API key is invalid. Check the GitHub Actions secret."
    else -> code.ifBlank { "Firebase authentication failed." }
   }
   throw IllegalStateException(friendly)
  }
  return json.getString("idToken")
 }
}

private fun askAgent(agentId: String, prompt: String, token: String): String {
 val payload = JSONObject().put("message", prompt).toString()
 val request = Request.Builder().url(BuildConfig.API_BASE_URL + "/api/agents/" + agentId)
  .header("Authorization", "Bearer " + token)
  .post(payload.toRequestBody("application/json".toMediaType())).build()
 http.newCall(request).execute().use { response ->
  val raw = response.body?.string().orEmpty()
  val json = JSONObject(raw)
  if (!response.isSuccessful) throw IllegalStateException(json.optString("detail", json.optString("error", "Agent request failed.")))
  return json.optString("answer", "No response received.")
 }
}
