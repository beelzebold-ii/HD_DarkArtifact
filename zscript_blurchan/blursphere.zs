//blursphere taken from hdest version 4.3.3a
//with some slight modifications to my own preference
//and bent into shape until it works.


//-------------------------------------------------
// Blur Sphere
//-------------------------------------------------
class BlurTaint:InventoryFlag{default{+inventory.undroppable}}
class HDPreciousBlurSphere:HDPickup{
	//true +invisible can never be used.
	//it will cause the monsters to be caught in a consant 1-tic see loop.
	//no one seems to consider this to be a bug.
	//shadow will at least cause attacks to happen less often.
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Blur Sphere"
		//$Sprite "PINSA0"
		
		+forcexybillboard
		+inventory.alwayspickup
		inventory.maxamount 9;
		inventory.interhubamount 1;
		inventory.pickupmessage "\c[red]So precious in your sight.";
		tag "dark artifact";
		renderstyle "translucent";
		inventory.pickupsound "misc/casing";
		inventory.icon "PBLRC0";
		scale 0.3;
	}
	int intensity;int xp;int level;bool worn;
	// [nkc] hack to get around issues with dropping from the use state
	bool tobedropped;
	// [nkc] when you forcibly remove a fused blursphere, it will be weakened
	// and will refuse/be unable to gain xp until this timer hits zero
	int weakened;
	// [nkc] added a 5th slot to replace the modification I made to the first one
	int randticker[5];double randtickerfloat;
	override void ownerdied(){
		buntossable=false;
		owner.DropInventory(self);
	}
	states{
	spawn:
		PBLR ABCDCB random(3,4); // [nkc] new sprites, tick length 1..6 > 3..4
		loop;
	use:
		TNT1 A 0{
			int cmd = player.cmd.buttons;
			if(cmd & BT_ZOOM){
				// [nkc] tear off blur
				if(invoker.level <= 7){
					// [nkc] this might cause crashes; I might need to hack a different way of having the item be dropped.
					invoker.buntossable = false;
					invoker.bundroppable = false;
					invoker.worn = false;
					invoker.tobedropped = true;
					return;
				}else{
					// [nkc] level is greater than 7, ring can no longer be taken off.
					// guess we'll have to *force* it off.
					// if the ring is at max level, it cannot be removed by any means.
					// attempting to do so will not damage the player.
					if(invoker.level >= BLUR_LEVELCAP){
						string msg[6];
						msg[0]="How could I do such a thing...?";
						msg[1]="It's too precious to let go of.";
						msg[2]="don't you dare";
						msg[3]="do you think you're stronger than me?";
						msg[4]="We can't.";
						msg[5]="No...";
						if(preciousblur_talkative)
							A_Log(msg[int(clamp(invoker.randtickerfloat*msg.size(),0,msg.size()-1))],true);
						return;
					}else{
						string msg[7];
						msg[0]="how could you";
						msg[1]="how could you";
						msg[2]="we were so strong together";
						msg[3]="ow ow ow why why why";
						msg[4]="why";
						msg[5]="don't you trust me";
						msg[6]=string.format(player.getusername().makelower().."\c-...");
						if(preciousblur_talkative)
							A_Log(msg[int(clamp(invoker.randtickerfloat*msg.size(),0,msg.size()-1))],true);
						
						let hdp = hdplayerpawn(invoker.owner);
						if(hdp){
							HDBleedingWound.inflict(hdp,frandom(20.,14. + invoker.level),frandom(26. + invoker.level/2. ,28. + invoker.level/1.),false,self,'balefire');
							hdp.damagemobj(invoker,invoker,min(hdp.health - 14, 10 + invoker.level),'balefire',DMG_NO_ARMOR);
							// [nkc] deaggravate the player a little bit for gameplay's sake.
							// in essence the player is receiving a little bit of their soul back
							hdp.aggravateddamage = max(0, hdp.aggravateddamage - random(6,6+invoker.level));
						}
						invoker.xp = 0;
						invoker.level = 0;
						// [nkc] 100 seconds timer before functional again; only ticks down while carried
						invoker.weakened = BLUR_LEVELUP;
						
						invoker.buntossable = false;
						invoker.bundroppable = false;
						invoker.worn = false;
						invoker.tobedropped = true;
						
						A_TakeInventory("BlurTaint");
					}
				}
			}else{
				// [nkc] if the artifact is weakened, it will refuse being worn
				if(invoker.weakened){
					string msg[6];
					msg[0]="stop";
					msg[1]="it hurts";
					msg[2]="Noise.";
					msg[3]="i hate you";
					msg[4]="what";
					msg[5]="leave me alone";
					if(preciousblur_talkative)
						A_Log(msg[int(clamp(invoker.randtickerfloat*msg.size(),0,msg.size()-1))],true);
					A_StartSound("imp/sight2",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
					return;
				}
				// [nkc] existing 4.3.3a matt code
				A_SetBlend("01 00 00",0.9,48);
				if(!invoker.worn){
					invoker.worn=true;
					HDF.Give(self,"BlurTaint",1);
					A_StartSound("imp/sight2",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
					invoker.level=min(13,invoker.level+invoker.xp/BLUR_LEVELUP);
					if(invoker.xp >= BLUR_LEVELUP){
						if(invoker.xp < BLUR_LEVELUP * 2)
							A_Log("You feel a jump in dark power within you.",true);
						else
							A_Log("You feel a large boost in dark power within you.",true);
					}
					invoker.xp%=BLUR_LEVELUP;
					invoker.stamina=clamp(invoker.level+random(-2,2),0,10);
					if(invoker.level>7)invoker.buntossable=true;  
					//console.printf("xp: "..invoker.xp.." - level: "..invoker.level);
					if(preciousblur_visualchanges)
						invoker.A_SpawnItemEx("WraithLight",flags:SXF_SETTARGET);
					
					/* // [nkc] spirit arm no longer exists; maybe integrate with new blur and/or shieldcore?
					// [nkc] new plan: ability to forcibly remove a permanently attached blursphere below lv13
					// with say, [zoom + use (item)], at the cost of opening a large wound.
					// freedom from this great evil is not cheap, and it will hurt, but after a quick patch up
					// you'll be good to either pick up another one or even the same one, or move on with holy
					// magicks instead of evil ones.
					// level 13 blur would have to be burned off a little before you can purge it. picking up
					// specifically a megasphere might purge it instantly. maybe not. might be a bit unfair
					// to doom 1 players.
					
					// maybe ghost soldiers could target you if you have high level blur, thus reducing its level.
					// maybe.
					int spac=countinv("SpiritualArmour");
					if(spac){
						hdplayerpawn(self).cheatgivestatusailments("fire",spac*3);
						A_TakeInventory("SpiritualArmour");
					}
					*/
				}else{
					invoker.worn=false;
					bspecialfiredamage=false;
					A_StartSound("imp/sight1",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
				}
			}
		}fail;
	}
	enum blurstats{
		BLUR_LEVELUP=3500,
		BLUR_LEVELCAP=13,
	}
	override void tick(){
		super.tick();
		double frnd=frandom[blur](0.98,1.02);
		// [nkc] scale and alpha now use separate flickerers
		double frnd2=frandom[blur](0.4,0.9);
		scale=(0.3,0.3)*frnd;
		alpha=frnd2;
		randticker[0]=random(0,4);// [nkc] 0..3 > 0..4
		randticker[1]=random(8,25);
		randticker[2]=random(0,40 + level * 2);// [nkc] 40 + level > 40 + level * 2
		randticker[3]=random(0,BLUR_LEVELUP);
		randticker[4]=random(0,3);// [nkc] replaces the old slot zero
		randtickerfloat=frandom(0.,1.);
		
		if(tobedropped && owner){
			tobedropped = false;
			owner.DropInventory(self);
		}
	}
	override void DoEffect(){
		if(
			!owner
			||owner.health<1
		){
			return;
		}
		
		//they eat their own
		if(amount>1){  
			amount=1;
			xp+=666; // [nkc] 100 > 666
			//console.printf("xp: "..xp.." - level: "..level);
		}
		
		// [nkc] deplete weakness; threaten the player once fully recovered
		if(weakened>0){
			weakened--;
			if(!weakened) owner.A_Log("you better not do that again.",true);
		}
		
		bool doxpeffect = false;
		
		// [nkc] can't gain experience while weakened
		if(!worn){
			owner.bspecialfiredamage=false;
			intensity=max(0,intensity-1);
			if(!weakened)
				if(level<BLUR_LEVELCAP&&!randticker[0]){
					xp++;
					doxpeffect = true;
				}
		}else{
			if(intensity<99)intensity=max(intensity+1,-135);
			if(!weakened){
				xp++;
				doxpeffect = true;
			}

			let ltm=PortableLiteAmp(owner.findinventory("PortableLiteAmp"));
			if(ltm)ltm.worn=false;
		}
		
		// [nkc] set intensity down if we fire a bright gun
		// apparently this wasn't handled inside of the old blursphere
		if(owner.frame == 5){ // [nkc] F
			intensity -= 70;
			intensity = max(-200,intensity);
		}
		
		bool invi=true;

		if(intensity<randticker[1]){
			owner.a_setrenderstyle(1.,STYLE_Normal);
			invi=false;
		}else{
			owner.a_setrenderstyle(0.9,STYLE_Fuzzy);
			// [nkc] flicker between fuzzy and subtract renderstyles
			if(randticker[0]>1 && preciousblur_visualchanges){
				owner.a_setrenderstyle(0.9,STYLE_Subtract);
			}
			// [nkc] 0.5% chance to become fully invisible per tic
			if(randtickerfloat < 0.005){
				owner.a_setrenderstyle(0.9,STYLE_None);
				owner.bspecialfiredamage=true;
			}else{
				owner.bspecialfiredamage=false;
			}
		}

		//apply result
		owner.bshadow=invi;
		owner.bnevertarget=invi;

		if(!owner.countinv("blurtaint"))return;
		
		// [nkc] if there's a shy blursphere in the player's inventory, drop it instantly
		let shyblur = owner.FindInventory("HDBlursphere");
		if(shyblur){
			owner.DropInventory(shyblur);
			if(preciousblur_talkative && !random(0,6)){
				string msg[5];
				msg[0]="what is this";
				msg[1]="get away";
				msg[2]="fuck off";
				msg[3]="leave me alone";
				msg[4]="are you trying to replace me";
				owner.A_Log(msg[int(clamp(randtickerfloat*msg.size(),0,msg.size()-1))],true);
			}
		}
		
		//medusa gaze
		if(invi&&!!randticker[0]){
			flinetracedata medusagaze;
			owner.linetrace(
				owner.angle,4096,owner.pitch,
				offsetz:owner.height-6,
				data:medusagaze
			);
			actor aaa=medusagaze.hitactor;
			if(aaa&&aaa.bismonster){
				aaa.A_ClearTarget();
				aaa.A_ClearSoundTarget();
				heat.inflict(aaa,random(1,level+2));
				if(!random(0,3))xp++;
			}
			owner.A_ClearSoundTarget();
		}

		let hdp=hdplayerpawn(owner);
		if(hdp){
			if(hdp.countinv("healingmagic")>random(1,80)){
				// [nkc] cut aggro from burning off blur in half.
				if(gametic % 2 == 0) hdp.aggravateddamage++;
				// [nkc] blues are an inventory item now, not an integer in the player
				hdp.takeinventory("healingmagic",3);
				heat.inflict(hdp,12);
				// [nkc] reduce blurpower by some amount for every bit this happens.
				// this effect is more efficient with a higher amount of blues.
				// (on top of already being outright faster)
				int xpdrain = random(20,20 + (hdp.countinv("healingmagic")));
				// [nkc] if we're below critical level, cut xp drain in half
				if(level <= 7) xpdrain /= 2;
				xp -= xpdrain;
				//console.printf("burned away "..xpdrain.." xp; now at "..xp.." xp");
				if((level > 0 && xp < 0) || xp < -1332){
					level--;
					if(level == 7 || level == 12){
						if(level == 7)
							buntossable = false;
						if(preciousblur_talkative)
							owner.A_Log("what are you doing",true);
					}
					
					xp += BLUR_LEVELUP;
					string msg[8];
					msg[0]="ow ow ow";
					msg[1]="stop stop stop";
					msg[2]="fuck";
					msg[3]="leave me alone";
					msg[4]="i've been so good to you";
					msg[5]="why choose light over the comfort of darkness";
					msg[6]="i hate you";
					msg[7]="why do you hate me";
					if(preciousblur_talkative)
						owner.A_Log(msg[int(clamp(randtickerfloat*msg.size(),0,msg.size()-1))],true);
					if(level < 0){
						// [nkc] if we somehow burn the thing all the way away,
						// just purge it
						hdp.A_TakeInventory("BlurTaint");
						destroy();
						return;
					}
				}
				if(!worn&&!randticker[2]){
					hdp.A_TakeInventory("BlurTaint");
					xp += 400;
					owner.A_Log("You feel cleaner.",true);
				}
			}
			/* // [nkc] spirit armor still doesn't exist...
			if(hdp.countinv("SpiritualArmour")){
				hdp.cheatgivestatusailments("fire",countinv("SpiritualArmour")*10);
				hdp.A_TakeInventory("SpiritualArmour");
			}
			*/
			
			// [nkc] wounds have been reworked, some small tweaking required for
			// it to properly bandage over your wounds.
			// I'd like for it to also seal them though, as that was something
			// you had to deal with in old hdest conditions.
			// [nkc] changed the random max from level > (BLUR_LEVELCAP - level) + 7
			// that way wounds patch *faster* at higher levels instead of slower
			// was that intentional?
			// changed random min from 0 to -2 such that there's still a good chance for
			// small wounds to patch
			// [nkc] this feels way too fast, toning it down a bit.
			bool trytoseal = false;
			if(HDBleedingWound.woundcount(hdp)>random(-2,(BLUR_LEVELCAP - level) + 7)){
				let wwwound = HDBleedingWound.findandpatch(hdp,0.2 + (level * 0.02));
				// [nkc] the above check may still return a high value with a lot of patched or sealed
				// wounds. if we don't find an *open* wound to patch, we act like the check failed.
				if(!wwwound){
					trytoseal = true;
				}else{
					// [nkc] if it finishes patching a wound, low chance for it to say hi
					if(wwwound.depth <= 0){
						if(wwwound.healing < 1 && !random(0,10)){
							string msg[6];
							msg[0]="see how much i do for you?";
							msg[1]="doesn't that feel better";
							msg[2]="you're nothing without me.";
							msg[3]="you're welcome.";
							msg[4]="thank me later";
							msg[5]="you would never get rid of me, right?";
							if(preciousblur_talkative)
								owner.A_Log(msg[int(clamp(randtickerfloat*msg.size(),0,msg.size()-1))],true);
						}
						
						// [nkc] ensure that it really is all the way closed
						// annoyingly enough wounds seem to immediately unpatch themselves
						// the second they're patched
						wwwound.patch(5.);
						wwwound.patch(1.,true);
					}
				}
			}else{
				trytoseal = true;
			}
			
			if(trytoseal){
				// [nkc] if the above check fails, check if the player has any patched
				// wounds and slowly seal them if so.
				// this happens quite slowly at first, but very quickly at high levels
				if(!random(0, max((BLUR_LEVELCAP - level) * 2 - 4, 2))){
					if(HDBleedingWound.woundcount(hdp) > 0)
						HDBleedingWound.findandpatch(hdp,0.04,HDBW_FINDPATCHED);
				}
			}
		}

		if(xp<1) return;
		
		if(!doxpeffect && !preciousblur_maxlevelbug) return;

		//power.
		if(!(xp%666)){
			// [nkc] chance to react with any active shield core the bearer
			// may have. shields are demon magicks, after all.
			// base chance is 1/6, goes up every 3 levels (ie 1/5 > 1/4)
			// caps out at being a 1/3 at level 9
			// at level 13, always boost shields, since you'd need to actively
			// be wearing it anyway for the effect to trigger
			if(preciousblur_newinteractions){
				if(level >= 13 || !random(0,max(2,5 - level/3))){
					let shield = hdmagicshield(owner.findinventory("hdmagicshield"));
					if(shield){
						// [nkc] charges by 256 by default, chance to charge by 666
						// from level 4 and onward, always charge by 666 by lv 10
						int shieldcharge = (level <= random(4,10))?666:256;
						// [nkc] don't overcharge shields
						shieldcharge = min(shieldcharge,1024 - shield.amount);
						owner.giveinventory("hdmagicshield",shieldcharge);
						HDMagicShield.FlashSparks(owner);
						// [nkc] aggravate.
						if(!random(0,1))
							hdp.aggravateddamage++;
					}
				}
			}
			
			// [nkc] default Power code
			bool nub=!level&&xp<1066;
			if(nub||!random(0,15))owner.A_Log("You feel power growing in you.",true);
			blockthingsiterator it=blockthingsiterator.create(owner,512);
			array<actor>monsters;
			while(it.next()){
				actor itt=it.thing;
				if(
					itt==owner
					||!itt.bismonster
					||itt.health<1
				)continue;
				monsters.push(itt);
				if(itt.target==owner)itt.A_ClearTarget();
				if(
					nub
					||!random(0,66-level)
				){
					actor fff=itt.spawn("HDFire",itt.pos,ALLOW_REPLACE);
					fff.target=itt;
					fff.stamina=nub?122:13*level;
					fff.master=self;
				}else if(random(0,6-level)<1){
					HDBleedingWound.Inflict(itt,13*level);
				}
			}
			if(monsters.size()){
				int maxindex=monsters.size()-1;
				for(int i=0;i<maxindex;i++){
					actor mmm1=monsters[random(0,maxindex)];
					actor mmm2=monsters[random(0,maxindex)];
					mmm1.damagemobj(
						self,mmm2,1,"Balefire"
					);
					mmm1.target=mmm2;
				}
			}
		}

		//precious.
		if(randticker[3]<level){
			if(!(xp%3)){
				owner.A_StartSound("blursphere/hallu"..int(clamp(randtickerfloat*7,0,6)),
					CHAN_VOICE,CHANF_OVERLAP|CHANF_LOCAL,randtickerfloat*0.3+0.3
				);
			}
			if(!(xp%5)){
				string msg[17];
				// [nkc] I'm gonna remove the error message fakeouts for hopefully
				// obvious reasons. I don't wanna deal with false error reports.
				// replaced with some pickup messages for maximum fun
				// and a message from our abusive dark artifact girlfriend
				msg[0]=preciousblur_talkative?"you know i would never hurt you":"Noise.";
				msg[1]="Picked up a used medikit.";
				msg[2]="\cd[DERP] \cjEngaging hostile.";
				msg[3]="Picked up some 9mm ammo.";
				msg[4]="Picked up a 4.26 UAC Standard magazine.";
				msg[5]="Noise.";
				msg[6]="hello";
				msg[7]="i hate you.";
				// [nkc] idk if deep rock galactic even existed yet atp but. lol. changing the line to preserve my immersion
				// "This is worthless." > "worthless."
				msg[8]="worthless.";
				msg[9]="it hurts";
				msg[10]="error";
				msg[11]="Precious.";
				msg[12]="Precious.";
				msg[13]="Precious.";
				msg[14]="Precious.";
				// [nkc] adding these two cos I think they're funny
				msg[15]="\cd[DERP] \cjEngaging hostile. \n\cd[DERP] \cjOut of ammo. Await retrieval.";
				msg[16]="can't... go... on...";
				owner.A_Log(msg[int(clamp(randtickerfloat*msg.size(),0,msg.size()-1))],true);
			}
			if(!(xp%7)){
				// [nkc] if the bearer is stimulated, aggravated damage is reduced
				// this is just for funsies so as to add a bit more interaction
				// one stim is 400 units, this means you never get *no* aggravation
				// as that would kind of undermine things.
				// however this effect still might not quite be negligable.
				if(owner.countinv("hdstim")<random(100,400) && preciousblur_newinteractions)
					hdplayerpawn(owner).aggravateddamage++;
				// [nkc] modifying this message from "Precious." to be at least not identical
				// to the other ones so you can tell, hey, you just got aggravated a lil.
				if(!randticker[4])owner.A_Log("mine.",true);
			}
		}
		
		// [nkc] this (already existing from old blur) keeps xp in a loop even when
		// blur is at max level. I want blue to be able to burn blur away and weaken
		// it, so I want this loop to be at a higher value.
		if(level>=BLUR_LEVELCAP&&xp>=1998){
			xp-=666; // [nkc] 0..666 > 1332..1998
			//console.printf("xp loop");
		}
	}
	override void DetachFromOwner(){
		owner.bshadow=false;
		owner.bspecialfiredamage=false;
		owner.a_setrenderstyle(1.,STYLE_Normal);
		if(worn){
			worn=false;
			owner.damagemobj(self,owner,random(1,level),"balefire");
		}
		intensity=0;
		owner.A_StartSound("imp/sight1",CHAN_BODY,volume:frandom(0.3,0.5),attenuation:8.);
		super.detachfromowner();
	}
	
	// [nkc] since this doesn't have access to hdest's internal player damagemobj,
	// I have to give the balefire resistance through this function.
	override void ModifyDamage(int damage,name damagetype,out int newdamage,bool passive,actor inflictor,actor source,int flags){
		if(passive){
			if(damagetype=="balefire")newdamage=max(1,damage-level*2);
			// [nkc] don't want intensity to go below zero in this case, just for
			// the player's sake lol (intensity -= 100 > intensity = 0)
			else if(damagetype=="thermal")intensity = 0;
		}
	}
}





//a mortal man doomed to die
class WraithLight:PointLight{
	default{
		+dynamiclight.subtractive
	}
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=66;
		args[1]=121;
		args[2]=87;
		args[3]=0;
		args[4]=0;
	}
	bool fading;
	override void tick(){
		// [nkc] this is supposed to be the pointlight for shellshades. however,
		// it's been repurposed to work properly with the dark artifacts
		if(!target 
			|| !(HDPreciousBlursphere(target).owner) 
			|| !(HDPreciousBlursphere(target).worn) 
			|| fading 
			|| !preciousblur_visualchanges){
			fading = true;
			args[3]+=random(-5,2);
			if(args[3]<1)destroy();
		}else{
			setorigin(HDPreciousBlursphere(target).owner.pos,true);
			if(HDPreciousBlursphere(target).owner.getrenderstyle() == STYLE_Fuzzy)args[3]=random(32,40);
			else args[3]=random(48,64);
			args[3] += (HDPreciousBlursphere(target).level * 6) - 60;
			args[3] -= (100 - HDPreciousBlursphere(target).intensity);
		}
	}
}


// [nkc] this eventhandler is made by me; the code that actually draws the weird
// double vision effect is matt's from hdest 433a
class HDPreciousBlurOverlayHandler:EventHandler{
	override void RenderUnderlay(renderevent e){
		bool blurred;
		let hpl = HDPlayerPawn(players[consoleplayer].mo);
		int renderst = hpl.getrenderstyle();
		if(hpl){
			blurred = (renderst == STYLE_Fuzzy || renderst == STYLE_None || renderst == STYLE_Subtract);
		}
		
		if(blurred){
			let bls=HDPreciousBlurSphere(hpl.findinventory("HDPreciousBlurSphere"));
			if(!bls)blurred=false;else{
				statusbar.SetSize(0,320,200);
				statusbar.BeginHUD(forcescaled:true);
				texman.setcameratotexture(hpl.scopecamera,"HDPBLRCAM",97);
				double lv=bls.stamina+frandom[blurhud](-2,2);
				double camalpha=bls.intensity*0.0003*clamp(lv,0,9);
				statusbar.drawimage(
					"HDPBLRCAM",(-random[blurhud](30,32)-lv,0),basestatusbar.DI_SCREEN_CENTER|basestatusbar.DI_ITEM_CENTER,
					alpha:camalpha,scale:(2.0,2.0)*frandom[blurhud](0.99,1.01)
				);
				texman.setcameratotexture(hpl.scopecamera,"HDPBLRCAM",110);
				statusbar.drawimage(
					"HDPBLRCAM",(random[blurhud](30,32)+lv,0),basestatusbar.DI_SCREEN_CENTER|basestatusbar.DI_ITEM_CENTER,
					alpha:camalpha*0.6,scale:(2.0,2.0)*frandom[blurhud](0.99,1.01)
				);
				// [nkc] this is a really funny way to do what essentially amounts to a color blend lol
				// actually I do understand that the player can only have one color blend at once
				// I forgot abt that
				// still I find this amusing
				statusbar.drawimage(
					"DUSTA0",(0,0),basestatusbar.DI_SCREEN_CENTER|basestatusbar.DI_ITEM_CENTER,
					alpha:0.01*lv,scale:(1000,600)
				);
				return;
			}
		}
	}
	
	override void CheckReplacement(replaceevent e){
		if(e.replacee == "hdblursphere" && random(1,100) <= preciousblur_spawnpercent){
			e.replacement = "hdpreciousblursphere";
		}
	}
	
	// [nkc] if a Thing in the World is Damaged and has a blursphere, run a check
	// to have the blursphere automagically equip itself to them.
	// for players, this happens if incapacitated; for anything else, just if below
	// 10% of its spawnhealth. only a cointoss to actually do it per damage tho.
	// ofc, a player could just use it through the console.
	override void WorldThingDamaged(worldevent e){
		let blr = hdpreciousblursphere(e.thing.findinventory("hdpreciousblursphere"));
		let hdp = hdplayerpawn(e.thing);
		if(blr){
			if(
				(
					(hdp && hdp.incapacitated)
					|| e.thing.health <= e.thing.spawnhealth() * 0.10
				)
				&& !blr.worn
				&& !random(0,1)
			){
				// [nkc] it will ofc bully you for this
				if(preciousblur_talkative && !random(0,2)){
					string msg[10];
					msg[0]="see how much i do for you?";
					msg[1]="let's not give up just yet";
					msg[2]="you're nothing without me.";
					msg[3]="you're welcome.";
					msg[4]="thank me later";
					msg[5]="you're only useful to me alive";
					msg[6]="i thought you were supposed to be strong?";
					msg[7]="nice one";
					msg[8]="i hate you";
					msg[9]="ew, what happened to your face";
					e.thing.A_Log(msg[int(clamp(blr.randtickerfloat*msg.size(),0,msg.size()-1))],true);
				}
				e.thing.useinventory(blr);
				// [nkc] and aggravate you a little too
				if(hdp) hdp.aggravateddamage++;
			}
		}
	}
}

// [nkc] the entirety of the following pickupgiver is written by me
class HDPreciousBlurGiver:HDPickupGiver{
	default{
		HDPickupGiver.pickuptogive "HDPreciousBlursphere";
		tag "dark artifact";
		hdpickup.refid "prc";
	}
	
	// [nkc] why is this only defined in weapons? why isn't it also static? whatever.
	int getloadoutvar(string input,string varname,int maxdigits=int.MAX){
		int varstart=input.indexof(varname);
		if(varstart<0)return -1;
		int digitstart=varstart+varname.length();
		string inp=input.mid(digitstart,maxdigits);
		if(inp=="0")return 0;
		if(inp.indexof("e")>=0)inp=inp.left(inp.indexof("e")); //"123e45"
		if(inp.indexof("x")>=0)inp=inp.left(inp.indexof("x")); //"0xffffff..."
		int inpint=inp.toint();
		if(!inpint)return 1; //var merely mentioned with no number
		return inpint;
	}
	
	int blurlevel;
	int starttaint;
	override void loadoutconfigure(string input){
		blurlevel = clamp(getloadoutvar(input,"level",2),0,hdpreciousblursphere.BLUR_LEVELCAP);
		
		starttaint = max(getloadoutvar(input,"tainted"),0);
	}
	override void configureactualpickup(){
		if(blurlevel <= 0) blurlevel = clamp(amount,0,hdpreciousblursphere.BLUR_LEVELCAP);
		HDPreciousBlursphere(actualitem).level = blurlevel;
		HDPreciousBlursphere(actualitem).xp = 0;
		actualitem.amount = 1;
		
		if(starttaint) owner.GiveInventory("BlurTaint",1);
	}
}