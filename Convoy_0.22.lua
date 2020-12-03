-- Convoy_0.22 Implementing a _RandomizeStartPoint(coordinate) function which is derived from _RandomizeZones() and instead of using a Zone as a Group's
--             start point, uses a coordinate, making it easy to start a route at a given waypoint (i.e. a random waypoint from a route marker Group).

-- Convoy_0.20 2020.11.25 Starting with 0.18 to get the objects spawning. What's the issue?
               -- so far failed

-- Convoy_0.19 Full test of creating a fully randomized convoy at a random start point (via Zones) on a random route (copied to all convoy vehicles).
--             - script runs without errors but no objects are spawned

-- Convoy_0.18 1) Starting modified MOOSE function section at the top of this file. MOOSE.lua will now be used, not a modified MOOSE.lua
--             2) BIG: Copyable waypoints working, i.e. inthis case to allow a route from a one of 2+ route marker groups to be applied to all spawned vehicle in the convoyVeh
--                    - BUT limitations
--                           1) InitLimit needs to be set for now as the _RandomizeRoute fn which InitReplaceRoute is based on processes up to SpawnMaxGroups, which is 0 by default. #TODO I guess SpawnMaxGroups is incremented when a SPAWN occurs? How to get around this hack?
--                           2) Due tot he same issue of processing all spawns of the same group, this won't I believe allow for differnt spawns to have different waypoints (ideally would be creating one object of each convoy and spawning it for different convoys or simply in different places)

-- Convoy_0.17 2020.11.22 Successsfully tests RouteGroundTo() BUT only with ME Activated unit. Script spawning didn't work

-- Convoy_0.16 2020.11.21 Implements Exclusive Or (XOR) via XorTable to allow one of two groups to be generated (e.g. the convoy either has fuel trucks OR MBTs as the core vehlicles).

-- Convoy_0.15 2020.11.21 1) Implements FixedVehicleOrder for the objects in a convoy. Vehicles are generated in the same order as in the convoy component listing.                        2) 
--                        2) Checks for a convoy component Actual Qty of 0 or more and only generates a Gaussian quantity if ActualQty < 0 (i.e. enables manual setting of precise quantities).

-- Convoy_0.14 2020.11.15 Implements MaxOneSpawnPerItem for each component (MaxOneSpawnPerItem = "true" or "")

-- Convoy_0.13 2020.11.15 Implements random order of selected convoy components within the ENTIRE CONVOY (Order = "" gives same position as listed in ConvoyComponents; All components with Order = "?" are shuffled)

-- Convoy 0.12 2020.11.15 Implements probability for each component

-- Convoy_0.11 2020.11.15 Implements an n-section fully flexible structure. Great! This is not the basis for additional features like "ChanceOfNone", "Order" (of selected components) & "Fixed" (same order as in component table)

-- Convoy_0.10 2020.11.14  Created the 5-section instead of 3-section convoy, i.e. 
--    1) Lead1 group (e.g. scouts vehicles)
--    2) Lead2 groups (e.g. heavy weapons/SAMs)
--    3) Cenral group (e.g. MBTs or transports)
--    4) Trailer2 group (second to last, e.g. heavy weapons)
--    5) Trailer1 group (e.g. scout vehicles)

--  Convoy_0.9 2020.11.10 Added zones for a random start point!   
--    : ISSUE: Some vehs have different road speeds which seem to be independent of the speed set in the ME e.g. M1 & Stryker are faster 
--             than the marine APC.

--  Test 0.8 Added a Gaussian Spawn Time callback. Great!

--  Test 0.7 Removed (in TIMER) the args min and max spawn time and the related self.dTMin and self.dtMax

--  Test_0.6: Works great
--    : Callback function to execute the random spawn time, with math.random now but next a Gaussian distn for ultimate realism.

--  Test_0.5: Fully random and customisable convoys. :-)
--    : Generates a convoy with random spawn times, by passing in min and max spawn times and using math.random hard-coded within MOOSE's TIMER class
--    : Needs every vehicle to have it's own type and full waypoints


--
--  MODIFIED MOOSE FUNCTIONS
--
function SPAWN:InitReplaceRoute( Route )
  --self:F( { self.SpawnTemplatePrefix, SpawnStartPoint, SpawnEndPoint, SpawnRadius, SpawnHeight } )
  env.info( ">> In InitReplaceRoute()" )
  env.info( "  - The replacement route has " .. tostring( table.getn(Route) ) .. " waypoints" )

  self.SpawnWithReplacementRoute = true
  self.ReplacementRoute = Route

  env.info(" self.SpawnMaxGroups is: " .. tostring(self.SpawnMaxGroups) )
  for GroupID = 1, self.SpawnMaxGroups do
    self:_ReplaceGroundRoute( GroupID )
  end
  
  env.info("")
  return self
end

function SPAWN:InitSpawnAtWayPoint( waypointIndex )
  --self:F( { self.SpawnTemplatePrefix, SpawnStartPoint, SpawnEndPoint, SpawnRadius, SpawnHeight } )
  env.info( ">> In InitSpawnAtWayPoint()" )
  env.info( "  - The waypointIndex to  spawn at is: " .. tostring( waypointIndex ) )

  self.SpawnAtProvidedWaypointIndex = true
  self.WaypointIndexToSpawnAt = waypointIndex

  env.info(" self.SpawnAtProvidedWaypoint is: " .. tostring(self.SpawnAtProvidedWaypoint) )
  for GroupID = 1, self.SpawnMaxGroups do
    self:_SpawnAtWaypoint( GroupID )
  end
  
  env.info("")
  return self
end


function SPAWN:_ReplaceGroundRoute( SpawnIndex )
  --self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeRoute, self.SpawnRandomizeRouteStartPoint, self.SpawnRandomizeRouteEndPoint, self.SpawnRandomizeRouteRadius } )
  env.info( ">> In _ReplaceGroundRoute()" )
  env.info( "  - SpawnIndex is: " .. tostring(SpawnIndex) )

  if self.SpawnWithReplacementRoute then
    env.info( "  - self.SpawnWithReplacementRoute is true")
  else
    env.info( "  - self.SpawnWithReplacementRoute is FALSE")
  end

  if self.SpawnWithReplacementRoute then

    local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate 
    local RouteCount = #self.ReplacementRoute

    -- remove all but the first point
    -- firstPoint = SpawnTemplate.route.points[1]
    SpawnTemplate.route.points = {}
    --SpawnTemplate.route.insert(firstPoint)

    for t = 1, RouteCount do
      env.info("  - t: " .. t )
      env.info("  - x: " .. self.ReplacementRoute[t].x )
      env.info("  - x: " .. self.ReplacementRoute[t].y )

      table.insert(SpawnTemplate.route.points, routines.utils.deepCopy ( self.ReplacementRoute[t] )  )

      -- local thisPoint = { self.ReplacementRoute[t].x, self.ReplacementRoute[t].y }
      -- env.info( " thisPoint: " .. table.concat(thisPoint, ", ") )

      -- table.insert( SpawnTemplate.route.points, thisPoint )



      -- SpawnTemplate.route.points[t].x = self.ReplacementRoute[t].x
      -- SpawnTemplate.route.points[t].y = self.ReplacementRoute[t].y
      
     -- env.info( '  - SpawnTemplate.route.points[' .. t .. '].x = ' .. SpawnTemplate.route.points[t].x .. ', SpawnTemplate.route.points[' .. t .. '].y = ' .. SpawnTemplate.route.points[t].y )
    end


------------------------------------------------------------------------

function SPAWN:_SpawnAtWaypoint( SpawnIndex )
  --self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeZones } )

  if self.SpawnAtProvidedWaypointIndex and not self.SpawnRandomizeZones then -- let the official MOOSE Zones rand rake precedence (it doesn't make sense to do both do both)
    
    
    self:T( "Preparing Spawn at provided Waypoint", SpawnZone:GetName() )
    
    local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate
    local SpawnVec2 = self.ReplacementRoute.points[ self.WaypointIndexToSpawnAt ]
    
    self:T( { SpawnVec2 = SpawnVec2 } )
    
    local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate
    -----  continue from here (2020.12.03.1240)
    self:T( { Route = SpawnTemplate.route } )
    
    for UnitID = 1, #SpawnTemplate.units do
      local UnitTemplate = SpawnTemplate.units[UnitID]
      self:T( 'Before Translation SpawnTemplate.units['..UnitID..'].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. UnitTemplate.y )
      local SX = UnitTemplate.x
      local SY = UnitTemplate.y 
      local BX = SpawnTemplate.route.points[1].x
      local BY = SpawnTemplate.route.points[1].y
      local TX = SpawnVec2.x + ( SX - BX )
      local TY = SpawnVec2.y + ( SY - BY )
      UnitTemplate.x = TX
      UnitTemplate.y = TY
      -- TODO: Manage altitude based on landheight...
      --SpawnTemplate.units[UnitID].alt = SpawnVec2:
      self:T( 'After Translation SpawnTemplate.units['..UnitID..'].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. UnitTemplate.y )
    end
    SpawnTemplate.x = SpawnVec2.x
    SpawnTemplate.y = SpawnVec2.y
    SpawnTemplate.route.points[1].x = SpawnVec2.x
    SpawnTemplate.route.points[1].y = SpawnVec2.y
  end
    
  return self
  
end
------------------------------------------------------------------------




    env.info( "SpawnTemplate.route.points has " .. #SpawnTemplate.route.points .. " waypoints inserted")


--  FROM SPAWN_InitRand Route
-- for t = self.SpawnRandomizeRouteStartPoint + 1, ( RouteCount - self.SpawnRandomizeRouteEndPoint ) do
      
--       SpawnTemplate.route.points[t].x = SpawnTemplate.route.points[t].x + math.random( self.SpawnRandomizeRouteRadius * -1, self.SpawnRandomizeRouteRadius )
--       SpawnTemplate.route.points[t].y = SpawnTemplate.route.points[t].y + math.random( self.SpawnRandomizeRouteRadius * -1, self.SpawnRandomizeRouteRadius )

-- FROM CONTROLLABLE:CopyRoute
-- for TPointID = Begin + 1, #Template.route.points - End do
--       if Template.route.points[TPointID] then
--         Points[#Points+1] = routines.utils.deepCopy( Template.route.points[TPointID] )



  end
  
  env.info("")
  return self
end

--
----------------------------- end modified MOOSE functions
--




env.info("")
env.info(">>! Starting FN mission script")

--  ConvoyStartZoneTable has all of the possible start points for the convoy. These are marked with Trigger Zones with a 1 metre radius (so each
--  vehicle spawns from the same location). Actually the Zone radius doesn't matter as the location is the centre of the Zone. And BTW DCS resets a small radius to 16ft.
ConvoyStartZoneTable = { 
        ZONE:New( "ConvoyStartZone-1" ), 
        ZONE:New( "ConvoyStartZone-2" ),
        ZONE:New( "ConvoyStartZone-3" ),
        ZONE:New( "ConvoyStartZone-4" ),
        ZONE:New( "ConvoyStartZone-5" ),
        ZONE:New( "ConvoyStartZone-6" )
      }

 --  choose a random start point, which will appy to ALL vehicles int he convoy (all spawned vehicles) by creating a single zone table to supply to InitRandomizeZones
 actualStartZoneIndex = math.random( 1, #ConvoyStartZoneTable )
 env.info( ">> actualStartZoneIndex: " .. tostring(actualStartZoneIndex) )
 convoyStartZone = ConvoyStartZoneTable[ actualStartZoneIndex ]

 -- prepare a table with just the one zone for InitRandomizeZones because we want all vehicles to spawn at the same point
 convoySingleZoneTable = { convoyStartZone }  
 

--create classes for each convoy vehicle type. We can spawn as many of each as we like
-- "ARMOR"
APC_AAV_7                = SPAWN:New("APC AAV-7"):InitRandomizeZones( convoySingleZoneTable )
APC_M1043_HMMWV_Armament = SPAWN:New("APC M1043 HMMWV Armament"):InitRandomizeZones( convoySingleZoneTable )
APC_M1126_Stryker_ICV    = SPAWN:New("APC M1126 Stryker ICV"):InitRandomizeZones( convoySingleZoneTable )
APC_M113                 = SPAWN:New("APC M113"):InitRandomizeZones( convoySingleZoneTable )
ATGM_M1045_HMMWV_TOW     = SPAWN:New("ATGM M1045 HMMWV TOW"):InitRandomizeZones( convoySingleZoneTable )
ATGM_M1134_Stryker       = SPAWN:New("ATGM M1134 Stryker"):InitRandomizeZones( convoySingleZoneTable )
IFV_LAV_25               = SPAWN:New("IFV LAV-25"):InitRandomizeZones( convoySingleZoneTable )
IFV_M2A2_Bradley         = SPAWN:New("IFV M2A2 Bradley"):InitRandomizeZones( convoySingleZoneTable )
MBT_M1A2_Abrams          = SPAWN:New("MBT M1A2 Abrams"):InitRandomizeZones( convoySingleZoneTable )
TPz_Fuchs                = SPAWN:New("TPz Fuchs"):InitRandomizeZones( convoySingleZoneTable )
SPG_M1128_Stryker_MGS    = SPAWN:New("SPG M1128 Stryker MGS"):InitRandomizeZones( convoySingleZoneTable )

-- "UNARMMED"
Transport_M818           = SPAWN:New("Transport M818"):InitRandomizeZones( convoySingleZoneTable )
Tanker_M978_HEMTT        = SPAWN:New("Tanker M978 HEMTT"):InitRandomizeZones( convoySingleZoneTable )
HEMTT_TFFT               = SPAWN:New("HEMTT TFFT"):InitRandomizeZones( convoySingleZoneTable )
APC_M1025_HMMWV          = SPAWN:New("APC M1025 HMMWV"):InitRandomizeZones( convoySingleZoneTable )

-- "ARTILLERY"
SPH_M109_Paladin         = SPAWN:New("SPH M109 Paladin"):InitRandomizeZones( convoySingleZoneTable )
MLRS_M270                = SPAWN:New("MLRS M270"):InitRandomizeZones( convoySingleZoneTable )
MLRS_FDDM                = SPAWN:New("MLRS FDDM"):InitRandomizeZones( convoySingleZoneTable )

-- "AIR DEFENCE" 
AAA_Vulcan_M163         = SPAWN:New("AAA Vulcan M163"):InitRandomizeZones( convoySingleZoneTable )





--  ALL GROUPS  (WITH PROPERTIES) IN A LIGHT OBJECT
XConvoyComponents = {

    {
      Name = "Scouts",
      ChanceOfAny = 100,
      Order = "",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 3, 1, 1, 4},
      Items = { 
            APC_M1043_HMMWV_Armament
          }
    },

    {
      Name = "HeavyWeaponsFront",
      ChanceOfAny = 100,
      Order = "",
      FixedVehicleOrder = "true",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 5, 2, 2, 7},
      Items = { 
            APC_AAV_7, 
            APC_M1126_Stryker_ICV,  
            APC_M113,
            ATGM_M1045_HMMWV_TOW,
            ATGM_M1134_Stryker,
            IFV_LAV_25,
            IFV_M2A2_Bradley,
            SPG_M1128_Stryker_MGS,
          }
    },

    {
      Name = "Core Convoy 1",
      ChanceOfAny = 100,
      Order = "?",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 5, 2, 3, 14},
      Items = { 
           AAA_Vulcan_M163,
           --Tanker_M978_HEMTT, -- the tanker's speed seems to be well less than the 20kts test speed
           HEMTT_TFFT,
           MLRS_FDDM
          }
    },

    {
      Name = "Core Convoy 2",
      ChanceOfAny = 100,
      Order = "?",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 5, 2, 3, 14},
      Items = { 
          MBT_M1A2_Abrams
          }
    },

    {
      Name = "Transports",
      ChanceOfAny = 100,
      Order = "?",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 4, 2, 2, 8},
      Items = { 
           Transport_M818
          }
    },

    {
      Name = "Paladin Platoon",
      ChanceOfAny = 100,
      Order = "?",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 3, 2, 2, 6},
      Items = { 
           SPH_M109_Paladin
          }
    },

    {
      Name = "HeavyWeaponsRear",
      ChanceOfAny = 100,
      Order = "",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 3, 2, 2, 7},
      Items = { 
            APC_M1043_HMMWV_Armament,
            APC_AAV_7, 
            APC_M1043_HMMWV_Armament, 
            APC_M1126_Stryker_ICV,  
            APC_M113,
            ATGM_M1045_HMMWV_TOW,
            ATGM_M1134_Stryker,
            IFV_LAV_25,
            IFV_M2A2_Bradley,
            SPG_M1128_Stryker_MGS,
            AAA_Vulcan_M163
          }
    },

    {
      Name = "TailEndCharlie",
      ChanceOfAny = 100,
      Order = "",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 2, 1, 1, 3 },
      Items = {
            TPz_Fuchs
          }
    }

}


env.info("")
env.info( ">> STARTING ROUTE TEST")
-- RouteMarkerVehicle = SPAWN:New("RouteMarker")


-- local myRoute=GROUP:FindByName("RouteMarker"):CopyRoute()
-- env.info( "  - Copied route length: " .. tostring( table.getn(myRoute) ) )

-- --local convoyVeh=GROUP:FindByName("Test Dummy"):Spawn()
-- convoyVeh = SPAWN:New("Test Dummy")
-- convoyVeh:Spawn()

-- if (convoyVeh) then
--   env.info("Found the test dummy")
-- else 
--   env.info("Didn't find test dummy")
-- end

-- env.info("Setting the route")
-- convoyVeh:Route(myRoute)


-- local VehicleGroupInstance = SPAWN:New( "Test Dummy" )
-- VehicleGroupInstance:Spawn() -- 
--========================== WORKS

-- testGroup = GROUP:FindByName( "Test Dummy" )

-- local ToCoord = testGroup:GetCoordinate():Translate( 1000, 103 )

-- testGroup:RouteGroundTo(ToCoord, 50, "Vee")

--====================
routes = {
  "RouteMarker1",
  "RouteMarker2"
}

zones = {
  "Test Zone-1",
  "Test Zone-1"
}

luckyRouteIndex = math.random(1, #routes)

luckyRouteMarker = routes[luckyRouteIndex ]
convoyStartZone = zones[ luckyRouteIndex ]

RouteMarkerVehicle = SPAWN:New(luckyRouteMarker)
convoyRoute=GROUP:FindByName(luckyRouteMarker):CopyRoute()
env.info("  - Copied route has " .. tostring( table.getn(convoyRoute) ) ..  " waypoints")

--TestDummy  = SPAWN:New( "Test Dummy" ):InitLimit(3, 3):InitRandomizeZones( { convoyStartZone } ):InitReplaceRoute( convoyRoute )
TestDummy   = SPAWN:New( "APC BTR-80" ):InitLimit(20, 20):InitRandomizeZones( { convoyStartZone } ):InitReplaceRoute( convoyRoute )
APC_BTR_80 = SPAWN:New( "APC BTR-80" ):InitLimit(20, 20):InitRandomizeZones( { convoyStartZone } ):InitReplaceRoute( convoyRoute )   
APC_MTLB   = SPAWN:New( "APC MTLB"   ):InitLimit(20, 20):InitRandomizeZones( { convoyStartZone } ):InitReplaceRoute( convoyRoute )
ARV_BRDM_2 = SPAWN:New( "ARV BRDM-2" ):InitLimit(20, 20):InitRandomizeZones( { convoyStartZone } ):InitReplaceRoute( convoyRoute )
ARV_BTR_RD = SPAWN:New( "ARV BTR-RD" ):InitLimit(20, 20):InitRandomizeZones( { convoyStartZone } ):InitReplaceRoute( convoyRoute )
FDDM_Grad  = SPAWN:New( "FDDM Grad"  ):InitLimit(20, 20):InitRandomizeZones( { convoyStartZone } ):InitReplaceRoute( convoyRoute )

--TestDummy:Spawn() -- spawn it via DisplayVehicle()

ConvoyComponents = {
    {
      Name = "Only",
      ChanceOfAny = 100,
      Order = "",
      FixedVehicleOrder = "",
      MaxOneSpawnPerItem = "",
      ActualQty = -1,
      GaussianArgs = { 3, 1, 1, 4},
      Items = { 
            APC_BTR_80
          }
    }
  }

--

env.info("  ------")
env.info("")




-- XOR table
XorTable = {
  {
    Indices = { 3, 4 },  -- indices of the convoy components
    Weights = { 30, 70 }   -- % probabilities for which component will be ELIMINATED (the way it's currently set up to remove the "winner") to be generated (if it gets through any Probabilty filter)
  }
}


env.info("")
env.info(">> STARTING XOR FILTER")
-- Perform XOR elimiation from ConvoyComponents
for i = 1, #XorTable do  -- for each XOR entry 

    -- local thisXor = XorTable[i]

    -- -- get the total of the weights, e.g. 100
    -- local sumOfWeights = 0;
    -- for j = 1, #thisXor.Weights do
    --     sumOfWeights = sumOfWeights + thisXor.Weights[j]
    -- end
    -- env.info("  - XOR weights for XOR Table[" .. tostring(i) .. "] is " .. sumOfWeights )

    -- -- get a random number between 1 and thw max weights e.g. 33
    -- local luckyNum = math.random(1, sumOfWeights)
    -- env.info( "  - XOR lucky num is: " .. luckyNum )

    -- -- cycle through the individual weights, until the random number is <= the cumulative value weight 30, 100 would be index 2 winner
    -- local winningIndex = -1
    -- local cumulativeWeight = 0
    -- for k = 1, #thisXor.Weights do
    --     cumulativeWeight = cumulativeWeight + thisXor.Weights[k]
    --     env.info("    - XOR cumulative weight after index " .. tostring(k) .. " is " .. cumulativeWeight)
    --     if ( luckyNum <= cumulativeWeight ) then
    --         winningIndex = k
    --         break
    --     end
    -- end

    -- local convoyIndexToRemove = thisXor.Indices[winningIndex]
    -- env.info( "  ** XOR Result: Removing convoy index " .. tostring(convoyIndexToRemove) )  --.. " from ConvoyComponents (" .. ConvoyComponents[winningIndex].Name .. ")" )
    -- table.remove( ConvoyComponents, convoyIndexToRemove ) -- #TODO actually the non-winning indices should be removed, which allows for more than 2 convoy components in the XOR table.

end
env.info("  ------")
env.info("")


env.info("")
env.info(">> STARTING 'CHANCE OF ANY' FILTER")
-- put together a "survival" list, i.e. eliminate groups from spawning which don't pass the ChanceOfNone filter
ConvoyComponentGenerationOrderArrayOfIndices = {}  -- the table with the component indices that will actually be spawned, and in the order added
EliminatedIndices = {} -- just for testing (easier than printing all the survivors)

for i = 1, #ConvoyComponents do
  rollToSurvive = math.random( 1, 100 )
  thisComponent = ConvoyComponents[i]
  env.info( ">> Roll to survive for convoy component " .. ConvoyComponents[i].Name .. " is: " .. tostring(rollToSurvive) .. " against ChanceOfAny of: " .. tostring(thisComponent.ChanceOfAny) )

  if ( rollToSurvive <= thisComponent.ChanceOfAny ) then
    table.insert( ConvoyComponentGenerationOrderArrayOfIndices, i )
  else -- else the component gets missed out (no spawming)
   table.insert( EliminatedIndices, i )  
  end 
end  

env.info( ">> Eliminated Convoy Component indices: " .. table.concat(EliminatedIndices, ", ") .. " END")
env.info("  ------")
env.info("")



env.info("")
env.info(">> STARTING ORDER SHUFFLE")
-- now that the surviving units are in a list, check for convoy components that can be shuffled, makrked by "Order = ?"
FinalConvoyOrder = { unpack(ConvoyComponentGenerationOrderArrayOfIndices) }
env.info( "  - FinalConvoyOrder elements: " .. table.concat(FinalConvoyOrder, "; ") )

OrdinalIndicesToReallocate = {}
ConvoyComponentIndicesToShuffle = {}
-- check all convoy components for "Order = ?", creating a list of such indices
for i = 1, #ConvoyComponentGenerationOrderArrayOfIndices do
  local convoyComponentIndex = ConvoyComponentGenerationOrderArrayOfIndices[i]
  local thisComponent = ConvoyComponents[convoyComponentIndex]
  
  env.info("  - thisComponent.Order for index = " .. i .. " is " .. thisComponent.Order)
  if ( thisComponent.Order == "?" ) then
    table.insert( OrdinalIndicesToReallocate, i )
    table.insert( ConvoyComponentIndicesToShuffle, convoyComponentIndex )
  end  -- else do nothing; the other convoy components will hold their current position
end
env.info("OrdinalIndicesToReallocate: " .. table.concat(OrdinalIndicesToReallocate, "; "))
env.info("ConvoyComponentIndicesToShuffle: " .. table.concat(ConvoyComponentIndicesToShuffle, "; "))

-- now shuffle the positions
env.info("  .. ConvoyComponentGenerationOrderArrayOfIndices BEFORE shuffle: " .. table.concat(FinalConvoyOrder, "; "))
if ( #OrdinalIndicesToReallocate > 1 ) then -- if there's only one there's' nothing to swap with; if zero then all will follow there natural order from the ConvoyComponents table
  for i = 1, #OrdinalIndicesToReallocate do
    env.info(" Looking to relocate index: " .. OrdinalIndicesToReallocate[i] )
    FinalConvoyOrder[ OrdinalIndicesToReallocate[i] ] = table.remove( ConvoyComponentIndicesToShuffle,  math.random(1, #ConvoyComponentIndicesToShuffle) )
  end
  env.info("  --> ConvoyComponentGenerationOrderArrayOfIndices AFTER shuffle: " .. table.concat(FinalConvoyOrder, "; "))
end
env.info("  ------")
env.info("")



-- Keep track of which index and how many of that index have been spawned (vs ActualQty). #TODO Add these to the ConvoyComponents object?
CurrentConvoyComponentSpawningIndex = 1
QtySpawnedFromCurrentConvoyComponentSpawningIndex = 0
env.info("  >> #ConvoyComponents: " .. #ConvoyComponents )



env.info("")
env.info(">> STARTING COMPONENT QTY DETERMINATION")
--
-- Determine the number of items to generate for each convoy component
--
for  i = 1, #FinalConvoyOrder  do
  local convoyComponentIndex = FinalConvoyOrder[i]
  local thisComponent = ConvoyComponents[convoyComponentIndex]

  -- if the ActualQty is set (i.e. is 0 or more, use that quantity, otherwise generate a Gaussian random quantity)
  env.info( "  - ConvoyComponent " .. i .. " (" .. thisComponent.Name .. ") initial qty set to: " .. tostring(thisComponent.ActualQty) )
  if ( thisComponent.ActualQty < 0 ) then
    local decimalRand = UTILS.RandomGaussian( unpack(thisComponent.GaussianArgs) )
    env.info( "  - decimalRand: " .. tostring(decimalRand) )
    thisComponent.ActualQty = math.floor( decimalRand + 0.5 )   -- math.floor(a + .5) is a workaround for no "round" fn in Lua(!)
  end 
  
  --  for a MaxOneSpawnPerItem component, there can be a maximum qty of the number of vehicles in the component
  if ( thisComponent.MaxOneSpawnPerItem == "true" ) and ( thisComponent.ActualQty > #thisComponent.Items ) then
    env.info( " -- MaxOneSpawnPerItem Convoy Component " ..  thisComponent.Name .. " is about to have its quantity changed from " .. thisComponent.ActualQty .. " to " .. #thisComponent.Items)
    thisComponent.ActualQty = #thisComponent.Items
  end  

--  for a FixedOrder component, there can be a maximum qty of the number of vehicles in the component
  if ( thisComponent.FixedOrder == "true" ) and ( thisComponent.ActualQty > #thisComponent.Items ) then
    env.info( " -- FixedOrder Convoy Component " ..  thisComponent.Name .. " is about to have its quantity changed from " .. thisComponent.ActualQty .. " to " .. #thisComponent.Items)
    thisComponent.ActualQty = #thisComponent.Items
  end  

  env.info( "  - ConvoyComponent " .. i .. " (" .. thisComponent.Name .. ") final qty set to: " .. tostring(thisComponent.ActualQty) )

end
env.info("  ------")
env.info("")




function DisplayVeh()

  env.info("")
  env.info(">> In fn DisplayVeh()")
  env.info("  - CurrentConvoyComponentSpawningIndex: " .. tostring(CurrentConvoyComponentSpawningIndex) )
  env.info("  - QtySpawnedFromCurrentConvoyComponentSpawningIndex: " .. tostring(QtySpawnedFromCurrentConvoyComponentSpawningIndex) )

  --//lead1_Vehs[ math.random( #lead1_Vehs ) ]:Spawn()
  local convoyFullyGenerated = ( CurrentConvoyComponentSpawningIndex > #FinalConvoyOrder ) -- because after generating the last one, the CurrentConvoyComponentSpawningIndex is incremented
  if ( convoyFullyGenerated ) then
    env.info(" --> CONVOY COMPLETE")
    return -- later, #TODO stop the timer
  end

  -- else spawn another next unit
  local currentConvoyComponentIndex = FinalConvoyOrder[CurrentConvoyComponentSpawningIndex]
  local thisConvoyComponent = ConvoyComponents[currentConvoyComponentIndex]
  env.info("  ..About to spawn from " .. #thisConvoyComponent.Items .. " items from convoy component " .. thisConvoyComponent.Name )
  

  if ( thisConvoyComponent.FixedVehicleOrder == "true" ) then
    env.info(" -- FixedVehicleOrder generation")
    env.info(" Num items in component: " .. #thisConvoyComponent.Items )
    table.remove( thisConvoyComponent.Items, 1 ):Spawn() -- remove & spawn the 1st ("next") item

  elseif ( thisConvoyComponent.MaxOneSpawnPerItem == "true" ) then -- remove a random item and spawn it
    env.info(" -- MaxOneSpawnPerItem generation")
    --env.info(" This convoy component: " .. table.concat( thisConvoyComponent.Items, "; " ) )
    env.info(" Num items in component: " .. #thisConvoyComponent.Items )
    table.remove( thisConvoyComponent.Items, math.random( #thisConvoyComponent.Items) ):Spawn() -- remove & spawn a random item

  else -- normal random selection for convoy component: just spawn the item and keep it there for next time
    thisConvoyComponent.Items[ math.random( #thisConvoyComponent.Items) ]:Spawn()
  end

  -- increment the count for the the number spawned from this convoy component index
  QtySpawnedFromCurrentConvoyComponentSpawningIndex = QtySpawnedFromCurrentConvoyComponentSpawningIndex + 1
  env.info( "  - Qty Spawned Index now: " .. tostring(QtySpawnedFromCurrentConvoyComponentSpawningIndex) )

  -- adjust the spawning indices as appropriate
  local justSpawnedLastUnitForThisComponent = ( QtySpawnedFromCurrentConvoyComponentSpawningIndex == thisConvoyComponent.ActualQty )
  if ( justSpawnedLastUnitForThisComponent ) then
    -- reset the indexing to start spawning from the next Convoy Component
    CurrentConvoyComponentSpawningIndex = CurrentConvoyComponentSpawningIndex + 1  -- note that if we have just spawned the last unit of the last component, the index will be one more than the length of ConvoyComponents, which is what we're checking for at the beginning of this function
    QtySpawnedFromCurrentConvoyComponentSpawningIndex = 0
    env.info( "  - Indexing set for next ConvoyComponent: " .. tostring(CurrentConvoyComponentSpawningIndex) .. " and Qty Spawned: " ..  tostring(QtySpawnedFromCurrentConvoyComponentSpawningIndex) )
  --else: the component index stays the same and the Qty Spawned has already been incremented for the next call
  end

  env.info("")
end


local function UniformSpawnTimeGenerator( minSpawnDelay, maxSpawnDelay )
     local newSpawnTime = math.random( minSpawnDelay, maxSpawnDelay ) 
     env.info( "newSpawnTime from UniformSpawnTimeGenerator: " .. tostring(newSpawnTime) )

     return newSpawnTime
 end


local function GaussianSpawnTimeGenerator(x0, sigma, xmin, xmax, imax)
     local newSpawnTime = UTILS.RandomGaussian(x0, sigma, xmin, xmax, imax)
     env.info( "newSpawnTime from GaussianSpawnTimeGenerator: " .. tostring(newSpawnTime) )

     return newSpawnTime
 end


--  KICK START THE TIMER CALL TO DISPLAY THE EACH VEHICLE
function CreateConvoy()  
 
    env.info(">> In CreateConvoy()")
    -- for UniformSpawnTimeGenerator
    local minSpawnDelay = 6
    local maxSpawnDelay = 12

    -- for GaussianSpawnTimeGenerator
    local x0 = 8
    local sigma = 3
    local xmin = 5
    local xmax = 12

    convoySpawner=TIMER:New(DisplayVeh):Start(1, 8, 300, GaussianSpawnTimeGenerator, x0, sigma, xmin, xmax)
    -- IN 0.11 we no longer establish a convoy size at the start, but keep going through all the groups until they're "run through" 
    --convoySpawner:SetMaxFunctionCalls(actualPatrolSize):Start(1, 8, 300, GaussianSpawnTimeGenerator, x0, sigma, xmin, xmax)
    --convoySpawner:SetMaxFunctionCalls(actualPatrolSize):Start(1, 8, 240, UniformSpawnTimeGenerator, minSpawnDelay, maxSpawnDelay)  --:Start(1, 1, 90, math.random( minSpawnDelay, maxSpawnDelay ))
end


CreateConvoy()