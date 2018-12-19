/mob/living/exosuit
	movement_handlers = list(
		/datum/movement_handler/mob/exosuit
	)

/mob/living/exosuit/Move()
	. = ..()
	if(. && !istype(loc, /turf/space))
		playsound(src.loc, mech_step_sound, 40, 1)

/datum/movement_handler/mob/exosuit
	expected_host_type = /mob/living/exosuit
	var/next_move

/datum/movement_handler/mob/exosuit/MayMove(var/mob/mover, var/is_external)
	var/mob/living/exosuit/exosuit = host
	if(world.time < next_move)
		return MOVEMENT_STOP
	if((!(mover in exosuit.pilots) && mover != exosuit) || exosuit.incapacitated() || mover.incapacitated())
		return MOVEMENT_STOP
	if(!exosuit.legs)
		to_chat(mover, SPAN_WARNING("\The [exosuit] has no means of propulsion!"))
		next_move = world.time + 3 // Just to stop them from getting spammed with messages.
		return MOVEMENT_STOP
	if(!exosuit.legs.motivator || !exosuit.legs.motivator.is_functional())
		to_chat(mover, SPAN_WARNING("Your motivators are damaged! You can't move!"))
		next_move = world.time + 15
		return MOVEMENT_STOP
	if(exosuit.maintenance_protocols)
		to_chat(mover, SPAN_WARNING("Maintenance protocols are in effect."))
		next_move = world.time + 3 // Just to stop them from getting spammed with messages.
		return MOVEMENT_STOP
	if(!exosuit.check_solid_ground())
		var/allowmove = exosuit.Allow_Spacemove(0)
		if(!allowmove)
			return MOVEMENT_STOP
		else if(allowmove == -1 && exosuit.handle_spaceslipping())
			return MOVEMENT_STOP
		else
			exosuit.inertia_dir = 0
	next_move = world.time + (exosuit.legs ? exosuit.legs.move_delay : 3)
	return MOVEMENT_PROCEED

/datum/movement_handler/mob/exosuit/DoMove(var/direction, var/mob/mover, var/is_external)
	var/mob/living/exosuit/exosuit = host
	var/moving_dir = direction

	var/failed = FALSE
	var/fail_prob = mover != host ? (mover.skill_check(SKILL_MECH, HAS_PERK) ? 0 : 25) : 0
	if(prob(fail_prob))
		to_chat(mover, SPAN_DANGER("You clumsily fumble with the exosuit joystick."))
		failed = TRUE
	else if(exosuit.emp_damage >= EMP_MOVE_DISRUPT && prob(30))
		failed = TRUE
	if(failed)
		moving_dir = pick(GLOB.cardinal - exosuit.dir)

	if(exosuit.dir != moving_dir)
		playsound(exosuit.loc, exosuit.mech_turn_sound, 40,1)
		exosuit.set_dir(moving_dir)
	else
		var/turf/target_loc = get_step(exosuit, direction)
		if(target_loc && exosuit.legs && exosuit.legs.can_move_on(exosuit.loc, target_loc) && exosuit.MayEnterTurf(target_loc))
			exosuit.Move(target_loc)
	return MOVEMENT_HANDLED