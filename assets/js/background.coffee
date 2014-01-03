TICK_MINUTES = 1
ALARM_NAME = 'tick'
STORAGE_KEY = 'chromagochi'
LIFE_MINUTES = 120
BLINK_INTERVAL = 300
BLINK_LIMIT = 30

# http://jsfiddle.net/EPWF6/9/
hsl2rgb = (H, S, L) ->

	# calculate chroma
	C = (1 - Math.abs((2 * L) - 1)) * S

	# Find a point (R1, G1, B1) along the bottom three faces of the RGB cube, with the same hue and chroma as our color (using the intermediate value X for the second largest component of this color)
	H_ = H / 60

	X = C * (1 - Math.abs((H_ % 2) - 1))

	if (H == undefined || isNaN(H) || H == null)
		R1 = G1 = B1 = 0
	else
		if (H_ >= 0 && H_ < 1)
			R1 = C
			G1 = X
			B1 = 0
		else if (H_ >= 1 && H_ < 2)
			R1 = X
			G1 = C
			B1 = 0
		else if (H_ >= 2 && H_ < 3)
			R1 = 0
			G1 = C
			B1 = X
		else if (H_ >= 3 && H_ < 4)
			R1 = 0
			G1 = X
			B1 = C
		else if (H_ >= 4 && H_ < 5)
			R1 = X
			G1 = 0
			B1 = C
		else if (H_ >= 5 && H_ < 6)
			R1 = C
			G1 = 0
			B1 = X

	# Find R, G, and B by adding the same amount to each component, to match lightness
	m = L - (C / 2)

	# Normalise to range [0,255] by multiplying 255
	R = (R1 + m) * 255
	G = (G1 + m) * 255
	B = (B1 + m) * 255

	R = Math.round(R)
	G = Math.round(G)
	B = Math.round(B)
	
	R: R
	G: G
	B: B

class Pet

	default:
		name: 'Chromagochi'
		happiness: LIFE_MINUTES
	blinker: null
	
	status: null

	constructor: (callback) ->
		self = @
		@load ->
			callback() if callback?
			self.update()

	isAlive: ->
		@status.happiness > 0

	feed: =>
		@status.happiness = @default.happiness
		@save()
		@update()
		@stopBlinking()
	
	age: (minutes) =>
		@status.happiness--
		@save()
		@update()
		if @status.happiness == BLINK_LIMIT
			@startBlinking()

	update: =>
		chrome.browserAction.setBadgeText
			text: @status.happiness + ''
		l = 1-1/(1.3+@status.happiness/5)
		c = hsl2rgb 0, 1, l
		@_setColor [c.R, c.G, c.B, 255]

	clone: (object) ->
		JSON.parse(JSON.stringify(object))

	load: (callback) =>
		self = @
		chrome.storage.local.get STORAGE_KEY, (items) ->
			self.status = items[STORAGE_KEY] || self.clone self.default
			callback() if callback?
		true

	save: (callback) ->
		data = {}
		data[STORAGE_KEY] = @status
		chrome.storage.local.set data, ->
			callback() if callback?
		
	_setColor: (color) ->
		chrome.browserAction.setBadgeBackgroundColor
			color: color
		true

	startBlinking: =>
		self = @
		toggle = false
		@blinker = setInterval () ->
			color = [0, 0, 0, 255]
			if toggle
				color = [255, 0, 0, 255]
			self._setColor color
			toggle = !toggle

	stopBlinking: =>
		clearInterval(@blinker) if @blinker?
		@blinker = null
		true

class Chromagochi

	pet: null

	constructor: ->
		self = @
		@pet = new Pet null
		chrome.browserAction.onClicked.addListener (tab) ->
			self.pet.feed()
		chrome.alarms.onAlarm.addListener @processAlarm
		true

	start: ->
		chrome.alarms.create ALARM_NAME,
			periodInMinutes: TICK_MINUTES
		true

	stop: ->
		chrome.alarms.clear ALARM_NAME
		true

	processAlarm: (alarm) =>
		if alarm.name == ALARM_NAME
			@pet.age alarm.periodInMinutes if @pet.isAlive()

cg = new Chromagochi
cg.start()
