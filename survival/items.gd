class_name SurvivalItems

# Survival consumables (potions, bombs, flares), round-start loadouts and prices.
# Everything here lasts one run; coins come from the same bank as the Armory.

const ITEMS := {
	"potion_heal": {"name": "Health Potion", "price": 20, "desc": "Heals 2 hearts."},
	"potion_big": {"name": "Grand Elixir", "price": 55, "desc": "Heals every heart."},
	"potion_speed": {"name": "Swift Brew", "price": 25, "desc": "+40% move speed for 12 s."},
	"potion_power": {"name": "Giant's Draught", "price": 35, "desc": "+60% damage for 12 s."},
	"potion_shield": {"name": "Stoneskin Tonic", "price": 30, "desc": "Take no damage for 6 s."},
	"grenade": {"name": "Frag Grenade", "price": 20, "desc": "Thrown where you aim. Big blast."},
	"frost": {"name": "Frost Bomb", "price": 30, "desc": "Freezes monsters around you for 4 s."},
	"flare": {"name": "Paratrooper Flare", "price": 60, "desc": "3 soldiers parachute in and fight."},
	"repair": {"name": "Repair Kit", "price": 30, "desc": "Fixes every machine you built."},
}
const ORDER := ["potion_heal", "potion_big", "potion_speed", "potion_power", "potion_shield", "grenade", "frost", "flare", "repair"]
const SLOT_KEYS := [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_F, KEY_G]   # hotbar slots, left to right
const SLOT_NAMES := ["Z", "X", "C", "V", "F", "G"]
const INFLATION := 0.12   # every price goes up 12% per round

# Pick 1 of 3 before every round. guns: airdrop gun -> ammo, builds: free machines.
const LOADOUTS := [
	{"name": "Gunner", "desc": "Minigun (180 shots)\n+ Frag Grenade", "guns": {"minigun": 180}, "items": {"grenade": 1}},
	{"name": "Demolition", "desc": "Rocket Launcher (12)\n+ 2 Frag Grenades", "guns": {"rocket": 12}, "items": {"grenade": 2}},
	{"name": "Medic", "desc": "2 Health Potions\n+ Stoneskin Tonic", "items": {"potion_heal": 2, "potion_shield": 1}},
	{"name": "Engineer", "desc": "Free Bolt Turret\n+ 2 Barricades, Repair Kit", "builds": {"turret": 1, "wall": 2}, "items": {"repair": 1}},
	{"name": "Banker", "desc": "+40 coins\n+ free Coin Minter", "coins": 40, "builds": {"minter": 1}},
	{"name": "Sniper", "desc": "Railgun (12)\n+ Swift Brew", "guns": {"railgun": 12}, "items": {"potion_speed": 1}},
	{"name": "Alchemist", "desc": "Giant's Draught, Swift Brew\n+ Health Potion", "items": {"potion_power": 1, "potion_speed": 1, "potion_heal": 1}},
	{"name": "Commander", "desc": "Paratrooper Flare\n+ Frost Bomb", "items": {"flare": 1, "frost": 1}},
	{"name": "Laser Ace", "desc": "Laser Rifle (140)\n+ Health Potion", "guns": {"laser": 140}, "items": {"potion_heal": 1}},
	{"name": "Ice Warden", "desc": "Free Frost Spire\n+ 2 Frost Bombs", "builds": {"frost": 1}, "items": {"frost": 2}},
	{"name": "Trapper", "desc": "2 free Spike Traps\n+ free Barricade, Grenade", "builds": {"spikes": 2, "wall": 1}, "items": {"grenade": 1}},
]


static func price(base: int, round_no: int) -> int:
	return int(roundf(base * (1.0 + INFLATION * maxi(round_no - 1, 0))))


static func icon(id: String) -> Texture2D:
	return load("res://assets/survival/item_%s.png" % id)


# First frame of a 2-frame strip (machine / mob sprites) for menus.
static func frame0(path: String) -> Texture2D:
	var src: Texture2D = load(path)
	var at := AtlasTexture.new()
	at.atlas = src
	at.region = Rect2(0, 0, src.get_width() / 2.0, src.get_height())
	return at
