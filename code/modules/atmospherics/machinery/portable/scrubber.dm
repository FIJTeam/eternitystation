/obj/machinery/portable_atmospherics/scrubber
	name = "portable air scrubber"
	icon_state = "pscrubber:0"
	density = TRUE

	var/on = FALSE
	var/volume_rate = 1000
	var/overpressure_m = 80
	volume = 1000

	var/list/scrubbing = list(
		/datum/gas/plasma,
		/datum/gas/carbon_dioxide,
		/datum/gas/nitrous_oxide,
		/datum/gas/miasma,
		/datum/gas/bz,
		/datum/gas/nitrium,
		/datum/gas/tritium,
		/datum/gas/hypernoblium,
		/datum/gas/dilithium,
		/datum/gas/freon,
		/datum/gas/hydrogen,
		/datum/gas/water_vapor,
		/datum/gas/healium,
		/datum/gas/pluoxium,
		/datum/gas/pluonium,
		/datum/gas/halon,
		/datum/gas/zauker,
		/datum/gas/antinoblium,
		/datum/gas/hexane,
	)

/obj/machinery/portable_atmospherics/scrubber/Destroy()
	var/turf/T = get_turf(src)
	T.assume_air(air_contents)
	air_update_turf()
	return ..()

/obj/machinery/portable_atmospherics/scrubber/update_icon_state()
	. = ..()
	icon_state = "pscrubber:[on]"

/obj/machinery/portable_atmospherics/scrubber/update_overlays()
	. = ..()

	if(holding)
		. += "scrubber-open"
	if(connected_port)
		. += "scrubber-connector"

/obj/machinery/portable_atmospherics/scrubber/process_atmos()
	..()
	if(!on)
		return

	if(holding)
		scrub(holding.air_contents)
	else
		var/turf/T = get_turf(src)
		scrub(T.return_air())

/obj/machinery/portable_atmospherics/scrubber/proc/scrub(datum/gas_mixture/mixture)
	if(air_contents.return_pressure() >= overpressure_m * ONE_ATMOSPHERE)
		return

	var/transfer_moles = min(1, volume_rate / mixture.return_volume()) * mixture.total_moles()

	var/datum/gas_mixture/filtering = mixture.remove(transfer_moles) // Remove part of the mixture to filter.
	if(!filtering)
		return

	filtering.scrub_into(air_contents, scrubbing)

	mixture.merge(filtering) // Returned the cleaned gas.
	if(!holding)
		air_update_turf()

/obj/machinery/portable_atmospherics/scrubber/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(is_operational())
		if(prob(50 / severity))
			on = !on
		update_appearance(UPDATE_ICON)

/obj/machinery/portable_atmospherics/scrubber/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortableScrubber", name)
		ui.open()

/obj/machinery/portable_atmospherics/scrubber/ui_data()
	var/data = list()
	data["on"] = on
	data["connected"] = connected_port ? 1 : 0
	data["pressure"] = round(air_contents.return_pressure() ? air_contents.return_pressure() : 0)

	data["id_tag"] = -1 //must be defined in order to reuse code between portable and vent scrubbers
	data["filter_types"] = list()
	for(var/path in GLOB.meta_gas_info)
		var/list/gas = GLOB.meta_gas_info[path]
		data["filter_types"] += list(list("gas_id" = gas[META_GAS_ID], "gas_name" = gas[META_GAS_NAME], "enabled" = (path in scrubbing)))

	if(holding)
		data["holding"] = list()
		data["holding"]["name"] = holding.name
		data["holding"]["pressure"] = round(holding.air_contents.return_pressure())
	else
		data["holding"] = null
	return data

/obj/machinery/portable_atmospherics/scrubber/replace_tank(mob/living/user, close_valve)
	. = ..()
	if(.)
		if(close_valve)
			if(on)
				on = FALSE
				update_appearance(UPDATE_ICON)
		else if(on && holding)
			investigate_log("[key_name(user)] started a transfer into [holding].<br>", INVESTIGATE_ATMOS)

/obj/machinery/portable_atmospherics/scrubber/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("power")
			on = !on
			. = TRUE
		if("eject")
			if(holding)
				replace_tank(usr, FALSE)
				. = TRUE
		if("toggle_filter")
			scrubbing ^= gas_id2path(params["val"])
			. = TRUE
	update_appearance(UPDATE_ICON)

/obj/machinery/portable_atmospherics/scrubber/huge
	name = "huge air scrubber"
	icon_state = "scrubber:0"
	anchored = TRUE
	active_power_usage = 500
	idle_power_usage = 10

	overpressure_m = 200
	volume_rate = 1500
	volume = 50000

	var/movable = FALSE

/obj/machinery/portable_atmospherics/scrubber/huge/movable
	movable = TRUE

/obj/machinery/portable_atmospherics/scrubber/huge/update_icon_state()
	. = ..()
	icon_state = "scrubber:[on]"

/obj/machinery/portable_atmospherics/scrubber/huge/process_atmos()
	if((!anchored && !movable) || !is_operational())
		on = FALSE
		update_appearance(UPDATE_ICON)
	use_power = on ? ACTIVE_POWER_USE : IDLE_POWER_USE
	if(!on)
		return

	..()
	if(!holding)
		var/turf/T = get_turf(src)
		for(var/turf/AT in T.GetAtmosAdjacentTurfs(alldir = TRUE))
			scrub(AT.return_air())

/obj/machinery/portable_atmospherics/scrubber/huge/attackby(obj/item/W, mob/user)
	if(default_unfasten_wrench(user, W))
		if(!movable)
			on = FALSE
	return ..()

/obj/machinery/portable_atmospherics/scrubber/CtrlShiftClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	on = !on
	update_appearance(UPDATE_ICON)
