/*
 * Description
 *
 * Status flags:
 *   1 enabled
 *   2 present
 *   4 active
 *   8 user possession
 *
 * Checkboxes:
 *   wearer:
 *     ☒ missing
 *     ☐ present
 *     ☑ active
 *   user:
 *     ☒ failed/not available
 *     ☐ available
 *     ☑ possessing
 */


// MESSAGE MAP
// integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
// integer CMD_TRUSTED = 501;
// integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
// integer CMD_EVERYONE = 504;
// integer CMD_SAFEWORD = 510;
// integer CMD_SAFEWORD = 510;
integer CMD_NOACCESS = 599; // Required for when public is disabled

// integer POPUP_HELP = 1001;
// integer NOTIFY = 1002;
// integer NOTIFY_OWNERS = 1003;
// integer SAY = 1004;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;
// integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
// integer LM_SETTING_DELETE = 2003;
// integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
// integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
// integer RLV_CLEAR = 6002;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
// integer DIALOG_TIMEOUT = -9002;

// menu buttons
string UPMENU = "BACK";
// string HELP = "Quick Help";
// string DEFAULT = "Default" ;

string g_sParentMenu = "Apps";
string g_sApp = "Coco";
string g_s = "|";
integer g_iMenuStride=3;
list g_lButtons = ["Purse"];
list g_lCheckboxes = ["☒", "☐", "☑"];
key g_kWearer;
list g_lMenuIDs;
integer g_InitialSettingsLoaded = FALSE;
list g_lCommands = [];

// inventory
list g_lItemNames =  ["phone",  "keys",     "glasses", "cards"  ];
list g_lItemStatus = [ 3,        3,          7,         2       ];
list g_lItemOwners = [NULL_KEY,  NULL_KEY,  NULL_KEY,  NULL_KEY ];

////////// Helpers //////////

string setS(integer condition, string sTrue, string sFalse) {
    if (condition)  return sTrue;
    else            return sFalse;
}

integer setI(integer condition, integer iTrue, integer iFalse) {
    if (condition)  return iTrue;
    else            return iFalse;
}

string makeItemButton(string label, integer status, key user) {
    integer i;

    if (user == g_kWearer)  i = setI(status &2, setI(status &4, 2, 1), 0);
    else                    i = setI(status &2, 1, setI(status &8, 2, 1));

    return llList2String(g_lCheckboxes, i) + " " + label;
}

list makePurseButtons(key user) {
    list items = [];
    string name;
    integer status;
    key storedOwner;
    integer i;

    for (i = 0; i < llGetListLength(g_lItemNames); i++)
    {
        name = llList2String(g_lItemNames, i);
        status = llList2Integer(g_lItemStatus, i);
        storedOwner = llList2Key(g_lItemOwners, i);

        if (status &1) {
            if (user == g_kWearer) {
                items += makeItemButton(name, status, user);
            }
            else {
                if (status &2)                  items += makeItemButton(name, status, user);
                else if (user == storedOwner)   items += makeItemButton(name, status|8, user);
            }
        }
    }

    return items;
}

string getButtonLabel(string text) {
    list splitted = llParseString2List(text, [" "], []);

    return llToLower(llList2String(splitted, 1));
}

////////// Update methods //////////

UpdateSettings() {
    string nameSettings = g_sApp + "_names=";
    string statusSettings = g_sApp + "_status=";
    string ownerSettings = g_sApp + "_owners=";

    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, nameSettings + llDumpList2String(g_lItemNames, g_s), "");
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, statusSettings + llDumpList2String(g_lItemStatus, g_s), "");
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, ownerSettings + llDumpList2String(g_lItemOwners, g_s), "");
}

UpdateRestrictions() {
    string phoneRestricted      = "recvim=n,sendim=n,startim=n";
    string phoneAllowed         = "recvim=y,sendim=y,startim=y";
    string keysRestricted       = "tplm=n,tplocal=n,tploc=n,tplure_sec=n,sittp:5=n,standtp=n";
    string keysAllowed          = "tplm=y,tplocal=y,tploc=y,tplure_sec=y,sittp:5=y,standtp=y";
    string glassesRestricted    = "showhovertext=n,shownames=n,showloc=n,showminimap=n,showworldmap=n";
    string glassesAllowed       = "showhovertext=y,shownames=y,showloc=y,showminimap=y,showworldmap=y";
    string cardsRestricted      = "";
    string cardsAllowed         = "";
    integer i;
    string item;
    integer status;
    g_lCommands = [];

    for (i = 0; i < llGetListLength(g_lItemNames); i++)
    {
        item = llList2String(g_lItemNames, i);
        status = llList2Integer(g_lItemStatus, i);

        if (status &1) {
            if (item == "phone")        g_lCommands += setS(status &2, phoneAllowed, phoneRestricted);
            else if (item == "keys")    g_lCommands += setS(status &2, keysAllowed, keysRestricted);
            else if (item == "glasses") g_lCommands += setS(status &2, glassesAllowed, glassesRestricted);
            else if (item == "cards")   g_lCommands += setS(status &2, cardsAllowed, cardsRestricted);
            else llOwnerSay("Item " + item + " not found.");
        }
    }

    llMessageLinked(LINK_THIS, RLV_CMD, llDumpList2String(g_lCommands, ","), g_sApp);
}

UpdateItemStatus(string item, integer change, key owner) {
        integer index = llListFindList(g_lItemNames, [item]);
        integer status = llList2Integer(g_lItemStatus, index);

        g_lItemStatus = llListReplaceList(g_lItemStatus, [status^change], index, index);
        g_lItemOwners = llListReplaceList(g_lItemOwners, [owner], index, index);

        UpdateSettings();
        UpdateRestrictions();
}

UpdateMenuIDs(key userId, key menuId, string name) {
    list record = [userId, menuId, name];
    integer index = llListFindList(g_lMenuIDs, [userId]);

    if (~index) g_lMenuIDs = llListReplaceList(g_lMenuIDs, record, index, index + g_iMenuStride - 1);
    else        g_lMenuIDs += record;
}

////////// Dialog methods //////////

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    // llOwnerSay("Dialog: " + (string)kID + " | " + sPrompt +" | " + (string)iAuth +" | " + sName);
    key menuId = llGenerateKey();
    string buttons = llDumpList2String(lChoices, "`") + g_s + llDumpList2String(lUtilityButtons, "`");

    llMessageLinked(LINK_THIS, DIALOG, (string)kID + g_s + sPrompt + g_s + (string)iPage + g_s + buttons + g_s + (string)iAuth, menuId);

    UpdateMenuIDs(kID, menuId, sName);
}

DialogMain(key kID, integer iAuth) {
    list buttons = g_lButtons;
    string prompt = g_sApp + " main menu";

    if (iAuth == CMD_WEARER) buttons += ["Settings"];

    Dialog(kID, prompt, buttons, ["Help!", UPMENU], 0, iAuth, g_sApp);
}

DialogSettings(key kID, integer iAuth) {
    list buttons;
    string label;
    integer status;
    string icon;
    integer i;
    string prompt = "Enable/Disable items";

    for (i = 0; i < llGetListLength(g_lItemNames); i++)
    {
        label = llList2String(g_lItemNames, i);
        status = llList2Integer(g_lItemStatus, i);
        icon = llList2String(g_lCheckboxes, setI(status &1, 2, 1));
        buttons += icon + " " + label;
    }

    Dialog(kID, prompt, buttons, [UPMENU], 0, iAuth, "settings-change");
}

DialogPurse(key kID, integer iAuth) {
    string prompt;
    string legend;
    list buttons = makePurseButtons(kID);

    if (iAuth == CMD_WEARER) {
        prompt = "This is your purse's content";
        legend = "\n☒ Missing\n☐ Kept\n☑ Using";
    }
    else {
        prompt = "You're poking about " + llGetDisplayName(g_kWearer) + "'s purse";
        legend = "\n☒ Not available\n☐ Available\n☑ In possession";
    }

    Dialog(kID, prompt + legend, buttons, ["Help!", UPMENU], 0, iAuth, "purse-inspect");
}

DialogPurseItem(key kID, integer iAuth, string message) {
    list buttons;
    string item = getButtonLabel(message);
    integer index = llListFindList(g_lItemNames, [item]);
    integer status = llList2Integer(g_lItemStatus, index);
    string prompt = "What do you want to do with the " + item + "?";

    if (iAuth == CMD_WEARER) {
        if (status &2) {
            buttons += "Give away";

            if (status &4) buttons += "Keep in";
            else buttons += "Use";
        }
        else buttons += ["Search", "Recover"];

    }
    else {
        if (status &2) {
            if (status &4) buttons += "Rob";
            else buttons += "Pick";
        }
        else buttons += "Give back";
    }

    Dialog(kID, prompt, buttons, ["Help!", UPMENU], 0, iAuth, "item" + g_s + item);
}

////////// Commands //////////

UserCommand(integer iAuth, string sStr, key kID, integer remenu) {
    llOwnerSay("UserCommand: " + (string)iAuth + ", " + sStr + ", " + (string)kID);
    if (iAuth > CMD_WEARER || iAuth < CMD_OWNER) return; // sanity check

    string sCmd = llToLower(sStr);
    string sApp = llToLower(g_sApp);
    list breadcrumbs = llParseString2List(llToLower(sStr), [g_s], []);
    string menu = llList2String(breadcrumbs, 0);
    string item = llList2String(breadcrumbs, 1);
    string action = llList2String(breadcrumbs, 2);

    if (sCmd == "menu " + sApp || sCmd == sApp) {
        DialogMain(kID, iAuth);
    }
    else if (sCmd == sApp + " mem") llOwnerSay("memory used: " + (string)llGetUsedMemory());

    else if (sCmd == sApp + " purse") DialogPurse(kID, iAuth);

    else if (sCmd == sApp + " settings") DialogSettings(kID, iAuth);

    else if (menu == "settings-change") {
        UpdateItemStatus(getButtonLabel(item), 1, kID);
    }
    else {
        if (action == "pick") {
            // llOwnerSay("Your " + item + " has been stolen!");
            llRegionSayTo(kID, 0, "You successfully slipped your hand and took the " + item + "!");
            UpdateItemStatus(item, 2, kID);
        }
        else if (action == "rob") {
            llOwnerSay("Your " + item + " has been stolen!");
            llRegionSayTo(kID, 0, "You succeded snatching the " + item + "!");
            UpdateItemStatus(item, 2, kID);
        }
        else if (action == "give away") {
            llOwnerSay("You gave your " + item + " away.");
            UpdateItemStatus(item, 2, kID);
        }
        else if (action == "recover") {
            llOwnerSay("You got your " + item + " back.");
            UpdateItemStatus(item, 2, NULL_KEY);
        }
        else if (action == "give back") {
            llOwnerSay("You got your " + item + " back.");
            llRegionSayTo(kID, 0, "You gave the " + item + " back.");
            UpdateItemStatus(item, 2, NULL_KEY);
        }
        else if (action == "use") {
            llOwnerSay("You are now using the " + item + ".");
            UpdateItemStatus(item, 4, NULL_KEY);
        }
        else if (action == "keep in") {
            llOwnerSay("You put your " + item + " back in your purse.");
            UpdateItemStatus(item, 4, NULL_KEY);
        }
    }

    if (remenu) {
        if (menu == "settings-change") DialogSettings(kID, iAuth);
        else if (llSubStringIndex(menu, "item") == 0) DialogPurse(kID, iAuth);
        else DialogMain(kID, iAuth);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////

default {
    state_entry()
    {
        g_kWearer = llGetOwner();
    }

    link_message( integer iSender, integer iNum, string sStr, key kID )
    {
        if(iNum >= CMD_OWNER && iNum <= CMD_NOACCESS) UserCommand(iNum, sStr, kID, FALSE);

        else if (iNum == LM_SETTING_RESPONSE) {
            // llOwnerSay("link_message :" + (string)iSender + ", " + (string)iNum + ", " + sStr + ", " + (string)kID);
            if (!g_InitialSettingsLoaded) {
                g_InitialSettingsLoaded = TRUE;
                list parts = llParseString2List(sStr, ["_", "="], []);

                if (llList2String(parts, 0) == llToLower(g_sApp)) {
                    if (llList2String(parts, 1) == "names") {
                        g_lItemNames = llParseString2List(llList2String(parts, 3), [g_s], []);
                    }
                    else if (llList2String(parts, 1) == "status") {
                        g_lItemStatus = llParseString2List(llList2String(parts, 3), [g_s], []);
                    }
                    else if (llList2String(parts, 1) == "owners") {
                        g_lItemOwners = llParseString2List(llList2String(parts, 3), [g_s], []);
                    }
                }
            }
        }

        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + g_s + g_sApp, "");
        }

        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);

            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, [g_s], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //remove stride from g_lMenuIDs
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenu == g_sApp) {
                    if (sMsg == UPMENU) llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);

                    else if (sMsg == "Purse") DialogPurse(kAv, iAuth);

                    else if (sMsg == "Settings") DialogSettings(kAv, iAuth);
                }

                else if (sMenu == "settings-change") {
                    if (sMsg == UPMENU) llMessageLinked(LINK_THIS, iAuth, "menu " + g_sApp, kAv);

                    else UserCommand(iAuth, sMenu + g_s + sMsg, kAv, TRUE);
                }

                else if (sMenu == "purse-inspect") {
                    if (sMsg == UPMENU) llMessageLinked(LINK_THIS, iAuth, "menu " + g_sApp, kAv);

                    else {
                        DialogPurseItem(kAv, iAuth, sMsg);
                    }
                }

                else if (llSubStringIndex(sMenu, "item") == 0) UserCommand(iAuth , sMenu + g_s + sMsg, kAv, TRUE);

                else {
                    llOwnerSay("not found: " + sMenu + ", " + sMsg);
                }
            }
            else llOwnerSay("Menu entry for " + (string)kID + "(" + llGetUsername(kID) + ") not found.");
        }

        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }
}

