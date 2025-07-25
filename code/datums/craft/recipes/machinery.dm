/datum/craft_recipe/machinery
	category = "Machinery"
	flags = CRAFT_ON_FLOOR|CRAFT_ONE_PER_TURF
	time = 120
	related_stats = list(STAT_MEC)

/datum/craft_recipe/machinery/computer
	related_stats = list(STAT_MEC, STAT_COG)

/datum/craft_recipe/machinery/AI_core
	name = "AI core"
	result = /obj/structure/AIcore
	steps = list(
		list(CRAFT_MATERIAL, 10, MATERIAL_PLASTEEL)
	)
	related_stats = list(STAT_MEC, STAT_COG)

/datum/craft_recipe/machinery/wall
	flags = null

/datum/craft_recipe/machinery/wall/air_alarm
	name = "air alarm frame"
	result = /obj/item/frame/air_alarm
	icon_state = "electronic"
	steps = list(
		list(CRAFT_MATERIAL, 5, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/wall/apc
	name = "APC frame"
	result = /obj/item/frame/apc
	icon_state = "electronic"
	steps = list(
		list(CRAFT_MATERIAL, 5, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/computer/computer_frame
	name = "computer frame"
	result = /obj/structure/computerframe
	steps = list(
		list(CRAFT_MATERIAL, 5, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/wall/fire_alarm
	name = "fire alarm frame"
	result = /obj/item/frame/fire_alarm
	icon_state = "electronic"
	steps = list(
		list(CRAFT_MATERIAL, 2, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/wall/lightfixture
	name = "light fixture frame"
	result = /obj/item/frame/light
	icon_state = "electronic"
	steps = list(
		list(CRAFT_MATERIAL, 2, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/wall/lightfixture/small
	name = "light fixture frame, small"
	result = /obj/item/frame/light/small
	icon_state = "electronic"
	steps = list(
		list(CRAFT_MATERIAL, 1, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/machine_frame
	name = "machine frame"
	result = /obj/machinery/constructable_frame/machine_frame
	steps = list(
		list(CRAFT_MATERIAL, 8, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/vertical_machine_frame
	name = "machine frame, vertical"
	result = /obj/machinery/constructable_frame/machine_frame/vertical
	steps = list(
		list(CRAFT_MATERIAL, 8, MATERIAL_STEEL)
	)

/datum/craft_recipe/machinery/computer/modularconsole
	name = "modular console frame"
	result = /obj/item/modular_computer/console
	time = 200
	flags = CRAFT_ON_FLOOR|CRAFT_ONE_PER_TURF
	steps = list(
		list(CRAFT_MATERIAL, 10, MATERIAL_STEEL),
		list(CRAFT_MATERIAL, 4, MATERIAL_GLASS)
	)
	dir_type = CRAFT_TOWARD_USER  // spawn modular console toward the user

/datum/craft_recipe/machinery/computer/modularlaptop
	name = "modular frame, laptop"
	result = /obj/item/modular_computer/laptop
	icon_state = "electronic"
	time = 200
	steps = list(
		list(CRAFT_MATERIAL, 8, MATERIAL_STEEL),
		list(CRAFT_MATERIAL, 4, MATERIAL_GLASS)
	)

/datum/craft_recipe/machinery/computer/modularpda
	name = "modular frame, pda"
	result = /obj/item/modular_computer/pda
	icon_state = "electronic"
	time = 200
	steps = list(
		list(CRAFT_MATERIAL, 3, MATERIAL_STEEL),
		list(CRAFT_MATERIAL, 1, MATERIAL_GLASS)
	)

/datum/craft_recipe/machinery/computer/modularwrist
	name = "modular frame, wristmounted"
	result = /obj/item/modular_computer/wrist
	icon_state = "electronic"
	time = 200
	steps = list(
		list(CRAFT_MATERIAL, 3, MATERIAL_STEEL),
		list(CRAFT_MATERIAL, 1, MATERIAL_GLASS)
	)

/datum/craft_recipe/machinery/computer/modulartablet
	name = "modular frame, tablet"
	result = /obj/item/modular_computer/tablet
	icon_state = "electronic"
	time = 200
	steps = list(
		list(CRAFT_MATERIAL, 5, MATERIAL_STEEL),
		list(CRAFT_MATERIAL, 2, MATERIAL_GLASS)
	)

/datum/craft_recipe/machinery/computer/modulartelescreen
	name = "modular frame, telescreen"
	result = /obj/item/modular_computer/telescreen
	icon_state = "electronic"
	time = 200
	steps = list(
		list(CRAFT_MATERIAL, 8, MATERIAL_STEEL),
		list(CRAFT_MATERIAL, 6, MATERIAL_GLASS)
	)

/datum/craft_recipe/machinery/turret_frame
	name = "turret frame"
	result = /obj/machinery/porta_turret_construct
	steps = list(
		list(CRAFT_MATERIAL, 10, MATERIAL_STEEL)
	)
