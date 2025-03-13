# 501st Legion Troop Tracker Mobile App
A troop tracker mobile app for the 501st Legion developed for the Florida Garrison. Xenforo (https://xenforo.com/) and Troop Tracker (https://github.com/MattDrennan/501-troop-tracker) is required.

## Use
You are free to download, modify, and use freely for non-commerical purposes.

## How to setup

<ol>
	<li>Upload all the files in "xenforo_api_files/" to the root of your Xenforo directory.</li>
	<li>All SQL data is included with the install of Troop Tracker.</li>
	<li>Install this Xenforo add-on: https://github.com/MattDrennan/TroopTrackerViewAttachment</li>
	<li>Create a .env file in the root directory and put this inside:</li>
	
	FORUM_URL=https://www.fl501st.com/boards/
	API_USER=1
	API_KEY=XENFORO_API_KEY

  <li>Create a key.properties in 'android/':</li>
  
	storeFile=release-key.jks
	storePassword=###
	keyAlias=#####
	keyPassword=###
  
  <li>Set up a webhook in Xenforo:</li>
</ol>

	Title: Post Insert
	Description: For push notifications
	Target URL: https://www.fl501st.com/troop-tracker/script/php/webhook/post_insert.php
	Events: Send only specific events->post.insert
	Content type: application/json
	Enable SSL verification (yes)
	Webhook is active (yes)

## Create icons

```
dart run flutter_launcher_icons
```

## Please contact me with any questions, comments, or concerns
drennanmattheww@gmail.com

## Android App
https://play.google.com/store/apps/details?id=com.drennansoftware.troop_tracker

## iOS App
https://apps.apple.com/us/app/troop-tracker/id6739888656

## Visit the live website here:
https://www.fl501st.com/troop-tracker/
