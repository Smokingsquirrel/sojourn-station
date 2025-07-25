// Blunt
/datum/component/internal_wound/organic/heart_blunt
	treatments_item = list(/obj/item/stack/medical/bruise_pack/advanced = 2)
	treatments_tool = list(QUALITY_CLAMPING = FAILCHANCE_HARD)
	treatments_chem = list(CE_HEARTHEAL = 1)
	severity = 0
	severity_max = 3 // with 3 health it takes around 3 wounds to kill heart
	hal_damage = IWOUND_MEDIUM_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/organic/heart_blunt/dissection
	name = "cardiovascular dissection"

/datum/component/internal_wound/organic/heart_blunt/erosion //PAINFUL
	name = "cardiovascular erosion"
	hal_damage = IWOUND_HEAVY_DAMAGE

// Sharp

/datum/component/internal_wound/organic/heart_sharp
	treatments_item = list(/obj/item/stack/medical/bruise_pack/advanced = 2)
	treatments_tool = list(QUALITY_LASER_CUTTING = FAILCHANCE_HARD)
	treatments_chem = list(CE_HEARTHEAL = 1)
	severity = 0
	severity_max = 3
	hal_damage = IWOUND_MEDIUM_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/organic/heart_sharp/slice
	name = "traumatic cardiovascular"

/datum/component/internal_wound/organic/heart_sharp/perforation
	name = "cardiovascular superonasal perforation"

/datum/component/internal_wound/organic/heart_sharp/matter
	name = "cardiovascular foreign matter"
	treatments_tool = list(QUALITY_CLAMPING = FAILCHANCE_HARD)

// Edge
/datum/component/internal_wound/organic/heart_edge
	treatments_item = list(/obj/item/stack/medical/bruise_pack/advanced = 2)
	treatments_tool = list(QUALITY_CAUTERIZING = FAILCHANCE_HARD)
	treatments_chem = list(CE_HEARTHEAL = 1)
	severity = 0
	severity_max = 3
	hal_damage = IWOUND_MEDIUM_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/organic/heart_edge/laceration
	name = "cardiovascular laceration"

/datum/component/internal_wound/organic/heart_edge/cuts
	name = "cut cardiovascular"

/datum/component/internal_wound/organic/heart_edge/slice
	name = "sliced cardiovascular"

// Burn
// Gonna be avoiding infections here. Far more likely you get welding flare then a direct laser to the heart. Makes little sense in some cases but easier then reworking welding!
/datum/component/internal_wound/organic/heart_burn
	treatments_item = list(/obj/item/stack/medical/ointment/advanced = 2)
	treatments_tool = list(QUALITY_LASER_CUTTING = FAILCHANCE_HARD)
	treatments_chem = list(CE_HEARTHEAL = 1, CE_DEBRIDEMENT = 1)
	severity = 0
	severity_max = 3
	hal_damage = IWOUND_MEDIUM_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/organic/heart_burn/scorch
	name = "scorched cardiovascular tissue"
	treatments_tool = list(QUALITY_RETRACTING = FAILCHANCE_HARD)
	next_wound = /datum/component/internal_wound/organic/heart_burn/heart_deep_burn

/datum/component/internal_wound/organic/heart_burn/heart_deep_burn //stage 2
	name = "scorched deep cardiovascular tissue"
	severity = 2 // starts with high damage as it is a second stage
	severity_max = 3
	next_wound = /datum/component/internal_wound/organic/heart_special

/datum/component/internal_wound/organic/heart_special
	treatments_item = list(/obj/item/stack/medical/ointment/advanced = 2)
	treatments_tool = list(QUALITY_CLAMPING = FAILCHANCE_HARD)
	treatments_chem = list(CE_HEARTHEAL = 1)
	severity = 0
	severity_max = 8 //slow death of heart like infection but we dont want it spreading elsewhere!
	progression_threshold = IWOUND_10_MINUTES //very slow! I hope

/datum/component/internal_wound/organic/heart_special/failer
	name = "cardiovascular failer"

/datum/component/internal_wound/organic/heart_special/still
	name = "cardiovascular stillness"

// Tox (toxins)
/datum/component/internal_wound/organic/heart_poisoning
	treatments_item = list(/obj/item/stack/medical/bruise_pack/advanced = 1)
	treatments_tool = list(QUALITY_CUTTING = FAILCHANCE_HARD)
	treatments_chem = list(CE_ANTITOX = 2, CE_HEARTHEAL = 1)
	severity = 0
	severity_max = 3
	hal_damage = IWOUND_LIGHT_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT
	progress_while_healthy = TRUE

/// Cheap hack, but prevents unbalanced toxins from killing someone immediately
/datum/component/internal_wound/organic/heart_poisoning/InheritComponent()
	if(prob(5))
		progress()

/datum/component/internal_wound/organic/heart_poisoning/pustule
	name = "cardiovascular pustule"
	specific_organ_size_multiplier = 0.20

/datum/component/internal_wound/organic/heart_poisoning/intoxication
	name = "cardiovascular intoxication"
	blood_req_multiplier = 0.25
	nutriment_req_multiplier = 0.25
	oxygen_req_multiplier = 0.25

/datum/component/internal_wound/organic/heart_poisoning/accumulation
	name = "cardiovascular backlogged accumulation"
	hal_damage = IWOUND_MEDIUM_DAMAGE

/// Robotic

// Blunt
/datum/component/internal_wound/robotic/heart_blunt
	treatments_item = list(/obj/item/stack/nanopaste = 1)
	treatments_tool = list(QUALITY_SCREW_DRIVING = FAILCHANCE_HARD)
	treatments_chem = list(CE_MECH_REPAIR = 0.55)		// repair nanites + 3 metals OR repair nanite OD + a metal
	severity = 0
	severity_max = 3
	hal_damage = IWOUND_INSIGNIFICANT_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/robotic/heart_blunt/bruses
	name = "brused cardiovascular"
	treatments_tool = list(QUALITY_CLAMPING = FAILCHANCE_HARD)

/datum/component/internal_wound/robotic/heart_blunt/jam
    name = "jammed mechanics"

/datum/component/internal_wound/robotic/heart_blunt/matrix
	name = "dented cardiovascular"
	organ_efficiency_multiplier = -1 // can't see anything because of loose wire

// Sharp

/datum/component/internal_wound/robotic/heart_sharp
	treatments_item = list(/obj/item/stack/nanopaste = 2)
	treatments_tool = list()
	treatments_chem = list(CE_MECH_REPAIR = 0.85)		// repair nanites + 6 metals OR repair nanite OD + 7 metals
	severity = 0
	severity_max = 3
	hal_damage = IWOUND_INSIGNIFICANT_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/robotic/heart_sharp/leaking
	name = "leaking cardiovascular tank"
	treatments_tool = list(QUALITY_ADHESIVE = FAILCHANCE_HARD)

/datum/component/internal_wound/robotic/heart_sharp/shatter
	name = "leaking cardiovascular tubing"
	treatments_chem = list(CE_MECH_REPAIR = 0.20)

/datum/component/internal_wound/robotic/heart_sharp/failure
	name = "mechanical cardiovascular failure"
	treatments_item = list(/obj/item/stock_parts/scanning_module = 1, /obj/item/stack/nanopaste = 2)

// Edge
/datum/component/internal_wound/robotic/heart_edge
	treatments_item = list(/obj/item/stack/nanopaste = 1)
	treatments_tool = list(QUALITY_CAUTERIZING = FAILCHANCE_HARD)
	treatments_chem = list(CE_MECH_REPAIR = 0.85)
	severity = 0
	severity_max = 3
	hal_damage = IWOUND_INSIGNIFICANT_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/robotic/heart_edge/case
	name = "scratched cardiovascular"

/datum/component/internal_wound/robotic/heart_edge/tubing
	name = "torn cardiovascular tube"

/datum/component/internal_wound/robotic/heart_edge/slice
	name = "sliced open cardiovascular pump"
	treatments_item = list(/obj/item/stack/cable_coil = 5)

// EMP/burn wounds

/datum/component/internal_wound/robotic/heart_emp_burn
	treatments_item = list(/obj/item/stack/cable_coil = 5)
	treatments_tool = list(QUALITY_WIRE_CUTTING = FAILCHANCE_HARD)
	treatments_chem = list(CE_MECH_REPAIR = 0.95)	// repair nanite OD + all metals
	severity = 0
	severity_max = 3
	next_wound = /datum/component/internal_wound/robotic/heart_overheat
	hal_damage = IWOUND_INSIGNIFICANT_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/robotic/heart_emp_burn/tube
	name = "burnt cardiovascular tubing"
	treatments_item = list(/obj/item/stack/nanopaste = 1)
	treatments_tool = list(QUALITY_PULSING = FAILCHANCE_HARD)

/datum/component/internal_wound/robotic/heart_emp_burn/inverse
	name = "inversed cardiovascular moter"
	treatments_tool = list(QUALITY_SCREW_DRIVING = FAILCHANCE_HARD)

/datum/component/internal_wound/robotic/heart_emp_burn/carbonized
	name = "mangled pump wiring"

/datum/component/internal_wound/robotic/heart_overheat
	treatments_item = list(/obj/item/stack/cable_coil = 10, /obj/item/stack/nanopaste = 2)
	treatments_chem = list(CE_MECH_STABLE = 0.5)	// coolant or refrigerant
	severity = 0
	severity_max = IORGAN_MAX_HEALTH
	hal_damage = IWOUND_INSIGNIFICANT_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/robotic/heart_overheat/standard
	name = "overheating cardiovascular pump"

/datum/component/internal_wound/robotic/heart_overheat/alt
	name = "coolent lacking cardiovascular"
	organ_efficiency_multiplier = -1

// Tox - UNUSED
/datum/component/internal_wound/robotic/heart_build_up
	treatments_tool = list(QUALITY_CLAMPING = FAILCHANCE_HARD)	// Clear any clog wtih a thin tool
	treatments_chem = list(CE_MECH_ACID = 1)		// sulphiric acid
	severity = 0
	severity_max = 3
	next_wound = /datum/component/internal_wound/robotic/corrosion
	hal_damage = IWOUND_INSIGNIFICANT_DAMAGE
	diagnosis_difficulty = STAT_LEVEL_EXPERT

/datum/component/internal_wound/robotic/heart_build_up/breach
	name = "breached cardiovascular pump"
	treatments_tool = list(QUALITY_ADHESIVE = FAILCHANCE_HARD)
	treatments_item = list(/obj/item/stack/nanopaste = 1)
	treatments_chem = list(CE_MECH_REPAIR = 0.30)

/datum/component/internal_wound/robotic/heart_build_up/clog
	name = "clogged center circuitry"
	severity_max = 5
	hal_damage = IWOUND_MEDIUM_DAMAGE

// Clone/radiation
/datum/component/internal_wound/organic/heart_radiation
	treatments_tool = list(QUALITY_CUTTING = FAILCHANCE_NORMAL)
	treatments_chem = list(CE_ONCOCIDAL = 1, CE_HEARTHEAL = 1)
	severity = 1
	severity_max = 1
	hal_damage = IWOUND_LIGHT_DAMAGE
	status_flag = ORGAN_WOUNDED|ORGAN_MUTATED
	progress_while_healthy = TRUE

/datum/component/internal_wound/organic/heart_radiation/benign
	name = "benign tumor"

/datum/component/internal_wound/organic/heart_radiation/malignant
	name = "malignant tumor"
	treatments_chem = list(CE_ONCOCIDAL = 2, CE_HEARTHEAL = 1)
	characteristic_flag = IWOUND_CAN_DAMAGE|IWOUND_PROGRESS|IWOUND_SPREAD
	severity = 0
	severity_max = IORGAN_MAX_HEALTH	// Will kill any organ
	spread_threshold = IORGAN_SMALL_HEALTH	// This will spread at the same moment it kills a small organ
