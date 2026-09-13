extends SceneTree

func _init() -> void:
	print("Generating UI sounds...")
	
	# Generate Hover Sound (Sine wave sweep up)
	var hover_stream = AudioStreamWAV.new()
	hover_stream.format = AudioStreamWAV.FORMAT_16_BITS
	hover_stream.mix_rate = 44100
	hover_stream.stereo = false
	var hover_data = PackedByteArray()
	var num_samples = int(44100.0 * 0.04) # 40ms
	for i in range(num_samples):
		var t = float(i) / 44100.0
		var progress = float(i) / num_samples
		var freq = lerp(300.0, 400.0, progress)
		
		var env = 1.0
		if progress < 0.1: env = progress / 0.1
		elif progress > 0.9: env = (1.0 - progress) / 0.1
		
		var val = sin(2.0 * PI * freq * t) * 0.3 * env
		var int_val = int(val * 32767.0)
		hover_data.append(int_val & 0xFF)
		hover_data.append((int_val >> 8) & 0xFF)
	hover_stream.data = hover_data
	ResourceSaver.save(hover_stream, "res://assets/audio/ui/ui_hover.tres")
	
	# Generate Click Sound (Square wave sweep down)
	var click_stream = AudioStreamWAV.new()
	click_stream.format = AudioStreamWAV.FORMAT_16_BITS
	click_stream.mix_rate = 44100
	click_stream.stereo = false
	var click_data = PackedByteArray()
	var click_samples = int(44100.0 * 0.06) # 60ms
	for i in range(click_samples):
		var t = float(i) / 44100.0
		var progress = float(i) / click_samples
		var freq = lerp(600.0, 500.0, progress)
		
		var env = 1.0
		if progress < 0.1: env = progress / 0.1
		elif progress > 0.9: env = (1.0 - progress) / 0.1
		
		var val = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		val = val * 0.3 * env
		var int_val = int(val * 32767.0)
		click_data.append(int_val & 0xFF)
		click_data.append((int_val >> 8) & 0xFF)
	click_stream.data = click_data
	ResourceSaver.save(click_stream, "res://assets/audio/ui/ui_click.tres")
	
	print("Sounds generated in res://assets/audio/ui/")
	quit()
