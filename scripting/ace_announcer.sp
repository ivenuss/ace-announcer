#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors_csgo>

#pragma semicolon 1
#pragma newdecls required

int g_iKills[MAXPLAYERS + 1];
int g_iCountCT;
int g_iCountT;

ConVar g_cvAnnouncerMinplayers;
ConVar g_cvAnnouncerCountSuicide;
ConVar g_cvAnnouncerSoundEnabled;

public Plugin myinfo = 
{
	name = "[CS:GO] Ace announcer", 
	author = "venus", 
	version = "1.0", 
	url = "id/venuss"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	g_cvAnnouncerMinplayers = CreateConVar("sm_aceannouncer_minimum_players", "5", "Minimum kills to count as an ace to user.", 0, true, 1.0, true, 64.0);
	g_cvAnnouncerCountSuicide = CreateConVar("sm_aceannouncer_count_suicide", "0", "Enable/Disable counting suicide as kill (1/0)", 0, true, 0.0, true, 1.0);
	g_cvAnnouncerSoundEnabled = CreateConVar("sm_aceannouncer_sound_enabled", "1", "Enable/Disable sound when player does ace (1/0)", 0, true, 0.0, true, 1.0);

	AutoExecConfig(true, "aceannouncer.cfg");
}

public void OnMapStart()
{
	PrecacheSound("ui/item_drop3_rare.wav");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iCountCT = 0;
	g_iCountT = 0;
	
	for (int i; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
		{
			continue;
		}
		
		if (!IsPlayerAlive(i))
		{
			continue;
		}
		
		if (GetClientTeam(i) == CS_TEAM_CT)
		{
			g_iCountCT++;
		}
		
		else if (GetClientTeam(i) == CS_TEAM_T)
		{
			g_iCountT++;
		}
		
		g_iKills[i] = 0;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(attacker) && IsValidClient(client) && IsPlayerAlive(attacker))
	{
		g_iKills[attacker]++;
	}
	
	else
	{
		g_iKills[attacker] = 0;
	}
	
	if (GetConVarBool(g_cvAnnouncerCountSuicide))
	{
		if (attacker == client)
		{
			if (GetClientTeam(attacker) == CS_TEAM_CT)
			{
				g_iCountCT--;
			}
			else if (GetClientTeam(attacker) == CS_TEAM_T)
			{
				g_iCountT--;
			}
		}
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	char szKills[16];
	
	for (int i; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
		{
			continue;
		}
		
		if (!IsPlayerAlive(i))
		{
			continue;
		}
		
		if (g_iKills[i] > 0 && g_iKills[i] >= GetConVarInt(g_cvAnnouncerMinplayers))
		{
			Format(szKills, sizeof(szKills), "kill%s", (g_iKills[i] > 1) ? "s" : "");
			
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				if (g_iKills[i] == g_iCountT)
				{
					if (GetConVarBool(g_cvAnnouncerSoundEnabled))
					{
						EmitSoundToAll("ui/item_drop3_rare.wav");
					}
					
					CPrintToChatAll("[{yellow}ACE{default}] Player {orange}%N{default} did {blue}ACE{default} with {red}%d{default} %s!", i, g_iKills[i], szKills);
				}
			}
			
			else if (GetClientTeam(i) == CS_TEAM_T)
			{
				if (g_iKills[i] == g_iCountCT)
				{
					if (GetConVarBool(g_cvAnnouncerSoundEnabled))
					{
						EmitSoundToAll("ui/item_drop3_rare.wav");
					}
					
					CPrintToChatAll("[{yellow}ACE{default}] Player {orange}%N{default} did {blue}ACE{default} with {red}%d{default} %s!", i, g_iKills[i], szKills);
				}
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	return (0 < client && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) == false);
} 