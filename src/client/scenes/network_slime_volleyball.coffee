# asynchronously load socket.io if necessary
unless window.io
	s = document.createElement('script')
	s.setAttribute('src', '/socket.io/socket.io.js')
	document.head.appendChild(s)

class NetworkSlimeVolleyball extends SlimeVolleyball
	init: -> # load socket.io asynchronously
		super(true)
		@freezeGame = true
		@displayMsg = 'Loading...'
		@gameFrame = null
		@framebuffer = []
		@networkInterpolationRemainder = 0
		@world.deterministic = true # necessary for sync
		
		# initialize socket.io connection to server
		@socket.disconnect() && @socket = null if @socket
		@socket = io.connect()
		@socket.on 'connect', =>
			@displayMsg = 'Connected. Waiting for opponent...'
		@socket.on 'gameInit', (frame) =>
			@displayMsg = 'Opponent found! Game begins in 1 second...'
			@world.setFrame(frame)
		@socket.on 'gameStart', =>
			@freezeGame = false
			@displayMsg = null
			this.start()
		@socket.on 'gameFrame', (data) =>
			@gameFrame = data
		@socket.on 'roundEnd', (didWin, frame) =>
			@freezeGame = true
			if didWin
				@displayMsg = @winMsgs[Helpers.rand(@winMsgs.length-2)] 
				@p1.score += 1
			else
				@displayMsg = @failMsgs[Helpers.rand(@winMsgs.length-2)] 
				@p2.score += 1
		@socket.on 'gameEnd', (winner) =>
			@freezeGame = true
		@socket.on 'opponentLost', =>
			@freezeGame = true
			@displayMsg = 'Lost connection to opponent. Looking for new match...'
		@socketInitialized = true

	start: -> # prebuffer the first Constants.FRAME_DELAY frames
		for i in [0...Constants.FRAME_DELAY]
			@world.step(Constants.TICK_DURATION)
			@framebuffer.push(@world.getState())
		super()

	draw: ->
		frame = @framebuffer.shift() if @framebuffer # shift the front frame out of buf
		frame ||= @world.getState()
		# draw everything!
		@ctx.clearRect(0, 0, @width, @height) 
		@bg.draw(@ctx)
		@world.p1.draw(@ctx, frame.p1.x, frame.p1.y)
		@world.p2.draw(@ctx, frame.p2.x, frame.p2.y)
		@world.pole.draw(@ctx)
		@p1Scoreboard.draw(@ctx)
		@p2Scoreboard.draw(@ctx)
		@world.ball.draw(@ctx, frame.ball.x, frame.ball.y)

		# draw displayMsg, if any
		if @displayMsg
			@ctx.font = 'bold 14px '+ Constants.MSG_FONT
			@ctx.fillStyle = '#ffffff'
			@ctx.textAlign = 'center'
			msgs = @displayMsg.split("\n")
			@ctx.fillText(msgs[0], @width/2, 85)
			if msgs.length > 1 # draw sub text
				@ctx.font = 'bold 11px ' + Constants.MSG_FONT
				@ctx.fillText(msgs[1], @width/2, 110)

	step: (timestamp) ->
		this.next()
		if @gameFrame
			f = @gameFrame
			@gameFrame = null
			@world.injectFrame(f)

		if @freezeGame || !@socketInitialized # freeze everything!
			@gameStateBuffer.push(@world.getState()) if @gameStateBuffer
			this.draw()
			return
		if this.inputChanged() # send update to server that input has changed
			frame = 
				input: 
					p1: @keyState
				state: 
					p1: @world.p1.getState()
					clock: @world.clock
			#eval('debugger')
			@socket.emit('input', frame)
			#@world.injectFrame(frame)
		@world.step() # step physics
		@framebuffer.push(@world.getState()) # save in buffer
		this.draw() # we overrode this to draw frame at front of buffer

	destroy: ->
		@socket.disconnect()