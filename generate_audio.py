import wave, math, struct
from pathlib import Path
p=Path(__file__).parent/'assets'
for name, tones, dur in [('flip',[370,510],.18),('pickup',[640,810,1040],.22),('hit',[220,150],.27),('win',[440,550,660,880],.48)]:
 rate=22050; frames=[]
 for i in range(int(rate*dur)):
  t=i/rate; k=min(int(t/dur*len(tones)),len(tones)-1)
  env=min(1,t/.013)*max(0,1-t/dur)**1.5
  s=.22*env*(math.sin(2*math.pi*tones[k]*t)+.22*math.sin(2*math.pi*tones[k]*2*t))
  frames.append(struct.pack('<h',round(s*32767)))
 with wave.open(str(p/(name+'.wav')),'wb') as f:
  f.setnchannels(1); f.setsampwidth(2); f.setframerate(rate); f.writeframes(b''.join(frames))
