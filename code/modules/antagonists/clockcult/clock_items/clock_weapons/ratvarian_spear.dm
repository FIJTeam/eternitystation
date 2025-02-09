//Ratvarian spear: A relatively fragile spear from the Celestial Derelict. Deals extreme damage to silicons and enemy cultists, but doesn't last long when summoned.
/obj/item/clockwork/weapon/ratvarian_spear
	name = "ratvarian spear"
	desc = "A razor-sharp spear made of brass. It thrums with barely-contained energy."
	clockwork_desc = "A powerful spear of Ratvarian making. It's more effective against enemy cultists and silicons."
	icon_state = "ratvarian_spear"
	item_state = "ratvarian_spear"
	force = 15 //Extra damage is dealt to targets in attack()
	throwforce = 25
	armour_penetration = 10
	wound_bonus = 10
	sharpness = SHARP_POINTY
	attack_verb = list("stabbed", "poked", "slashed")
	hitsound = 'sound/weapons/bladeslice.ogg'
	w_class = WEIGHT_CLASS_BULKY
	var/bonus_burn = 5

/obj/item/clockwork/weapon/ratvarian_spear/ratvar_act()
	if(GLOB.ratvar_awakens) //If Ratvar is alive, the spear is extremely powerful
		force = 20
		bonus_burn = 10
		throwforce = 40
		armour_penetration = 50
	else
		force = initial(force)
		bonus_burn = initial(bonus_burn)
		throwforce = initial(throwforce)
		armour_penetration = initial(armour_penetration)

/obj/item/clockwork/weapon/ratvarian_spear/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += span_inathneq_small("Attacks on living non-Servants will generate <b>[bonus_burn]</b> units of vitality.")
		if(!iscyborg(user))
			. += span_brass("Throwing the spear will do massive damage, break the spear, and knock down the target.")

/obj/item/clockwork/weapon/ratvarian_spear/attack(mob/living/target, mob/living/carbon/human/user)
	. = ..()
	if(!QDELETED(target) && target.stat != DEAD && !target.anti_magic_check(chargecost = 0) && !is_servant_of_ratvar(target)) //we do bonus damage on attacks unless they're a servant, have a null rod, or are dead
		var/bonus_damage = bonus_burn //normally a total of 20 damage, 30 with ratvar
		if(issilicon(target))
			target.visible_message(span_warning("[target] shudders violently at [src]'s touch!"), span_userdanger("ERROR: Temperature rising!"))
			bonus_damage *= 5 //total 40 damage on borgs, 70 with ratvar
		else if(iscultist(target) || isconstruct(target))
			to_chat(target, span_userdanger("Your body flares with agony at [src]'s presence!"))
			bonus_damage *= 3 //total 30 damage on cultists, 50 with ratvar
		GLOB.clockwork_vitality += target.adjustFireLoss(bonus_damage) //adds the damage done to existing vitality

/obj/item/clockwork/weapon/ratvarian_spear/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/turf/T = get_turf(hit_atom)
	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(is_servant_of_ratvar(L))
			if(L.put_in_active_hand(src))
				L.visible_message(span_warning("[L] catches [src] out of the air!"))
			else
				L.visible_message(span_warning("[src] bounces off of [L], as if repelled by an unseen force!"))
		else if(!..())
			if(!L.anti_magic_check())
				if(issilicon(L) || iscultist(L))
					L.Paralyze(100)
				else
					L.Paralyze(40)
				GLOB.clockwork_vitality += L.adjustFireLoss(bonus_burn * 3) //normally a total of 40 damage, 70 with ratvar
			break_spear(T)
	else
		..()

/obj/item/clockwork/weapon/ratvarian_spear/proc/break_spear(turf/T)
	if(src)
		if(!T)
			T = get_turf(src)
		if(T) //make sure we're not in null or something
			T.visible_message(span_warning("[src] [pick("cracks in two and fades away", "snaps in two and dematerializes")]!"))
			new /obj/effect/temp_visual/ratvar/spearbreak(T)
			qdel(src)
		action.weapon_reset(RATVARIAN_SPEAR_COOLDOWN)
