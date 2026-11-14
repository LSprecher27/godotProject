extends Node
class_name GameManager

const START_LIVES = 5
const SAVE_PATH = "user://save.cfg"
const TOTAL_SECRETS = 3

# every achievement: id = [name, how to get it]
const ACHIEVEMENTS = {
	"first_stomp": ["Sorry, Grandma", "Stomp your first granny"],
	"granny_25": ["Senior Discount", "Stomp 25 grannies (all games added up)"],
	"all_cash": ["Penny Pincher", "Collect every bill in a level"],
	"secret": ["Secret Stash", "Find a golden bill"],
	"all_secrets": ["Treasure Hunter", "Find all 3 golden bills"],
	"beat_tyler": ["Car Thief Thief", "Beat Giant Tyler"],
	"no_death": ["Untouchable", "Beat the game without dying"],
	"shopper": ["Big Spender", "Buy something in the shop"],
	"game_over": ["Try Again", "Get a Game Over"],
}

# "static" means there is only one value for the whole game,
# so it stays the same when we go to the next level

# --- this game only (reset when you press Play) ---
static var money = 0
static var lives = START_LIVES
static var died_this_game = false

# --- saved forever in the save file ---
static var bank = 0                 # money you can spend in the shop
static var upgrades = {}            # shop item id -> how many you own
static var unlocked = []            # achievement ids you have
static var secrets_found = []       # golden bill numbers you found
static var grannies_stomped = 0

# achievement names waiting to pop up on screen
static var popup_queue = []
static var loaded = false


# ---------- money and lives ----------

static func add_money(amount):
	money += amount
	bank += amount
	save_game()

static func lose_life():
	lives -= 1
	died_this_game = true

# called when a new game starts
static func reset():
	load_game()
	money = 0
	lives = START_LIVES + get_upgrade("extra_life")
	died_this_game = false


# ---------- shop ----------

static func get_upgrade(id):
	return upgrades.get(id, 0)

static func has_upgrade(id):
	return get_upgrade(id) > 0

# returns true if it worked
static func buy(id, price):
	if bank < price:
		return false
	bank -= price
	upgrades[id] = get_upgrade(id) + 1
	unlock("shopper")
	save_game()
	return true


# ---------- achievements and secrets ----------

static func unlock(id):
	if id in unlocked:
		return
	unlocked.append(id)
	popup_queue.append(ACHIEVEMENTS[id][0])
	save_game()

static func stomped_granny():
	grannies_stomped += 1
	unlock("first_stomp")
	if grannies_stomped >= 25:
		unlock("granny_25")
	save_game()

static func found_secret(number):
	if not number in secrets_found:
		secrets_found.append(number)
	unlock("secret")
	if secrets_found.size() >= TOTAL_SECRETS:
		unlock("all_secrets")
	save_game()

static func beat_game():
	unlock("beat_tyler")
	if not died_this_game:
		unlock("no_death")


# ---------- saving and loading ----------

static func save_game():
	var file = ConfigFile.new()
	file.set_value("save", "bank", bank)
	file.set_value("save", "upgrades", upgrades)
	file.set_value("save", "unlocked", unlocked)
	file.set_value("save", "secrets_found", secrets_found)
	file.set_value("save", "grannies_stomped", grannies_stomped)
	file.save(SAVE_PATH)

static func load_game():
	# only load once, the values stay in memory after that
	if loaded:
		return
	loaded = true
	var file = ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return  # no save yet, that's fine
	bank = file.get_value("save", "bank", 0)
	upgrades = file.get_value("save", "upgrades", {})
	unlocked = file.get_value("save", "unlocked", [])
	secrets_found = file.get_value("save", "secrets_found", [])
	grannies_stomped = file.get_value("save", "grannies_stomped", 0)
