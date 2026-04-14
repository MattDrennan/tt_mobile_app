# XenForo OAuth Setup for the Mobile App

This guide describes how to configure XenForo OAuth2 so the **Troop Tracker mobile app** can log users in and access the XenForo API for troop chat and related features.

It assumes you already have:

- A running XenForo 2.3+ forum
- The Troop Tracker web app installed and configured
- The Troop Tracker mobile app built from this repository

If you are configuring XenForo for the first time, read the web app guide at `docs/XENFORO_OAUTH.md` in the Troop Tracker web repo as well.

---

## 1. Create the XenForo OAuth2 client

In XenForo Admin CP:

1. Go to **Setup → OAuth2 clients**.
2. Click **Add OAuth2 client** (or edit your existing "Troop Tracker Mobile" client).
3. Set:
   - **Title**: `Troop Tracker Mobile`
   - **Client type**: **Public** (recommended for a mobile app)
   - **Authorization endpoint**: `https://your-forum.example.com/index.php?oauth2/authorize`
   - **Token endpoint**: `https://your-forum.example.com/index.php?api/oauth2/token`
   - **Token revocation endpoint**: `https://your-forum.example.com/index.php?api/oauth2/revoke`
4. Under **Redirect URIs**, add:
   - `https://redirectmeto.com/ttmobileapp://oauth-callback`

> The mobile app uses the `ttmobileapp://oauth-callback` custom scheme and goes through `redirectmeto.com` to get back into the app after the browser-based login.

5. Click **Save** and copy the **Client ID**.

You do **not** need to embed the client secret in the mobile app when using the PKCE flow; the app uses `code_verifier` / `code_challenge` instead.

---

## 2. Configure allowed scopes in XenForo

In the same OAuth client in XenForo, enable at least these scopes:

- `user:read` — read the logged-in user profile
- `thread:read` — read troop chat threads and posts
- `thread:write` — send chat messages / replies
- `attachment:read` — view attachments referenced in chat
- `attachment:write` — upload new attachments (for image messages)

You may enable additional scopes for future features, but the list above is the minimum needed for the current mobile app.

Click **Save** after updating scopes.

---

## 3. Configure the mobile app `.env`

In the root of this Flutter project there is a `.env` file loaded by `flutter_dotenv`. Configure these keys for XenForo:

```env
# Base XenForo URL (no trailing slash)
FORUM_URL=https://www.yourforum.com/boards/

# OAuth2 client configuration
OAUTH_CLIENT_ID=3658754186606517           # example: your XenForo OAuth client ID
OAUTH_AUTHORIZE_PATH=/index.php?oauth2/authorize
OAUTH_TOKEN_PATH=/index.php?api/oauth2/token
OAUTH_REDIRECT_URI=https://redirectmeto.com/ttmobileapp://oauth-callback
OAUTH_CALLBACK_SCHEME=ttmobileapp

# Requested OAuth scopes for the mobile app
OAUTH_SCOPES="user:read thread:read thread:write attachment:read attachment:write"
```

Notes:

- `FORUM_URL` must match your forum base URL used in the browser (no trailing slash).
- `OAUTH_CLIENT_ID` must match the **Client ID** shown in XenForo for the Troop Tracker Mobile client.
- The authorize and token paths only need to be changed if you have customized XenForo routing.
- `OAUTH_SCOPES` must be a space-separated list of scopes that are **also allowed** on the XenForo client.

The mobile app reads these values in `lib/services/auth_service.dart`.

---

## 4. How the mobile app uses OAuth

The flow implemented in `AuthService.performOAuthLogin()` is:

1. Generate a random `state` and PKCE `code_verifier` / `code_challenge` pair.
2. Open the system browser to the XenForo authorize URL built from:
   - `FORUM_URL`
   - `OAUTH_AUTHORIZE_PATH`
   - `OAUTH_CLIENT_ID`
   - `OAUTH_REDIRECT_URI`
   - `OAUTH_SCOPES`
3. User logs in on XenForo and approves the client.
4. XenForo redirects to `OAUTH_REDIRECT_URI`, which forwards to `ttmobileapp://oauth-callback` and back into the app.
5. The app exchanges the authorization `code` for an `access_token` using:
   - `FORUM_URL + OAUTH_TOKEN_PATH`
   - `OAUTH_CLIENT_ID`
   - `OAUTH_REDIRECT_URI`
   - `code_verifier`
6. The access token is then sent to the Troop Tracker web API (`login_with_forum` action), and the returned `apiKey` is stored locally.
7. For all subsequent forum API calls (threads, posts, attachments, block/report endpoints), the app sends:

   ```http
   Authorization: Bearer <access_token>
   ```

   using `ApiClient.forumAuthHeaders`.

---

## 5. Validating the setup

After configuring XenForo and the mobile app:

1. **Clean login**
   - Delete the app’s local data or log out from within the app.
   - Launch the app and choose XenForo login.
   - Confirm you see the XenForo login/consent page for the Troop Tracker Mobile client.

2. **Confirm scopes**
   - After login, open a troop with chat.
   - If you see an error like `Needs access to thread:read`, the access token does not have the required scope — double-check the allowed scopes on the XenForo client and the `OAUTH_SCOPES` in `.env`.

3. **Chat operations**
   - Load a troop chat and confirm messages appear.
   - Send a text message; it should post to the corresponding XenForo thread.
   - Send an image message; it should upload an attachment and post an `[IMG]` BBCode.

If login works but chat calls fail with permission errors, the cause is almost always missing or mismatched OAuth scopes.

---

## 6. Related XenForo add-ons

For the best experience, especially for chat and profile features, install these XenForo add-ons:

- `TroopTrackerViewAttachment` — exposes a safe API for serving attachments.
- `TroopTrackerIgnoreUsers` — adds block/unblock and report endpoints used by the mobile chat UI.
- `Troop Tracker - Upgrade Stats API` — provides upgrade/payment stats (used mainly by the web app).
- `TroopTrackerUserGroups` — exposes XenForo user groups and banner text (used by the web app and profiles).

See the Troop Tracker web app docs (`docs/XENFORO_OAUTH.md` in that repo) for full details on what each add-on does.
