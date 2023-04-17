
HarvestMissionFix = {}
addModEventListener(HarvestMissionFix)

HarvestMissionFix.missions = {}

function HarvestMissionFix.getMissionIndex(self)
	local field = self.field
	for k, v in pairs(HarvestMissionFix.missions) do
		if v.field.fieldId == field.fieldId then
			return k
		end
	end
	return 0
end

function HarvestMissionFix.insertMission(self, active)
	local mission = self
	mission.active = active
	mission.collectedLiters = 0

	table.insert(HarvestMissionFix.missions, mission)
	table.sort(HarvestMissionFix.missions, function(a, b) return a.field.fieldId < b.field.fieldId end )
end

FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, function()
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
	
	if g_currentMission:getIsServer() and not g_currentMission.missionDynamicInfo.isMultiplayer then
		local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_TOGGLE_INFO", HarvestMissionFix, HarvestMissionFix.toggleInfo, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		HarvestMissionFix.toggleInfoActionEventId = actionEventId
		
		local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_CYCLE_FW", HarvestMissionFix, HarvestMissionFix.cycleFW, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		g_inputBinding:setActionEventTextVisibility(actionEventId, false)
		HarvestMissionFix.cycleFWActionEventId = actionEventId
		
		local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_CYCLE_BW", HarvestMissionFix, HarvestMissionFix.cycleBW, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		g_inputBinding:setActionEventTextVisibility(actionEventId, false)
		HarvestMissionFix.cycleBWActionEventId = actionEventId
	
		local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_TEST", HarvestMissionFix, HarvestMissionFix.test, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		HarvestMissionFix.testActionEventId = actionEventId
	end
end)

		
function HarvestMissionFix:toggleInfo()
	HarvestMissionFix.show = not (HarvestMissionFix.show or false)
	g_inputBinding:setActionEventTextVisibility(HarvestMissionFix.cycleFWActionEventId, HarvestMissionFix.show)
	g_inputBinding:setActionEventTextVisibility(HarvestMissionFix.cycleBWActionEventId, HarvestMissionFix.show)
end

function HarvestMissionFix:cycleFW()
	if HarvestMissionFix.show then
		HarvestMissionFix.cycleIndex('FW')
	end
end

function HarvestMissionFix:cycleBW()
	if HarvestMissionFix.show then
		HarvestMissionFix.cycleIndex('BW')
	end
end

function HarvestMissionFix:test()
	if HarvestMissionFix.show then
		HarvestMissionFix.index = HarvestMissionFix.index or 1
		local mission = HarvestMissionFix.missions[HarvestMissionFix.index]
		if mission and mission.active and mission.harvestCompletion == 0 then
			mission.simulationLitres, mission.simulationMultiplier = HarvestMissionFix.testHarvestField(mission)
		else
			DebugUtil.printTableRecursively(mission, "--", 0, 1)
		end
	end
end

function HarvestMissionFix.cycleIndex(direction)

	HarvestMissionFix.index = HarvestMissionFix.index or 1

	if direction == 'BW' then
		HarvestMissionFix.index = HarvestMissionFix.index - 1
	else
		HarvestMissionFix.index = HarvestMissionFix.index + 1
	end
	
	if HarvestMissionFix.index < 1 then
		HarvestMissionFix.index = #HarvestMissionFix.missions
	end
	if HarvestMissionFix.index > #HarvestMissionFix.missions then
		HarvestMissionFix.index = 1
	end
end

function HarvestMissionFix:draw()

	local left = 0.05
	local right = 0.20
	local top = 0.88
	local d = 0.0150
	local b = 0.0130
	local x = function(delta)
		top = top - (delta or 0)
		return top
	end
	local printLeft = function(name)
		renderText(left, x(d), d, name)
	end
	local printRight = function(value)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(right, x(), d, value)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
	local printLine = function(name, value)
		printLeft(name) printRight(value)
	end
	local printSpace = function()
		renderText(left, x(b), b, string.format(""))
	end
	local printBreak = function(space)
		renderText(left, x(b), d, string.format("----------------------------------------"))
		if space then
			printSpace()
		end
	end
	
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(false)
	
	HarvestMissionFix.index = HarvestMissionFix.index or 1
	local mission = HarvestMissionFix.missions[HarvestMissionFix.index]
	if mission == nil or not HarvestMissionFix.show or #HarvestMissionFix.missions == 0 then
		if HarvestMissionFix.show then
			setTextColor(1, 1, 1, 1)
			printBreak()
			printLeft("     NO HARVEST MISSIONS ACTIVE     ")
			printBreak()
		end
		return
	end
	
	if mission.collectedLiters and mission.collectedLiters < 0 then
		mission.collectedLiters = 0
		self.collectedLiters = 0
	end
	
	if mission.complete then
		if mission.success then
			setTextColor(0, 1, 0, 1)
		else
			setTextColor(1, 0, 0, 1)
		end
	else
		setTextColor(1, 1, 1, 1)
	end
	printBreak()
	local state                    = "Available"
	if mission.active then state   = "Active" end
	if mission.complete then state = "Complete" end
	printLeft(string.format("FIELD #%d", mission.field.fieldId or 0)) printRight(state)
	printLeft("Sell Point:") printRight(mission.sellPoint:getName())
	printBreak()
	printLine("Field Area:", string.format("%.3f ha", mission.field.fieldArea or 0))
	printLine("Max Cut Litres:", string.format("%.1f l", mission.maxCutLiters or 0))
	printLine("Yield Multiplier:", string.format("%.3f", mission.totalFactor or 0))
	printLine("Correction Factor:", string.format("%.3f", mission.correctionFactor or 0))
	printLine("Litres Per Sqm:", string.format("%.3f", mission.literPerSqm or 0))
	printLine("Fruit Pixels To Sqm:", string.format("%.3f", g_currentMission:getFruitPixelsToSqm() or 0))
	printBreak()
	
	if state == "Available" then return end
	
	local realExpectedLitres = (mission.expectedLiters or 0) * (mission.correctionFactor or 0) * AbstractMission.SUCCESS_FACTOR
	local totalCollectedLitres = mission.collectedLiters + mission.depositedLiters
	
	printLine("Expected:", string.format("%.1f l", realExpectedLitres or 0))
	printLine("Collected:", string.format("%.1f l", mission.collectedLiters or 0))
	printLine("Deposited:", string.format("%.1f l", mission.depositedLiters or 0))
	printLine("SELL Completion:", string.format("%.1f %%", 100*(mission.sellCompletion or 0)))
	--printLine("FIELD Completion:", string.format("%.1f %%", 100*(mission.fieldCompletion or 0)))
	printLine("HARVEST Completion:", string.format("%.1f %%", 100*(mission.harvestCompletion or 0)))
	printBreak()
	setTextBold(true)
	printLine("TOTAL COMPLETION:", string.format("%.1f %%", 100*(mission.totalCompletion or 0)))
	setTextBold(false)
	printBreak(true)

	if mission.harvestCompletion and mission.expectedLiters then
		local shortfallPercent = math.max(0, (realExpectedLitres-totalCollectedLitres)/realExpectedLitres)
		local surplusPercent = math.max(0, ((totalCollectedLitres-realExpectedLitres)+(mission.surplusLitres or 0))/realExpectedLitres)
		printLine("FIELD Completion:", string.format("%.1f %%", 100*mission.harvestCompletion))
		printLine("Litres Remaining:", string.format("%.2f %%", 100*shortfallPercent))
		printLine("Expected Surplus:", string.format("%.2f %%", 100*surplusPercent))
		printSpace()
	end
	
	if mission.simulationLitres and mission.simulationMultiplier then
		printLine("Simulation Multiplier:", string.format("%.3f", mission.simulationMultiplier or 0))
		printLine("Simulation Litres:", string.format("%.1f l", mission.simulationLitres or 0))
		printSpace()
	end
	
	if mission.numPartitions then
		local w = left
		renderText(left, x(d), d, string.format("Partitions: %d   Area: %.3f ha", mission.numPartitions, mission.totalArea))
		renderText(left, x(b/2), b/2, string.format(""))
		for i = 1, #mission.partition do
			if i == 1 then
				w = left
				original = top
			end
			local h = x(d)
			renderText(w, h, d, string.format(" [%d] = %d %%", i, 100*(mission.partition[i].partitionPercentage or 0) ))
			if h < 0.05 then
				top = original
				w = w + 0.05
			end
		end
	end
	
end

-- DETECT WHEN A MISSION IS ACTIVATED
local function getStart(self, spawnVehicles)
	HarvestMissionFix.insertMission(self, true)
	HarvestMissionFix.index = HarvestMissionFix.getMissionIndex(self)
end
local oldHarvestStart = HarvestMission.start
HarvestMission.start = function(...) getStart(...) return oldHarvestStart(...) end

-- DETECT WHEN A MISSION IS ENDED
local function getFinish(self, success)
	local i = HarvestMissionFix.getMissionIndex(self)
	HarvestMissionFix.getCompletion(self)
	HarvestMissionFix.missions[i].active = false
	HarvestMissionFix.missions[i].complete = true
	HarvestMissionFix.missions[i].success = success
end
local oldHarvestFinish = HarvestMission.finish
HarvestMission.finish = function(...) getFinish(...) return oldHarvestFinish(...) end

-- DETECT WHEN CROP IS HARVESTED DURING A MISSION
local function raiseEvent(self, eventName, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	if eventName == "onFillUnitFillLevelChanged" then
		for k, v in pairs(HarvestMissionFix.missions) do
			if v.fillType == fillTypeIndex then
				local mission = HarvestMissionFix.missions[k]
				if mission and mission.active and mission.collectedLiters then
					mission.collectedLiters = mission.collectedLiters + fillLevelDelta
				end
			end
		end
	end
end
local oldRaiseEvent = SpecializationUtil.raiseEvent
SpecializationUtil.raiseEvent = function(...) raiseEvent(...) return oldRaiseEvent(...) end

-- NEW FUNCTION TO CALCULATE MISSON COMPLETION
function HarvestMissionFix.getCompletion(self)

	local i = HarvestMissionFix.getMissionIndex(self)
	if i == 0 then
		HarvestMissionFix.insertMission(self, true)
		i = HarvestMissionFix.getMissionIndex(self)
	end
	
	local mission = HarvestMissionFix.missions[i]
	if mission then
	
		if mission.simulationLitres and mission.harvestCompletion > 0.999 and not mission.simulationComplete then

			local realExpectedLitres = mission.expectedLiters * mission.correctionFactor * AbstractMission.SUCCESS_FACTOR
			
			if realExpectedLitres > mission.simulationLitres then
				mission:fillSold(mission.simulationLitres)
				print(string.format("HarvestMissionFix: %.3f litres from field #%d deposited at %s",
					mission.simulationLitres, mission.field.fieldId, mission.sellPoint:getName()))
			else
				local farmId = g_currentMission:getFarmId()
				mission:fillSold(realExpectedLitres)
				print(string.format("HarvestMissionFix: %.3f litres from field #%d deposited at %s",
					realExpectedLitres, mission.field.fieldId, mission.sellPoint:getName()))
					
				mission.surplusLitres = mission.simulationLitres - realExpectedLitres
				mission.sellPoint:sellFillType(farmId, mission.surplusLitres, mission.fillType, ToolType.UNDEFINED)
				print(string.format("HarvestMissionFix: %.3f surplus litres from field #%d sold to %s",
					mission.surplusLitres, mission.field.fieldId, mission.sellPoint:getName()))
			end
			mission.simulationComplete = true
		end
		
		mission.maxCutLiters = self:getMaxCutLiters()
		mission.fieldCompletion = HarvestMissionFix.getFieldCompletion(self)

		if mission.totalArea and mission.correctionFactor == nil then

			mission.sprayFactor = self.sprayFactor or 0
			mission.plowFactor = self.fieldPlowFactor or 0
			mission.limeFactor = self.limeFactor or 0
			mission.weedFactor = self.weedFactor or 0
			mission.stubbleFactor = self.stubbleFactor or 0
			mission.rollerFactor = self.rollerFactor or 0
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)
			mission.multiplier = g_currentMission:getHarvestScaleMultiplier(self.fruitType, mission.sprayFactor, mission.plowFactor, mission.limeFactor, mission.weedFactor, mission.stubbleFactor, mission.rollerFactor)
			mission.literPerSqm = fruitDesc.literPerSqm
			if fruitDesc.hasWindrow then
				mission.literPerSqm = math.min(mission.literPerSqm, fruitDesc.windrowLiterPerSqm)
			end
			
			mission.totalFactor = 1
			mission.totalFactor = mission.totalFactor + g_currentMission.harvestSprayScaleRatio * mission.sprayFactor
			mission.totalFactor = mission.totalFactor + g_currentMission.harvestPlowScaleRatio * mission.plowFactor
			mission.totalFactor = mission.totalFactor + g_currentMission.harvestLimeScaleRatio * mission.limeFactor
			mission.totalFactor = mission.totalFactor + g_currentMission.harvestWeedScaleRatio * mission.weedFactor
			mission.totalFactor = mission.totalFactor + g_currentMission.harvestStubbleScaleRatio * mission.stubbleFactor
			mission.totalFactor = mission.totalFactor + g_currentMission.harvestRollerRatio * mission.rollerFactor

			mission.averageMultiplier = HarvestMissionFix.getHarvestMultiplier(mission)
			
			local correction = (mission.totalFactor - mission.averageMultiplier) / mission.totalFactor
			if correction > 0 then
				mission.correctionFactor = 1/(1+correction)
			else
				mission.correctionFactor = 1
			end
			
			local areaFactor = mission.totalArea/mission.field.fieldArea
			if areaFactor < 1 then
				mission.correctionFactor = mission.correctionFactor * areaFactor
			end
			
			if HarvestMissionFix.bonusfactor and HarvestMissionFix.bonusfactor > 0 then
				function clamp(x, min, max)
					if x < min then return min end
					if x > max then return max end
					return x
				end
				HarvestMissionFix.bonusfactor = clamp(HarvestMissionFix.bonusfactor, 0, 0.05)
				mission.correctionFactor = mission.correctionFactor * (1-HarvestMissionFix.bonusfactor)
			end
			print(string.format("HarvestMissionFix: Using correction factor %.3f for field #%d",
				mission.correctionFactor, mission.field.fieldId))
			-- self.expectedLiters = self.expectedLiters * mission.correctionFactor
		end
		
		local expectedLiters = self.expectedLiters
		if mission.correctionFactor then
			expectedLiters = expectedLiters * mission.correctionFactor
		end
		
		mission.sellCompletion = math.min(1, self.depositedLiters / expectedLiters / HarvestMission.SUCCESS_FACTOR)
		mission.harvestCompletion = math.min(1, mission.fieldCompletion / AbstractMission.SUCCESS_FACTOR)
		mission.totalCompletion = math.min(1, 0.8 * mission.harvestCompletion + 0.2 * mission.sellCompletion)
		
		return mission.totalCompletion

	end
	
	return 0
end

-- NEW FUNCTION TO CALCULATE FIELD COMPLETION
function HarvestMissionFix.getFieldCompletion(self)

	if #HarvestMissionFix.missions == 0 then
		return 0
	end
	
	local i = HarvestMissionFix.getMissionIndex(self)
	local mission = HarvestMissionFix.missions[i]
	if mission then
	
		mission.partition = {}
		mission.numPartitions = table.getn(self.field.getFieldStatusPartitions)
		
		local pixels = 0;
		local totalPixels = 0;

		for i = 1, mission.numPartitions do
		
			mission.partition[i] = {}
			
			local partition = self.field.getFieldStatusPartitions[i]
			local area, totalArea = self:partitionCompletion(partition.x0, partition.z0, partition.widthX, partition.widthZ, partition.heightX, partition.heightZ)
			mission.partition[i].partitionArea = area
			mission.partition[i].partitionTotalArea = totalArea
			mission.partition[i].partitionPercentage = area / totalArea
			
			pixels = pixels + area
			totalPixels = totalPixels + totalArea
			
		end

		local realArea = MathUtil.areaToHa(pixels, g_currentMission:getFruitPixelsToSqm())
		local totalArea = MathUtil.areaToHa(totalPixels, g_currentMission:getFruitPixelsToSqm())
		
		mission.totalArea = totalArea
		mission.harvestCompletion = realArea / totalArea
		
		return mission.harvestCompletion
	end
	
	return 0
end

-- OVERRIDE SOME HARVEST MISSION FUNCTIONS
local oldHarvestGetCompletion = HarvestMission.getCompletion
HarvestMission.getCompletion = function(...)
	
	local correctedCompletion = HarvestMissionFix.getCompletion(...)
	if correctedCompletion then
		return correctedCompletion
	else
		local originalCompletion = oldHarvestGetCompletion(...)
		print("Original Completion: " .. originalCompletion)
		return originalCompletion
	end
end

local oldHarvestSaveToXMLFile = HarvestMission.saveToXMLFile
HarvestMission.saveToXMLFile = function(self, xmlFile, key)
	oldHarvestSaveToXMLFile(self, xmlFile, key)
	local harvestKey = string.format("%s.harvest", key)
	if self.collectedLiters then setXMLFloat(xmlFile, harvestKey .. "#collectedLiters", self.collectedLiters) end
	if self.correctionFactor then setXMLFloat(xmlFile, harvestKey .. "#correctionFactor", self.correctionFactor) end
end

local oldHarvestLoadFromXMLFile = HarvestMission.loadFromXMLFile
HarvestMission.loadFromXMLFile = function(self, xmlFile, key)
	local harvestKey = key .. ".harvest(0)"
	self.collectedLiters = getXMLFloat(xmlFile, harvestKey .. "#collectedLiters") or 0
	self.correctionFactor = getXMLFloat(xmlFile, harvestKey .. "#correctionFactor") or nil
	return oldHarvestLoadFromXMLFile(self, xmlFile, key)
end



-- DETERMINE THE REAL PARAMETERS WITHOUT CHANGING FIELD
function HarvestMissionFix.testFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, useMinForageState, excludedSprayType, setsWeeds, limitToField)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)

	if desc.terrainDataPlaneId == nil or desc.cutState == 0 then
		return 0
	end

	-- INITIALISE FUNCTION CACHE
	local functionData = FSDensityMapUtil.functionCache.cutFruitArea
	if functionData == nil then
		FSDensityMapUtil.cutFruitArea(fruitIndex, 0, 0, 0, 0, 0, 0, destroySpray, useMinForageState, excludedSprayType)
		functionData = FSDensityMapUtil.functionCache.cutFruitArea
		if functionData == nil then
			print("HarvestMissionFix: FSDensityMapUtil.functionCache was NOT INITIALISED")
			return 0
		end
	end

	-- FRIUT FILTER
	local terrainRootNode = g_currentMission.terrainRootNode
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local fruitValueModifier = functionData.fruitValueModifiers[fruitIndex]
	local fruitFilter = functionData.fruitFilters[fruitIndex]

	if fruitValueModifier == nil then
		fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		fruitValueModifier:setReturnValueShift(-1)

		fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		functionData.fruitFilters[fruitIndex] = fruitFilter
	end
	
	local minState = desc.minHarvestingGrowthState
	if useMinForageState then
		minState = desc.minForageGrowthState
	end
	fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)
	fruitValueModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	
	local groundTypeFilter = nil
	if limitToField then
		groundTypeFilter = functionData.groundTypeFilter
	end

	local density, numPixels, totalNumPixels = fruitValueModifier:executeGet(fruitFilter, groundTypeFilter)
	local plowFactor = 0
	local limeFactor = 0
	local sprayFactor = 0
	local stubbleFactor = 0
	local rollerFactor = 0
	
	-- WEED FACTOR
	local weedFactor = 1
	local missionInfo = g_currentMission.missionInfo
	if missionInfo.weedsEnabled and desc.plantsWeed then
		weedFactor = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
	end

	if numPixels > 0 then
	
		-- PLOW FACTOR
		if desc.lowSoilDensityRequired and missionInfo.plowingRequiredEnabled then
			local plowLevelModifier = functionData.plowLevelModifier
			local plowLevelFilter = functionData.plowLevelFilter
			plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			local _, plowTotalDelta, _ = plowLevelModifier:executeGet(fruitFilter, plowLevelFilter)
			plowFactor = math.abs(plowTotalDelta) / numPixels
		else
			plowFactor = 1
		end

		-- LIME FACTOR
		if desc.growthRequiresLime and missionInfo.limeRequired and Platform.gameplay.useLimeCounter then
			if desc.consumesLime then
				local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
				local limeLevelFilter = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
				local limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
				limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
				limeLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
				local _, limeTotalDelta, _ = limeLevelModifier:executeGet(limeLevelFilter)
			
				limeFactor = math.abs(limeTotalDelta) / numPixels
			else
				limeFactor = 0
			end
		else
			limeFactor = 1
		end
		
		--SPRAY FACTOR
		local sprayLevelModifier = functionData.sprayLevelModifier
		local sprayLevelMaxValue = functionData.sprayLevelMaxValue
		sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local sprayPixelsSum, _, _ = sprayLevelModifier:executeGet(fruitFilter)
		sprayFactor = sprayPixelsSum / (numPixels * sprayLevelMaxValue)
		
		-- STUBBLE FACTOR
		if Platform.gameplay.useStubbleShred then
			local stubbleShredModifier = functionData.stubbleShredModifier
			stubbleShredModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			local _, stubbleTotalDelta, _ = stubbleShredModifier:executeGet(fruitFilter, functionData.stubbleShredFilter)
		
			stubbleFactor = math.abs(stubbleTotalDelta) / numPixels
		else
			stubbleFactor = 1
		end
		
		-- ROLLER FACTOR
		if desc.needsRolling and Platform.gameplay.useRolling then
			local rollerLevelModifier = functionData.rollerLevelModifier
			local rollerLevelFilter = functionData.rollerLevelFilter
			rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			local _, rollerTotalDelta, _ = rollerLevelModifier:executeGet(fruitFilter, rollerLevelFilter)
		
			rollerFactor = math.abs(rollerTotalDelta) / numPixels
		else
			rollerFactor = 1
		end

	end
	
	if desc.allowsPartialGrowthState then
		return density / math.max(desc.maxHarvestingGrowthState - 1, 1), totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor
	else
		return numPixels, totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor
	end
end

-- DETERMINE THE REAL MULTIPLIER WITHOUT CHANGING FIELD
function HarvestMissionFix.getHarvestMultiplier(mission)

	local field = mission.field
	local sumArea = 0
	local sumMultiplier = 0
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		local destroySpray = true
		local useMinForageState = false
		local excludedSprayType = nil
		local setsWeeds = nil
		local limitToField = nil
		local realArea, _, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor = HarvestMissionFix.testFruitArea(field.fruitType, x, z, x1, z1, x2, z2, destroySpray, useMinForageState, excludedSprayType, setsWeeds, limitToField)
		local multiplier = g_currentMission:getHarvestScaleMultiplier(field.fruitType, sprayFactor or 0, plowFactor or 0, limeFactor or 0, weedFactor or 0, stubbleFactor or 0, rollerFactor or 0)
		sumArea = sumArea + (realArea or 0) * multiplier
		sumMultiplier = sumMultiplier + multiplier
	end

	local averageMultiplier = sumMultiplier / numDimensions

	return averageMultiplier
end

-- DO AN ACTUAL REAL HARVEST OF THE FIELD
function HarvestMissionFix.testHarvestField(mission)

	local field = mission.field
	local sumArea = 0
	local sumMultiplier = 0
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		local destroySpray = true
		local useMinForageState = false
		local excludedSprayType = nil
		local setsWeeds = nil
		local limitToField = nil
		local realArea, _, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, _, _, _, _ = FSDensityMapUtil.cutFruitArea(field.fruitType, x, z, x1, z1, x2, z2, destroySpray, useMinForageState, excludedSprayType, setsWeeds, limitToField)
		local multiplier = g_currentMission:getHarvestScaleMultiplier(field.fruitType, sprayFactor or 0, plowFactor or 0, limeFactor or 0, weedFactor or 0, stubbleFactor or 0, rollerFactor or 0)
		sumArea = sumArea + realArea * multiplier
		sumMultiplier = sumMultiplier + multiplier
	end

	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)
	local litersPerSqm = fruitDesc.literPerSqm
	local totalLiters = sumArea * g_currentMission:getFruitPixelsToSqm() * litersPerSqm
	local averageMultiplier = sumMultiplier / numDimensions

	return totalLiters, averageMultiplier
end


-- REPLACE "findFieldSizes" TO FIX THE INCORRECT AREA REPORTED FOR DIFFERENT SIZED MAPS
function FieldManager:findFieldSizes(bitMapSize)

	local terrainSize = getTerrainSize(self.mission.terrainRootNode) or 2048
    local bitMapSize = bitMapSize or (2*terrainSize)
	
    local function convertWorldToAccessPosition(x, z)
        return math.floor(bitMapSize * (x + terrainSize * 0.5) / terrainSize), math.floor(bitMapSize * (z + terrainSize * 0.5) / terrainSize)
    end

    local function pixelToHa(area)
        local pixelToSqm = terrainSize / bitMapSize

        return area * pixelToSqm * pixelToSqm / 10000
    end

    for N, field in pairs(self.fields) do
        local sumPixel = 0
        local bitVector = createBitVectorMap("field")

        loadBitVectorMapNew(bitVector, bitMapSize, bitMapSize, 1, true)

        for i = 0, getNumOfChildren(field.fieldDimensions) - 1 do
            local dimWidth = getChildAt(field.fieldDimensions, i)
            local dimStart = getChildAt(dimWidth, 0)
            local dimHeight = getChildAt(dimWidth, 1)
            local x0, _, z0 = getWorldTranslation(dimStart)
            local widthX, _, widthZ = getWorldTranslation(dimWidth)
            local heightX, _, heightZ = getWorldTranslation(dimHeight)
            local x, z = convertWorldToAccessPosition(x0, z0)
            widthX, widthZ = convertWorldToAccessPosition(widthX, widthZ)
            heightX, heightZ = convertWorldToAccessPosition(heightX, heightZ)
            sumPixel = sumPixel + setBitVectorMapParallelogram(bitVector, x, z, widthX - x, widthZ - z, heightX - x, heightZ - z, 0, 1, 0)
        end

        field.fieldArea = pixelToHa(sumPixel)

        delete(bitVector)
    end
	
end



