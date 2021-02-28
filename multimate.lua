local tab = require 'tabutil'
local NameSizer = include("namesizer/lib/namesizer")
samples_recorded = 0

function init()
  os.execute("mkdir -p ".._path.dust.."/audio/multimate")
  softcut.buffer_clear()
	audio.level_adc_cut(1)
  
  notes = {
    20, 30, 40, 50, 60, 
    70, 80, 90, 100, 108
  }
  
  midi_channels = {
    1, 2, 3, 4, 5, 6, 7, 8,
    9, 10, 11, 12, 13, 14, 15, 16
  }
  cur_midi_channel_idx = 1
  
  sample_length = 10.0
  samples_to_record = tab.count(notes)
  random_name = NameSizer.rnd()
  while string.len(random_name) < 10 do
    random_name = NameSizer.rnd()
  end
  working = false
  recording = false

end

function textwrap(s, w, offset, start_y)
  local len =  string.len(s)
  local strstore = {}
  local k = 1
    if len == 0 then
      screen.text()
    else 
      while k <= len do
        table.insert(strstore, string.sub(s, k, k+w-1))
        k = k + w
      end
      strposition = start_y + offset
      for v in pairs(strstore) do
        screen.text(strstore[v])
        screen.move(0, strposition)
        strposition = strposition + offset
      end 
    end 
end

function redraw()
  if working == true then
    screen.clear()
    screen.clear()
    screen.move(0, 10)
    screen.text(string.format("Saving to"))
    screen.level(15)
    screen.move(40, 60)
    screen.text(string.format("Recorded %d", samples_recorded))
    screen.line_width(30)
    screen.font_face(3)
    screen.font_size(12)
    screen.move(0, 30)
    textwrap(string.format("/multimate/"), 30, 0, 0)
    screen.move(10, 45)
    textwrap(string.format("%s-x", random_name), 30, 0, 0)
    screen.update()
  else   
    screen.clear()
    screen.move(20, 20)
    screen.level(15)
    screen.text("midi channel = " .. midi_channels[cur_midi_channel_idx])
    screen.move(20, 30)
    screen.text("sample length (s) " .. sample_length)
    screen.update()
  end
end

function record(n, rnd_name)
    softcut.rec(1, 1)
    m:note_on(n, midi_channels[cur_midi_channel_idx])
    print("NOTE ON: " .. n)
    clock.sleep(sample_length - 1.0)
    m:note_off(n, 127, midi_channels[cur_midi_channel_idx])
    print("NOTE OFF: " .. n)
    saved = _path.dust.."/audio/multimate/"..rnd_name.."-"..n..".wav"
    softcut.buffer_write_stereo(saved,1,sample_length)
    softcut.buffer_clear()
    softcut.rec(1, 0)
    samples_recorded = samples_recorded + 1
    print(samples_recorded)

end

function multisample()
  clock.run(send_notes)
end

function send_notes()
  m = midi.connect(1)
  random_name = NameSizer.rnd()
  for k,n,i in ipairs(notes) do
      clock.run(record, n, random_name)
      clock.sleep(sample_length + 0.2)
  end
end
      

  
function key(n, z)
  print(z)
  if n == 3 then
    if z == 0 then
      if working == true then
        working = false
      else
        -- call midi fn
        multisample()
        working = true
      end
    end
  end
  redraw()
end                                               

function enc(n,d)
  if n == 1 then
    if d > 0 then
      if cur_midi_channel_idx < 16 then
        cur_midi_channel_idx = cur_midi_channel_idx + 1
      end
    end
    if d < 0 then
      if cur_midi_channel_idx > 1 then
        cur_midi_channel_idx = cur_midi_channel_idx - 1
      end
    end
  end
  if n == 2 then
    if d > 0 then
      sample_length = sample_length + 0.10
    end
    if d < 0 then
      sample_length = sample_length - 0.10
    end
  end
  if cur_midi_channel_idx < 0 then
    cur_midi_channel_idx = 0
  end
  redraw()
end