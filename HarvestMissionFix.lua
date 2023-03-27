
HarvestMissionFix = {}
addModEventListener(HarvestMissionFix)

HarvestMissionFix.missions = {}

function HarvestMissionFix.getMissionIndex(field)
	for k, v in pairs(HarvestMissionFix.missions) do
		if v.field.fieldId == field.fieldId then
			return k
		end
	end
	return 0
end

function HarvestMissionFix.insertMission(self)
	local mission = {}
	mission.active = true
	mission.self = self
	mission.field = self.field
	mission.sellPoint = self.sellPoint
	mission.harvestedLitres = 0
	table.insert(HarvestMissionFix.missions, mission)
	table.sort(HarvestMissionFix.missions, function(a, b) return a.field.fieldId < b.field.fieldId end )
	
	local index = HarvestMissionFix.getMissionIndex(self.field)	
	return HarvestMissionFix.missions[index]
end

FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, function()
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
	
    local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_TOGGLE_INFO", HarvestMissionFix, HarvestMissionFix.toggleInfo, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
	HarvestMissionFix.toggleInfoActionEventId = actionEventId
	
	local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_CYCLE_FW", HarvestMissionFix, HarvestMissionFix.cycleFW, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
	g_inputBinding:setActionEventTextVisibility(actionEventId, false)
	HarvestMissionFix.cycleFWActionEventId = actionEventId
	
	local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_CYCLE_BW", HarvestMissionFix, HarvestMissionFix.cycleBW, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
	g_inputBinding:setActionEventTextVisibility(actionEventId, false)
	HarvestMissionFix.cycleBWActionEventId = actionEventId
	

	local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent("HARVEST_MISSION_TEST", HarvestMissionFix, HarvestMissionFix.test, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
	HarvestMissionFix.testActionEventId = actionEventId
end)

		
function HarvestMissionFix:toggleInfo()
	HarvestMissionFix.show = not (HarvestMissionFix.show or false)
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
		if mission and mission.active then
			mission.simulationLitres, mission.simulationMultiplier = HarvestMissionFix.testHarvestField(mission)
		end
	end
end

function HarvestMissionFix.cycleIndex(direction)

	HarvestMissionFix.index = HarvestMissionFix.index or 0

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
	local top = 0.88
	local d = 0.0150
	local b = 0.0125
	local x = function(delta)
		top = top - (delta or d)
		return top
	end
	local printLine = function(delta)
		top = top - (delta or d)
		return top
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(false)
	
	local mission = HarvestMissionFix.missions[HarvestMissionFix.index or 1]
	if mission == nil or not HarvestMissionFix.show or #HarvestMissionFix.missions == 0 then
		if HarvestMissionFix.show then
			setTextColor(1, 1, 1, 1)
			renderText(left, x(b), d, string.format("------------------------------"))
			renderText(left, x(d), d, string.format("NO ACTIVE MISSIONS"))
			renderText(left, x(b), d, string.format("------------------------------"))
		end
		return
	end
	
	if mission.harvestedLitres and mission.harvestedLitres < 0 then
		mission.harvestedLitres = 0
	end
	
	if mission.active then
		setTextColor(1, 1, 1, 1)
	else
		if mission.success then
			setTextColor(0, 1, 0, 1)
		else
			setTextColor(1, 0, 0, 1)
		end
	end
	renderText(left, x(b), d, string.format("------------------------------"))
	renderText(left, x(d), d, string.format("FIELD #%d       AREA: %.3f ha", mission.fieldNumber or 0, mission.area or 0))
	renderText(left, x(d), d, string.format("Sell Point:  %s", mission.sellPoint:getName()))
	renderText(left, x(d), d, string.format("Max Cut Litres:       %.1f l", mission.maxCutLiters or 0))
	renderText(left, x(d), d, string.format("Litres Per Sqm:       %.3f", mission.literPerSqm or 0))
	renderText(left, x(d), d, string.format("Fruit Pixels To Sqm:  %.3f", g_currentMission:getFruitPixelsToSqm() or 0))
	renderText(left, x(b), d, string.format("------------------------------"))
	local realExpectedLitres = (mission.expectedLiters or 0) * AbstractMission.SUCCESS_FACTOR
	renderText(left, x(d), d, string.format("Expected:             %.1f l", realExpectedLitres or 0))
	renderText(left, x(d), d, string.format("Collected:            %.1f l", mission.harvestedLitres or 0))
	renderText(left, x(d), d, string.format("Deposited:            %.1f l", mission.depositedLiters or 0))
	renderText(left, x(d), d, string.format("SELL Completion:      %.1f %%", 100*(mission.sellCompletion or 0)))
	renderText(left, x(d), d, string.format("FIELD Completion:     %.1f %%", 100*(mission.fieldCompletion or 0)))
	renderText(left, x(d), d, string.format("HARVEST Completion:   %.1f %%", 100*(mission.harvestCompletion or 0)))
	renderText(left, x(b), d, string.format("------------------------------"))
	setTextBold(true)
	renderText(left, x(d), d, string.format("TOTAL COMPLETION:   %.1f %%", 100*(mission.totalCompletion or 0)))
	setTextBold(false)
	renderText(left, x(b), d, string.format("------------------------------"))
	renderText(left, x(b), b, string.format(""))
	renderText(left, x(d), d, string.format("Spray Factor:   %.3f", mission.sprayFactor or 0))
	renderText(left, x(d), d, string.format("Plow Factor:    %.3f", mission.plowFactor or 0))
	renderText(left, x(d), d, string.format("Lime Factor:    %.3f", mission.limeFactor or 0))
	renderText(left, x(d), d, string.format("Weed Factor:    %.3f", mission.weedFactor or 0))
	renderText(left, x(d), d, string.format("Stubble Factor: %.3f", mission.stubbleFactor or 0))
	renderText(left, x(d), d, string.format("Roller Factor:  %.3f", mission.rollerFactor or 0))
	setTextBold(true)
	renderText(left, x(d), d, string.format("TOTAL Factor:   %.3f", mission.totalFactor or 0))
	setTextBold(false)
	renderText(left, x(b), b, string.format(""))
	
	if mission.averageMultiplier and mission.correctionFactor then
		renderText(left, x(d), d, string.format("Predicted Multiplier:   %.3f", mission.averageMultiplier or 0))
		renderText(left, x(d), d, string.format("Correction Factor:      %.3f", mission.correctionFactor or 0))
		renderText(left, x(b), b, string.format(""))
	end
	
	if mission.simulationLitres and mission.simulationMultiplier and mission.expectedLiters then
	
		local realExpectedLitres = mission.expectedLiters * AbstractMission.SUCCESS_FACTOR
		local harvestRatio = (realExpectedLitres-mission.simulationLitres)/realExpectedLitres
		renderText(left, x(d), d, string.format("Simulation Multiplier:   %.3f", mission.simulationMultiplier or 0))
		renderText(left, x(d), d, string.format("Simulation Litres:       %.1f l", mission.simulationLitres or 0))
		renderText(left, x(d), d, string.format("Simulation Shortfall:    %.2f %%", 100*harvestRatio ))
		renderText(left, x(b), b, string.format(""))
	end

	if mission.totalArea and mission.realArea and mission.expectedLiters then
		mission.completion = mission.realArea / mission.totalArea
		local realExpectedLitres = mission.expectedLiters * AbstractMission.SUCCESS_FACTOR
		local totalCollectedLitres = mission.harvestedLitres + mission.depositedLiters
		local shortfallPercent = math.max(0, (realExpectedLitres-totalCollectedLitres)/realExpectedLitres)
		local surplusPercent = math.max(0, ((totalCollectedLitres-realExpectedLitres)+(mission.surplusLitres or 0))/realExpectedLitres)
		renderText(left, x(d), d, string.format("Harvest Completion:  %.1f %%", 100*mission.completion))
		renderText(left, x(d), d, string.format("Harvest Shortfall:   %.2f %%", 100*shortfallPercent))
		renderText(left, x(d), d, string.format("Harvest Surplus:     %.2f %%", 100*surplusPercent))
		renderText(left, x(b), b, string.format(""))
	end
	
	if mission.numPartitions then
		local w = left
		renderText(left, x(d), d, string.format("Partitions: %d   Area: %.3f ha", mission.numPartitions, mission.totalArea))
		renderText(left, x(b/2), b/2, string.format(""))
		for i = 1, mission.numPartitions do
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
	local mission = HarvestMissionFix.insertMission(self)
	HarvestMissionFix.index = HarvestMissionFix.getMissionIndex(self.field)	
end
local oldHarvestStart = HarvestMission.start
HarvestMission.start = function(...) getStart(...) return oldHarvestStart(...) end

-- DETECT WHEN A MISSION IS ENDED
local function getFinish(self, success)
	local i = HarvestMissionFix.getMissionIndex(self.field)
	HarvestMissionFix.missions[i].active = false
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
				if mission and mission.active and mission.harvestedLitres then
					mission.harvestedLitres = mission.harvestedLitres + fillLevelDelta
				end
			end
		end
	end
end
local oldRaiseEvent = SpecializationUtil.raiseEvent
SpecializationUtil.raiseEvent = function(...) raiseEvent(...) return oldRaiseEvent(...) end

function HarvestMissionFix.getCompletion(self)

	local i = HarvestMissionFix.getMissionIndex(self.field)
	if i == 0 then
		HarvestMissionFix.insertMission(self)
		i = HarvestMissionFix.getMissionIndex(self.field)
	end
	
	local mission = HarvestMissionFix.missions[i]
	if mission then
	
		if mission.simulationLitres and mission.expectedLiters and mission.fieldCompletion > 0.999 and not mission.complete then

			local realExpectedLitres = mission.expectedLiters * AbstractMission.SUCCESS_FACTOR
			
			if realExpectedLitres > mission.simulationLitres then
				mission.self:fillSold(mission.simulationLitres)
			else
				local farmId = FarmManager.SINGLEPLAYER_FARM_ID
				mission.self:fillSold(realExpectedLitres)
				mission.surplusLitres = mission.simulationLitres - realExpectedLitres
				mission.sellPoint:sellFillType(farmId, mission.surplusLitres, mission.fillType, ToolType.UNDEFINED)
				print(string.format("HarvestMissionFix: Surplus Litres %.3f from field #%d sold to %s",
					mission.surplusLitres, mission.fieldNumber, mission.sellPoint:getName()))
			end
			mission.complete = true
		end
		
		mission.active = true
		mission.fillType = self.fillType
		mission.field = self.field
		mission.fieldNumber = self.field.fieldId
		mission.maxCutLiters = self:getMaxCutLiters()
		mission.expectedLiters = self.expectedLiters
		mission.depositedLiters = self.depositedLiters
		mission.fieldCompletion = self:getFieldCompletion()
		
		mission.sellCompletion = math.min(1, self.depositedLiters / self.expectedLiters / HarvestMission.SUCCESS_FACTOR)
		mission.harvestCompletion = math.min(1, mission.fieldCompletion / AbstractMission.SUCCESS_FACTOR)
		mission.totalCompletion = math.min(1, 0.8 * mission.harvestCompletion + 0.2 * mission.sellCompletion)

		if mission.correctionFactor == nil then

			mission.sprayFactor = self.sprayFactor or 0
			mission.plowFactor = self.fieldPlowFactor or 0
			mission.limeFactor = self.limeFactor or 0
			mission.weedFactor = self.weedFactor or 0
			mission.stubbleFactor = self.stubbleFactor or 0
			mission.rollerFactor = self.rollerFactor or 0
			
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)
			mission.area = self.field.fieldArea
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
			
			local areaFactor = mission.totalArea/mission.area
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
			print(string.format("HarvestMissionFix: Applied correction factor %.3f to field #%d",
				mission.correctionFactor, mission.fieldNumber))
			self.expectedLiters = self.expectedLiters * mission.correctionFactor
		end
	end
end

function HarvestMissionFix.getFieldCompletion(self)

	if #HarvestMissionFix.missions == 0 then
		return
	end
	
	local i = HarvestMissionFix.getMissionIndex(self.field)
	local mission = HarvestMissionFix.missions[i] or {}
	
	mission.partition = {}
	mission.numPartitions = table.getn(self.field.getFieldStatusPartitions)
	
	mission.pixels = 0;
	mission.totalPixels = 0;
	mission.realArea = 0;
	mission.totalArea = 0;
	mission.maxPix = 0
	mission.minPix = math.huge
	
	for i = 1, mission.numPartitions do
	
		mission.partition[i] = {}
		
		local partition = self.field.getFieldStatusPartitions[i]
		local area, totalArea = self:partitionCompletion(partition.x0, partition.z0, partition.widthX, partition.widthZ, partition.heightX, partition.heightZ)
		mission.partition[i].partitionArea = area
		mission.partition[i].partitionTotalArea = totalArea
		mission.partition[i].partitionPercentage = area / totalArea
		
		mission.pixels = mission.pixels + area
		mission.totalPixels = mission.totalPixels + totalArea
		
		mission.maxPix = math.max(mission.maxPix, totalArea)
		mission.minPix = math.min(mission.minPix, totalArea)
		
	end
	
		
	local deltaSum = 0
	mission.mean = mission.totalPixels / mission.numPartitions
	
	for i = 1, mission.numPartitions do
	
		local delta = mission.mean - mission.partition[i].partitionTotalArea
		deltaSum = deltaSum + (delta*delta)
	end
	mission.variance = deltaSum / mission.numPartitions
	mission.stddev = math.sqrt(mission.variance)

	mission.realArea = MathUtil.areaToHa(mission.pixels, g_currentMission:getFruitPixelsToSqm())
	mission.totalArea = MathUtil.areaToHa(mission.totalPixels, g_currentMission:getFruitPixelsToSqm())
	
end

-- DETECT WHEN "getCompletion" IS CALLED DURING A MISSION
local oldHarvestGetCompletion = HarvestMission.getCompletion
HarvestMission.getCompletion = function(...)
	local originalCompletion = oldHarvestGetCompletion(...)
	HarvestMissionFix.getFieldCompletion(...)
	HarvestMissionFix.getCompletion(...)
	return originalCompletion
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



