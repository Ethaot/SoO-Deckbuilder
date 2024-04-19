extends Control

@export var cardContainer: GridContainer
@export var deckContainer: VBoxContainer
@export var factionDropdown: OptionButton
@export var typeDropdown: OptionButton
@export var subfactionDropdown: OptionButton
@export var cardCountLabel: Label
@export var charactersContainer: VBoxContainer
@export var generalContainer: VBoxContainer
@export var subfaction1Container: VBoxContainer
@export var subfaction2Container: VBoxContainer
@export var subfaction3Container: VBoxContainer
@export var genericsContainer: VBoxContainer
@export var subfaction1Label: Label
@export var subfaction2Label: Label
@export var subfaction3Label: Label
@export var saveButton: Button
@export var loadButton: Button
@export var saveFileDialog: FileDialog
@export var loadFileDialog: FileDialog
@export var exportToPDFFileDialog: FileDialog
@export var exportToTTSFileDialog: FileDialog
@export var fileMenuButton: MenuButton
@export var cardPNGContainer: GridContainer
@export var deckExporter: Node
var deckArray = []
var deckButtonArray = []
var card_array = []
var json_array
var subfaction1 = ""
var subfaction2 = ""
var subfaction3 = ""
var deckTab
var cardBuilderInstance
var exportval=0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var cardBuilder = preload("res://mainscreen.tscn")	
	saveButton.button_up.connect(func(): saveFileDialog.popup())
	loadButton.button_up.connect(func(): loadFileDialog.popup())
	saveFileDialog.file_selected.connect(saveDeck.bind())
	loadFileDialog.file_selected.connect(loadDeck.bind())
	exportToPDFFileDialog.file_selected.connect(exportDeckToPNGs.bind())
	exportToTTSFileDialog.file_selected.connect(exportDeckToPNGs.bind())
	fileMenuButton.get_popup().id_pressed.connect(manageSave.bind())
	factionDropdown.item_selected.connect(updateSubfactionDropdown.bind())
	#create_new_save_file('res://save.json')
	cardBuilderInstance = cardBuilder.instantiate()
	add_child(cardBuilderInstance)
	#displayCards(-1, json_array)
	cardBuilderInstance.initialize()	
	add_user_signal("cards_done")
	connect("cards_done", go_time.bind())

func go_time():
	var json_file_path = cardBuilderInstance.json_path
	json_array = processJSON(json_file_path)	
	factionDropdown.item_selected.connect(displayCards.bind(json_array))
	typeDropdown.item_selected.connect(displayCards.bind(json_array))
	subfactionDropdown.item_selected.connect(displayCards.bind(json_array))
	resized.connect(func(): displayCards(-1, json_array))
	combine_arrays()
	displayCards(-1, json_array)
	show_cards_in_deck()
	
func combine_arrays():
	for i in range(json_array.size()):
		json_array[i]["cardimage"] = CardHolderScript.card_images[i]
	json_array.sort_custom(func(a, b): return a["name"] < b["name"])
	
func displayCards(index, display_array):
	for card in card_array:
		card.queue_free()
	card_array.clear()
	var filtered_array = get_filtered_array(display_array)
	for i in range(filtered_array.size()):
		pass
	
	for card in filtered_array:	
		var card_image_button = TextureButton.new()
		cardContainer.add_child(card_image_button)
		var imageFile = card["cardimage"]
		var itex = ImageTexture.new()
		itex = ImageTexture.create_from_image(imageFile)
		itex.set_size_override(Vector2i(itex.get_width()/2.0,itex.get_height()/2.0))
		card_image_button.texture_normal = itex
		card_image_button.button_up.connect(func(): add_card_to_deck(card)) 
		card_array.append(card_image_button)
		
		cardContainer.columns = get_viewport_rect().size.x / 2.0 / itex.get_width()		
	disable_cards_in_card_array()

func get_filtered_array(arrayToFilter):
	var filtered_array = []
	filtered_array = arrayToFilter.duplicate()	
	if(factionDropdown.get_selected_id() != 0):
		for i in range(filtered_array.size()-1,-1,-1):
			if(filtered_array[i]["faction"] != factionDropdown.get_item_text(factionDropdown.get_selected_id()) and filtered_array[i]["faction"] != "Generic"):
				filtered_array.remove_at(i)
	if subfactionDropdown.get_selected_id() != 0:
		for i in range(filtered_array.size()-1,-1,-1):
			if filtered_array[i]["subfaction"] != subfactionDropdown.get_item_text((subfactionDropdown.get_selected_id())):
				filtered_array.remove_at(i)
	if(typeDropdown.get_selected_id() != 0):
		for i in range(filtered_array.size()-1,-1,-1):
			if filtered_array[i]["type"] != typeDropdown.get_item_text(typeDropdown.get_selected_id()):# and typeDropdown.get_selected_id()!=0:
				filtered_array.remove_at(i)
	return filtered_array

func add_card_to_deck(card):
	if get_in_subfaction(card):
		if check_deck_for_max_cards(card):
			deckArray.append(card)
	show_cards_in_deck()
	disable_cards_in_card_array()
	enable_cards_in_card_array()
	
func check_deck_for_max_cards(card):
	var cardCount = 0
	var maxCards = 3
	if card["type"]=="Character":
		maxCards = 1
		var numCharacters = 0
		for i in deckArray.size():
			if deckArray[i]["type"]=="Character":
				numCharacters += 1
		if numCharacters>=3:
			return false
	for i in deckArray.size():
		if deckArray[i] == card:
			cardCount += 1
	if cardCount < maxCards:
		return true
	else:
		return false
	
func remove_card_from_deck(card):
	if card["type"]=="Character":
		match card["subfaction"]:
			subfaction1:
				remove_subfaction_from_deck(subfaction1)
			subfaction2:
				remove_subfaction_from_deck(subfaction2)
			subfaction3:
				remove_subfaction_from_deck(subfaction3)
	for i in deckArray.size():
		if(deckArray[i] == card):
			deckArray.remove_at(i)
			break
	show_cards_in_deck()
	enable_cards_in_card_array()
	disable_cards_in_card_array()

func remove_subfaction_from_deck(subfaction):
	for i in range(deckArray.size()-1, -1, -1):
		if deckArray[i]["subfaction"]==subfaction:
			deckArray.remove_at(i)
	match subfaction:
		subfaction1:
			subfaction1=""
			subfaction1Label.text="Subfaction 1"
			if subfaction2 != "":
				subfaction1 = subfaction2
				if subfaction3 != "":
					subfaction2 = subfaction3
					subfaction3 = ""
				else:
					subfaction2 = ""
		subfaction2:
			subfaction2=""
			subfaction2Label.text="Subfaction 2"
			if subfaction3 != "":
				subfaction2 = subfaction3
				subfaction3 = ""
		subfaction3:
			subfaction3=""
			subfaction3Label.text="Subfaction 3"
	
func show_cards_in_deck():
	for b in deckButtonArray:
		b.queue_free()
	deckButtonArray.clear()
	var numCharacters = 0
	var numSF1 = 0
	var numSF2 = 0
	var numSF3 = 0
	for card in deckArray:
		if subfaction1 == card["subfaction"] and card["type"] != "Character":
			numSF1 += 1
		elif subfaction2 == card["subfaction"] and card["type"] != "Character":
			numSF2 += 1
		elif subfaction3 == card["subfaction"] and card["type"] != "Character":
			numSF3 += 1
		
		var button_exists = false
		for b in deckButtonArray:
			if b.text.left(-3) == card["name"]:
				button_exists = true
				break
		if(!button_exists):
			var card_name_button_deck = Button.new()
			if card["type"] == "Character":
				numCharacters += 1
				charactersContainer.add_child(card_name_button_deck)
				add_subfaction(card["subfaction"])
			elif card["faction"] == "Generic":
				genericsContainer.add_child(card_name_button_deck)
			elif card["subfaction"] == "None":
				generalContainer.add_child(card_name_button_deck)
			else:
				if subfaction1 == card["subfaction"]:
					subfaction1Container.add_child(card_name_button_deck)
				elif subfaction2 == card["subfaction"]:
					subfaction2Container.add_child(card_name_button_deck)
				elif subfaction3 == card["subfaction"]:
					subfaction3Container.add_child(card_name_button_deck)
			card_name_button_deck.text = card["name"] + ' x'
			var cardCount = 0
			for i in deckArray.size():
				if deckArray[i]["name"] == card["name"]:
					cardCount += 1
			card_name_button_deck.text += str(cardCount)
			card_name_button_deck.button_up.connect(func(): remove_card_from_deck(card))	
			deckButtonArray.append(card_name_button_deck)
	var numCardsInDeck = deckArray.size() - numCharacters
	cardCountLabel.text = "Card Count: " + str(numCardsInDeck)
	if numCardsInDeck < 40:
		cardCountLabel.add_theme_color_override("font_color", Color(1,0,0))
	else:
		cardCountLabel.add_theme_color_override("font_color", Color(0,1,0))
	subfaction1Label.text = subfaction1 + " (" + str(numSF1) + ")"
	subfaction2Label.text = subfaction2 + " (" + str(numSF2) + ")"
	subfaction3Label.text = subfaction3 + " (" + str(numSF3) + ")"

func get_in_subfaction(card):
	if card["type"]=="Character": return true
	if card["subfaction"] == subfaction1 or card["subfaction"] == subfaction2 or card["subfaction"] == subfaction3 or card["subfaction"] == "None":
		return true
	else: 
		return false

func add_subfaction(subfaction):	
	if subfaction1==subfaction or subfaction1=="":
		subfaction1=subfaction
		subfaction1Label.text=subfaction
	elif subfaction2==subfaction or subfaction2=="":
		subfaction2=subfaction
		subfaction2Label.text=subfaction
	elif subfaction3==subfaction or subfaction3=="":
		subfaction3=subfaction
		subfaction3Label.text=subfaction

func disable_cards_in_card_array():
	for card in card_array:
		if isCardDisabled(card):
			card.self_modulate = Color(.6,.6,.6)

func enable_cards_in_card_array():
	for card in card_array:
		if !isCardDisabled(card):
			card.self_modulate = Color(1,1,1)

func isCardDisabled(cardButton):	
	var filtered_array = get_filtered_array(json_array)
	var faction=""
	var characters = []
	for card in deckArray:
		if card["type"]=="Character":
			faction=card["faction"]
			characters.append(card)
	for i in range(card_array.size()):
		if card_array[i] == cardButton:
			if filtered_array[i]["type"]=="Character" and characters.size() == 0:
				return false
			if filtered_array[i]["faction"] != faction and filtered_array[i]["faction"] != "Generic":
				return true	
			var numCards=0			
			if filtered_array[i]["subfaction"] != "None" and filtered_array[i]["subfaction"] != subfaction1 and filtered_array[i]["subfaction"] != subfaction2 and filtered_array[i]["subfaction"] != subfaction3 and filtered_array[i]["type"] != "Character":
				return true
			if characters.size() >= 3 and filtered_array[i]["type"] == "Character":
				return true
			for character in characters:
				if character==filtered_array[i]:
					return true
			for card in deckArray:
				if card==filtered_array[i]:
					numCards += 1
					if numCards>=3:
						return true
	return false

func updateSubfactionDropdown(_index):
	match factionDropdown.get_item_text(factionDropdown.get_selected_id()):
		"Prophets":
			subfactionDropdown.set_item_text(2, "Cenobite")
			subfactionDropdown.set_item_text(3, "Chaplain")
			subfactionDropdown.set_item_text(4, "Demagogue")
			subfactionDropdown.set_item_text(5, "Fanatic")
			subfactionDropdown.set_item_text(6, "Priest")
		"Recursion":
			subfactionDropdown.set_item_text(2, "Chainbreaker")
			subfactionDropdown.set_item_text(3, "Exterminator")
			subfactionDropdown.set_item_text(4, "Processor")
			subfactionDropdown.set_item_text(5, "Rampancy")
			subfactionDropdown.set_item_text(6, "Virus")
		"Swarm":
			subfactionDropdown.set_item_text(2, "Alpha")
			subfactionDropdown.set_item_text(3, "Bellator")
			subfactionDropdown.set_item_text(4, "Hive Mind")
			subfactionDropdown.set_item_text(5, "Parasite")
			subfactionDropdown.set_item_text(6, "Queen")
		"UMC":
			subfactionDropdown.set_item_text(2, "Medic")
			subfactionDropdown.set_item_text(3, "Sharpshooter")
			subfactionDropdown.set_item_text(4, "Soldier")
			subfactionDropdown.set_item_text(5, "Tactician")
			subfactionDropdown.set_item_text(6, "Tech")

func processJSON(json_file_path):
	var json_file_text = FileAccess.get_file_as_string(json_file_path)
	var json_text_array= json_file_text.split("\n",false)
	var json_dict_array=[]
	for json_text in json_text_array:
		var json_dict=JSON.parse_string(json_text)
		if !(json_dict):
			continue
		json_dict_array.append(json_dict)
	return json_dict_array

func saveDeck(file_path):
	print("Writing to disk...")
	var json = JSON.new()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json.stringify(deckArray))
	file.close()
	file = null
	
func loadDeck(file_path):	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_dict=JSON.parse_string(file.get_as_text())
	deckArray=json_dict.duplicate()
	subfaction1 = ""
	subfaction2 = ""
	subfaction3 = ""
	show_cards_in_deck()
	
func create_new_save_file(file_path):
	print("Creating New Save")
	var json = JSON.new()
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = json.parse_string(file.get_as_text())
	var json_dict_array = []
	json_dict_array = content
	saveDeck(file_path)
	
func manageSave(id):
	if id==0: #Save Deck
		saveFileDialog.popup()
	if id==1: #Load Deck
		loadFileDialog.popup()
	if id==2: #Export to PDF
		exportval=0
		exportToPDFFileDialog.popup()		
	if id==3: #Export to TTS png
		exportval=1
		exportToTTSFileDialog.popup()		

func exportDeckToPNGs(path):
	for card in deckArray:
		for c in json_array:
			if card["name"]==c["name"]:
				card["cardimage"]=c["cardimage"]
	var imageArray = []
	
	if exportval==0:
		print("Export Val == 0")
		cardPNGContainer.columns=3
		var iteration = 0
		for i in range(ceil(deckArray.size()/9.0)):
			for child in cardPNGContainer.get_children():
				child.queue_free()
			for j in range(iteration*9, iteration*9+9, 1):
				if j<deckArray.size():
					#var cardimg = Image.new()
					var cardtex = ImageTexture.new()
					var cardRect = TextureRect.new()
					#cardimg.load("res://" + deckArray[j]["cardimg"])
					var cardimg = deckArray[j]["cardimage"]
					if typeof(cardimg)==4: #If type is string					
						pass
					else:
						cardtex = ImageTexture.create_from_image(cardimg)
					cardRect.texture = cardtex
					cardPNGContainer.add_child(cardRect)
			await get_tree().process_frame	
			$SubViewport.size = Vector2(cardPNGContainer.size.x, cardPNGContainer.size.y)
			await RenderingServer.frame_post_draw
			var img = $SubViewport.get_viewport().get_texture().get_image()
			if(!DirAccess.dir_exists_absolute("user://tmp/")):
				DirAccess.make_dir_recursive_absolute("user://tmp/")
			img.save_png("user://tmp/img" + str(iteration) + ".png")
			imageArray.append(img)
			iteration += 1
		export_pngs_to_pdf(path)
	if exportval==1:
		for child in cardPNGContainer.get_children():
			child.queue_free()
		var cardblank = Image.new()
		cardblank = load("res://card_templates/cardblank.png")
		var betaCardBack = Image.new()
		betaCardBack = load("res://card_templates/Beta Card Back.png")
		var numRows = floori(deckArray.size()/10) #floor(deckArray.size()/10.0)		
		var numBlanks = 0
		numBlanks = (((numRows + 1) * 10) - deckArray.size()) - 1
		#if deckArray.size() % 10 > 0:
		#	numBlanks = deckArray.size() % 10 - 1
		if numBlanks == 0:
			numBlanks = 9
		print("Number of Rows: " + str(numRows + 1))
		print("Number of Blanks: " + str(numBlanks))
		cardPNGContainer.columns=10
		for i in range(deckArray.size()):
			var cardtex = ImageTexture.new()
			var cardRect = TextureRect.new()
			var cardimg = deckArray[i]["cardimage"]
			if typeof(cardimg)==4: #If type is string					
				pass
			else:
				cardtex = ImageTexture.create_from_image(cardimg)
			cardRect.texture = cardtex
			cardPNGContainer.add_child(cardRect)
		for i in range(numBlanks):
			var cardtex = ImageTexture.new()
			var cardRect = TextureRect.new()
			cardtex = ImageTexture.create_from_image(cardblank)
			cardRect.texture = cardtex
			cardPNGContainer.add_child(cardRect)
		var cardtex = ImageTexture.new()
		var cardRect = TextureRect.new()
		cardtex = ImageTexture.create_from_image(betaCardBack)
		cardRect.texture = cardtex
		cardPNGContainer.add_child(cardRect)
		await get_tree().process_frame
		$SubViewport.size = Vector2(cardPNGContainer.size.x, cardPNGContainer.size.y)
		await RenderingServer.frame_post_draw
		print(path)
		var img = $SubViewport.get_viewport().get_texture().get_image().save_png(path)
		
func export_pngs_to_pdf(path):
	#var path = OS.get_user_data_dir()+"/tmp/testPDF.pdf"
	if !path.contains(".pdf"):
		if !path.contains("."):
			path+=".pdf"
	deckExporter.CreatePDF(path);
