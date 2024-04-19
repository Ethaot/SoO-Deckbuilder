extends Control
@export var view: Viewport
@export var template: TextureRect
@export var nameplate_label: Label
@export var faceplate_label: Label
@export var pitch_label: Label
@export var cost_label: Label
@export var attack_label: Label
@export var defense_label: Label
@export var maintext_label: RichTextLabel
@export var card_progress: ProgressBar
var json_path
var template_textures = []
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func initialize():
	template_textures.append(load("res://card_templates/betaactiontemplate01.png"))
	template_textures.append(load("res://card_templates/betawarriortemplate01.png"))
	template_textures.append(load("res://card_templates/betacharactertemplate01.png"))
	$jsonDialog.popup()
	
func open_file():
	pass
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

func drawCard(card_dict):
	#define type and template
	var card_type=card_dict['type']
	template.set_texture(template_textures[0])
	nameplate_label.size=Vector2(324,67)
	nameplate_label.position=Vector2(76,2)
	nameplate_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	match card_type:
		"Warrior","Warrior Token":
			template.set_texture(template_textures[1])
		"Character":
			template.set_texture(template_textures[2])
			nameplate_label.size=Vector2(444,67)
			nameplate_label.position=Vector2(16,2)
			nameplate_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT

	#prepare values
	var card_path=card_dict['cardimg']
	var card_faceplate=card_dict['faction']+' '+card_type
	if card_dict['subfaction']!="None":
		card_faceplate+=' - '+card_dict['subfaction']

	var card_text=parseItem(card_dict['cardtext'])
	if card_dict['flavortext']!=null:
		card_text+='\n[i]'+card_dict['flavortext']+'[/i]'
	#set and adjust labels
	nameplate_label.text = card_dict['name']
	adjustLabelFontSize(nameplate_label,40)
	faceplate_label.text = card_faceplate
	adjustLabelFontSize(faceplate_label,40)
	maintext_label.text = card_text
	formatMainText()
	adjustRichFontSize(maintext_label,22)
	pitch_label.text=parseItem(card_dict['pitch'])
	adjustLabelFontSize(pitch_label,40)
	cost_label.text=parseItem(card_dict['cost'])
	adjustLabelFontSize(cost_label,40)
	attack_label.text=parseItem(card_dict['attack'])
	adjustLabelFontSize(attack_label,40)
	defense_label.text=parseItem(card_dict['defense'])
	adjustLabelFontSize(defense_label,40)
	#draw card
	#var dir_path=output_dir+card_path.rsplit("/",false,1)[0]
	#if !(DirAccess.dir_exists_absolute(dir_path)):
		#DirAccess.make_dir_recursive_absolute(dir_path)
	#card_path=output_dir+card_path
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func adjustLabelFontSize(label, standard_size):
	label.add_theme_font_size_override('font_size',standard_size)
	var font_size= label.get_theme_font_size("font_size")
	var string_size = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	while string_size[0]>label.size[0]:
		label.add_theme_font_size_override('font_size',font_size-1)
		font_size= label.get_theme_font_size("font_size")
		string_size = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

func adjustRichFontSize(label, standard_size):
	label.add_theme_font_size_override('normal_font_size',standard_size)
	label.add_theme_font_size_override('bold_font_size',standard_size)
	var font_size= label.get_theme_font_size("font_size")
	var string_size = label.get_content_height()
	while string_size>label.size[1]:
		label.add_theme_font_size_override('normal_font_size',font_size-1)
		label.add_theme_font_size_override('bold_font_size',font_size-1)
		font_size= label.get_theme_font_size("font_size")
		string_size = label.get_content_height()

func formatMainText():
	var keywords = ["Bond","Bounce","Exert","Rally","Recur","Ritual","Invoke","Action","Instant","Attack","Negate","Oncer per turn action","Kill"]
	var regex=RegEx.new()
	for keyword in keywords:
		#maintext_label.text = maintext_label.text.replace(keyword,'[b]'+keyword+'[/b]')
		regex.compile(keyword+r' [0-9]|'+keyword+r' X|'+keyword)
		var search_pointer=0
		var new_text=''
		for result in regex.search_all(maintext_label.text):
			new_text+=maintext_label.text.substr(search_pointer,result.get_start()-search_pointer)+'[b]'
			new_text+=maintext_label.text.substr(result.get_start(),result.get_end()-result.get_start())+'[/b]'
			search_pointer=result.get_end()
		new_text+=maintext_label.text.substr(search_pointer,-1)
		maintext_label.text=new_text
	regex.clear()
	
func parseItem(dict_item):
	if dict_item!=null:
		return String(dict_item)
	else:
		return ''

func _on_json_selected(path):
	$jsonDialog.hide()
	json_path=path
	var card_dict_array=processJSON(json_path)
	var progress=0.0
	for card_dict in card_dict_array:
		await get_tree().process_frame
		#card_image_array.append(await self.drawCard(card_dict))
		CardHolderScript.addCardImage(await self.drawCard(card_dict))
		progress+=1
		card_progress.value=progress/card_dict_array.size()*100
	add_user_signal("cards_done")
	connect("cards_done", get_parent().go_time.bind())
	var cardsDone = emit_signal("cards_done")
	queue_free()
	#$cardDialog.popup()
func _on_output_selected(output_dir):
	$cardDialog.hide()
	var card_dict_array=processJSON(json_path)
	var progress=0.0
	for card_dict in card_dict_array:
		await get_tree().process_frame
		#card_image_array.append(await self.drawCard(card_dict))
		CardHolderScript.addCardImage(await self.drawCard(card_dict))
		progress+=1
		card_progress.value=progress/card_dict_array.size()*100
		
	$VBoxContainer/Progress_done.visible=true
func _on_cancel():
	get_tree().quit()
