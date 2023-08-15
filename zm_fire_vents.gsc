#using scripts\codescripts\struct;

#using scripts\zm\_zm_perks;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\compass;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm;
#using scripts\zm\_load;
#using scripts\zm\_zm_power;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_zonemgr;

#using scripts\shared\ai\zombie_utility;
#using scripts\shared\ai\zombie_death;

#insert scripts\zm\zm_fire_vents.gsh;

#using scripts\shared\_burnplayer;

#namespace zm_fire_vents;

REGISTER_SYSTEM_EX( "zm_fire_vents", &__init__, &__main__, undefined )

function __init__(){
    clientfield::register( "scriptmover", FX_FIRE_VENT, VERSION_SHIP, 1, "int" );
}

function __main__(){
	level waittill("initial_blackscreen_passed"); // wait till structs are spawned

	level.fire_vents_0 = struct::get_array( "fire_vents_0");
	level.fire_vents_1 = struct::get_array( "fire_vents_1");
	level.fire_vents_2 = struct::get_array( "fire_vents_2");
	level.fire_vents_3 = struct::get_array( "fire_vents_3");

	array::thread_all(level.fire_vents_0, &init_struct, GetEnt("fire_vents_0", "targetname"));
	array::thread_all(level.fire_vents_1, &init_struct, GetEnt("fire_vents_1", "targetname"));
	array::thread_all(level.fire_vents_2, &init_struct, GetEnt("fire_vents_2", "targetname"));
	array::thread_all(level.fire_vents_3, &init_struct, GetEnt("fire_vents_3", "targetname"));

	thread watch_intermission_bool();
	thread manage_fire_vents();
}

function init_struct(trigger){
	self.trigger_burn = trigger;
    self.tag = util::spawn_model("tag_origin", self.origin, (270,0,0));
}

function watch_intermission_bool(){
	while(true){
		level waittill("start_of_round");
		level.is_intermission = false;
		level waittill("end_of_round");
		level.is_intermission = true;

		// End all fire vents when intermission starts
		array::notify_all(level.fire_vents_0, "end");
		array::notify_all(level.fire_vents_1, "end");
		array::notify_all(level.fire_vents_2, "end");
		array::notify_all(level.fire_vents_3, "end");
	}
}

function manage_fire_vents(){
	while(true){
		round = level.round_number;

		if(round % 6 == 0){
			array::thread_all(level.fire_vents_0, &fire_vent);
			array::thread_all(level.fire_vents_2, &fire_vent);
			wait(FIRE_VENT_TIME);
			array::thread_all(level.fire_vents_1, &fire_vent);
			array::thread_all(level.fire_vents_3, &fire_vent);
			level waittill("start_of_round");
			continue;
		}
		else if(round % 2 == 0){ // every 2 rounds
			array::thread_all(level.fire_vents_0, &fire_vent);
			array::thread_all(level.fire_vents_2, &fire_vent);
		} else if(round % 3 == 0){ // every 3 rounds
			array::thread_all(level.fire_vents_1, &fire_vent);
			array::thread_all(level.fire_vents_3, &fire_vent);
		}else{
			array::thread_all(level.fire_vents_0, &fire_vent);
			wait(FIRE_VENT_TIME);
			array::thread_all(level.fire_vents_1, &fire_vent);
			wait(FIRE_VENT_TIME/2);
			array::thread_all(level.fire_vents_2, &fire_vent);
			wait(FIRE_VENT_TIME/3);
			array::thread_all(level.fire_vents_3, &fire_vent);
		}
		level waittill("start_of_round");
	}
}

function fire_vent(){
	// self == fire_vent_struct
	self endon ("end");
	
	self.active = true;
	self.countdown_started = false;
    self.tag clientfield::set( FX_FIRE_VENT, 1 );

	self thread watch_delete_fire_vent();
	self thread watch_fire_vent_damage();
    self.was_on = false;

	while(!level.is_intermission){
		while(self.active){
            self.was_on = true;
			self thread fire_vent_countdown(FIRE_VENT_TIME, false); // start activation timer
			wait FIRE_VENT_DAMAGE_INTERVAL;
			wait 0.05;
		}
		if(!self.active){
            if(self.was_on){
                self.was_on = false;
                self.tag clientfield::set( FX_FIRE_VENT, 0 );
            }

			wait FIRE_VENT_TIME; // wait for cooldown

			self.active = true;
			self.countdown_started = false;
            self.tag clientfield::set( FX_FIRE_VENT, 1 );
		}
	}
}

// self = player
function damage_player(){
	iprintlnbold("damage_player");
    self.burn_cooldown = true;
    // self SetMoveSpeedScale(0.5);
    self DoDamage(FIRE_VENT_DAMAGE, self.origin);
	self burnplayer::SetPlayerBurning(FIRE_VENT_DAMAGE_INTERVAL, 0, 0, undefined, undefined );
    wait FIRE_VENT_DAMAGE_INTERVAL;
    self.burn_cooldown = false;
    // self SetMoveSpeedScale(1);
}

function watch_fire_vent_damage(){
	self endon ("end");
    while(true){
		if(!isdefined(self.trigger_burn)){
			IPrintLnBold("ERROR: fire_vent_struct missing trigger_burn entity");
		}
        if(self.active){
			if(DAMAGE_ZOMBIES){
				zombies = GetAiSpeciesArray( "all" );
				foreach(zombie in zombies){
					if(zombie IsTouching(self.trigger_burn)){
						if(isdefined(zombie.burn_cooldown)){
							if(!zombie.burn_cooldown){
								zombie DoDamage(zombie.health/5, zombie.origin);
							}
						}
						else{
							zombie DoDamage(zombie.health/5, zombie.origin);
						}
					}
				}
			}

            players = GetPlayers();
            foreach(player in players){
                if(player IsTouching(self.trigger_burn)){
                    if(isdefined(player.burn_cooldown)){
                        if(!player.burn_cooldown){
                            player thread damage_player();
                        }
                    }
                    else{
                        player thread damage_player();
                    }
                }
            }
        }
        wait .1;
    }
}

function watch_delete_fire_vent(){
	self waittill("end");
    self.tag clientfield::set( FX_FIRE_VENT, 0 );
}

function fire_vent_countdown(time, set_active){
	wait time;
	if(self.countdown_started) return;
	self.countdown_started = true;
	self.active = set_active;
}