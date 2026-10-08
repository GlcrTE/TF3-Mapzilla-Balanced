-- Mapzilla Balanced - Germany. A copy of the Mountains to delta generator with
-- its own node tree (mapzilla_balanced_germany.tree): no Layout param, always
-- the Alps at the far end and the North Sea at the other, with the terrain of
-- Germany in between - the Alpine foreland, the uplands (Mittelgebirge) and
-- the North German Plain. The tree passes profile 1 to the river node, which
-- picks the GERMANY bands in nodes.script.lua; the heights per band are
-- mz_profile_steps and mz_roll_amp_steps in the tree.
function data()
return { 
		nodeTree = "mapzilla_balanced_germany.tree",
		climate = "::/climates/temperate/temperate.clima",
		desc = { 
			cargoTypeSet = { 
				cargoClassesExcluded = { },
				cargoClassesIncluded = { },
				cargoTypesExcluded = { },
				cargoTypesIncluded = { },
			},
			name = _("Mapzilla Balanced - Germany"),
		},
		editorOnly = false,
		order = 91,
		params = {
			{
				defaultIndex = 3,
				images = { },
				key = "mz_coast",
				name = _("Coastline"),
				tags = { },
				tooltip = _("How far the coastline wanders in and out of a straight line."),
				uiType = "Slider",
				valueIndices = { },
				values = {
					_("Straight"),
					_("Gentle"),
					_("Medium"),
					_("Rugged"),
					_("Wild"),
				},
				yearFrom = 0,
				yearTo = 0,
			},
			{
				defaultIndex = 3,
				images = { },
				key = "mz_islands",
				name = _("Islands"),
				tags = { },
				tooltip = _("How many islands lie off the coast."),
				uiType = "Slider",
				valueIndices = { },
				values = {
					_("Few"),
					_("Scattered"),
					_("Medium"),
					_("Dense"),
					_("Packed"),
				},
				yearFrom = 0,
				yearTo = 0,
			},
			{
				defaultIndex = 2,
				images = { },
				key = "mz_axis",
				name = _("Orientation"),
				tags = { },
				tooltip = _("Which side of the map the layout runs along. A square map looks the same either way."),
				uiType = "ComboBox",
				valueIndices = { },
				values = {
					_("Random"),
					_("Long side"),
					_("Short side"),
				},
				yearFrom = 0,
				yearTo = 0,
			},
			{ 
				
				defaultIndex = 3,
				images = { },
				key = "oceans",
				name = _("Lakes"),
				tags = { },
				tooltip = _("Adjust the number of lakes on the map."),
				uiType = "Slider",
				valueIndices = { },
				values = {
					_("Sparse"),
					_("Scattered"),
					_("Medium"),
					_("Dense"),
					_("Packed"),
				},
				yearFrom = 0,
				yearTo = 0,
			},
			{ 
				
				defaultIndex = 3,
				images = { },
				key = "water",
				name = _("Rivers"),
				tags = { },
				tooltip = _("Adjust the number of rivers on the map."),
				uiType = "Slider",
				valueIndices = { },
				values = {
					_("Sparse"),
					_("Scattered"),
					_("Medium"),
					_("Dense"),
					_("Packed"),
				},
				yearFrom = 0,
				yearTo = 0,
			},
			{ 
				
				defaultIndex = 3,
				images = { },
				key = "mountains",
				name = _("Mountains"),
				tags = { },
				tooltip = _("Adjust the number and height of mountains on the map."),
				uiType = "Slider",
				valueIndices = { },
				values = {
					_("Sparse"),
					_("Scattered"),
					_("Medium"),
					_("Dense"),
					_("Packed"),
				},
				yearFrom = 0,
				yearTo = 0,
			},
		},
		previewSeed = "yQKiK",
		updateScript = { 
			fileName = "",
			params = { },
		},
	}
end
