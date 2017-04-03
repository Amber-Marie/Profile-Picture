key ownerKey; // Global key variable to store the prim owners key
string ownerName; // Global string variable to store the prim owners name
string onlineStatus; // Global string variable to store the owners online or offline status
string statusTime; // Global string variable to store the last updated time
list returns; // Global list variable
vector vColour; // Global vector variable to store the colour of the displayed text
float gap = 60.0; // Global float variable to store the refresh time
string lastSeen; // Global string variable to store when the prim owner was last seen
key request_id; // Global key variable to store the UUI(D of the picture

default
{
    // reset script when the object is rezzed
    on_rez(integer start_param)
    {
        llResetScript();
        ownerKey = llGetOwner();
    }

    changed(integer change)
    {
        // reset script when the owner or the inventory changed
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY))
        {
            llResetScript();
        }
    }

    state_entry()
    {
        ownerKey = llGetOwner(); // Get the prim owners name and save it to the variable
        ownerName = llKey2Name(ownerKey); // Using the key obtained before, look up the owners name
        string texture = llGetInventoryName(INVENTORY_TEXTURE, 0); // Set a local variable called texture, and get the name of a default texture
        // set it on all sides of the prim containing the script
        llSetTexture(texture, ALL_SIDES);
        llSetText ("Waiting for update...",<1,1,0>,1); // Set the hover text above the prim, set the colour to yellow and make it visible
        llSetTimerEvent(gap); // Run a timer event for the amount sent in the global variable
    }

    timer()
    {        
        onlineStatus = llRequestAgentData(ownerKey, DATA_ONLINE); // Make a call to the profile server to see if the person is online or not
        request_id = llHTTPRequest("http://profiles.osgrid.org/getprofilepicuuid/?uuid=" + (string)ownerKey + "&type=uuid", [HTTP_METHOD, "GET"], ""); // Here is where we get the actual pic from.
    }
   
    touch_start(integer num)
    {
        // If the prim is touched, blank the texture and request a new version
        string texture = llGetInventoryName(INVENTORY_TEXTURE, 0);
        llSetTexture(texture, ALL_SIDES);
        llSetText("Loading...",<1,0,0>,1); // Set the float text to red
        request_id = llHTTPRequest("http://profiles.osgrid.org/getprofilepicuuid/?uuid=" + (string)ownerKey + "&type=uuid", [HTTP_METHOD, "GET"], ""); // Here is where we get the actual pic from.
    }
    
    http_response(key response_id, integer status, list metadata, string body)
    {
        // Get the response to the web request and set the texture of the prim to the UID reported back
        if(response_id == request_id)
        {
            llSetTexture(body, ALL_SIDES);
        }
    }

    dataserver(key queryid, string data)
    {
        string timeLastseen;
        if((integer)data == TRUE)
        {
            string correctedHour;
            string correctedMinute;
            string indicator;
            data = "Online";
            vColour=<0.0, 1.0, 0.0>;
            //float now = llGetWallclock();
            float now = llGetGMTclock();
            integer tmp = (integer)now / 60;
            integer hour = tmp / 60;
            integer minute = tmp - (hour * 60);
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
            data = "Offline";
            vColour=<1.0, 0.0, 0.0>;
            timeLastseen = "\n Last seen at " + lastSeen + " GMT";
        }
        float timeNow = llGetWallclock();
        integer nowTmp = (integer)timeNow / 60;
        integer nowHour = nowTmp / 60;
        integer nowMinute = nowTmp - (nowHour * 60);
        llSetText(ownerName + " is " + data + ".\n" + timeLastseen,vColour,1);
    }
}
