//mob verbs are faster than object verbs. See mob/verb/examine.
/mob/living/verb/pulled(atom/movable/AM as mob|obj in oview(1))
	set name = "Pull"
	set category = "Object"

	if(AM.Adjacent(src))
		src.start_pulling(AM)

	return

/mob/living/proc/flash(duration = 0, drop_items = FALSE, doblind = FALSE, doblurry = FALSE)
	if(blinded)
		return
	if (HUDtech.Find("flash"))
		flick("e_flash", HUDtech["flash"])
	if(duration || drop_items)
		Weaken(duration, drop_items)
	if(doblind)
		eye_blind += duration
	if(doblurry)
		eye_blurry += duration

//mob verbs are faster than object verbs. See above.
/mob/living/pointed(atom/A as mob|obj|turf in view())
	if(src.stat || !src.canmove || src.restrained())
		return FALSE
	if(src.status_flags & FAKEDEATH)
		return FALSE
	if(!..())
		return FALSE

	usr.visible_message("<b>[src]</b> points to [A]")
	return TRUE

/*one proc, four uses
swapping: if it's 1, the mobs are trying to switch, if 0, non-passive is pushing passive
default behaviour is:
 - non-passive mob passes the passive version
 - passive mob checks to see if its mob_bump_flag is in the non-passive's mob_bump_flags
 - if si, the proc returns
*/
/mob/living/proc/can_move_mob(mob/living/swapped, swapping = 0, passive = 0)
	if(!swapped)
		return TRUE
	if(!passive)
		return swapped.can_move_mob(src, swapping, 1)
	else
		var/context_flags = 0
		if(swapping)
			context_flags = swapped.mob_swap_flags
		else
			context_flags = swapped.mob_push_flags
		if(!mob_bump_flag) //nothing defined, go wild
			return TRUE
		if(mob_bump_flag & context_flags)
			return TRUE
		return FALSE

/mob/living/Bump(atom/movable/AM, yes)
	spawn(0)
		if ((!( yes ) || now_pushing) || !loc)
			return
		now_pushing = TRUE
		if (isliving(AM))
			var/mob/living/tmob = AM

			for(var/mob/living/M in range(tmob, 1))
				if(tmob.pinned.len ||  ((M.pulling == tmob && ( tmob.restrained() && !( M.restrained() ) && M.stat == 0)) || locate(/obj/item/grab, tmob.grabbed_by.len)) )
					if ( !(world.time % 5) )
						to_chat(src, "<span class='warning'>[tmob] is restrained, you cannot push past</span>")
					now_pushing = FALSE
					return
				if( tmob.pulling == M && ( M.restrained() && !( tmob.restrained() ) && tmob.stat == 0) )
					if ( !(world.time % 5) )
						to_chat(src, "<span class='warning'>[tmob] is restraining [M], you cannot push past</span>")
					now_pushing = FALSE
					return

			//Leaping mobs just land on the tile, no pushing, no anything.
			if(status_flags & LEAPING)
				loc = tmob.loc
				status_flags &= ~LEAPING
				now_pushing = FALSE
				return

			if(can_swap_with(tmob)) // mutual brohugs all around!
				var/turf/oldloc = loc
				forceMove(tmob.loc)
				tmob.forceMove(oldloc)
				now_pushing = FALSE
				for(var/mob/living/carbon/slime/slime in view(1,tmob))
					if(slime.Victim == tmob)
						slime.UpdateFeed()
				return

			if(!can_move_mob(tmob, 0, 0))
				now_pushing = FALSE
				return
			if(a_intent == I_HELP || src.restrained())
				now_pushing = FALSE
				return
			if(ishuman(tmob) && (FAT in tmob.mutations))
				if(prob(40) && !(FAT in src.mutations))
					to_chat(src, "<span class='danger'>You fail to push [tmob]'s fat ass out of the way.</span>")
					now_pushing = FALSE
					return
			if(tmob.r_hand && istype(tmob.r_hand, /obj/item/shield/riot))
				if(prob(99))
					now_pushing = FALSE
					return
			if(tmob.l_hand && istype(tmob.l_hand, /obj/item/shield/riot))
				if(prob(99))
					now_pushing = FALSE
					return
			if(!(tmob.status_flags & CANPUSH))
				now_pushing = FALSE
				return

			tmob.LAssailant_weakref = WEAKREF(src)

		now_pushing = FALSE
		spawn(0)
			..()
			if (!istype(AM, /atom/movable))
				return
			if (!now_pushing)
				now_pushing = TRUE

				if (!AM.anchored)
					var/t = get_dir(src, AM)
					if (istype(AM, /obj/structure/window))
						for(var/obj/structure/window/win in get_step(AM,t))
							now_pushing = FALSE
							return
					step_glide(AM, t, glide_size)
					if(ishuman(AM) && AM:grabbed_by)
						for(var/obj/item/grab/G in AM:grabbed_by)
							step_glide(G:assailant, get_dir(G:assailant, AM), glide_size)
							G.adjust_position()
				now_pushing = FALSE
			return
	return

/proc/swap_density_check(mob/swapper, mob/swapee)
	var/turf/T = get_turf(swapper)
	if(!T) return TRUE //If there's nothing there, feel free to move.
	if(T.density)
		return TRUE
	for(var/atom/movable/A in T)
		if(A == swapper)
			continue
		if(!A.CanPass(swapee, T, 1))
			return TRUE

/mob/living/proc/can_swap_with(mob/living/tmob)
	if(tmob.buckled || buckled)
		return FALSE
	//BubbleWrap: people in handcuffs are always switched around as if they were on 'help' intent to prevent a person being pulled from being seperated from their puller
	if(!(tmob.mob_always_swap || (tmob.a_intent == I_HELP || tmob.restrained()) && (a_intent == I_HELP || src.restrained())))
		return FALSE
	if(!tmob.canmove || !canmove)
		return FALSE

	if(swap_density_check(src, tmob))
		return FALSE

	if(swap_density_check(tmob, src))
		return FALSE

	return can_move_mob(tmob, 1, 0)

/mob/living/verb/succumb()
	set hidden = TRUE
	if (health < 0) // Health below Zero but above 5-away-from-death, as before, but variable
		adjustOxyLoss(health + maxHealth * 2) // Deal 2x health in OxyLoss damage, as before but variable.
		health = -maxHealth
		to_chat(src, "\blue You have given up life and succumbed to death.")


/mob/living/proc/updatehealth()
	if(status_flags & GODMODE)
		health = 100
		stat = CONSCIOUS
	else
		health = maxHealth - getOxyLoss() - getToxLoss() - getFireLoss() - getBruteLoss() - getCloneLoss() - halloss

//This proc is used for mobs which are affected by pressure to calculate the amount of pressure that actually
//affects them once clothing is factored in. ~Errorage
/mob/living/proc/calculate_affecting_pressure(pressure)
	return

//sort of a legacy burn method for /electrocute, /shock, and the e_chair
/mob/living/proc/burn_skin(burn_amount)

/mob/living/carbon/human/burn_skin(burn_amount)
	//world << "DEBUG: burn_skin(), mutations=[mutations]"
	if(mShock in mutations) //shockproof
		return FALSE
	if (COLD_RESISTANCE in mutations) //fireproof
		return FALSE
	var/divided_damage = (burn_amount)/(organs.len)
	var/extradam = 0	//added to when organ is at max dam
	for(var/obj/item/organ/external/affecting in organs)
		//TODO: fix the extradam stuff. Or, ebtter yet...rewrite this entire proc ~Carn
		if(affecting.take_damage(divided_damage+extradam, BURN))
			UpdateDamageIcon()
	updatehealth()
	return TRUE

/mob/living/silicon/ai/burn_skin()
	return FALSE

/mob/living/proc/adjustBodyTemp(actual, desired, incrementboost)
	var/temperature = actual
	var/difference = abs(actual-desired)	//get difference
	var/increments = difference/10 //find how many increments apart they are
	var/change = increments*incrementboost	// Get the amount to change by (x per increment)

	// Too cold
	if(actual < desired)
		temperature += change
		if(actual > desired)
			temperature = desired
	// Too hot
	if(actual > desired)
		temperature -= change
		if(actual < desired)
			temperature = desired
	return temperature


// ++++ROCKDTBEN++++ MOB PROCS -- Ask me before touching.
// Stop! ... Hammertime! ~Carn
// I touched them without asking... I'm soooo edgy ~Erro (added nodamage checks)

/mob/living/proc/getBruteLoss()
	return bruteloss

/mob/living/proc/adjustBruteLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	bruteloss = min(max(bruteloss + amount, 0),(maxHealth*2))

/mob/living/proc/getOxyLoss()
	return oxyloss

/mob/living/proc/adjustOxyLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	oxyloss = min(max(oxyloss + amount, 0),(maxHealth*2))

/mob/living/proc/setOxyLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	oxyloss = amount

/mob/living/proc/getToxLoss()
	return toxloss

/mob/living/proc/adjustToxLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	toxloss = min(max(toxloss + amount, 0),(maxHealth*2))

/mob/living/proc/setToxLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	toxloss = amount

/mob/living/proc/getFireLoss()
	return fireloss

/mob/living/proc/adjustFireLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	fireloss = min(max(fireloss + amount, 0),(maxHealth*2))

/mob/living/proc/getCloneLoss()
	return cloneloss

/mob/living/proc/adjustCloneLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	cloneloss = min(max(cloneloss + amount, 0),(maxHealth*2))

/mob/living/proc/setCloneLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	cloneloss = amount

/mob/living/proc/getBrainLoss()
	return brainloss

/mob/living/proc/adjustBrainLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	brainloss = min(max(brainloss + amount, 0),(maxHealth*2))

/mob/living/proc/setBrainLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	brainloss = amount

/mob/living/proc/getHalLoss()
	return halloss

/mob/living/proc/adjustHalLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	halloss = min(max(halloss + amount, 0),(maxHealth*2))

/mob/living/proc/setHalLoss(amount)
	if(status_flags & GODMODE)
		return FALSE	//godmode
	halloss = amount

/mob/living/proc/getmaxHealth()
	return maxHealth

/mob/living/proc/setmaxHealth(newmaxHealth)
	maxHealth = newmaxHealth

/mob/living/proc/get_limb_efficiency(bodypartdefine)
	return 100

/mob/living/proc/get_specific_organ_efficiency(process_define, parent_organ_tag)
	return 100

/mob/living/proc/Stuttering(amount)
	stuttering = max(max(stuttering,amount),0)
	return

/mob/living/proc/SetStuttering(amount)
	stuttering = max(amount,0)
	return

/mob/living/proc/AdjustStuttering(amount)
	stuttering = max(stuttering + amount,0)
	return

// ++++ROCKDTBEN++++ MOB PROCS //END

/mob/get_contents()
	return contents


//Recursive function to find everything a mob is holding.
/mob/living/get_contents(obj/item/storage/Storage = null)
	var/list/L = list()

	if(Storage) //If it called itself
		L += Storage.return_inv()

		//Leave this commented out, it will cause storage items to exponentially add duplicate to the list
		//for(var/obj/item/storage/S in Storage.return_inv()) //Check for storage items
		//	L += get_contents(S)

		for(var/obj/item/gift/G in Storage.return_inv()) //Check for gift-wrapped items
			L += G.gift
			if(istype(G.gift, /obj/item/storage))
				L += get_contents(G.gift)

		for(var/obj/item/smallDelivery/D in Storage.return_inv()) //Check for package wrapped items
			L += D.wrapped
			if(istype(D.wrapped, /obj/item/storage)) //this should never happen
				L += get_contents(D.wrapped)

		for(var/obj/item/clothing/C in Storage.return_inv())//Check for pockets and shoe knifes
			L += get_contents(C)

		for(var/obj/item/rig/R in Storage.return_inv()) //Check for rig modules basically
			L += get_contents(R)

		for(var/obj/item/rig_module/RM in Storage.return_inv()) //Check stuff in rig storage
			L += RM.get_contents(RM)

		return L

	else

		L += src.contents
		for(var/obj/item/storage/S in src.contents)	//Check for storage items
			L += get_contents(S)

		for(var/obj/item/clothing/C in src.contents)	//Check for pockets and shoe knifes
			L += get_contents(C)

		for(var/obj/item/rig/R in src.contents) //Check for rig modules basically
			L += get_contents(R)

		for(var/obj/item/rig_module/RM in src.contents) //Check stuff in rig storage
			L += get_contents(RM)

		for(var/obj/item/gift/G in src.contents) //Check for gift-wrapped items
			L += G.gift
			if(istype(G.gift, /obj/item/storage))
				L += get_contents(G.gift)

		for(var/obj/item/smallDelivery/D in src.contents) //Check for package wrapped items
			L += D.wrapped
			if(istype(D.wrapped, /obj/item/storage)) //this should never happen
				L += get_contents(D.wrapped)
		return L

/mob/living/proc/check_contents_for(A)
	var/list/L = src.get_contents()

	for(var/obj/B in L)
		if(B.type == A)
			return TRUE
	return FALSE


/mob/living/proc/can_inject(mob/user, error_msg, target_zone)
	return TRUE

/mob/living/is_injectable(allowmobs = TRUE)
	return (allowmobs && reagents && can_inject())

/mob/living/is_drawable(allowmobs = TRUE)
	return (allowmobs && reagents && can_inject())


/mob/living/proc/get_organ_target()
	var/mob/shooter = src
	var/t = shooter:targeted_organ
	if(t in list(BP_EYES, BP_MOUTH))
		t = BP_HEAD
	var/obj/item/organ/external/def_zone = ran_zone(t)
	return def_zone



/mob/living/proc/restore_all_organs()
	return

/mob/living/proc/revive()
	rejuvenate()
	if(buckled)
		buckled.unbuckle_mob()
	if(iscarbon(src))
		var/mob/living/carbon/C = src

		if (C.handcuffed && !initial(C.handcuffed))
			C.drop_from_inventory(C.handcuffed)
		C.handcuffed = initial(C.handcuffed)

		if (C.legcuffed && !initial(C.legcuffed))
			C.drop_from_inventory(C.legcuffed)
		C.legcuffed = initial(C.legcuffed)
	BITSET(hud_updateflag, HEALTH_HUD)
	BITSET(hud_updateflag, STATUS_HUD)
	BITSET(hud_updateflag, LIFE_HUD)
	ExtinguishMob()
	fire_stacks = 0

/mob/living/proc/rejuvenate()
	if (reagents)
		reagents.clear_reagents()

	// shut down various types of badness
	setToxLoss(0)
	setOxyLoss(0)
	setCloneLoss(0)
	setBrainLoss(0)
	SetParalysis(0)
	SetStunned(0)
	SetWeakened(0)
	setHalLoss(0)

	// shut down ongoing problems
	radiation = 0
	bodytemperature = T20C
	sdisabilities = 0
	disabilities = 0

	// fix blindness and deafness
	blinded = 0
	eye_blind = 0
	eye_blurry = 0
	ear_deaf = 0
	ear_damage = 0
	heal_overall_damage(getBruteLoss(), getFireLoss())

	// fix all of our organs
	restore_all_organs()

	// remove the character from the list of the dead
	if(stat == DEAD)
		GLOB.dead_mob_list -= src
		GLOB.living_mob_list += src
		tod = null
		timeofdeath = 0

	// restore us to conciousness
	stat = CONSCIOUS

	// make the icons look correct
	regenerate_icons()

	BITSET(hud_updateflag, HEALTH_HUD)
	BITSET(hud_updateflag, STATUS_HUD)
	BITSET(hud_updateflag, LIFE_HUD)

	failed_last_breath = 0 //So mobs that died of oxyloss don't revive and have perpetual out of breath.

	return

/mob/living/proc/UpdateDamageIcon()
	return

/mob/living/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0)
	if (buckled)
		return

	if (restrained())
		stop_pulling()


	var/t7 = 1
	if (restrained())
		for(var/mob/living/M in range(src, 1))
			if ((M.pulling == src && M.stat == 0 && !( M.restrained() )))
				t7 = null
	if ((t7 && (pulling && ((get_dist(src, pulling) <= 1 || pulling.loc == loc) && (moving)))))
		var/turf/T = loc
		. = ..()

		if (pulling && pulling.loc)
			if(!(isturf(pulling.loc)))
				stop_pulling()
				return

		/////
		if(pulling && pulling.anchored)
			stop_pulling()
			return

		if (!restrained())
			var/diag = get_dir(src, pulling)
			if ((diag - 1) & diag)
			else
				diag = null
			if ((get_dist(src, pulling) > 1 || diag))
				if (isliving(pulling))
					var/mob/living/M = pulling
					var/ok = 1
					if (locate(/obj/item/grab, M.grabbed_by))
						if (prob(75))
							var/obj/item/grab/G = pick(M.grabbed_by)
							if (istype(G, /obj/item/grab))
								for(var/mob/O in viewers(M, null))
									O.show_message(text("\red [] has been pulled from []'s grip by []", G.affecting, G.assailant, src), 1)
								//G = null
								qdel(G)
						else
							ok = 0
						if (locate(/obj/item/grab, M.grabbed_by.len))
							ok = 0
					if (ok)
						var/atom/movable/t = M.pulling
						M.stop_pulling()

						if(!istype(M.loc, /turf/space))
							var/area/A = get_area(M)
							if(A.has_gravity)
								//this is the gay blood on floor shit -- Added back -- Skie
								if(M.lying && (prob(M.getBruteLoss() / 6)))
									var/turf/location = M.loc
									if (istype(location, /turf/simulated))
										location.add_blood(M)
								//pull damage with injured people
									if(prob(25))
										M.adjustBruteLoss(1)
										visible_message("<span class='danger'>\The [M]'s [M.isSynthetic() ? "state worsens": "wounds open more"] from being dragged!</span>")
								if(M.pull_damage())
									if(prob(25))
										M.adjustBruteLoss(2)
										visible_message("<span class='danger'>\The [M]'s [M.isSynthetic() ? "state" : "wounds"] worsen terribly from being dragged!</span>")
										var/turf/location = M.loc
										if(istype(location, /turf/simulated))
											if(ishuman(M))
												var/mob/living/carbon/human/H = M
												var/blood_volume = round(H.vessel.get_reagent_amount("blood"))
												if(blood_volume > 0)
													H.vessel.remove_reagent("blood", 0.5)
													location.add_blood(M)

						step_glide(pulling, get_dir(pulling.loc, T), glide_size)
						if(t)
							M.start_pulling(t)
				else
					if (pulling)
						if (istype(pulling, /obj/structure/window))
							var/obj/structure/window/W = pulling
							if(W.is_full_window())
								for(var/obj/structure/window/win in get_step(pulling,get_dir(pulling.loc, T)))
									stop_pulling()
					if (pulling)
						step_glide(pulling, get_dir(pulling.loc, T), glide_size)
	else
		stop_pulling()
		. = ..()

	if (s_active && !( s_active in contents ) && get_turf(s_active) != get_turf(src))	//check !( s_active in contents ) first so we hopefully don't have to call get_turf() so much.
		s_active.close(src)

	step_count++

	if(update_slimes)
		for(var/mob/living/carbon/slime/M in view(1,src))
			M.UpdateFeed(src)

/mob/living/verb/lay_down()
	set name = "Rest"
	set category = "IC"

	if(is_busy)
		return FALSE

	var/mob/living/carbon/human/H = ishuman(src) ? src : null


	if(resting)
		is_busy = TRUE

		if(do_after(src, (stats.getPerk(PERK_PARKOUR) ? 0.2 SECONDS : 0.4 SECONDS), null, 0, 1, INCAPACITATION_DEFAULT, immobile = 0))
			resting = FALSE
			to_chat(src, SPAN_NOTICE("You are now getting up."))
			update_lying_buckled_and_verb_status()

		is_busy = FALSE

	else if(H && H.momentum_speed && !(istype(loc, /turf/space) || grabbed_by.len))
		H.dive()

	else
		resting = TRUE
		to_chat(src, SPAN_NOTICE("You are now resting."))
		update_lying_buckled_and_verb_status()

/mob/living/carbon/human/proc/dive()
	var/client/C = client
	resting = TRUE
	var/_dir = C.true_dir

//The sanity! - SoJ edits
	var/_hunger = (MOB_BASE_MAX_HUNGER - nutrition)
	if(_hunger >= 250) //Will be shown on overlay as orange nutrition
		to_chat(src, SPAN_WARNING("You weakly slump down!")) //You fall down because the rest still procs; a huge disadvantage
		return

	if(ishuman(src) && !weakened && (_dir))// If true_dir = 0(src isn't moving), doesn't proc.
		var/mob/living/carbon/human/H = src
		if(H.handcuffed || H.legcuffed)
			to_chat(H, SPAN_NOTICE("You can't dive while cuffed!"))
			return

		if(H.grabbed_by.len)
			to_chat(H, SPAN_NOTICE("You can't dive while grappled!"))
			return

		if(H.stat != CONSCIOUS)
			to_chat(H, SPAN_NOTICE("You can't dive while unconcious!"))
			return

		if(buckled)
			to_chat(H, SPAN_NOTICE("You can't dive while buckled!"))
			return

		if(40 >= health)
			to_chat(H, SPAN_NOTICE("You are too hurt to dive!"))
			return
//End of SoJ edits
	if(!weakened && _dir)// If true_dir = 0(src isn't moving), doesn't proc.
		if(momentum_dir == _dir)
			livmomentum = momentum_speed // Set momentum value as soon as possible for stopSliding to work better
		var/range = 1 //checks for move intent; dive one tile further if on run intent

		// Diving
		to_chat(src, SPAN_NOTICE("You dive onwards!"))
		pass_flags += PASSTABLE // Jump over them!
		allow_spin = FALSE
		if(istype(get_step(src, _dir), /turf/simulated/open))
			range++
		if(momentum_speed > 4)
			range++
		throw_at(get_edge_target_turf(src, _dir), range, 1) // If you dive over a table, your momentum is set to 0. If you dive over space, you are thrown 1 tile further.
		update_lying_buckled_and_verb_status()
		pass_flags -= PASSTABLE // Jumpn't over them anymore!
		allow_spin = TRUE
		if(!species.reagent_tag == IS_SYNTHETIC)
			var/par_core = learnt_tasks.get_task_mastery_level("PARCOURS")
			var/hunger_to_take = clamp(25 - par_core, 0, 25)
			nutrition -= hunger_to_take  //SOJ EDIT: WE TAKE HUNER
			learnt_tasks.attempt_add_task_mastery(/datum/task_master/task/parcours, "PARCOURS", skill_gained = range, learner = src)

		// Slide
		sleep(1.5)
		C.mloop = 1
		while(livmomentum > 0 && C.true_dir)
			Move(get_step(loc, _dir),dir)
			livmomentum--
			sleep(world.tick_lag + 0.5)
		C.mloop = 0

/mob/living/simple/spiderbot/is_allowed_vent_crawl_item(obj/item/carried_item)
	if(carried_item == held_item)
		return FALSE
	return ..()

/mob/living/carbon/human/verb/stopSliding()
	set hidden = 1
	set instant = 1
	livmomentum = 0

/mob/living/proc/cannot_use_vents()
	return "You can't fit into that vent."

/mob/living/proc/has_brain()
	return TRUE

/mob/living/proc/has_eyes()
	return TRUE

/mob/living/proc/slip(slipped_on,stun_duration=8)
	return FALSE

/mob/living/proc/trip(tripped_on, stun_duration)
	return FALSE


//damage/heal the mob ears and adjust the deaf amount
/mob/living/adjustEarDamage(damage, deaf)
	ear_damage = max(0, ear_damage + damage)
	ear_deaf = max(0, ear_deaf + deaf)

//pass a negative argument to skip one of the variable
/mob/living/setEarDamage(damage, deaf)
	if(damage >= 0)
		ear_damage = damage
	if(deaf >= 0)
		ear_deaf = deaf

/mob/living/proc/can_feel_pain(check_organ)
	if(isSynthetic())
		return FALSE
	return TRUE

/mob/proc/can_be_possessed_by(mob/observer/ghost/possessor)
	return istype(possessor) && possessor.client

/mob/living/can_be_possessed_by(mob/observer/ghost/possessor, animal_check = TRUE)
	if(!..())
		return FALSE
	if(!possession_candidate)
		to_chat(possessor, "<span class='warning'>That animal cannot be possessed.</span>")
		return FALSE
	if(jobban_isbanned(possessor, "Animal") && animal_check)
		to_chat(possessor, "<span class='warning'>You are banned from animal roles.</span>")
		return FALSE
	if(!possessor.MayRespawn(0 ,ANIMAL))
		return FALSE
	return TRUE

/mob/living/proc/do_possession(mob/observer/ghost/possessor)

	if(!(istype(possessor) && possessor.ckey))
		return FALSE

	if(src.ckey || src.client)
		to_chat(possessor, "<span class='warning'>\The [src] already has a player.</span>")
		return FALSE

	message_admins("<span class='adminnotice'>[key_name_admin(possessor)] has taken control of \the [src].</span>")
	log_admin("[key_name(possessor)] took control of \the [src].")
	src.ckey = possessor.ckey
	qdel(possessor)

	to_chat(src, "<b>You are now \the [src]!</b>")
	to_chat(src, "<span class='notice'>Remember to stay in character for a mob of this type!</span>")
	return TRUE

/mob/living/reset_layer()
	if(hiding)
		set_plane(HIDING_MOB_PLANE)
		layer = HIDING_MOB_LAYER
	else
		..()

/mob/living/throw_mode_off()
	src.in_throw_mode = 0
	if (HUDneed.Find("throw"))
		var/obj/screen/HUDthrow/HUD = HUDneed["throw"]
		HUD.update_icon()

/mob/living/throw_mode_on()
	src.in_throw_mode = 1
	if (HUDneed.Find("throw"))
		var/obj/screen/HUDthrow/HUD = HUDneed["throw"]
		HUD.update_icon()

/mob/living/start_pulling(atom/movable/AM)

	if (!AM || !usr || src==AM || !isturf(src.loc))	//if there's no person pulling OR the person is pulling themself OR the object being pulled is inside something: abort!
		return

	if (AM.anchored)
		to_chat(src, "<span class='warning'>It won't budge!</span>")
		return

	if (AM.cant_be_pulled)
		return

	var/mob/M = AM
	if(ismob(AM))

		if(!can_pull_mobs || !can_pull_size)
			to_chat(src, "<span class='warning'>It won't budge!</span>")
			return

		if((mob_size < M.mob_size) && (can_pull_mobs != MOB_PULL_LARGER))
			to_chat(src, "<span class='warning'>It won't budge!</span>")
			return

		if((mob_size == M.mob_size) && (can_pull_mobs == MOB_PULL_SMALLER))
			to_chat(src, "<span class='warning'>It won't budge!</span>")
			return

		// If your size is larger than theirs and you have some
		// kind of mob pull value AT ALL, you will be able to pull
		// them, so don't bother checking that explicitly.

		if(!iscarbon(src))
			M.LAssailant_weakref = null
		else
			M.LAssailant_weakref = WEAKREF(usr)

	else if(isobj(AM))
		var/obj/I = AM
		if(!can_pull_size || can_pull_size < I.w_class)
			to_chat(src, "<span class='warning'>It won't budge!</span>")
			return

	if(pulling)
		var/pulling_old = pulling
		stop_pulling()
		// Are we pulling the same thing twice? Just stop pulling.
		if(pulling_old == AM)
			return

	src.pulling = AM
	AM.pulledby = src

	if (HUDneed.Find("pull"))
		var/obj/screen/HUDthrow/HUD = HUDneed["pull"]
		HUD.update_icon()

	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(H.pull_damage())
			to_chat(src, "\red <B>Pulling \the [H] in their current condition would probably be a bad idea.</B>")

	//Attempted fix for people flying away through space when cuffed and dragged.
	if(ismob(AM))
		var/mob/pulled = AM
		pulled.inertia_dir = 0

// Static over-lays and Stats

/mob/living/proc/generate_static_overlay()
	static_overlay = image(get_static_icon(new/icon(icon, icon_state)), loc = src)
	static_overlay.override = 1

/mob/living/New()
	..()

	//Some mobs may need to create their stats datum farther up
	if (!stats)
		stats = new /datum/stat_holder(src)


	//Mutations populated through horrendous genetic tampering.
	unnatural_mutations = new(src)

	//Skills and mastery holder
	learnt_tasks = new(src)

	generate_static_overlay()
	for(var/mob/observer/eye/angel/A in GLOB.player_list)
		if(A)
			A.static_overlays |= static_overlay
			A.client.images |= static_overlay

	var/turf/T = get_turf(src)
	if(T)
		update_z(T.z)

/mob/living/Destroy()

	for (var/obj/effect/bmode/buildholder/selector in selected_by)
		selector.selected_mobs -= src
	selected_by.Cut()

	for (var/group in groups_in)
		GLOB.mob_groups[group] -= src
	groups_in.Cut()

	QDEL_NULL(stats)

	static_overlay.loc = null
	static_overlay.transform = null
	QDEL_NULL(static_overlay)

	unnatural_mutations = null //causes a GC failure if we qdel-and it seems its not SUPPOSED to qdel, oddly

	learnt_tasks = null

	if(registered_z)
		SSmobs.mob_living_by_zlevel[registered_z] -= src	// STOP_PROCESSING() doesn't remove the mob from this list

	update_z(null)

	destroy_HUD() //this should fix the harddel on humans
	. = ..()

/mob/living/proc/vomit()
	return

/mob/living/proc/adjustNutrition(amount, mob/living/carbon/human/H)
	if(H)
		if(H.species.reagent_tag == IS_SYNTHETIC)
			return
	nutrition += amount
	nutrition = max(0,min(nutrition, max_nutrition))	//clamp the value

/mob/living/proc/is_asystole()
	return FALSE

//Makes a creature drop loot if they have any set
//must be called manually in death()
/mob/living/proc/drop_death_loot()
	if(drop_items)
		for(var/drop_item in drop_items)
			if(ispath(drop_item, /obj))
				new drop_item(src.loc)
		drop_items = null

//Makes a blood drop, leaking amt units of blood from the mob
/mob/living/proc/drip_blood(amt as num)
	blood_splatter(src,src)

/mob/living/proc/eyecheck()
	return 0

/mob/living/proc/earcheck()
	return 0

/mob/living/verb/show_tasks()
	set name		= "Show tasks"
	set desc		= "Browse your character tasks."
	set category	= "IC"
	set src			= usr

	var/list/data = list()
	var/list/tasks = learnt_tasks.learnt_tasks
	if(LAZYLEN(tasks))
		for(var/task in tasks)
			var/datum/task_master/task/T = task
			data["tasks"] += list(list(
				"name" = T.name,
				"desc" = T.desc,
				"value" = T.value,
				"level_threshold" = T.level_thresholds,
				"level" = T.level
			))

	var/datum/nanoui/ui = new(usr, src, "main", "tasks.tmpl", "Tasks", 500, 300)
	ui.set_initial_data(data)	// when the ui is first opened this is the data it will use
	ui.open()					// open the new ui window
