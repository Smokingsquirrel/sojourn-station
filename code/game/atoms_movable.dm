/atom/movable
	layer = OBJ_LAYER
	var/last_move = null
	var/anchored = 0
	// var/elevation = 2    - not used anywhere
	var/move_speed = 10
	var/l_move_time = 1
	var/m_flag = 1
	var/throwing = 0
	var/thrower
	var/turf/throw_source = null
	var/throw_speed = 2
	var/throw_range = 7
	var/moved_recently = 0
	var/mob/pulledby = null
	var/item_state = null // Used to specify the item state for the on-mob over-lays.
	var/inertia_dir = 0
	///Holds information about any movement loops currently running/waiting to run on the movable. Lazy, will be null if nothing's going on
	var/datum/movement_packet/move_packet
	var/can_anchor = TRUE
	var/cant_be_pulled = FALSE //Used for things that cant be anchored, but also shouldnt be pullable

	/// Used in SSmove_manager.move_to. Set to world.time whenever a walk is called that uses temporary_walk = TRUE. Prevents walks that dont respect the override from conflicting with eachother.
	var/walk_to_initial_time = 0

	/// Used in SSmove_manager.move_to. If something with an override is called, it will set it to world.time + the value of override in the proc, and any walks that respect the override after will return until world.time is more than the var.
	var/walk_override_timer = 0

	//spawn_values
	var/price_tag = 0 // The item price in credits. atom/movable so we can also assign a price to animals and other thing.
	var/surplus_tag = FALSE //If true, attempting to export this will net you a greatly reduced amount of credits, but we don't want to affect the actual price tag for selling to others.
	var/spawn_tags

	/**
	 * Associative list. Key should be a typepath of /datum/stat_modifier, and the value should be a weight for use in prob.
	 *
	 * NOTE: Arguments may be passed to certain modifiers. To do this, change the value to this: list(prob, ...) where prob is the probability and ... are any arguments you want passed.
	**/
	var/list/allowed_stat_modifiers = null

	/// List of all instances of /datum/stat_modifier that have been applied in /datum/stat_modifier/proc/apply_to(). Should never have more instances of one typepath than that typepath's maximum_instances var.
	var/list/current_stat_modifiers = null

	/// List of all stored prefixes. Used for stat_modifiers, on everything but tools and guns, which use them for attachments.
	var/list/name_prefixes = null

	var/get_stat_modifier = FALSE
	var/times_to_get_stat_modifiers = 1
	var/get_prefix = TRUE

	var/fancy_glide = FALSE //Max is 6
	var/fancy_glide_colour
	var/fancy_glide_custom_frames = FALSE

/atom/movable/Initialize()
	. = ..()
	init_stat_modifiers()

/atom/movable/proc/init_stat_modifiers()
	if(get_stat_modifier)
		for(var/i in 0 to (times_to_get_stat_modifiers - 1))
			var/list/excavated = list()
			for(var/entry in allowed_stat_modifiers)
				var/to_add = allowed_stat_modifiers[entry]
				if(islist(allowed_stat_modifiers[entry]))
					var/list/entrylist = allowed_stat_modifiers[entry]
					to_add = entrylist[1]
				excavated[entry] = to_add

			var/list/successful_rolls = list()
			for(var/typepath in excavated)
				if(prob(excavated[typepath]))
					successful_rolls += typepath

			var/picked
			if(LAZYLEN(successful_rolls))
				picked = pick(successful_rolls)

			if(isnull(picked))
				continue

			var/list/arguments
			if(islist(allowed_stat_modifiers[picked]))
				var/list/nested_list = allowed_stat_modifiers[picked]
				if(length(nested_list) > 1)
					arguments = nested_list.Copy(2)

			var/datum/stat_modifier/chosen_modifier = new picked
			if(!(chosen_modifier.valid_check(src, arguments)))
				qdel(chosen_modifier)

/atom/movable/Destroy()
	var/turf/T = loc
	if(opacity && istype(T))
		T.reconsider_lights()

	if(move_packet)
		SSmove_manager.stop_looping(src) // not 1:1 with tg movess, niko todo: replace
		if(!QDELETED(move_packet))
			qdel(move_packet)
		move_packet = null

	QDEL_LAZYLIST(current_stat_modifiers)

	. = ..()

	for(var/atom/movable/AM in contents)
		qdel(AM)

	if(loc)
		loc.handle_atom_del(src)

	forceMove(null)
	if (pulledby)
		if (pulledby.pulling == src)
			pulledby.pulling = null
		pulledby = null

	for (var/datum/movement_handler/handler in movement_handlers)
		handler.host = null
		movement_handlers -= handler //likely unneeded but just in case

/atom/movable/examine(mob/user, distance, infix, suffix)
	. = ..()

//Soj Edits
	var/list/descriptions_to_print = list()
	// `in null` is fine, it just won't iterate
	for(var/datum/stat_modifier/mod in current_stat_modifiers)
		if(mod.description)
			if(!(mod.description in descriptions_to_print))
				descriptions_to_print += mod.description
	for(var/description in descriptions_to_print)
		to_chat(user, SPAN_NOTICE(description))


/atom/movable/Bump(var/atom/A, yes)
	if(src.throwing)
		src.throw_impact(A)
		src.throwing = 0

	spawn(0)
		if (A && yes)
			A.last_bumped = world.time
			A.Bumped(src)
		return
	..()
	return

/atom/movable/proc/entered_with_container(var/atom/old_loc)
	return

/atom/movable/proc/forceMove(atom/destination, var/special_event, glide_size_override=0)
	if(loc == destination)
		return 0

	if (glide_size_override)
		set_glide_size(glide_size_override)

	var/is_origin_turf = isturf(loc)
	var/is_destination_turf = isturf(destination)
	// It is a new area if:
	//  Both the origin and destination are turfs with different areas.
	//  When either origin or destination is a turf and the other is not.
	var/is_new_area = (is_origin_turf ^ is_destination_turf) || (is_origin_turf && is_destination_turf && loc.loc != destination.loc)

	var/atom/origin = loc
	loc = destination

	if(origin)
		origin.Exited(src, destination)
		if(is_origin_turf)
			for(var/atom/movable/AM in origin)
				AM.Uncrossed(src)
			if(is_new_area && is_origin_turf)
				origin.loc.Exited(src, destination)

	if(destination)
		destination.Entered(src, origin, special_event)
		if(is_destination_turf) // If we're entering a turf, cross all movable atoms
			for(var/atom/movable/AM in loc)
				if(AM != src)
					AM.Crossed(src)
			if(is_new_area && is_destination_turf)
				destination.loc.Entered(src, origin)

	SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, origin, loc)

	// Only update plane if we're located on map
	if(isturf(loc))
		// if we wasn't on map OR our Z coord was changed
		if( !isturf(origin) || (get_z(loc) != get_z(origin)) )
			update_plane()

	return 1


//called when src is thrown into hit_atom
/atom/movable/proc/throw_impact(atom/hit_atom, var/speed)
	if(isliving(hit_atom))
		var/mob/living/M = hit_atom
		M.hitby(src,speed)

	else if(isobj(hit_atom))
		var/obj/O = hit_atom
		if(!O.anchored)
			step(O, src.last_move)
		O.hitby(src,speed)

	else if(isturf(hit_atom))
		src.throwing = 0
		var/turf/T = hit_atom
		if(T.density)
			spawn(2)
				step(src, turn(src.last_move, 180))
			if(isliving(src))
				var/mob/living/M = src
				M.turf_collision(T, speed)

//decided whether a movable atom being thrown can pass through the turf it is in.
/atom/movable/proc/hit_check(var/speed)
	if(src.throwing)
		for(var/atom/A in get_turf(src))
			if(A == src) continue
			if(isliving(A))
				if(A:lying) continue
				src.throw_impact(A,speed)
			if(isobj(A))
				if(A.density && !A.throwpass)	// **TODO: Better behaviour for windows which are dense, but shouldn't always stop movement
					src.throw_impact(A,speed)

/atom/movable/proc/throw_at(atom/target, range, speed, thrower)
	if(!target || !src)	return 0
	//use a modified version of Bresenham's algorithm to get from the atom's current position to that of the target

	set_dir(pick(cardinal))
	src.throwing = 1
	if(target.allow_spin && src.allow_spin)
		SpinAnimation(5,1)
	src.thrower = thrower
	src.throw_source = get_turf(src)	//store the origin turf

	if(usr)
		if(HULK in usr.mutations)
			src.throwing = 2 // really strong throw!

	var/dist_x = abs(target.x - src.x)
	var/dist_y = abs(target.y - src.y)

	var/dx
	if (target.x > src.x)
		dx = EAST
	else
		dx = WEST

	var/dy
	if (target.y > src.y)
		dy = NORTH
	else
		dy = SOUTH
	var/dist_travelled = 0
	var/dist_since_sleep = 0
	var/area/a = get_area(src.loc)
	if(dist_x > dist_y)
		var/error = dist_x/2 - dist_y

		while(src && target &&((((src.x < target.x && dx == EAST) || (src.x > target.x && dx == WEST)) && dist_travelled < range) || (a && a.has_gravity == 0)  || istype(src.loc, /turf/space)) && src.throwing && istype(src.loc, /turf))
			// only stop when we've gone the whole distance (or max throw range) and are on a non-space tile, or hit something, or hit the end of the map, or someone picks it up
			if(error < 0)
				var/atom/step = get_step(src, dy)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error += dist_x
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)
			else
				var/atom/step = get_step(src, dx)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error -= dist_y
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)
			a = get_area(src.loc)
	else
		var/error = dist_y/2 - dist_x
		while(src && target &&((((src.y < target.y && dy == NORTH) || (src.y > target.y && dy == SOUTH)) && dist_travelled < range) || (a && a.has_gravity == 0)  || istype(src.loc, /turf/space)) && src.throwing && istype(src.loc, /turf))
			// only stop when we've gone the whole distance (or max throw range) and are on a non-space tile, or hit something, or hit the end of the map, or someone picks it up
			if(error < 0)
				var/atom/step = get_step(src, dx)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error += dist_y
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)
			else
				var/atom/step = get_step(src, dy)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error -= dist_x
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)

			a = get_area(src.loc)

	//done throwing, either because it hit something or it finished moving
	var/turf/new_loc = get_turf(src)
	if(new_loc)
		if(isobj(src))
			src.throw_impact(new_loc,speed)
		new_loc.Entered(src)
	src.throwing = 0
	src.thrower = null
	src.throw_source = null


//over-lays
/atom/movable/overlay
	var/atom/master = null
	anchored = 1

/atom/movable/overlay/New()
	for(var/x in src.verbs)
		src.verbs -= x
	..()

/atom/movable/overlay/attackby(a, b)
	if (src.master)
		return src.master.attackby(a, b)
	return

/atom/movable/overlay/attack_hand(a, b, c)
	if (src.master)
		return src.master.attack_hand(a, b, c)
	return

/atom/movable/proc/touch_map_edge()
	if(z in GLOB.maps_data.sealed_levels)
		return

	if(config.use_overmap)
		overmap_spacetravel(get_turf(src), src)
		return

	var/move_to_z = src.get_transit_zlevel()
	var/move_to_x = x
	var/move_to_y = y
	if(move_to_z)
		if(x <= TRANSITIONEDGE)
			move_to_x = world.maxx - TRANSITIONEDGE - 2
			move_to_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

		else if (x >= (world.maxx - TRANSITIONEDGE + 1))
			move_to_x = TRANSITIONEDGE + 1
			move_to_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

		else if (y <= TRANSITIONEDGE)
			move_to_y = world.maxy - TRANSITIONEDGE -2
			move_to_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

		else if (y >= (world.maxy - TRANSITIONEDGE + 1))
			move_to_y = TRANSITIONEDGE + 1
			move_to_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

		forceMove(locate(move_to_x, move_to_y, move_to_z))

//by default, transition randomly to another zlevel
/atom/movable/proc/get_transit_zlevel()
	var/list/candidates = GLOB.maps_data.accessable_levels.Copy()
	candidates.Remove("[src.z]")

	//If something was ejected from the ship, it does not end up on another part of the ship.
	if (z in GLOB.maps_data.station_levels)
		for (var/n in GLOB.maps_data.station_levels)
			candidates.Remove("[n]")

	if(!candidates.len)
		return null
	return text2num(pickweight(candidates))


/atom/movable/proc/set_glide_size(glide_size_override = 0, var/min = 0.2, var/max = world.icon_size/2)
	if (!glide_size_override || glide_size_override > max)
		glide_size = 0
	else
		glide_size = max(min, glide_size_override)

/*	for (var/atom/movable/AM in contents)
		AM.set_glide_size(glide_size, min, max)
*/

//This proc should never be overridden elsewhere at /atom/movable to keep directions sane.
// Spoiler alert: it is, in moved.dm
/atom/movable/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, var/glide_size_override = 0)
	if (glide_size_override > 0)
		set_glide_size(glide_size_override)

	// To prevent issues, diagonal movements are broken up into two cardinal movements.

	// Is this a diagonal movement?
	LEGACY_SEND_SIGNAL(src, COMSIG_MOVABLE_PREMOVE, src)
	if (Dir & (Dir - 1))
		if (Dir & NORTH)
			if (Dir & EAST)
				// Pretty simple really, try to move north -> east, else try east -> north
				// Pretty much exactly the same for all the other cases here.
				if (step(src, NORTH))
					step(src, EAST)
					dir = NORTHEAST
				else
					if (step(src, EAST))
						step(src, NORTH)
						dir = NORTHEAST
			else
				if (Dir & WEST)
					if (step(src, NORTH))
						step(src, WEST)
						dir = NORTHWEST
					else
						if (step(src, WEST))
							step(src, NORTH)
							dir = NORTHWEST
		else
			if (Dir & SOUTH)
				if (Dir & EAST)
					if (step(src, SOUTH))
						step(src, EAST)
						dir = SOUTHEAST
					else
						if (step(src, EAST))
							step(src, SOUTH)
							dir = SOUTHEAST
				else
					if (Dir & WEST)
						if (step(src, SOUTH))
							step(src, WEST)
							dir = SOUTHWEST
						else
							if (step(src, WEST))
								step(src, SOUTH)
								dir = SOUTHWEST
	else
		var/atom/oldloc = src.loc
		var/olddir = dir //we can't override this without sacrificing the rest of movable/New()

		. = ..()

		if(Dir != olddir)
			dir = olddir
			set_dir(Dir)

		src.move_speed = world.time - src.l_move_time
		src.l_move_time = world.time
		src.m_flag = 1

		if (oldloc != src.loc && oldloc && oldloc.z == src.z)
			src.last_move = get_dir(oldloc, src.loc)

		// Only update plane if we're located on map
		if(isturf(loc))

			// if we wasn't on map OR our Z coord was changed
			if( !isturf(oldloc) || (get_z(loc) != get_z(oldloc)) )
				onTransitZ(get_z(oldloc, get_z(loc)))
				update_plane()

			if(fancy_glide && oldloc)
				warpping_affect(oldloc)

		SEND_SIGNAL(src, COMSIG_MOVABLE_MOVED, oldloc, loc)

// Wrapper of step() that also sets glide size to a specific value.
/proc/step_glide(atom/movable/AM, newdir, glide_size_override)
	AM.set_glide_size(glide_size_override)
	return step(AM, newdir)

//We're changing zlevel
/atom/movable/proc/onTransitZ(old_z, new_z)//uncomment when something is receiving this signal
	/*LEGACY_SEND_SIGNAL(src, COMSIG_MOVABLE_Z_CHANGED, old_z, new_z)
	for(var/atom/movable/AM in src) // Notify contents of Z-transition. This can be overridden IF we know the items contents do not care.
		AM.onTransitZ(old_z,new_z)*/

/mob/living/proc/update_z(new_z) // 1+ to register, null to unregister
	if (registered_z != new_z)
		if (registered_z)
			SSmobs.mob_living_by_zlevel[registered_z] -= src
		if (new_z)
			SSmobs.mob_living_by_zlevel[new_z] += src
		registered_z = new_z
// if this returns true, interaction to turf will be redirected to src instead

///Sets the anchored var and returns if it was sucessfully changed or not. Port from eris since I was getting problems currently only used for the bioreactor
/atom/movable/proc/bio_anchored(anchorvalue)
	SHOULD_CALL_PARENT(TRUE)
	if(anchored == anchorvalue || !can_anchor)
		return FALSE
	anchored = anchorvalue
	LEGACY_SEND_SIGNAL(src, COMSIG_ATOM_UNFASTEN, anchored)
	. = TRUE

/atom/movable/proc/preventsTurfInteractions()
	return FALSE

/// First resets the name of the mob to the initial name it had, then adds each prefix in a random order.
/atom/movable/proc/update_prefixes()
	name = initial(src.name) //reset the name so we can accurately re-add prefixes without fear of double prefixes

	for (var/prefix in name_prefixes)
		name = "[prefix] [name]"

//It came to me in a dream, not a 100% sure this can be improved
/atom/movable/proc/warpping_affect(olden_loc)
	if(fancy_glide && move_speed > 0 && olden_loc)
		var/warps //Spefically needs to be zero or more for maths reasons
		for(warps = 0, warps < fancy_glide, warps++)
			if(warps > 6)
				break //Dont do more then 6 as it gets laggy as well as blurry
			if(!QDELETED(src)) //If we are somehow moving well deleted dont do this
				var/assumed_dir = dir
				//Humans can forcefully set face regardless of direction, this ensures that we do the affect in the correct diretion
				if(ishuman(src))
					var/mob/living/carbon/human/H = src
					assumed_dir = H.momentum_dir ?  H.momentum_dir : dir
				if(IS_CARDINAL(assumed_dir)) //If we are carnial we need to run faster to keep up
					addtimer(CALLBACK(src, PROC_REF(spawn_warpping_affect), olden_loc, warps), (50 MILLISECONDS * warps))
				else
					//We are slowed down by moving diagnally, this timer matches that
					addtimer(CALLBACK(src, PROC_REF(spawn_warpping_affect), olden_loc, warps), (125 MILLISECONDS * warps))

/atom/movable/proc/spawn_warpping_affect(olden_loc, warps)
	if(!olden_loc)
		return
	//This lets us turn a low aplha icon into a fuller brightness evenly
	var/aplha_adder = 255 / min(fancy_glide, 6)
	//This slowly moves us pixel by pixel for a smooth transition, evenly
	var/offsetter = 32 / min(fancy_glide, 6)
	//Snowflake temp_visual for are wierdly required timers and lack of spinning
	var/obj/effect/temp_visual/shorter/S = new(get_turf(olden_loc))
	var/directional = dir
	//The magic, this makes it so are image are 1:1 and even reflect it properly if changing icons a lot
	S.appearance = appearance
	//Untested, if issues then cry. - Trilby
	if(fancy_glide_custom_frames)
		//I.e roach_2 roach_3, note that we never start at 0, 1->6 i.e 6 frames
		S.appearance = null //So we can override the icon_state and icon
		S.icon_state = "[icon_state]_[warps]"
		S.icon = icon
	//If we set a new colour, use that otherwise use current objects
	S.color = fancy_glide_colour ? fancy_glide_colour : color
	S.alpha = aplha_adder * warps
	S.set_plane(-2) //Dont hide us!
	S.dir = directional //Helps with keeping us the correct way
	//Stagger out the removal of the shadows for a cleaner look
	QDEL_IN(S, 2 + warps)

	//Dont let us click these
	S.name = null
	S.desc = null
	S.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	//Humans can forcefully set face regardless of direction, this ensures that we do the affect in the correct diretion
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		S.dir = H.momentum_dir ?  H.momentum_dir : directional

	switch(directional)
		if(NORTH)
			S.pixel_y = 6 + offsetter * warps
		if(SOUTH)
			S.pixel_y = -6 + -offsetter * warps
		if(EAST)
			S.pixel_x = 6 + offsetter * warps
		if(WEST)
			S.pixel_x = -6 + -offsetter * warps
		if(NORTHEAST)
			S.pixel_x = 6 + offsetter * warps
			S.pixel_y = 6 + offsetter * warps
		if(NORTHWEST)
			S.pixel_x = -6 + -offsetter * warps
			S.pixel_y = 6 + offsetter * warps
		if(SOUTHEAST)
			S.pixel_x = 6 + offsetter * warps
			S.pixel_y = -6 + -offsetter * warps
		if(SOUTHWEST)
			S.pixel_x = -6 + -offsetter * warps
			S.pixel_y = -6 + -offsetter * warps

