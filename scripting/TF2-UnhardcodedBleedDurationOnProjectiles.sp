#include <sourcemod>

#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#include <sourcescramble>

#include <tf2attributes>

#pragma newdecls required
#pragma semicolon 1

float g_flBleedDuration;

#define DEFAULT_BLEED_DURATION 5.0

public Plugin myinfo =
{
	name        =  "[TF2] Unhardcoded Bleed Duration On Projectiles",
	author      =  "Zabaniya001",
	description =  "[TF2] The Flying Guillotine and Wrap Assassin have a hardcoded bleed duration. This plugin makes it so it, by default it's 5.0 to not mess with default behaviour, but it checks for the bleeding duration attribute.",
	version     =  "1.0.0",
	url         =  "https://github.com/Zabaniya001/TF2-UnhardcodedBleedDurationOnProjectiles"
};

public void OnPluginStart()
{
	GameData gameconf = new GameData("tf2.unhardcodedbleeddurationonprojectiles");

	/// Detours

	DynamicDetour detour_cleaver_on_hit = DynamicDetour.FromConf(gameconf, "CTFProjectile_Cleaver::OnHit()");

	if(!detour_cleaver_on_hit)
		SetFailState("Failed to setup detour for CTFProjectile_Cleaver::OnHit()");
	
	detour_cleaver_on_hit.Enable(Hook_Pre, DHooks_OnHitMakeBleedProjectile);


	DynamicDetour detour_wrapassassin_on_hit = DynamicDetour.FromConf(gameconf, "CTFBall_Ornament::ApplyBallImpactEffectOnVictim()");

	if(!detour_wrapassassin_on_hit)
		SetFailState("Failed to setup detour for CTFBall_Ornament::ApplyBallImpactEffectOnVictim()");
	
	detour_wrapassassin_on_hit.Enable(Hook_Pre, DHooks_OnHitMakeBleedProjectile);

	/// Memory Patches

	MemoryPatch mempatch_cleaverbleedingduration = MemoryPatch.CreateFromConf(gameconf, "CTFProjectile_Cleaver::OnHit()::MakeBleedDuration");

	if(!mempatch_cleaverbleedingduration.Validate())
		SetFailState("Failed to validate CTFProjectile_Cleaver::OnHit()::MakeBleedDuration.");
	
	mempatch_cleaverbleedingduration.Enable();

	StoreToAddress(mempatch_cleaverbleedingduration.Address + view_as<Address>(2), GetAddressOfCell(g_flBleedDuration), NumberType_Int32);


	MemoryPatch mempatch_wrapassassinbleedingduration = MemoryPatch.CreateFromConf(gameconf, "CTFBall_Ornament::ApplyBallImpactEffectOnVictim()::MakeBleedDuration");

	if(!mempatch_wrapassassinbleedingduration.Validate())
		SetFailState("Failed to validate CTFBall_Ornament::ApplyBallImpactEffectOnVictim()::MakeBleedDuration.");
	
	mempatch_wrapassassinbleedingduration.Enable();

	StoreToAddress(mempatch_wrapassassinbleedingduration.Address + view_as<Address>(2), GetAddressOfCell(g_flBleedDuration), NumberType_Int32);

	return;
}

MRESReturn DHooks_OnHitMakeBleedProjectile(int projectile, DHookReturn hReturn)
{
	g_flBleedDuration = DEFAULT_BLEED_DURATION;

	int weapon = GetEntPropEnt(projectile, Prop_Send, "m_hLauncher");

	if(weapon < 0 || weapon > 2048 || !IsValidEntity(weapon))
		return MRES_Ignored;

	g_flBleedDuration = TF2Attrib_HookValueFloat(5.0, "bleeding_duration", weapon);

	return MRES_Ignored;
}