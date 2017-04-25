// Online status and Profile Picture V3
// Updated to use my.osgrid.org, code provided by Lotek Ixtar @ OSgrid (22 March 2017)
// ©16 March 2017 by Amber-Marie Tracey @ OSgrid
// Latest version at https://github.com/Amber-Marie/Profile-Picture
//
key ownerKey; // Global key variable to store the prim owners key
string ownerName; // Global string variable to store the prim owners name
string onlineStatus; // Global string variable to store the owners online or offline status
string statusTime; // Global string variable to store the last updated time
list returns; // Global list variable
vector vColour; // Global vector variable to store the colour of the displayed text
float gap = 300.0; // Global float variable to store the refresh time
string lastSeen; // Global string variable to store when the prim owner was last seen
key request_id; // Global key variable to store the UUI(D of the picture

FetchProfilePic(string sName)
{
    // Call to the new profile section of the website
    integer space = llSubStringIndex(sName, " ");
    string sFirstName = llGetSubString(sName, 0, space-1);
    string sLastName = llGetSubString(sName, space+1, -1);
       
    string RESIDENT_URL = "http://my.osgrid.org/?name=" + sFirstName + "." + sLastName;
    llHTTPRequest(RESIDENT_URL, [HTTP_METHOD,"GET"], "");
}

default
{
    // reset script when the object is rezzed
    on_rez(integer start_param)
    {
        // This has been addded to do away with the need to have a texture in the prim
        llSetPrimitiveParams([ PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <0.0, 0.0, 0.0>, <0.0, 0.0, 0.0>, 0.0 ]); // Make all sides transparent
        llResetScript();
        ownerKey = llGetOwner();
    }

    changed(integer change)
    {
        // reset script when the owner or the inventory changed
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY))
        {
            // This has been addded to do away with the need to have a texture in the prim
            llSetPrimitiveParams([ PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <0.0, 0.0, 0.0>, <0.0, 0.0, 0.0>, 0.0 ]); // Make all sides transparent
            llResetScript();
        }
    }

    state_entry()
    {
        ownerKey = llGetOwner(); // Get the prim owners name and save it to the variable
        ownerName = llKey2Name(ownerKey); // Using the key obtained before, look up the owners name
        llSetPrimitiveParams([ PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <0.0, 0.0, 0.0>, <0.0, 0.0, 0.0>, 0.0 ]); // Make all sides transparent
        llSetText ("Waiting for update...",<1,1,0>,1); // Set the hover text above the prim, set the colour to yellow and make it visible
        FetchProfilePic(ownerName);
        llSetTimerEvent(gap); // Run a timer event for the amount sent in the global variable
    }

    timer()
    {        
        ownerKey = llGetOwner(); // Get the prim owners name and save it to the variable
        ownerName = llKey2Name(ownerKey); // Using the key obtained before, look up the owners name
        onlineStatus = llRequestAgentData(ownerKey, DATA_ONLINE); // Make a call to the profile server to see if the person is online or not
        request_id = llHTTPRequest("http://profiles.osgrid.org/getprofilepicuuid/?uuid=" + (string)ownerKey + "&type=uuid", [HTTP_METHOD, "GET"], ""); // Here is where we get the actual pic from.
        FetchProfilePic(ownerName);
    }
   
    touch_start(integer num)
    {
        ownerKey = llGetOwner(); // Get the prim owners name and save it to the variable
        ownerName = llKey2Name(ownerKey); // Using the key obtained before, look up the owners name
        // If the prim is touched, blank the texture and request a new version
        llSetPrimitiveParams([ PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <0.0, 0.0, 0.0>, <0.0, 0.0, 0.0>, 0.0 ]); // Make all sides transparent
        llSetText("Loading...",<1,0,0>,1); // Set the float text to red
        FetchProfilePic(ownerName);
        }
    
    http_response(key request_id,integer status, list metadata, string body)
    {
        // Parse profile pic UUID from OsGrid webprofile
        string sProfilePhotoUUID = (string)NULL_KEY;
        integer start = llSubStringIndex(body,"<img src=\"/img/");
        if (start != -1) {
            start += llStringLength("<img src=\"/img/");
            sProfilePhotoUUID = llGetSubString(body, start, start+35);
        }
       
        // No photo found for resident, select a 'no photo' texture
        if (sProfilePhotoUUID==(string)NULL_KEY)
            sProfilePhotoUUID = "9faab849-5428-48d6-b973-07dfcb70628b";

        // Finally display it if the UUID is valid
        if (osIsUUID(sProfilePhotoUUID))
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE, ALL_SIDES, sProfilePhotoUUID, <1,1,0>, <0,0,0>, 0]);
    }

    dataserver(key queryid, string data)
    {
        string timeLastseen;
        if((integer)data == TRUE) // If the prim owner is online, 
        {
            string correctedHour; // Local string variable to store hours
            string correctedMinute; // Local string variable to store minutes
            string indicator; // Local string variable to store 
            data = "Online"; // Set the status to online
            vColour=<0.0, 1.0, 0.0>; // Set the float text to green
            float now = llGetGMTclock(); // Set the local float variable to the number of seconds since midnight in GMT
            integer tmp = (integer)now / 60; // Set the local variable to the current seconds divided by 60 to give us minutes since midnight
            integer hour = tmp / 60; // Set the local variable to the number of minutes divided by 60 to give us the hours since midnight
            integer minute = tmp - (hour * 60); // Set the local variable to the number of hours multiplied by 60 minus the number of seconds to give us the minutes
            // Correct the display to handle single numbers and add leading zeros where needed
            if ( hour < 10 )
            {
                correctedHour = "0" + (string)hour;
            } 
            if ( hour >= 10 )
            { 
                correctedHour = (string)hour;
            }
            if ( minute < 10 )
            {
                correctedMinute = "0" + (string)minute;
            }
            if ( minute >= 10 )
            {
                correctedMinute = (string)minute;
            }
            // Add AM or PM depending upon the time given
            if ( hour < 12 )
            {
                indicator = "am";
            }
            if ( hour >= 12 )
            {
                indicator = "pm";
            }
            // lastSeen = correctedHour + ":" + correctedMinute + indicator; // Uses leading 0 on the hour
            lastSeen = (string)hour + ":" + correctedMinute + indicator; // No leading 0 on the hour
            timeLastseen = "";
        }
        else
        {
            data = "Offline"; // Prim owner is offline
            vColour=<1.0, 0.0, 0.0>; // Set the fload text to red
            timeLastseen = "\n Last seen at " + lastSeen + " GMT";
        }
        // Report the owners status and the time that they were last seen
        float timeNow = llGetGMTclock();
        integer nowTmp = (integer)timeNow / 60;
        integer nowHour = nowTmp / 60;
        integer nowMinute = nowTmp - (nowHour * 60);
        llSetText(ownerName + " is " + data + ".\n" + timeLastseen,vColour,1);
    }
}
