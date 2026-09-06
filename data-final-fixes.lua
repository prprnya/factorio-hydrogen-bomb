local SCALE = 2
local DAMAGE_MULTIPLIER = 2
local MAX_DECORATIVE_SPAWN_RADIUS = 24 - 1 / 256

local function clone_prototype(prototype_type, source_name, new_name)
  local bucket = data.raw[prototype_type]
  assert(bucket, "Missing prototype type: " .. prototype_type)
  local source = bucket[source_name]
  assert(source, "Missing source prototype: " .. prototype_type .. "/" .. source_name)
  local result = table.deepcopy(source)
  result.name = new_name
  return result
end

local reference_map =
{
  ["atomic-bomb-wave"] = "hydrogen-bomb-wave",
  ["atomic-bomb-ground-zero-projectile"] = "hydrogen-bomb-ground-zero-projectile",
  ["atomic-bomb-wave-spawns-nuke-shockwave-explosion"] = "hydrogen-bomb-wave-spawns-nuke-shockwave-explosion",
  ["atomic-bomb-wave-spawns-nuclear-smoke"] = "hydrogen-bomb-wave-spawns-nuclear-smoke",
  ["atomic-bomb-wave-spawns-fire-smoke-explosion"] = "hydrogen-bomb-wave-spawns-fire-smoke-explosion",
  ["atomic-bomb-wave-spawns-cluster-nuke-explosion"] = "hydrogen-bomb-wave-spawns-cluster-nuke-explosion",
  ["atomic-nuke-shockwave"] = "hydrogen-nuke-shockwave",
  ["atomic-fire-smoke"] = "hydrogen-fire-smoke",
  ["cluster-nuke-explosion"] = "hydrogen-cluster-nuke-explosion",
  ["nuclear-smoke"] = "hydrogen-nuclear-smoke",
  ["nuke-explosion"] = "hydrogen-nuke-explosion",
  ["nuke-effects-nauvis"] = "hydrogen-nuke-effects-nauvis",
  ["nuke-effects-aquilo"] = "hydrogen-nuke-effects-aquilo",
  ["nuke-effects-vulcanus"] = "hydrogen-nuke-effects-vulcanus",
  ["nuke-effects-space"] = "hydrogen-nuke-effects-space",
  ["huge-scorchmark"] = "hydrogen-huge-scorchmark",
  ["nuclear-ground-patch"] = "hydrogen-nuclear-ground-patch"
}

local function replace_references(value)
  if type(value) ~= "table" then return end
  for key, child in pairs(value) do
    if type(child) == "string" and reference_map[child] then
      value[key] = reference_map[child]
    elseif type(child) == "table" then
      replace_references(child)
    end
  end
end

local scalar_spatial_keys =
{
  radius = true,
  inner_radius = true,
  outer_radius = true,
  spawn_min_radius = true,
  spawn_max_radius = true,
  lower_distance_threshold = true,
  upper_distance_threshold = true,
  full_strength_max_distance = true,
  max_distance = true,
  max_movement_distance = true,
  max_movement_distance_deviation = true
}

local vector_spatial_keys =
{
  offset_deviation = true,
  offsets = true
}

local function scale_coordinate_tree(value)
  if type(value) ~= "table" then return end
  if type(value[1]) == "number" and type(value[2]) == "number" then
    value[1] = value[1] * SCALE
    value[2] = value[2] * SCALE
    return
  end
  for _, child in pairs(value) do
    if type(child) == "table" then
      scale_coordinate_tree(child)
    end
  end
end

local function scale_trigger_geometry(value)
  if type(value) ~= "table" then return end
  for key, child in pairs(value) do
    if scalar_spatial_keys[key] and type(child) == "number" then
      value[key] = child * SCALE
    elseif vector_spatial_keys[key] and type(child) == "table" then
      scale_coordinate_tree(child)
    elseif type(child) == "table" then
      scale_trigger_geometry(child)
    end
  end
  -- Decorative spawning has a strict radius limit of 24 tiles, independent of blast damage and sprite size.
  if value.type == "create-decorative" then
    value.spawn_max_radius = math.min(value.spawn_max_radius, MAX_DECORATIVE_SPAWN_RADIUS)
    value.spawn_min_radius = math.min(value.spawn_min_radius, value.spawn_max_radius)
  end
end

local function scale_trigger_damage(value)
  if type(value) ~= "table" then return end
  if value.type == "damage" then
    value.damage.amount = value.damage.amount * DAMAGE_MULTIPLIER
  end
  for _, child in pairs(value) do
    if type(child) == "table" then
      scale_trigger_damage(child)
    end
  end
end

local function scale_box(box)
  if type(box) ~= "table" then return end
  scale_coordinate_tree(box)
end

local function scale_sprite_tree(value)
  if type(value) ~= "table" then return end
  for key, child in pairs(value) do
    if key == "scale" and type(child) == "number" then
      value[key] = child * SCALE
    elseif key == "shift" and type(child) == "table" then
      scale_coordinate_tree(child)
    elseif type(child) == "table" then
      scale_sprite_tree(child)
    end
  end
end

-- Damage-wave projectiles. Repeat counts are intentionally left unchanged for the first test release.
local hydrogen_wave = clone_prototype("projectile", "atomic-bomb-wave", "hydrogen-bomb-wave")
scale_trigger_geometry(hydrogen_wave.action)
scale_trigger_damage(hydrogen_wave.action)

local hydrogen_ground_zero = clone_prototype("projectile", "atomic-bomb-ground-zero-projectile", "hydrogen-bomb-ground-zero-projectile")
scale_trigger_geometry(hydrogen_ground_zero.action)
scale_trigger_damage(hydrogen_ground_zero.action)

-- Secondary visual-effect projectiles. Their distribution geometry is doubled, but effect counts stay vanilla.
local hydrogen_shockwave_spawner = clone_prototype("projectile", "atomic-bomb-wave-spawns-nuke-shockwave-explosion", "hydrogen-bomb-wave-spawns-nuke-shockwave-explosion")
replace_references(hydrogen_shockwave_spawner)
scale_trigger_geometry(hydrogen_shockwave_spawner.action)

local hydrogen_smoke_spawner = clone_prototype("projectile", "atomic-bomb-wave-spawns-nuclear-smoke", "hydrogen-bomb-wave-spawns-nuclear-smoke")
replace_references(hydrogen_smoke_spawner)
scale_trigger_geometry(hydrogen_smoke_spawner.action)

local hydrogen_fire_smoke_spawner = clone_prototype("projectile", "atomic-bomb-wave-spawns-fire-smoke-explosion", "hydrogen-bomb-wave-spawns-fire-smoke-explosion")
replace_references(hydrogen_fire_smoke_spawner)
scale_trigger_geometry(hydrogen_fire_smoke_spawner.action)

local hydrogen_cluster_spawner = clone_prototype("projectile", "atomic-bomb-wave-spawns-cluster-nuke-explosion", "hydrogen-bomb-wave-spawns-cluster-nuke-explosion")
replace_references(hydrogen_cluster_spawner)
scale_trigger_geometry(hydrogen_cluster_spawner.action)

-- Main mushroom cloud: reuse the vanilla frames at twice the rendered spatial scale.
local hydrogen_nuke_explosion = clone_prototype("explosion", "nuke-explosion", "hydrogen-nuke-explosion")
scale_sprite_tree(hydrogen_nuke_explosion.animations)

-- Shockwave visuals: reuse vanilla frames at twice the rendered spatial scale.
local hydrogen_nuke_shockwave = clone_prototype("explosion", "atomic-nuke-shockwave", "hydrogen-nuke-shockwave")
scale_sprite_tree(hydrogen_nuke_shockwave.animations)

-- Other nuclear visual components are also enlarged without changing their lifetimes or counts.
local hydrogen_fire_smoke = clone_prototype("explosion", "atomic-fire-smoke", "hydrogen-fire-smoke")
hydrogen_fire_smoke.scale = (hydrogen_fire_smoke.scale or 1) * SCALE
if hydrogen_fire_smoke.scale_deviation then
  hydrogen_fire_smoke.scale_deviation = hydrogen_fire_smoke.scale_deviation * SCALE
end

local hydrogen_cluster_explosion = clone_prototype("explosion", "cluster-nuke-explosion", "hydrogen-cluster-nuke-explosion")
scale_sprite_tree(hydrogen_cluster_explosion.animations)

local hydrogen_nuclear_smoke = clone_prototype("trivial-smoke", "nuclear-smoke", "hydrogen-nuclear-smoke")
if hydrogen_nuclear_smoke.start_scale then hydrogen_nuclear_smoke.start_scale = hydrogen_nuclear_smoke.start_scale * SCALE end
if hydrogen_nuclear_smoke.end_scale then hydrogen_nuclear_smoke.end_scale = hydrogen_nuclear_smoke.end_scale * SCALE end

-- Surface-specific nuclear terrain effects.
local hydrogen_nuke_nauvis = clone_prototype("explosion", "nuke-effects-nauvis", "hydrogen-nuke-effects-nauvis")
scale_trigger_geometry(hydrogen_nuke_nauvis.created_effect)

local hydrogen_nuke_aquilo = clone_prototype("explosion", "nuke-effects-aquilo", "hydrogen-nuke-effects-aquilo")
scale_trigger_geometry(hydrogen_nuke_aquilo.created_effect)

local hydrogen_nuke_vulcanus = clone_prototype("explosion", "nuke-effects-vulcanus", "hydrogen-nuke-effects-vulcanus")
scale_trigger_geometry(hydrogen_nuke_vulcanus.created_effect)

local hydrogen_nuke_space = clone_prototype("explosion", "nuke-effects-space", "hydrogen-nuke-effects-space")
scale_trigger_geometry(hydrogen_nuke_space.created_effect)

-- Scorch mark and nuclear-ground decorative are enlarged to match the 2x blast geometry.
local hydrogen_scorchmark = clone_prototype("corpse", "huge-scorchmark", "hydrogen-huge-scorchmark")
scale_box(hydrogen_scorchmark.collision_box)
scale_box(hydrogen_scorchmark.selection_box)
scale_sprite_tree(hydrogen_scorchmark.ground_patch)
scale_sprite_tree(hydrogen_scorchmark.ground_patch_higher)

local hydrogen_ground_patch = clone_prototype("optimized-decorative", "nuclear-ground-patch", "hydrogen-nuclear-ground-patch")
scale_box(hydrogen_ground_patch.collision_box)
-- Factorio limits decorative collision boxes to 8 tiles in each direction; sprites can still scale by 2x.
for _, corner in ipairs(hydrogen_ground_patch.collision_box) do
  for axis, coordinate in ipairs(corner) do
    corner[axis] = math.max(-8, math.min(8, coordinate))
  end
end
scale_sprite_tree(hydrogen_ground_patch.pictures)

-- Rocket projectile. Geometry and damage are doubled within decorative limits; counts, timing and speed stay vanilla.
local hydrogen_rocket = clone_prototype("projectile", "atomic-rocket", "hydrogen-rocket")
replace_references(hydrogen_rocket)
scale_trigger_geometry(hydrogen_rocket.action)
scale_trigger_damage(hydrogen_rocket.action)
hydrogen_rocket.animation = require("__base__.prototypes.entity.rocket-projectile-pictures").animation({0.3, 0.873, 1.0})

-- Ammunition item. Keep vanilla atomic-bomb range/cooldown, stack size, weight and sounds; remove the green light layer.
local hydrogen_bomb = clone_prototype("ammo", "atomic-bomb", "hydrogen-bomb")
hydrogen_bomb.icon = "__hydrogen-bomb__/graphics/icons/hydrogen-bomb.png"
hydrogen_bomb.pictures =
{
  layers =
  {
    {
      size = 64,
      filename = "__hydrogen-bomb__/graphics/icons/hydrogen-bomb.png",
      scale = 0.5,
      mipmap_count = 4
    }
  }
}
hydrogen_bomb.ammo_type.action.action_delivery.projectile = "hydrogen-rocket"
hydrogen_bomb.order = data.raw["ammo"]["atomic-bomb"].order
hydrogen_bomb.localised_description = {"item-description.hydrogen-bomb"}

-- Production recipe: atomic primary + fusion fuel + end-game electronics.
local hydrogen_recipe = clone_prototype("recipe", "atomic-bomb", "hydrogen-bomb")
hydrogen_recipe.energy_required = 50
hydrogen_recipe.ingredients =
{
  {type = "item", name = "atomic-bomb", amount = 1},
  {type = "item", name = "fusion-power-cell", amount = 10},
  {type = "item", name = "quantum-processor", amount = 10}
}
hydrogen_recipe.results = {{type = "item", name = "hydrogen-bomb", amount = 1}}
hydrogen_recipe.enabled = false

-- Technology: atomic-bomb mushroom cloud with a fusion-power-cell badge.
local hydrogen_technology = clone_prototype("technology", "atomic-bomb", "hydrogen-bomb")
hydrogen_technology.icon = nil
hydrogen_technology.icons =
{
  {
    icon = "__base__/graphics/technology/atomic-bomb.png",
    icon_size = 256
  },
  {
    icon = "__space-age__/graphics/icons/fusion-power-cell.png",
    icon_size = 64,
    scale = 1,
    shift = {50, 50},
    floating = true
  }
}
hydrogen_technology.effects =
{
  {type = "unlock-recipe", recipe = "hydrogen-bomb"}
}
hydrogen_technology.prerequisites = {"atomic-bomb", "fusion-reactor", "legendary-quality"}
hydrogen_technology.unit =
{
  count = 2000,
  ingredients =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"chemical-science-pack", 1},
    {"military-science-pack", 1},
    {"utility-science-pack", 1},
    {"space-science-pack", 1},
    {"metallurgic-science-pack", 1},
    {"electromagnetic-science-pack", 1},
    {"agricultural-science-pack", 1},
    {"cryogenic-science-pack", 1}
  },
  time = 60
}
hydrogen_technology.localised_description = {"technology-description.hydrogen-bomb"}

-- Basic load-time sanity checks for the assumptions this test build relies on.
assert(hydrogen_bomb.ammo_type.range_modifier == data.raw.ammo["atomic-bomb"].ammo_type.range_modifier)
assert(hydrogen_bomb.ammo_type.action.action_delivery.projectile == "hydrogen-rocket")
assert(hydrogen_recipe.energy_required == 50)

data:extend
{
  hydrogen_wave,
  hydrogen_ground_zero,
  hydrogen_shockwave_spawner,
  hydrogen_smoke_spawner,
  hydrogen_fire_smoke_spawner,
  hydrogen_cluster_spawner,
  hydrogen_nuke_explosion,
  hydrogen_nuke_shockwave,
  hydrogen_fire_smoke,
  hydrogen_cluster_explosion,
  hydrogen_nuclear_smoke,
  hydrogen_nuke_nauvis,
  hydrogen_nuke_aquilo,
  hydrogen_nuke_vulcanus,
  hydrogen_nuke_space,
  hydrogen_scorchmark,
  hydrogen_ground_patch,
  hydrogen_rocket,
  hydrogen_bomb,
  hydrogen_recipe,
  hydrogen_technology
}
