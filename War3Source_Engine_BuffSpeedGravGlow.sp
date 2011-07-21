 	

////BUFF SYSTEM




#pragma semicolon 1

#include <sourcemod>

#include "W3SIncs/War3Source_Interface"


new m_OffsetSpeed=-1;
new m_OffsetClrRender=-1;

new reapplyspeed[MAXPLAYERSCUSTOM];
new bool:invisWeaponAttachments[MAXPLAYERSCUSTOM];
new bool:bDeniedInvis[MAXPLAYERSCUSTOM];

public Plugin:myinfo= 
{
	name="War3Source Buff Speed",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public OnPluginStart()
{
	CreateTimer(0.1,DeciSecondTimer,_,TIMER_REPEAT);
	
}

public bool:InitNativesForwards()
{

	CreateNative("W3ReapplySpeed",NW3ReapplySpeed);//for races
	if(GameTF())
	{
		m_OffsetSpeed=FindSendPropOffs("CTFPlayer","m_flMaxspeed");
	}
	else{
		m_OffsetSpeed=FindSendPropOffs("CBasePlayer","m_flLaggedMovementValue");
	}
	if(m_OffsetSpeed==-1)
	{
		PrintToServer("[War3Source] Error finding speed offset.");
	}
	
	m_OffsetClrRender=FindSendPropOffs("CBaseAnimating","m_clrRender");
	if(m_OffsetClrRender==-1)
	{
		PrintToServer("[War3Source] Error finding render color offset.");
	}
	
	CreateNative("W3IsBuffInvised",NW3IsBuffInvised);
	
	return true;
}


public NW3ReapplySpeed(Handle:plugin,numParams)
{	
	new client=GetNativeCell(1);
	reapplyspeed[client]++;
}
public NW3IsBuffInvised(Handle:plugin,numParams)
{	
	new client=GetNativeCell(1);
	return GetEntityAlpha(client)<50;
}


new Float:speedBefore[MAXPLAYERSCUSTOM];
new Float:speedWeSet[MAXPLAYERSCUSTOM];

public Action:DeciSecondTimer(Handle:timer)
{

		// Boy, this is going to be fun.
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true))
			{
				
		
				//PrintToChatAll("sdf %d",client);
				new Float:gravity=1.0; //default
				if(!W3GetBuffHasTrue(client,bLowGravityDenyAll)&&!W3GetBuffHasTrue(client,bBuffDenyAll)) //can we change gravity?
				{
					//if(!W3GetBuffHasTrue(client,bLowGravityDenySkill)){
					new Float:gravity1=W3GetBuffMinFloat(client,fLowGravitySkill);
					//}
					//if(!W3GetBuffHasTrue(client,bLowGravityDenyItem)){
					new Float:gravity2=W3GetBuffMinFloat(client,fLowGravityItem);
					
					gravity=gravity1<gravity2?gravity1:gravity2;
					//}
					//gravity=; //replace
					//PrintToChat(client,"mingrav=%f",gravity);
				}
				///now lets set the grav
				if(GetEntityGravity(client)!=gravity){ ///gravity offset is somewhoe different for each person? this offset is got on PutInServer
					SetEntityGravity(client,gravity);
				}
				
				
				
				
				///GLOW
				new r=255,g=255,b=255,alpha=255;
			//	new bool:skipinvis=false;
				
				new bestindex=-1;
				new highestvalue=0;
				new Float:settime=0.0;
				
				new limit=W3GetItemsLoaded()+War3_GetRacesLoaded()+W3GetItems2Loaded();
				for(new i=0;i<=limit;i++){
					if(W3GetBuff(client,iGlowPriority,i)>highestvalue){
						highestvalue=W3GetBuff(client,iGlowPriority,i);
						bestindex=i;
						settime=Float:W3GetBuff(client,fGlowSetTime,i);
					}
					else if(W3GetBuff(client,iGlowPriority,i)==highestvalue&&highestvalue>0){ //equal priority
						if(W3GetBuff(client,fGlowSetTime,i)>settime){ //only if this one set it sooner
							highestvalue=W3GetBuff(client,iGlowPriority,i);
							bestindex=i;
							settime=Float:W3GetBuff(client,fGlowSetTime,i);
						}
					}
				}
				if(bestindex>-1){
					r=W3GetBuff(client,iGlowRed,bestindex);
					g=W3GetBuff(client,iGlowGreen,bestindex);
					b=W3GetBuff(client,iGlowBlue,bestindex);
					alpha=W3GetBuff(client,iGlowAlpha,bestindex);
				//	skipinvis=true;
				}
				
				new bool:set=false;
				if(GetPlayerR(client)!=r)
					set=true;
				if(GetPlayerG(client)!=g)
					set=true;
				if(GetPlayerB(client)!=b)
					set=true;
				//alpha set is after invis block, not here
				if(set){
					//	PrintToChatAll("%d %d %d %d",r,g,b,alpha);
					SetPlayerRGB(client,r,g,b);
				}
				
				
				
				
				
				///invisbility!
				//PrintToChatAll("W3GetBuffMinFloat(client,fInvisibility) %f %f %f ",W3GetBuffMinFloat(client,fInvisibility),float(alpha),float(alpha)*W3GetBuffMinFloat(client,fInvisibility));
				
				
			
				new Float:falpha=1.0;
			//	if(!W3GetBuffHasTrue(client,bInvisibilityDenySkill))
			//	{
				falpha=FloatMul(falpha,W3GetBuffMinFloat(client,fInvisibilitySkill));
			//		
			//	}
				//if(!W3GetBuffHasTrue(client,bInvisibilityDenySkillbInvisibl  ///we dont have an item deny yet
				new Float:itemalpha=W3GetBuffMinFloat(client,fInvisibilityItem);
				if(falpha!=1.0){
					//PrintToChatAll("has skill invis");
					//has skill, reduce stack
					itemalpha=Pow(itemalpha,0.75);
				}
				falpha=FloatMul(falpha,itemalpha);
				
				//PrintToChatAll("%f",W3GetBuffMinFloat(client,fInvisibilityItem));
				
				new alpha2=RoundFloat(       FloatMul(255.0,falpha)  ); 
				//PrintToChatAll("alpha2 = %d",alpha2);
				if(alpha2>=0&&alpha2<=255){
					alpha=alpha2;
				}
				else{
					LogError("alpha playertracking out of bounds 0 - 255");
				}
				if(W3GetBuffHasTrue(client,bInvisibilityDenyAll)||W3GetBuffHasTrue(client,bBuffDenyAll) ){
					if( bDeniedInvis[client]==false && alpha<222) ///buff is not denied
					{
						bDeniedInvis[client]=true;
						PrintHintText(client,"Cannot Invis. Being revealed");
						
					}
					alpha=255;
				}
				else{
					bDeniedInvis[client]=false;
				}
				//PrintToChatAll("%d",alpha);
				if(GetEntityAlpha(client)!=alpha)
					SetEntityAlpha(client,alpha);
					
				invisWeaponAttachments[client]=alpha<200?true:false;
				
					
					
					
				new wpn=W3GetCurrentWeaponEnt(client);
				if(wpn>0){
					if(W3GetBuffHasTrue(client,bInvisWeaponOverride)){
						new alphaw=-1;
						new buffloop = W3GetBuffLoopLimit();
						for(new i=0;i<=buffloop;i++){
							if(W3GetBuff(client,bInvisWeaponOverride,i,true)){
								alphaw=W3GetBuffMinInt(client,iInvisWeaponOverrideAmount);
							}
						}
						if(alphaw==-1){
							ThrowError("could not find a valid weapon alpha");
						}
						if(GetWeaponAlpha(client)!=alphaw){
							SetEntityAlpha(wpn,alphaw);
						}
					}
					else if(!W3GetBuffHasTrue(client,bDoNotInvisWeapon)){
						if(GetWeaponAlpha(client)!=alpha){
							SetEntityAlpha(wpn,alpha);
							
						}
					}
					
				}
			
				///NEED 4 SPEED!
				///SPEED IS IN PLAYER FRAME	
			}
		}
	
}


public OnGameFrame()
{

		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true))//&&!bIgnoreTrackGF[client])
			{
				
				
				new Float:currentmaxspeed=GetEntDataFloat(client,m_OffsetSpeed);
				//DP("speed %f, speedbefore %f , we set %f",currentmaxspeed,speedBefore[client],speedWeSet[client]);
				if(currentmaxspeed!=speedWeSet[client]) ///SO DID engien set a new speed? copy that!! //TFIsDefaultMaxSpeed(client,currentmaxspeed)){ //ONLY IF NOT SET YET
				{	
					//DP("detected newspeed %f was %f",currentmaxspeed,speedWeSet[client]);
					speedBefore[client]=currentmaxspeed;
					reapplyspeed[client]++;
				}
				
				
				
				//PrintToChat(client,"speed %f %s",currentmaxspeed, TFIsDefaultMaxSpeed(client,currentmaxspeed)?"T":"F");
				if(reapplyspeed[client]>0)
				{
			//	DP("reapply");
					reapplyspeed[client]=0;
					///player frame tracking, if client speed is not what we set, we reapply speed
					
					//PrintToChatAll("1");
					if(War3_GetGame()==Game_TF){
						
						
						
					//	if(true||	speedBefore[client]>3.0){ //reapply speed, using previous cached base speed, make sure the cache isnt' zero lol 
							new Float:speedmulti=1.0;
							//DP("before");
							//new Float:speedadd=1.0;
							if(!W3GetBuffHasTrue(client,bBuffDenyAll)){
								speedmulti=W3GetBuffMaxFloat(client,fMaxSpeed);
							}
							if(W3GetBuffHasTrue(client,bStunned)||W3GetBuffHasTrue(client,bBashed)){
							//DP("stunned or bashed");
								speedmulti=0.0;
							}
							if(!W3GetBuffHasTrue(client,bSlowImmunity)){
								speedmulti=FloatMul(speedmulti,W3GetBuffStackedFloat(client,fSlow)); 
								speedmulti=FloatMul(speedmulti,W3GetBuffStackedFloat(client,fSlow2)); 
							}
							//PrintToConsole(client,"speedmulti should be 1.0 %f %f",speedmulti,speedadd);
							new Float:newmaxspeed=FloatMul(speedBefore[client],speedmulti);
							if(newmaxspeed<0.1){
								newmaxspeed=0.1;
							}
							speedWeSet[client]=newmaxspeed;
							SetEntDataFloat(client,m_OffsetSpeed,newmaxspeed,true);
							
							//DP("%f",newmaxspeed);
					//	}
					}
					else{ //cs?
											
						new Float:speedmulti=1.0;
						
						//new Float:speedadd=1.0;
						if(!W3GetBuffHasTrue(client,bBuffDenyAll)){
							new Float:speedmulti1=W3GetBuffMaxFloat(client,fMaxSpeed);
							new Float:speedmulti2=W3GetBuffMaxFloat(client,fMaxSpeed2);
							speedmulti=speedmulti1+(speedmulti2-1.0); ///1.0 + 1.0 - 1.0 = 1.0
						}
						if(W3GetBuffHasTrue(client,bStunned)||W3GetBuffHasTrue(client,bBashed)){
							speedmulti=0.0;
						}
						if(!W3GetBuffHasTrue(client,bSlowImmunity)){
							speedmulti=FloatMul(speedmulti,W3GetBuffStackedFloat(client,fSlow)); 
							speedmulti=FloatMul(speedmulti,W3GetBuffStackedFloat(client,fSlow2)); 
						}
						
						if(GetEntDataFloat(client,m_OffsetSpeed)!=speedmulti){
							SetEntDataFloat(client,m_OffsetSpeed,speedmulti);
						}
					}
				}
				
				
				
				new MoveType:currentmovetype=GetEntityMoveType(client);
				new MoveType:shouldmoveas=MOVETYPE_WALK;
				if(W3GetBuffHasTrue(client,bNoMoveMode)){
					shouldmoveas=MOVETYPE_NONE;
				}
				if(W3GetBuffHasTrue(client,bNoClipMode)){
					shouldmoveas=MOVETYPE_NOCLIP;
				}
				else if(W3GetBuffHasTrue(client,bFlyMode)&&!W3GetBuffHasTrue(client,bFlyModeDeny)){
					shouldmoveas=MOVETYPE_FLY;
				}
				
				/* Glider (290611): 
				 * 		I have implemented a extremly dirty way to prevent some
				 *      shit that goes wrong in L4D2.
				 *         
				 *      If a tank tries to climb a object, he changes his
				 *      move type. This code prevented them from ever
				 *      climbing anything.
				 *         
				 *      Players also change their move type when they get
				 *      hit so hard they stagger into a direction, making
				 *      them move slower. This code made them stagger much
				 *      faster, resulting in crossing a much larger distance
				 *      (usually right into some pit).
				 *         
				 *      TODO: Fix properly ;)
				 */
				
				if(currentmovetype!=shouldmoveas && !War3_IsL4DEngine()){
					SetEntityMoveType(client,shouldmoveas);
				}
				//PrintToChatAll("end");
			}
		}
	
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client,true)){ //block attack
		if(W3GetBuffHasTrue(client,bStunned)||W3GetBuffHasTrue(client,bDisarm)){
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
	}
	return Plugin_Continue;
}



stock GetEntityAlpha(index)
{
	return GetEntData(index,m_OffsetClrRender+3,1);
}

stock GetPlayerR(index)
{
	return GetEntData(index,m_OffsetClrRender,1);
}

stock GetPlayerG(index)
{
	return GetEntData(index,m_OffsetClrRender+1,1);
}

stock GetPlayerB(index)
{
	return GetEntData(index,m_OffsetClrRender+2,1);
}

stock SetPlayerRGB(index,r,g,b)
{
	SetEntityRenderMode(index,RENDER_TRANSCOLOR);
	SetEntityRenderColor(index,r,g,b,GetEntityAlpha(index));	
}

// FX Distort == 14
// Render TransAdd == 5
stock SetEntityAlpha(index,alpha)
{	
	//if(FindSendPropOffs(index,"m_nRenderFX")>-1&&FindSendPropOffs(index,"m_nRenderMode")>-1){
	new String:class[32];
	GetEntityNetClass(index, class, sizeof(class) );
	//PrintToServer("%s",class);
	if(FindSendPropOffs(class,"m_nRenderFX")>-1){
		SetEntityRenderMode(index,RENDER_TRANSCOLOR);
		SetEntityRenderColor(index,GetPlayerR(index),GetPlayerG(index),GetPlayerB(index),alpha);
	}
	//else{
	//	W3Log("deny render fx %d",index);
	//}
	//}	
}

stock GetWeaponAlpha(client)
{
	new wep=W3GetCurrentWeaponEnt(client);
	if(wep>MaxClients && IsValidEdict(wep))
	{
		return GetEntityAlpha(wep);
	}
	return 255;
}

