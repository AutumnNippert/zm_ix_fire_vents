#using scripts\codescripts\struct;

#using scripts\shared\audio_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_utility.gsh;
#insert scripts\zm\zm_fire_vents.gsh;

#using scripts\zm\_load;

#namespace zm_fire_vents;

#precache( "client_fx", FX_FIRE_VENT );

REGISTER_SYSTEM_EX( "zm_fire_vents", &__init__, &__main__, undefined )

function __init__(){
	clientfield::register( "scriptmover", FX_FIRE_VENT, VERSION_SHIP, 1, "int", &fire_fx, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
}

function __main__(){}

// self = fx
function fire_fx( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
    if( newVal )
        IPrintLnBold("Guess im spawning fx");
        IPrintLnBold("isdefined: " + isdefined( self.fx ));
        if( !isdefined( self.fx ) )
            self.fx = PlayFXOnTag( localClientNum, FX_FIRE_VENT , self, "tag_origin" );
    else
    {
        IPrintLnBold("Tryina delete fx");
        IPrintLnBold("isdefined: " + isdefined( self.fx ));
        if( isdefined( self.fx ) )
            DeleteFX( localClientNum, self.fx);
        self.fx = undefined;
    }
}