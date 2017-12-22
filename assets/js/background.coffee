TICK_MINUTES = 1
ALARM_NAME = 'tick'
STORAGE_KEY = 'chromagochi'
LIFE_MINUTES = 120
BLINK_INTERVAL = 300
BLINK_LIMIT = 30
MAX_HUE = 359
NAME = 'Chromagochi'

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

intervals = [
  {
    label: 'year'
    seconds: 31536000
  }
  {
    label: 'month'
    seconds: 2592000
  }
  {
    label: 'day'
    seconds: 86400
  }
  {
    label: 'hour'
    seconds: 3600
  }
  {
    label: 'minute'
    seconds: 60
  }
  {
    label: 'second'
    seconds: 1
  }
]

timeSince = (date) ->
	seconds = Math.floor((Date.now() - date.getTime()) / 1000)
	interval = intervals.find((i) ->
		i.seconds <= seconds
	)
	count = Math.floor(seconds / interval.seconds)
	ending = 's'
	if count == 1
		ending = ''
	count + ' ' + interval.label + ending

class Pet

	default:
		name: 'Chromagochi'
		happiness: LIFE_MINUTES
		dead_times: 0
		feed_times: 0
		born: new Date().getTime()
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
		window._gaq.push(['_trackEvent', @status.happiness, 'feed'])
		if !@isAlive()
			@status.born = new Date().getTime() - 1000;
		if @status.happiness != @default.happiness
			@status.feed_times = (@status.feed_times || 0) + 1
			window._gaq.push(['_trackEvent', @status.feed_times, 'feed'])
		@status.happiness = @default.happiness
		@save()
		@stopBlinking()
		@update()

	age: (minutes) =>
		@status.happiness--
		if @status.happiness == 0
			@status.dead_times = (@status.dead_times || 0) + 1
			window._gaq.push(['_trackEvent', @status.dead_times, 'dead'])
		@save()
		@update()
		if @status.happiness == BLINK_LIMIT
			@startBlinking()

	update: =>
		chrome.browserAction.setBadgeText
			text: @status.happiness + ''
		if !@blinker?
			#l = 1-1/(1.3+@status.happiness/5)
			#c = hsl2rgb 0, 1, l
			h = Math.round ((@status.happiness - BLINK_LIMIT)/(LIFE_MINUTES-BLINK_LIMIT)) * MAX_HUE
			h = (30 + h) % MAX_HUE
			c = hsl2rgb h, 1, 0.8
			@_setColor [c.R, c.G, c.B, 255]
		chrome.browserAction.setTitle
			title: NAME + " #" + (@status.dead_times + 1) + "\n" + "Born: " + timeSince(new Date(@status.born)) + " ago"

	clone: (object) ->
		JSON.parse(JSON.stringify(object))

	load: (callback) =>
		self = @
		chrome.storage.local.get STORAGE_KEY, (items) ->
			self.status = items[STORAGE_KEY] || self.clone self.default
			if !self.status.dead_times
				self.status.dead_times = 0
			if !self.status.born
				self.status.born = new Date().getTime()
			callback() if callback?
		true

	save: (callback) ->
		data = {}
		if !@status.born
			@status.born = new Date().getTime()
		if !@dead_times
			@dead_times = 0
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
		, BLINK_INTERVAL

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

((global) ->
	global._gaq = global._gaq || []
	global._gaq.push ['_setAccount', 'UA-115818-75']
	global._gaq.push ['_trackPageview']

	(->
		ga = document.createElement("script")
		ga.type = "text/javascript"
		ga.async = true
		ga.src = "https://ssl.google-analytics.com/ga.js"
		s = document.getElementsByTagName("script")[0]
		s.parentNode.insertBefore ga, s
		return
	)()
)(window)

cg = new Chromagochi
cg.start()
